import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/providers.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/db/database.dart';
import '../../../main.dart';

// ─── NotesPane — embeddable widget (no Scaffold) ─────────────────────────────
// State is public so TasksScreen can call newNote() via GlobalKey.

class NotesPane extends ConsumerStatefulWidget {
  const NotesPane({super.key});

  @override
  NotesPaneState createState() => NotesPaneState();
}

class NotesPaneState extends ConsumerState<NotesPane> {
  int?   _selectedId;
  String _searchQuery = '';

  final _searchCtrl = TextEditingController();
  final _titleCtrl  = TextEditingController();
  final _bodyCtrl   = TextEditingController();

  Timer? _saveTimer;
  List<NoteItemTableData> _notes = [];

  ThemeTokens get _t => ThemeTokens.of(context);

  @override
  void dispose() {
    _saveTimer?.cancel();
    _flushSave();
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // ── Public API (called via GlobalKey from TasksScreen) ────────────────────

  Future<void> newNote() async {
    _flushSave();
    final id = await database.addNote();
    await Future.microtask(() {});
    if (!mounted) return;
    final notes = ref.read(notesProvider).valueOrNull ?? [];
    final note  = notes.where((n) => n.id == id).firstOrNull;
    if (note != null) _select(note);
  }

  // ── Selection & auto-save ──────────────────────────────────────────────────

  void _select(NoteItemTableData note) {
    if (_selectedId == note.id) return;
    _flushSave();
    setState(() => _selectedId = note.id);
    _titleCtrl.text = note.title == 'Без названия' ? '' : note.title;
    _bodyCtrl.text  = note.body;
  }

  void _onChanged() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _flushSave);
  }

  void _flushSave() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final id = _selectedId;
    if (id == null) return;
    final title = _titleCtrl.text.trim();
    database.updateNote(id,
        title: title.isEmpty ? 'Без названия' : title,
        body:  _bodyCtrl.text);
  }

  Future<void> _deleteSelected() async {
    final id = _selectedId;
    if (id == null) return;
    _saveTimer?.cancel();
    setState(() => _selectedId = null);
    _titleCtrl.clear();
    _bodyCtrl.clear();
    await database.deleteNote(id);
  }

  Future<void> _togglePin(NoteItemTableData note) =>
      database.updateNote(note.id, isPinned: !note.isPinned);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _t;
    _notes = ref.watch(notesProvider).valueOrNull ?? [];

    // If selected note was deleted, clear selection
    final selected = _selectedId == null
        ? null
        : _notes.where((n) => n.id == _selectedId).firstOrNull;
    if (selected == null && _selectedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedId = null);
      });
    }

    final q = _searchQuery.toLowerCase();
    final visible = q.isEmpty
        ? _notes
        : _notes.where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q)).toList();

    final pinned  = visible.where((n) => n.isPinned).toList();
    final regular = visible.where((n) => !n.isPinned).toList();

    return Row(
      children: [
        // ── Sidebar ──
        SizedBox(
          width: 240,
          child: Column(
            children: [
              _buildSearch(t),
              Divider(height: 1, color: t.divider),
              Expanded(child: _buildList(t, pinned, regular)),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: t.divider),
        // ── Editor ──
        Expanded(
          child: selected == null
              ? _buildEmptyState(context, t)
              : _buildEditor(context, t, selected),
        ),
      ],
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Widget _buildSearch(ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: t.surfaceSunken,
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(Icons.search, size: 15, color: t.text3),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 13, color: t.text1),
                decoration: InputDecoration(
                  hintText: 'Поиск по заметкам...',
                  hintStyle: TextStyle(fontSize: 13, color: t.text4),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.close, size: 13, color: t.text4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Note list ─────────────────────────────────────────────────────────────

  Widget _buildList(ThemeTokens t,
      List<NoteItemTableData> pinned, List<NoteItemTableData> regular) {
    if (pinned.isEmpty && regular.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 32, color: t.text4),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isEmpty ? 'Нет заметок' : 'Ничего не найдено',
              style: TextStyle(fontSize: 13, color: t.text4),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      children: [
        if (pinned.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Text('ЗАКРЕПЛЁННЫЕ',
                style: AppTypography.caps(color: t.text4)),
          ),
          ...pinned.map((n) => _NoteCard(
                note: n, selected: n.id == _selectedId,
                t: t, onTap: () => _select(n))),
          if (regular.isNotEmpty) const SizedBox(height: 8),
        ],
        if (regular.isNotEmpty) ...[
          if (pinned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Text('ОСТАЛЬНЫЕ',
                  style: AppTypography.caps(color: t.text4)),
            ),
          ...regular.map((n) => _NoteCard(
                note: n, selected: n.id == _selectedId,
                t: t, onTap: () => _select(n))),
        ],
      ],
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, ThemeTokens t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 48, color: t.text4),
          const SizedBox(height: 14),
          Text(
            _notes.isEmpty
                ? 'Здесь будут твои заметки'
                : 'Выбери заметку слева',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: t.text3),
          ),
          if (_notes.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Нажми «Новая заметка» чтобы начать',
              style: TextStyle(fontSize: 13, color: t.text4),
            ),
          ],
        ],
      ),
    );
  }

  // ── Editor ────────────────────────────────────────────────────────────────

  Widget _buildEditor(
      BuildContext context, ThemeTokens t, NoteItemTableData note) {
    final wordCount = _bodyCtrl.text.trim().isEmpty
        ? 0
        : _bodyCtrl.text.trim().split(RegExp(r'\s+')).length;
    final charCount = _bodyCtrl.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          child: Row(
            children: [
              Text(
                _fmtDate(note.updatedAt),
                style: TextStyle(fontSize: 12, color: t.text4),
              ),
              const SizedBox(width: 12),
              Text(
                '$wordCount сл · $charCount симв',
                style: TextStyle(fontSize: 12, color: t.text4),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _togglePin(note),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      note.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      size: 18,
                      color: note.isPinned ? t.accentPress : t.text3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _confirmDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.delete_outline,
                        size: 18, color: t.text3),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: t.divider),
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl3, AppSpacing.xl2, AppSpacing.xl3, 0),
          child: TextField(
            controller: _titleCtrl,
            onChanged: (_) => _onChanged(),
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: t.text1,
                height: 1.2),
            decoration: InputDecoration(
              hintText: 'Без названия',
              hintStyle: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: t.text4,
                  height: 1.2),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        // Body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl3, AppSpacing.md,
                AppSpacing.xl3, AppSpacing.xl3),
            child: TextField(
              controller: _bodyCtrl,
              onChanged: (_) => _onChanged(),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(fontSize: 15, height: 1.65, color: t.text1),
              decoration: InputDecoration(
                hintText: 'Начни писать...',
                hintStyle: TextStyle(fontSize: 15, color: t.text4),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Delete confirmation ───────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final t = _t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text('Удалить заметку?',
            style: Theme.of(ctx).textTheme.titleLarge),
        content: Text('Это действие нельзя отменить.',
            style: TextStyle(fontSize: 14, color: t.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteSelected();
  }

  // ── Date formatter ────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) {
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(d.year, d.month, d.day);
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (noteDay == today) return 'сегодня $hh:$mm';
    final yesterday = today.subtract(const Duration(days: 1));
    if (noteDay == yesterday) return 'вчера $hh:$mm';
    return '${d.day.toString().padLeft(2,'0')}.'
        '${d.month.toString().padLeft(2,'0')}.${d.year}  $hh:$mm';
  }
}

// ─── Note card ────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.selected,
    required this.t,
    required this.onTap,
  });

  final NoteItemTableData note;
  final bool              selected;
  final ThemeTokens       t;
  final VoidCallback      onTap;

  @override
  Widget build(BuildContext context) {
    final title   = note.title.isEmpty ? 'Без названия' : note.title;
    final preview = note.body.isEmpty
        ? 'Нет текста'
        : note.body.replaceAll('\n', ' ').trim();
    final fg  = selected ? t.accentPress : t.text1;
    final fg2 = selected
        ? t.accentPress.withValues(alpha: 0.65)
        : t.text3;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? t.accentTint : Colors.transparent,
            borderRadius: AppRadius.smAll,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: fg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: TextStyle(fontSize: 12, color: fg2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (note.isPinned) ...[
                const SizedBox(width: 4),
                Icon(Icons.push_pin, size: 11, color: fg2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

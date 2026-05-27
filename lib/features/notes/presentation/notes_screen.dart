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

// ─── Screen ──────────────────────────────────────────────────────────────────

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  int?   _selectedId;
  String _searchQuery = '';
  bool   _sidebarVisible = true;

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

  // ── Selection ─────────────────────────────────────────────────

  void _select(NoteItemTableData note) {
    if (_selectedId == note.id) return;
    _flushSave();
    setState(() => _selectedId = note.id);
    _titleCtrl.text = note.title == 'Без названия' ? '' : note.title;
    _bodyCtrl.text  = note.body;
  }

  // ── Auto-save (debounced 700 ms) ──────────────────────────────

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

  // ── New note ──────────────────────────────────────────────────

  Future<void> _newNote() async {
    _flushSave();
    final id = await database.addNote();
    // Wait one frame so the stream rebuilds the list
    await Future.microtask(() {});
    if (!mounted) return;
    final notes = ref.read(notesProvider).valueOrNull ?? [];
    final note  = notes.where((n) => n.id == id).firstOrNull;
    if (note != null) _select(note);
  }

  // ── Delete current note ───────────────────────────────────────

  Future<void> _deleteSelected() async {
    final id = _selectedId;
    if (id == null) return;
    _saveTimer?.cancel();
    setState(() => _selectedId = null);
    _titleCtrl.clear();
    _bodyCtrl.clear();
    await database.deleteNote(id);
  }

  // ── Pin toggle ────────────────────────────────────────────────

  Future<void> _togglePin(NoteItemTableData note) =>
      database.updateNote(note.id, isPinned: !note.isPinned);

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _t;
    _notes = ref.watch(notesProvider).valueOrNull ?? [];

    // Selected note (may have been deleted)
    final selected = _selectedId == null
        ? null
        : _notes.where((n) => n.id == _selectedId).firstOrNull;
    if (selected == null && _selectedId != null) {
      // Was deleted externally
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedId = null);
      });
    }

    // Filter
    final q = _searchQuery.toLowerCase();
    final visible = q.isEmpty
        ? _notes
        : _notes
            .where((n) =>
                n.title.toLowerCase().contains(q) ||
                n.body.toLowerCase().contains(q))
            .toList();

    final pinned  = visible.where((n) => n.isPinned).toList();
    final regular = visible.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: t.bg,
      body: Row(
        children: [
          // ── Sidebar ──
          SizedBox(
            width: 260,
            child: Column(
              children: [
                _buildSidebarHeader(context, t),
                Divider(height: 1, color: t.divider),
                _buildSearch(t),
                Expanded(
                  child: _buildNoteList(t, pinned, regular),
                ),
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
      ),
    );
  }

  // ── Sidebar header ────────────────────────────────────────────

  Widget _buildSidebarHeader(BuildContext context, ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.xl),
      child: Row(
        children: [
          Text('Заметки',
              style: Theme.of(context).textTheme.headlineLarge),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _newNote,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────

  Widget _buildSearch(ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: t.surfaceSunken,
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(Icons.search, size: 14, color: t.text3),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 13, color: t.text1),
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  hintStyle: TextStyle(fontSize: 13, color: t.text4),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
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

  // ── Note list ─────────────────────────────────────────────────

  Widget _buildNoteList(ThemeTokens t,
      List<NoteItemTableData> pinned, List<NoteItemTableData> regular) {
    if (pinned.isEmpty && regular.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 36, color: t.text4),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isEmpty
                  ? 'Нет заметок'
                  : 'Ничего не найдено',
              style: TextStyle(fontSize: 13, color: t.text4),
              textAlign: TextAlign.center,
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
                note: n,
                selected: n.id == _selectedId,
                t: t,
                onTap: () => _select(n),
              )),
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
                note: n,
                selected: n.id == _selectedId,
                t: t,
                onTap: () => _select(n),
              )),
        ],
      ],
    );
  }

  // ── Empty state ───────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, ThemeTokens t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 56, color: t.text4),
          const SizedBox(height: 16),
          Text(
            _notes.isEmpty
                ? 'Здесь будут твои заметки'
                : 'Выбери заметку слева',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: t.text3),
          ),
          const SizedBox(height: 6),
          Text(
            _notes.isEmpty ? 'Нажми + чтобы создать первую' : '',
            style: TextStyle(fontSize: 14, color: t.text4),
          ),
          if (_notes.isEmpty) ...[
            const SizedBox(height: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton.icon(
                onPressed: _newNote,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Новая заметка'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Editor ────────────────────────────────────────────────────

  Widget _buildEditor(
      BuildContext context, ThemeTokens t, NoteItemTableData note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Toolbar ──
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          child: Row(
            children: [
              Text(
                _fmtDate(note.updatedAt),
                style: TextStyle(fontSize: 12, color: t.text4),
              ),
              const Spacer(),
              // Word count
              _buildWordCount(t),
              const SizedBox(width: 16),
              // Pin button
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
              const SizedBox(width: 4),
              // Delete button
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
        // ── Title field ──
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl3, AppSpacing.xl2, AppSpacing.xl3, 0),
          child: TextField(
            controller: _titleCtrl,
            onChanged: (_) => _onChanged(),
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: t.text1,
                height: 1.2),
            decoration: InputDecoration(
              hintText: 'Без названия',
              hintStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: t.text4,
                  height: 1.2),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        // ── Body field ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl3, AppSpacing.lg,
                AppSpacing.xl3, AppSpacing.xl3),
            child: TextField(
              controller: _bodyCtrl,
              onChanged: (_) => _onChanged(),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                  fontSize: 15, height: 1.65, color: t.text1),
              decoration: InputDecoration(
                hintText: 'Начни писать...',
                hintStyle:
                    TextStyle(fontSize: 15, color: t.text4),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Word / char count ─────────────────────────────────────────

  Widget _buildWordCount(ThemeTokens t) {
    final body   = _bodyCtrl.text;
    final words  = body.trim().isEmpty
        ? 0
        : body.trim().split(RegExp(r'\s+')).length;
    final chars  = body.length;
    return Text(
      '$words сл · $chars симв',
      style: TextStyle(fontSize: 11, color: t.text4),
    );
  }

  // ── Delete confirmation ───────────────────────────────────────

  Future<void> _confirmDelete() async {
    final t = _t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text('Удалить заметку?',
            style: Theme.of(ctx).textTheme.titleLarge),
        content: Text(
          'Это действие нельзя отменить.',
          style: TextStyle(fontSize: 14, color: t.text2),
        ),
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
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteSelected();
  }

  // ── Helpers ───────────────────────────────────────────────────

  static String _fmtDate(DateTime d) {
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(d.year, d.month, d.day);
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (noteDay == today) return 'сегодня $hh:$mm';
    final yesterday = today.subtract(const Duration(days: 1));
    if (noteDay == yesterday) return 'вчера $hh:$mm';
    final dd  = d.day.toString().padLeft(2, '0');
    final mo  = d.month.toString().padLeft(2, '0');
    return '$dd.$mo.${d.year}  $hh:$mm';
  }
}

// ─── Note card (sidebar list item) ───────────────────────────────────────────

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

    final fg = selected ? t.accentPress : t.text1;
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

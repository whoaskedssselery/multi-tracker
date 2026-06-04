import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../app/providers/providers.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/db/database.dart';
import '../../../core/notifications/notifications_service.dart';
import '../../../main.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/page_header.dart';
import '../../notes/presentation/notes_screen.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _folderLabels = [
  'Все активные',
  'Сегодня',
  'Завтра',
  'Эта неделя',
  'Позже',
  'Без даты',
  'Выполненные',
];

const _groupKeys   = ['today', 'tomorrow', 'week', 'later', 'none'];
const _groupLabels = ['Сегодня', 'Завтра', 'На неделе', 'Позже', 'Без даты'];

const _priorityKeys   = ['none', 'low', 'mid', 'high'];
const _priorityLabels = ['нет', 'низкий', 'средний', 'высокий'];

// ─── Tab ─────────────────────────────────────────────────────────────────────

enum _Tab { tasks, notes }

// ─── Screen ──────────────────────────────────────────────────────────────────

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _Tab _activeTab = _Tab.tasks;
  int _folderIndex = 0;
  int? _selectedTaskId;
  String _searchQuery = '';
  final _searchCtrl   = TextEditingController();
  final _taskBodyCtrl = TextEditingController();
  final _notesPaneKey = GlobalKey<NotesPaneState>();

  // Resizable folder pane — width is dragged by the user and persisted.
  static const _kPaneWidthKey = 'tasks_folder_pane_width';
  static const double _kPaneMin = 160;
  static const double _kPaneMax = 420;
  final _storage = const FlutterSecureStorage();
  double _folderPaneWidth = 200;

  // Populated from provider each build.
  List<TaskItemTableData> _allTasks = [];

  ThemeTokens get _t => ThemeTokens.of(context);

  @override
  void initState() {
    super.initState();
    _storage.read(key: _kPaneWidthKey).then((v) {
      final w = double.tryParse(v ?? '');
      if (w != null && mounted) {
        setState(() => _folderPaneWidth = w.clamp(_kPaneMin, _kPaneMax));
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _taskBodyCtrl.dispose();
    super.dispose();
  }

  void _persistPaneWidth() {
    _storage.write(
        key: _kPaneWidthKey, value: _folderPaneWidth.toStringAsFixed(1));
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<TaskItemTableData> _forFolder(int idx) {
    final base = switch (idx) {
      0 => _allTasks.where((t) => !t.isDone),
      1 => _allTasks.where((t) => !t.isDone && t.group == 'today'),
      2 => _allTasks.where((t) => !t.isDone && t.group == 'tomorrow'),
      3 => _allTasks.where((t) => !t.isDone && t.group == 'week'),
      4 => _allTasks.where((t) => !t.isDone && t.group == 'later'),
      5 => _allTasks.where((t) => !t.isDone && t.group == 'none'),
      6 => _allTasks.where((t) => t.isDone),
      _ => _allTasks.where((_) => true),
    };
    if (_searchQuery.isEmpty) return base.toList();
    final q = _searchQuery.toLowerCase();
    return base.where((t) => t.body.toLowerCase().contains(q)).toList();
  }

  int _folderCount(int idx) => switch (idx) {
        0 => _allTasks.where((t) => !t.isDone).length,
        1 => _allTasks.where((t) => !t.isDone && t.group == 'today').length,
        2 => _allTasks.where((t) => !t.isDone && t.group == 'tomorrow').length,
        3 => _allTasks.where((t) => !t.isDone && t.group == 'week').length,
        4 => _allTasks.where((t) => !t.isDone && t.group == 'later').length,
        5 => _allTasks.where((t) => !t.isDone && t.group == 'none').length,
        6 => _allTasks.where((t) => t.isDone).length,
        _ => 0,
      };

  // ── Default group for current folder ─────────────────────────────────────

  String get _defaultGroup => switch (_folderIndex) {
        1 => 'today',
        2 => 'tomorrow',
        3 => 'week',
        4 => 'later',
        _ => 'none',
      };

  // ── Notification helpers ──────────────────────────────────────────────────

  static bool get _notifSupported => Platform.isIOS;

  Future<void> _scheduleOrCancelNotif({
    required int taskId,
    required String body,
    required DateTime? notifyAt,
    int? oldNotifId,
  }) async {
    if (!_notifSupported) return;
    if (oldNotifId != null) {
      await NotificationsService.instance.cancel(oldNotifId);
    }
    if (notifyAt != null && notifyAt.isAfter(DateTime.now())) {
      await NotificationsService.instance.scheduleTask(
        id: taskId,
        title: 'Напоминание о задаче',
        body: body,
        scheduledAt: notifyAt,
      );
      await database.setTaskNotificationId(taskId, taskId);
    } else {
      await database.setTaskNotificationId(taskId, null);
    }
  }

  // ── Task form dialog ──────────────────────────────────────────────────────

  Future<void> _showTaskForm({TaskItemTableData? editing}) async {
    _taskBodyCtrl.text = editing?.body ?? '';
    var group    = editing?.group    ?? _defaultGroup;
    var priority = editing?.priority ?? 'none';
    DateTime? notifyAt = editing?.notifyAt;

    Future<void> pickNotifyAt(StateSetter setDlg) async {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: notifyAt ?? now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );
      if (date == null || !mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(notifyAt ?? now),
      );
      if (time == null) return;
      setDlg(() => notifyAt = DateTime(
            date.year, date.month, date.day, time.hour, time.minute));
    }

    await showAppModal<void>(
      context,
      maxWidth: 480,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final t = ThemeTokens.of(ctx);
          final notifLabel = notifyAt == null
              ? 'Без напоминания'
              : _formatDateTime(notifyAt!);
          return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 12, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            editing == null
                                ? 'Новая задача'
                                : 'Изменить задачу',
                            style: Theme.of(ctx).textTheme.headlineMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: t.text3,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: t.divider),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    TextField(
                      controller: _taskBodyCtrl,
                      autofocus: true,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Что надо сделать?',
                        border: OutlineInputBorder(
                            borderRadius: AppRadius.mdAll,
                            borderSide:
                                BorderSide(color: t.border)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('КОГДА',
                        style: AppTypography.caps(color: t.text3)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_groupKeys.length, (i) {
                        final active = group == _groupKeys[i];
                        return _Chip(
                          label: _groupLabels[i],
                          active: active,
                          onTap: () =>
                              setDlg(() => group = _groupKeys[i]),
                          t: t,
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    Text('ПРИОРИТЕТ',
                        style: AppTypography.caps(color: t.text3)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          List.generate(_priorityKeys.length, (i) {
                        final active = priority == _priorityKeys[i];
                        return _Chip(
                          label: _priorityLabels[i],
                          active: active,
                          accentColor:
                              _priorityAccent(_priorityKeys[i], t),
                          onTap: () => setDlg(
                              () => priority = _priorityKeys[i]),
                          t: t,
                        );
                      }),
                    ),
                    if (_notifSupported) ...[
                      const SizedBox(height: 14),
                      Text('НАПОМИНАНИЕ',
                          style: AppTypography.caps(color: t.text3)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => pickNotifyAt(setDlg),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: notifyAt != null
                                        ? t.accentTint
                                        : t.surfaceSunken,
                                    borderRadius: AppRadius.smAll,
                                    border: Border.all(
                                        color: notifyAt != null
                                            ? t.accentPress
                                                .withValues(alpha: 0.4)
                                            : t.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.notifications_outlined,
                                          size: 14,
                                          color: notifyAt != null
                                              ? t.accentPress
                                              : t.text3),
                                      const SizedBox(width: 6),
                                      Text(notifLabel,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: notifyAt != null
                                                  ? t.accentPress
                                                  : t.text3,
                                              fontWeight: notifyAt != null
                                                  ? FontWeight.w500
                                                  : FontWeight.w400)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (notifyAt != null)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () =>
                                    setDlg(() => notifyAt = null),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8),
                                  child: Icon(Icons.close,
                                      size: 16, color: t.text3),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: t.divider),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                    child: Row(
                      children: [
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Отмена'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () async {
                  final body = _taskBodyCtrl.text.trim();
                  if (body.isEmpty) return;
                  if (editing == null) {
                    final id = await database.addTask(
                        body: body,
                        group: group,
                        priority: priority,
                        notifyAt: notifyAt);
                    await _scheduleOrCancelNotif(
                        taskId: id, body: body, notifyAt: notifyAt);
                  } else {
                    await database.updateTask(editing.id,
                        body: body,
                        group: group,
                        priority: priority,
                        notifyAt: notifyAt,
                        clearNotifyAt: notifyAt == null);
                    await _scheduleOrCancelNotif(
                        taskId: editing.id,
                        body: body,
                        notifyAt: notifyAt,
                        oldNotifId: editing.notificationId);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                          child: Text(
                              editing == null ? 'Создать' : 'Сохранить'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
        },
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _t;
    _allTasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final noteCount = ref.watch(notesProvider).valueOrNull?.length ?? 0;

    if (Platform.isIOS) return _buildMobile(context, t, noteCount);

    final visible    = _forFolder(_folderIndex);
    final selectedTask = _selectedTaskId == null
        ? null
        : _allTasks.where((t) => t.id == _selectedTaskId).firstOrNull;
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        children: [
          AppPageHeader(
            title: _activeTab == _Tab.tasks ? 'Задачи' : 'Заметки',
            actions: _buildHeaderActions(context, t, noteCount),
          ),
          Expanded(
            child: IndexedStack(
              index: _activeTab == _Tab.tasks ? 0 : 1,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                        width: _folderPaneWidth,
                        child: _buildFolderList(context, t)),
                    _buildResizeHandle(t),
                    Expanded(
                        child: _buildTaskList(context, t, visible)),
                    if (wide && selectedTask != null) ...[
                      VerticalDivider(width: 1, color: t.divider),
                      SizedBox(
                          width: 300,
                          child: _buildDetailPanel(
                              context, selectedTask, t)),
                    ],
                  ],
                ),
                NotesPane(key: _notesPaneKey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile build ─────────────────────────────────────────────────────────

  static const _kMobileGroups = [
    ('today',    'СЕГОДНЯ'),
    ('tomorrow', 'ЗАВТРА'),
    ('week',     'ЭТА НЕДЕЛЯ'),
    ('later',    'ПОЗЖЕ'),
    ('none',     'БЕЗ ДАТЫ'),
  ];

  Widget _buildMobile(BuildContext context, ThemeTokens t, int noteCount) {
    final totalActive = _allTasks.where((t) => !t.isDone).length;
    final title = _activeTab == _Tab.tasks ? 'Задачи' : 'Заметки';
    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IosPageHeader(
            title: title,
            action: GestureDetector(
              onTap: _activeTab == _Tab.tasks
                  ? () => _showTaskForm()
                  : () async {
                      final id = await database.addNote();
                      if (mounted) setState(() => _mobileSelectedNoteId = id);
                    },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add, size: 26, color: t.text2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _mobileTabSwitcher(t, totalActive, noteCount),
          ),
          Expanded(
            child: _activeTab == _Tab.tasks
                ? _buildMobileTaskGroups(t)
                : _buildMobileNotesList(context, t),
          ),
        ],
      ),
    );
  }

  // ── Mobile notes list (full-screen, no sidebar) ───────────────────────────

  Widget _buildMobileNotesList(BuildContext context, ThemeTokens t) {
    final notes = ref.watch(notesProvider).valueOrNull ?? [];
    // If a note is selected, show full-screen editor instead
    if (_mobileSelectedNoteId != null) {
      final note = notes
          .where((n) => n.id == _mobileSelectedNoteId)
          .firstOrNull;
      if (note != null) {
        return _buildMobileNoteEditor(context, t, note);
      }
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: t.borderSoft),
            ),
            child: Row(children: [
              const SizedBox(width: 12),
              Icon(Icons.search, size: 16, color: t.text3),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(fontSize: 15, color: t.text1),
                  decoration: InputDecoration(
                    hintText: 'Поиск',
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
              if (_searchQuery.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.close, size: 14, color: t.text4),
                  ),
                ),
              ] else
                const SizedBox(width: 12),
            ]),
          ),
        ),
        Expanded(
          child: notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 40, color: t.text4),
                      const SizedBox(height: 12),
                      Text('Нет заметок',
                          style: TextStyle(fontSize: 15, color: t.text3)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: _filteredNotes(notes).length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: t.borderSoft,
                          indent: 0, endIndent: 0),
                  itemBuilder: (ctx, i) {
                    final note = _filteredNotes(notes)[i];
                    return _MobileNoteRow(
                      note: note,
                      t: t,
                      onTap: () => setState(
                          () => _mobileSelectedNoteId = note.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<NoteItemTableData> _filteredNotes(List<NoteItemTableData> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q))
        .toList();
  }

  // Track selected note for mobile editor
  int? _mobileSelectedNoteId;

  Widget _buildMobileNoteEditor(
      BuildContext context, ThemeTokens t, NoteItemTableData note) {
    return _MobileNoteEditorView(
      key: ValueKey(note.id),
      note: note,
      onBack: () => setState(() => _mobileSelectedNoteId = null),
    );
  }

  Widget _mobileTabSwitcher(ThemeTokens t, int taskCount, int noteCount) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(children: [
        _mobileTabPill('Tasks · $taskCount', _activeTab == _Tab.tasks,
            () => setState(() => _activeTab = _Tab.tasks), t),
        _mobileTabPill('Notes · $noteCount', _activeTab == _Tab.notes,
            () => setState(() => _activeTab = _Tab.notes), t),
      ]),
    );
  }

  Widget _mobileTabPill(
      String label, bool active, VoidCallback onTap, ThemeTokens t) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? t.surface : Colors.transparent,
            borderRadius: AppRadius.smAll,
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 2,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? t.text1 : t.text3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTaskGroups(ThemeTokens t) {
    final done = _allTasks.where((t) => t.isDone).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        for (final (key, label) in _kMobileGroups) ...[
          _mobileGroup(t, key, label),
        ],
        if (done.isNotEmpty) ...[
          _mobileGroupHeader(t, 'ВЫПОЛНЕНО'),
          _mobileGroupCard(t, done),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _mobileGroup(ThemeTokens t, String groupKey, String label) {
    final tasks = _allTasks
        .where((t) => !t.isDone && t.group == groupKey)
        .toList();
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _mobileGroupHeader(t, label),
        _mobileGroupCard(t, tasks),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _mobileGroupHeader(ThemeTokens t, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6, left: 4),
      child: Text(label, style: AppTypography.caps(color: t.text3)),
    );
  }

  Widget _mobileGroupCard(ThemeTokens t, List<TaskItemTableData> tasks) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: t.borderSoft),
      ),
      child: Column(
        children: tasks.asMap().entries.map((e) {
          final i = e.key;
          final task = e.value;
          final isLast = i == tasks.length - 1;
          return _MobileTaskRow(
            task: task,
            isLast: isLast,
            t: t,
            onToggle: () async {
              final done = !task.isDone;
              await database.toggleTaskDone(task.id, done: done);
              if (done && task.notificationId != null) {
                await NotificationsService.instance
                    .cancel(task.notificationId!);
                await database.setTaskNotificationId(task.id, null);
              }
            },
            onTap: () => _showTaskForm(editing: task),
          );
        }).toList(),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  static const double _kHeaderControlH = 40;

  List<Widget> _buildHeaderActions(
      BuildContext context, ThemeTokens t, int noteCount) {
    final totalActive = _allTasks.where((t) => !t.isDone).length;

    return [
      // Segmented switcher — height matches the button next to it.
      Container(
        height: _kHeaderControlH,
        decoration: BoxDecoration(
          border: Border.all(color: t.border),
          borderRadius: AppRadius.smAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = _Tab.tasks),
                child: _tabPill(context, 'Задачи', totalActive,
                    _activeTab == _Tab.tasks, t),
              ),
            ),
            Container(width: 1, height: _kHeaderControlH, color: t.border),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = _Tab.notes),
                child: _tabPill(context, 'Заметки', noteCount,
                    _activeTab == _Tab.notes, t),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      // Fixed width so switching задача/заметка never shifts the switcher.
      SizedBox(
        width: 176,
        height: _kHeaderControlH,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(176, _kHeaderControlH),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _activeTab == _Tab.tasks
              ? () => _showTaskForm()
              : () => _notesPaneKey.currentState?.newNote(),
          icon: const Icon(Icons.add, size: 16),
          label: Text(_activeTab == _Tab.tasks
              ? 'Новая задача'
              : 'Новая заметка'),
        ),
      ),
    ];
  }

  Widget _tabPill(BuildContext context, String label, int count,
      bool active, ThemeTokens t) {
    return Container(
      height: _kHeaderControlH,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      color: active ? t.surfaceSunken : Colors.transparent,
      child: Text(
        '$label · $count',
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? t.text1 : t.text3),
      ),
    );
  }

  // ── Resizable handle between folder pane and list ──────────────────────────

  Widget _buildResizeHandle(ThemeTokens t) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) {
          setState(() {
            _folderPaneWidth = (_folderPaneWidth + d.delta.dx)
                .clamp(_kPaneMin, _kPaneMax);
          });
        },
        onHorizontalDragEnd: (_) => _persistPaneWidth(),
        child: Container(
          width: 9,
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: t.divider)),
          ),
        ),
      ),
    );
  }

  // ── Folder list ───────────────────────────────────────────────────────────

  Widget _buildFolderList(BuildContext context, ThemeTokens t) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.md),
      itemCount: _folderLabels.length,
      itemBuilder: (_, i) {
        final active = i == _folderIndex;
        final count  = _folderCount(i);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() {
              _folderIndex = i;
              _selectedTaskId = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color:
                    active ? t.accentTint : Colors.transparent,
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_folderLabels[i],
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: active
                                ? t.accentPress
                                : t.text2)),
                  ),
                  Text('$count',
                      style: TextStyle(
                          fontSize: 12,
                          color: active
                              ? t.accentPress
                              : t.text4)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Task list ─────────────────────────────────────────────────────────────

  Widget _buildTaskList(BuildContext context, ThemeTokens t,
      List<TaskItemTableData> visible) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: t.surfaceSunken,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, size: 16, color: t.text3),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Поиск задач...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: t.text3),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style:
                        TextStyle(fontSize: 13, color: t.text1),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.close,
                          size: 14, color: t.text3),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'Ничего не найдено'
                        : _folderIndex == 6
                            ? 'Выполненных задач нет'
                            : 'Задач нет.\nНажми «Новая задача».',
                    style: TextStyle(
                        fontSize: 14, color: t.text4),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final task = visible[i];
                    return _TaskRow(
                      task: task,
                      selected: task.id == _selectedTaskId,
                      t: t,
                      onTap: () => setState(
                          () => _selectedTaskId = task.id),
                      onToggle: () async {
                      final done = !task.isDone;
                      await database.toggleTaskDone(task.id, done: done);
                      if (done && task.notificationId != null) {
                        await NotificationsService.instance
                            .cancel(task.notificationId!);
                        await database.setTaskNotificationId(task.id, null);
                      }
                    },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Detail panel ──────────────────────────────────────────────────────────

  Widget _buildDetailPanel(
      BuildContext context, TaskItemTableData task, ThemeTokens t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ЗАДАЧА',
              style: AppTypography.caps(color: t.text3)),
          const SizedBox(height: 8),
          Text(task.body,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: t.text1)),
          const SizedBox(height: 20),
          _detailRow('Когда',
              _groupDisplayLabel(task.group), t),
          _detailRow('Приоритет',
              _priorityDisplayLabel(task.priority), t,
              dot: task.priority != 'none',
              valueColor: _priorityColor(task.priority, t)),
          _detailRow('Повтор', task.recurrence == 'none' ? 'нет' : task.recurrence, t),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DetailButton(
                  label: 'Изменить',
                  icon: Icons.edit_outlined,
                  t: t,
                  onTap: () => _showTaskForm(editing: task),
                ),
              ),
              const SizedBox(width: 8),
              _DetailButton(
                icon: Icons.delete_outline,
                iconColor: AppColors.danger,
                t: t,
                squareSize: 40,
                onTap: () async {
                  if (task.notificationId != null) {
                    await NotificationsService.instance
                        .cancel(task.notificationId!);
                  }
                  await database.deleteTask(task.id);
                  if (mounted) setState(() => _selectedTaskId = null);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, ThemeTokens t,
      {Color? valueColor, bool dot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: t.text3)),
          ),
          if (dot)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: valueColor ?? t.text3,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? t.text1)),
          ),
        ],
      ),
    );
  }

  // ── Label helpers ─────────────────────────────────────────────────────────

  static String _groupDisplayLabel(String group) => switch (group) {
        'today'    => 'Сегодня',
        'tomorrow' => 'Завтра',
        'week'     => 'На неделе',
        'later'    => 'Позже',
        _          => 'Без даты',
      };

  static String _priorityDisplayLabel(String p) => switch (p) {
        'low'  => 'низкий',
        'mid'  => 'средний',
        'high' => 'высокий',
        _      => 'нет',
      };

  static Color? _priorityColor(String p, ThemeTokens t) => switch (p) {
        'low'  => t.text3,
        'mid'  => t.warning,
        'high' => t.danger,
        _      => null,
      };

  static Color? _priorityAccent(String p, ThemeTokens t) => switch (p) {
        'low'  => t.text3,
        'mid'  => t.warning,
        'high' => t.danger,
        _      => null,
      };
}

// ─── Small chip widget (used inside dialog) ───────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.t,
    this.accentColor,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final ThemeTokens t;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final fg = accentColor ?? t.accentPress;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? t.accentTint : t.surfaceSunken,
          borderRadius: AppRadius.pill,
          border: Border.all(
              color: active ? fg.withValues(alpha: 0.4) : t.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                active ? FontWeight.w600 : FontWeight.w400,
            color: active ? fg : t.text2,
          ),
        ),
      ),
    ),
    );
  }
}

// ─── Detail button ────────────────────────────────────────────────────────────

class _DetailButton extends StatefulWidget {
  const _DetailButton({
    this.label,
    required this.icon,
    required this.t,
    this.iconColor,
    required this.onTap,
    this.squareSize,
  });

  final String? label;
  final IconData icon;
  final ThemeTokens t;
  final Color? iconColor;
  final VoidCallback onTap;
  final double? squareSize;

  @override
  State<_DetailButton> createState() => _DetailButtonState();
}

class _DetailButtonState extends State<_DetailButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t         = widget.t;
    final iconColor = widget.iconColor ?? t.text2;
    final isSquare  = widget.squareSize != null;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown:  (_) => setState(() => _pressed = true),
        onTapUp:    (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width:   isSquare ? widget.squareSize : null,
          height:  isSquare ? widget.squareSize : 40,
          padding: isSquare
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _pressed ? t.surfaceRaised : t.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: t.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: iconColor),
              if (widget.label != null) ...[
                const SizedBox(width: 6),
                Text(widget.label!,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: iconColor)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile task row ──────────────────────────────────────────────────────────

class _MobileTaskRow extends StatelessWidget {
  const _MobileTaskRow({
    required this.task,
    required this.isLast,
    required this.t,
    required this.onToggle,
    required this.onTap,
  });

  final TaskItemTableData task;
  final bool isLast;
  final ThemeTokens t;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeLabel = task.notifyAt != null
        ? '${task.notifyAt!.hour.toString().padLeft(2, '0')}:'
          '${task.notifyAt!.minute.toString().padLeft(2, '0')}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: t.divider)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isDone ? t.accent : Colors.transparent,
                  border: Border.all(
                    color: task.isDone ? t.accent : t.border,
                    width: 1.75,
                  ),
                ),
                child: task.isDone
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            if (task.priority != 'none')
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _prioColor(task.priority, t),
                ),
              ),
            Expanded(
              child: Text(
                task.body,
                style: TextStyle(
                  fontSize: 15,
                  color: task.isDone ? t.text3 : t.text1,
                  decoration:
                      task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (timeLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                timeLabel,
                style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 12,
                  color: t.text3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _prioColor(String p, ThemeTokens t) => switch (p) {
        'high' => t.danger,
        'mid'  => t.warning,
        _      => t.text3,
      };
}

// ─── Mobile note editor ───────────────────────────────────────────────────────

class _MobileNoteEditorView extends StatefulWidget {
  const _MobileNoteEditorView({
    super.key,
    required this.note,
    required this.onBack,
  });
  final NoteItemTableData note;
  final VoidCallback onBack;

  @override
  State<_MobileNoteEditorView> createState() => _MobileNoteEditorViewState();
}

class _MobileNoteEditorViewState extends State<_MobileNoteEditorView> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();
  bool _editing = false; // true while a field has focus (keyboard up)

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
        text: widget.note.title == 'Без названия' ? '' : widget.note.title);
    _bodyCtrl  = TextEditingController(text: widget.note.body);
    void onFocus() {
      final f = _titleFocus.hasFocus || _bodyFocus.hasFocus;
      if (f != _editing && mounted) setState(() => _editing = f);
    }
    _titleFocus.addListener(onFocus);
    _bodyFocus.addListener(onFocus);
  }

  @override
  void dispose() {
    _flush();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _flush() {
    final id    = widget.note.id;
    final title = _titleCtrl.text.trim();
    database.updateNote(id,
        title: title.isEmpty ? 'Без названия' : title,
        body:  _bodyCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            GestureDetector(
              onTap: () {
                _flush();
                widget.onBack();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                child: Icon(Icons.arrow_back_ios,
                    size: 18, color: t.text2),
              ),
            ),
            const Spacer(),
            // "Готово" appears while a field is focused — taps dismiss it.
            if (_editing)
              GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  child: Text('Готово',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.accent)),
                ),
              ),
            GestureDetector(
              onTap: () async {
                _flush();
                await database.deleteNote(widget.note.id);
                widget.onBack();
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.delete_outline,
                    size: 20, color: t.text3),
              ),
            ),
          ]),
        ),
        Divider(height: 1, color: t.borderSoft),
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: TextField(
            controller: _titleCtrl,
            focusNode: _titleFocus,
            onChanged: (_) => _flush(),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: t.text1),
            decoration: InputDecoration(
              hintText: 'Без названия',
              hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: t.text4),
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: TextField(
              controller: _bodyCtrl,
              focusNode: _bodyFocus,
              onChanged: (_) => _flush(),
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                  fontSize: 15, height: 1.65, color: t.text1),
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
}

// ─── Mobile note row ──────────────────────────────────────────────────────────

class _MobileNoteRow extends StatelessWidget {
  const _MobileNoteRow({
    required this.note,
    required this.t,
    required this.onTap,
  });
  final NoteItemTableData note;
  final ThemeTokens t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title   = note.title.isEmpty ? 'Без названия' : note.title;
    final preview = note.body.isEmpty
        ? ''
        : note.body.replaceAll('\n', ' ').trim();
    final day = note.updatedAt;
    final dateStr = '${day.day} ${_mo[day.month - 1]}';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.text1)),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: t.text3)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(dateStr,
                style: TextStyle(fontSize: 12, color: t.text3)),
          ],
        ),
      ),
    );
  }

  static const _mo = [
    'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
  ];
}

// ─── Task row ─────────────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.selected,
    required this.t,
    required this.onTap,
    required this.onToggle,
  });

  final TaskItemTableData task;
  final bool selected;
  final ThemeTokens t;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _groupChipLabel(task.group);
    final isToday   = task.group == 'today';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          color: selected
              ? t.accentTint.withValues(alpha: 0.5)
              : Colors.transparent,
          child: Row(
            children: [
              // ── Checkbox ──
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isDone
                        ? AppColors.accent
                        : Colors.transparent,
                    border: Border.all(
                      color: task.isDone
                          ? AppColors.accent
                          : t.border,
                      width: 1.5,
                    ),
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check,
                          size: 12, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // ── Priority dot ──
              if (task.priority != 'none')
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority, t),
                    shape: BoxShape.circle,
                  ),
                ),
              // ── Body text ──
              Expanded(
                child: Text(
                  task.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: task.isDone ? t.text3 : t.text1,
                    decoration: task.isDone
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // ── Date chip ──
              if (dateLabel != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isToday ? t.accentTint : t.surfaceSunken,
                    borderRadius: AppRadius.xsAll,
                  ),
                  child: Text(dateLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isToday
                              ? t.accentPress
                              : t.text3)),
                )
              else
                Text('—',
                    style: TextStyle(fontSize: 13, color: t.text4)),
            ],
          ),
        ),
      ),
    );
  }

  static String? _groupChipLabel(String group) => switch (group) {
        'today'    => 'Сегодня',
        'tomorrow' => 'Завтра',
        'week'     => 'На неделе',
        'later'    => 'Позже',
        _          => null,
      };

  static Color? _priorityColor(String p, ThemeTokens t) => switch (p) {
        'low'  => t.text3,
        'mid'  => t.warning,
        'high' => t.danger,
        _      => null,
      };
}

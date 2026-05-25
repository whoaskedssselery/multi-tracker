import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_tokens.dart';
import '../../../app/theme/typography.dart';

// ─── Data models ────────────────────────────────────────────

enum _Priority { none, low, medium, high }

class _TaskData {
  _TaskData({
    required this.id,
    required this.title,
    this.time,
    this.dateLabel,
    this.dayLabel,
    this.priority = _Priority.none,
    this.done = false,
  });

  final int id;
  final String title;
  final String? time;
  final String? dateLabel;
  final String? dayLabel;
  _Priority priority;
  bool done;
}

class _FolderData {
  const _FolderData(this.name, this.count);

  final String name;
  final int count;
}

// ─── Screen ─────────────────────────────────────────────────

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _folderIndex = 0;
  int? _selectedTaskId = 1;

  ThemeTokens get _t => ThemeTokens.of(context);

  static const _folders = <_FolderData>[
    _FolderData('Все активные', 10),
    _FolderData('Сегодня', 3),
    _FolderData('Завтра', 2),
    _FolderData('Эта неделя', 2),
    _FolderData('Позже', 1),
    _FolderData('Без даты', 2),
    _FolderData('Выполненные', 0),
  ];

  final _tasks = <_TaskData>[
    _TaskData(
        id: 1,
        title: 'Написать Серёге',
        time: '14:00',
        dateLabel: 'Сегодня',
        priority: _Priority.medium),
    _TaskData(id: 2, title: 'Купить молоко', dateLabel: 'Сегодня'),
    _TaskData(
        id: 3,
        title: 'Отчёт за апрель',
        dateLabel: 'Сегодня',
        priority: _Priority.medium),
    _TaskData(
        id: 4,
        title: 'Тренировка Pull (взять кистевые ремни)',
        dateLabel: 'Завтра'),
    _TaskData(
        id: 5,
        title: 'Звонок врачу',
        time: '10:30',
        dateLabel: 'Завтра',
        priority: _Priority.medium),
    _TaskData(
        id: 6,
        title: 'Заказать витамины',
        dayLabel: 'Пт',
        dateLabel: 'На неделе'),
    _TaskData(
        id: 7,
        title: 'Записаться к парикмахеру',
        dayLabel: 'Сб',
        dateLabel: 'На неделе'),
    _TaskData(
        id: 8,
        title: 'Прочитать «4000 недель»',
        dayLabel: '5 июн',
        dateLabel: 'Позже'),
    _TaskData(id: 9, title: 'Поменять зимнюю резину'),
    _TaskData(id: 10, title: 'Список книг на лето'),
  ];

  _TaskData? get _selectedTask =>
      _selectedTaskId == null
          ? null
          : _tasks.firstWhere((t) => t.id == _selectedTaskId,
              orElse: () => _tasks.first);

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final w = MediaQuery.sizeOf(context).width;
    final showDetail = w >= 1100 && _selectedTask != null;

    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        children: [
          _buildTopBar(context, t),
          Divider(height: 1, color: t.divider),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 200, child: _buildFolderList(context, t)),
                VerticalDivider(width: 1, color: t.divider),
                Expanded(child: _buildTaskList(context, t)),
                if (showDetail) ...[
                  VerticalDivider(width: 1, color: t.divider),
                  SizedBox(
                      width: 300,
                      child: _buildDetailPanel(context, _selectedTask!, t)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.xl),
      child: Row(
        children: [
          Text('Задачи',
              style: Theme.of(context).textTheme.headlineLarge),
          const Spacer(),
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tabPill(context, 'Задачи', 10, true, t),
                Container(width: 1, height: 44, color: t.border),
                _tabPill(context, 'Заметки', 3, false, t),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdAll),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: const Text('Новая задача'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabPill(BuildContext context, String label, int count,
      bool active, ThemeTokens t) {
    return Container(
      height: 44,
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

  // ── Folder list ──────────────────────────────────────────

  Widget _buildFolderList(BuildContext context, ThemeTokens t) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.md),
      itemCount: _folders.length,
      itemBuilder: (_, i) {
        final f = _folders[i];
        final active = i == _folderIndex;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _folderIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: active ? t.accentTint : Colors.transparent,
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(f.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: active ? t.accentPress : t.text2)),
                  ),
                  Text('${f.count}',
                      style: TextStyle(
                          fontSize: 12,
                          color: active ? t.accentPress : t.text4)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Task list ────────────────────────────────────────────

  Widget _buildTaskList(BuildContext context, ThemeTokens t) {
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
                    decoration: InputDecoration(
                      hintText: 'Поиск задач...',
                      hintStyle: TextStyle(fontSize: 13, color: t.text3),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(fontSize: 13, color: t.text1),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (_, i) {
              final task = _tasks[i];
              final selected = task.id == _selectedTaskId;
              return _TaskRow(
                task: task,
                selected: selected,
                t: t,
                onTap: () => setState(() => _selectedTaskId = task.id),
                onToggle: () => setState(() => task.done = !task.done),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Detail panel ─────────────────────────────────────────

  Widget _buildDetailPanel(
      BuildContext context, _TaskData task, ThemeTokens t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ЗАДАЧА', style: AppTypography.caps(color: t.text3)),
          const SizedBox(height: 8),
          Text(task.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: t.text1)),
          const SizedBox(height: 20),
          _detailRow('Когда', task.dateLabel ?? '—', t),
          if (task.time != null) _detailRow('Время', task.time!, t),
          _detailRow('Приоритет', _priorityLabel(task.priority), t,
              valueColor: _priorityColor(task.priority),
              dot: task.priority != _Priority.none),
          _detailRow('Повтор', 'нет', t),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DetailButton(
                  label: 'Изменить',
                  icon: Icons.edit_outlined,
                  t: t,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              _DetailButton(
                icon: Icons.delete_outline,
                iconColor: AppColors.danger,
                t: t,
                onTap: () {},
                squareSize: 40,
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
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: valueColor ?? t.text3,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? t.text1)),
        ],
      ),
    );
  }

  static String _priorityLabel(_Priority p) => switch (p) {
        _Priority.none => 'нет',
        _Priority.low => 'низкий',
        _Priority.medium => 'средний',
        _Priority.high => 'высокий',
      };

  static Color? _priorityColor(_Priority p) => switch (p) {
        _Priority.none => null,
        _Priority.low => AppColors.text3,
        _Priority.medium => AppColors.warning,
        _Priority.high => AppColors.danger,
      };
}

// ─── Detail button ───────────────────────────────────────────

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
    final t = widget.t;
    final iconColor = widget.iconColor ?? t.text2;
    final isSquare = widget.squareSize != null;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: isSquare ? widget.squareSize : null,
          height: isSquare ? widget.squareSize : 40,
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
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: iconColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Task row ────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.selected,
    required this.t,
    required this.onTap,
    required this.onToggle,
  });

  final _TaskData task;
  final bool selected;
  final ThemeTokens t;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
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
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.done ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: task.done ? AppColors.accent : t.border,
                      width: 1.5,
                    ),
                  ),
                  child: task.done
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              if (task.priority != _Priority.none) ...[
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: task.done ? t.text3 : t.text1,
                    decoration:
                        task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.time != null) ...[
                    Text(task.time!,
                        style: TextStyle(fontSize: 12, color: t.text3)),
                    const SizedBox(width: 6),
                  ],
                  if (task.dayLabel != null) ...[
                    Text(task.dayLabel!,
                        style: TextStyle(fontSize: 12, color: t.text3)),
                    const SizedBox(width: 4),
                  ],
                  if (task.dateLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _dateBg(task.dateLabel!, t),
                        borderRadius: AppRadius.xsAll,
                      ),
                      child: Text(task.dateLabel!,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _dateColor(task.dateLabel!, t))),
                    )
                  else
                    Text('—',
                        style: TextStyle(fontSize: 13, color: t.text4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color? _priorityColor(_Priority p) => switch (p) {
        _Priority.none => null,
        _Priority.low => AppColors.text3,
        _Priority.medium => AppColors.warning,
        _Priority.high => AppColors.danger,
      };

  static Color _dateBg(String label, ThemeTokens t) =>
      label == 'Сегодня' ? t.accentTint : t.surfaceSunken;

  static Color _dateColor(String label, ThemeTokens t) =>
      label == 'Сегодня' ? t.accentPress : t.text3;
}

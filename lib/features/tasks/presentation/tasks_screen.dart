import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
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
    _TaskData(
        id: 2, title: 'Купить молоко', dateLabel: 'Сегодня'),
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
    final w = MediaQuery.sizeOf(context).width;
    final showDetail = w >= 1100 && _selectedTask != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildTopBar(context),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Folders sidebar
                SizedBox(
                  width: 200,
                  child: _buildFolderList(context),
                ),
                const VerticalDivider(
                    width: 1, color: AppColors.divider),
                // Task list
                Expanded(child: _buildTaskList(context)),
                // Detail panel
                if (showDetail) ...[
                  const VerticalDivider(
                      width: 1, color: AppColors.divider),
                  SizedBox(
                      width: 300,
                      child: _buildDetailPanel(context, _selectedTask!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.xl),
      child: Row(
        children: [
          Text('Задачи',
              style: Theme.of(context).textTheme.headlineLarge),
          const Spacer(),
          // Tab pills
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tabPill(context, 'Задачи', 10, true),
                Container(width: 1, height: 44, color: AppColors.border),
                _tabPill(context, 'Заметки', 3, false),
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

  Widget _tabPill(
      BuildContext context, String label, int count, bool active) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      color: active ? AppColors.surfaceSunken : Colors.transparent,
      child: Text(
        '$label · $count',
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.text1 : AppColors.text3),
      ),
    );
  }

  // ── Folder list ──────────────────────────────────────────

  Widget _buildFolderList(BuildContext context) {
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
              color:
                  active ? AppColors.accentTint : Colors.transparent,
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
                          color: active
                              ? AppColors.accentPress
                              : AppColors.text2)),
                ),
                Text('${f.count}',
                    style: TextStyle(
                        fontSize: 12,
                        color: active
                            ? AppColors.accentPress
                            : AppColors.text4)),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  // ── Task list ────────────────────────────────────────────

  Widget _buildTaskList(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: AppRadius.smAll,
            ),
            child: const Row(
              children: [
                SizedBox(width: 12),
                Icon(Icons.search, size: 16, color: AppColors.text3),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск задач...',
                      hintStyle: TextStyle(
                          fontSize: 13, color: AppColors.text3),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.text1),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Tasks
        Expanded(
          child: ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (_, i) {
              final t = _tasks[i];
              final selected = t.id == _selectedTaskId;
              return _TaskRow(
                task: t,
                selected: selected,
                onTap: () =>
                    setState(() => _selectedTaskId = t.id),
                onToggle: () =>
                    setState(() => t.done = !t.done),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Detail panel ─────────────────────────────────────────

  Widget _buildDetailPanel(BuildContext context, _TaskData task) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ЗАДАЧА',
              style: AppTypography.caps(color: AppColors.text3)),
          const SizedBox(height: 8),
          Text(task.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.text1)),
          const SizedBox(height: 20),
          _detailRow('Когда', task.dateLabel ?? '—'),
          if (task.time != null)
            _detailRow('Время', task.time!),
          _detailRow('Приоритет', _priorityLabel(task.priority),
              valueColor: _priorityColor(task.priority),
              dot: task.priority != _Priority.none),
          _detailRow('Повтор', 'нет'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DetailButton(
                  label: 'Изменить',
                  icon: Icons.edit_outlined,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              _DetailButton(
                icon: Icons.delete_outline,
                iconColor: AppColors.danger,
                onTap: () {},
                squareSize: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {Color? valueColor, bool dot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.text3)),
          ),
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: valueColor ?? AppColors.text3,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.text1)),
        ],
      ),
    );
  }

  static String _priorityLabel(_Priority p) {
    switch (p) {
      case _Priority.none:
        return 'нет';
      case _Priority.low:
        return 'низкий';
      case _Priority.medium:
        return 'средний';
      case _Priority.high:
        return 'высокий';
    }
  }

  static Color? _priorityColor(_Priority p) {
    switch (p) {
      case _Priority.none:
        return null;
      case _Priority.low:
        return AppColors.text3;
      case _Priority.medium:
        return AppColors.warning;
      case _Priority.high:
        return AppColors.danger;
    }
  }
}

// ─── Detail button ───────────────────────────────────────────

class _DetailButton extends StatefulWidget {
  const _DetailButton({
    this.label,
    required this.icon,
    this.iconColor = AppColors.text2,
    required this.onTap,
    this.squareSize,
  });

  final String? label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final double? squareSize;

  @override
  State<_DetailButton> createState() => _DetailButtonState();
}

class _DetailButtonState extends State<_DetailButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
          color: _pressed ? AppColors.surfaceRaised : AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 16, color: widget.iconColor),
            if (widget.label != null) ...[
              const SizedBox(width: 6),
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.iconColor,
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
    required this.onTap,
    required this.onToggle,
  });

  final _TaskData task;
  final bool selected;
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
            ? AppColors.accentTint.withValues(alpha: 0.5)
            : Colors.transparent,
        child: Row(
          children: [
            // Checkbox
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
                    color: task.done
                        ? AppColors.accent
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: task.done
                    ? const Icon(Icons.check,
                        size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Priority dot
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
            // Title
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  color: task.done
                      ? AppColors.text3
                      : AppColors.text1,
                  decoration: task.done
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            // Right side: time + date
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.time != null) ...[
                  Text(task.time!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.text3)),
                  const SizedBox(width: 6),
                ],
                if (task.dayLabel != null) ...[
                  Text(task.dayLabel!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.text3)),
                  const SizedBox(width: 4),
                ],
                if (task.dateLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _dateBg(task.dateLabel!),
                      borderRadius: AppRadius.xsAll,
                    ),
                    child: Text(task.dateLabel!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _dateColor(task.dateLabel!))),
                  )
                else
                  const Text('—',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.text4)),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  static Color? _priorityColor(_Priority p) {
    switch (p) {
      case _Priority.none:
        return null;
      case _Priority.low:
        return AppColors.text3;
      case _Priority.medium:
        return AppColors.warning;
      case _Priority.high:
        return AppColors.danger;
    }
  }

  static Color _dateBg(String label) {
    if (label == 'Сегодня') {
      return AppColors.accentTint;
    } else if (label == 'Завтра') {
      return AppColors.surfaceSunken;
    }
    return AppColors.surfaceSunken;
  }

  static Color _dateColor(String label) {
    if (label == 'Сегодня') return AppColors.accentPress;
    return AppColors.text3;
  }
}

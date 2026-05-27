import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/providers.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/db/database.dart';
import '../../../main.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Returns the Monday of the week containing [d].
DateTime _weekMonday(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

const _wdLabels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
const _wdFull   = ['Понедельник', 'Вторник', 'Среда', 'Четверг',
                   'Пятница', 'Суббота', 'Воскресенье'];
const _moShort  = ['янв', 'фев', 'мар', 'апр', 'май', 'июн',
                   'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

String _fmtWeekRange(DateTime mon) {
  final sun = mon.add(const Duration(days: 6));
  if (mon.month == sun.month) {
    return '${mon.day} – ${sun.day} ${_moShort[mon.month - 1]} ${mon.year}';
  }
  return '${mon.day} ${_moShort[mon.month - 1]} – '
      '${sun.day} ${_moShort[sun.month - 1]} ${mon.year}';
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class WeekGridScreen extends ConsumerStatefulWidget {
  const WeekGridScreen({super.key});

  @override
  ConsumerState<WeekGridScreen> createState() => _WeekGridScreenState();
}

class _WeekGridScreenState extends ConsumerState<WeekGridScreen> {
  int _weekOffset  = 0; // 0 = current week
  int _selectedDow = DateTime.now().weekday; // 1=Mon..7=Sun

  ThemeTokens get _t => ThemeTokens.of(context);

  DateTime get _weekStart =>
      _weekMonday(DateTime.now()).add(Duration(days: _weekOffset * 7));

  // ── Program dialog ────────────────────────────────────────────────────────

  Future<void> _showProgramDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ProgramDialog(db: database),
    );
  }

  // ── Workout logging dialog ────────────────────────────────────────────────

  Future<void> _showWorkoutDialog(
      WorkoutTemplateTableData template, DateTime date) async {
    final exercises = await database
        .watchExercisesForTemplate(template.id)
        .first;
    if (exercises.isEmpty || !mounted) return;

    // Pre-load last sets for each exercise
    final lastSets = <int, String>{};
    for (final ex in exercises) {
      lastSets[ex.id] = await database.getLastSetsString(ex.id);
    }
    if (!mounted) return;

    // Build controllers: exerciseId → list of (weightCtrl, repsCtrl)
    final ctrls = <int, List<(TextEditingController, TextEditingController)>>{};
    for (final ex in exercises) {
      final parts = (lastSets[ex.id] ?? '')
          .split(' · ')
          .where((s) => s.isNotEmpty)
          .toList();
      ctrls[ex.id] = List.generate(parts.isEmpty ? 3 : parts.length, (i) {
        final match =
            RegExp(r'([\d.]+)×(\d+)').firstMatch(i < parts.length ? parts[i] : '');
        return (
          TextEditingController(text: match?.group(1) ?? ''),
          TextEditingController(text: match?.group(2) ?? ''),
        );
      });
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => _WorkoutLogDialog(
        template: template,
        date: date,
        exercises: exercises,
        controllers: ctrls,
        db: database,
      ),
    );

    for (final pairs in ctrls.values) {
      for (final (w, r) in pairs) {
        w.dispose();
        r.dispose();
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t         = _t;
    final slots     = ref.watch(scheduleSlotsProvider).valueOrNull ?? [];
    final templates = ref.watch(workoutTemplatesProvider).valueOrNull ?? [];
    final logged    = ref.watch(loggedDatesProvider(_weekStart)).valueOrNull ?? {};

    final today     = DateTime.now();
    final todayMid  = DateTime(today.year, today.month, today.day);
    final weekStart = _weekStart;

    // Map dayOfWeek → template (or null = rest)
    final scheduleMap = <int, WorkoutTemplateTableData?>{};
    for (final slot in slots) {
      try {
        scheduleMap[slot.dayOfWeek] =
            templates.firstWhere((t) => t.id == slot.workoutTemplateId);
      } catch (_) {}
    }

    // Build day items for the week
    final days = List.generate(7, (i) {
      final date    = weekStart.add(Duration(days: i));
      final dateMid = DateTime(date.year, date.month, date.day);
      final dow     = i + 1; // 1=Mon..7=Sun
      final tmpl    = scheduleMap[dow];
      final isDone  = logged.contains(dateMid);
      final isToday = dateMid == todayMid;
      return _DayItem(
        dow: dow,
        date: date,
        template: tmpl,
        isDone: isDone,
        isToday: isToday,
      );
    });

    final selected = days[_selectedDow - 1];

    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, t, weekStart),
          Divider(height: 1, color: t.divider),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl3),
            child: _buildWeekGrid(context, t, days),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl3, 0, AppSpacing.xl3, AppSpacing.xl3),
              child: _buildDayDetail(context, t, selected),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ThemeTokens t, DateTime weekStart) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.xl),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Train',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 2),
              Text(_fmtWeekRange(weekStart),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: t.text3)),
            ],
          ),
          const Spacer(),
          _NavIconButton(
              icon: Icons.chevron_left,
              t: t,
              onTap: () => setState(() => _weekOffset--)),
          const SizedBox(width: 8),
          _outlinedBtn('Сегодня', t: t,
              onTap: () => setState(() {
                    _weekOffset  = 0;
                    _selectedDow = DateTime.now().weekday;
                  })),
          const SizedBox(width: 8),
          _NavIconButton(
              icon: Icons.chevron_right,
              t: t,
              onTap: () => setState(() => _weekOffset++)),
          const SizedBox(width: 16),
          _outlinedBtn('≡  Программа', t: t, onTap: _showProgramDialog),
        ],
      ),
    );
  }

  // ── Week grid ─────────────────────────────────────────────────────────────

  Widget _buildWeekGrid(
      BuildContext context, ThemeTokens t, List<_DayItem> days) {
    return Row(
      children: List.generate(7, (i) {
        final day = days[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 6 ? 8 : 0),
            child: _DayCard(
              day: day,
              selected: day.dow == _selectedDow,
              t: t,
              onTap: () => setState(() => _selectedDow = day.dow),
            ),
          ),
        );
      }),
    );
  }

  // ── Day detail ────────────────────────────────────────────────────────────

  Widget _buildDayDetail(
      BuildContext context, ThemeTokens t, _DayItem day) {
    if (day.template == null) {
      return _restCard(context, t, day);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day.isDone
              ? 'ТРЕНИРОВКА ВЫПОЛНЕНА'
              : day.isToday
                  ? 'СЕГОДНЯШНЯЯ ТРЕНИРОВКА'
                  : 'ЗАПЛАНИРОВАННАЯ ТРЕНИРОВКА',
          style: AppTypography.caps(color: t.text3),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl2),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: t.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.template!.name,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: t.text1)),
                      const SizedBox(height: 4),
                      Text(
                          '${_wdFull[day.dow - 1]} · ${_fmtDate(day.date)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: t.text3)),
                    ],
                  ),
                  const Spacer(),
                  if (!day.isDone)
                    ElevatedButton(
                      onPressed: () =>
                          _showWorkoutDialog(day.template!, day.date),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        side: BorderSide.none,
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdAll),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Записать тренировку'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: t.accentTint,
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 16, color: t.accentPress),
                          const SizedBox(width: 6),
                          Text('Готово',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: t.accentPress)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _ExerciseList(
                  templateId: day.template!.id, date: day.date),
            ],
          ),
        ),
      ],
    );
  }

  Widget _restCard(BuildContext context, ThemeTokens t, _DayItem day) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: t.borderSoft),
      ),
      child: Column(
        children: [
          Icon(Icons.self_improvement_outlined, size: 32, color: t.text4),
          const SizedBox(height: 12),
          Text('День отдыха',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: t.text2)),
          const SizedBox(height: 4),
          Text('${_wdFull[day.dow - 1]} · ${_fmtDate(day.date)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: t.text4)),
        ],
      ),
    );
  }

  static Widget _outlinedBtn(String label,
      {required ThemeTokens t, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: AppRadius.smAll,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.text1)),
        ),
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _DayItem {
  const _DayItem({
    required this.dow,
    required this.date,
    required this.template,
    required this.isDone,
    required this.isToday,
  });
  final int dow; // 1=Mon..7=Sun
  final DateTime date;
  final WorkoutTemplateTableData? template;
  final bool isDone;
  final bool isToday;
}

// ─── Exercise list (watches exercises + shows last sets) ──────────────────────

class _ExerciseList extends ConsumerWidget {
  const _ExerciseList({required this.templateId, required this.date});
  final int templateId;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises =
        ref.watch(exercisesForTemplateProvider(templateId)).valueOrNull ?? [];
    if (exercises.isEmpty) {
      final t = ThemeTokens.of(context);
      return Text('Нет упражнений. Добавь в разделе «Программа».',
          style: TextStyle(fontSize: 13, color: t.text4));
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: exercises.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) =>
            _ExerciseCard(exercise: exercises[i], date: date),
      ),
    );
  }
}

// ─── Exercise card ────────────────────────────────────────────────────────────

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({required this.exercise, required this.date});
  final ExerciseTemplateTableData exercise;
  final DateTime date;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  String _lastSets = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_ExerciseCard old) {
    super.didUpdateWidget(old);
    if (old.exercise.id != widget.exercise.id) _load();
  }

  Future<void> _load() async {
    final s = await database.getLastSetsString(widget.exercise.id);
    if (mounted) setState(() => _lastSets = s);
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.exercise.name,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: t.text1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(
            _lastSets.isEmpty ? 'нет данных' : 'прошлый раз: $_lastSets',
            style: TextStyle(fontSize: 11, color: t.text3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Workout log dialog ───────────────────────────────────────────────────────

class _WorkoutLogDialog extends StatefulWidget {
  const _WorkoutLogDialog({
    required this.template,
    required this.date,
    required this.exercises,
    required this.controllers,
    required this.db,
  });
  final WorkoutTemplateTableData template;
  final DateTime date;
  final List<ExerciseTemplateTableData> exercises;
  final Map<int, List<(TextEditingController, TextEditingController)>>
      controllers;
  final AppDatabase db;

  @override
  State<_WorkoutLogDialog> createState() => _WorkoutLogDialogState();
}

class _WorkoutLogDialogState extends State<_WorkoutLogDialog> {
  Future<void> _save() async {
    for (final ex in widget.exercises) {
      final pairs = widget.controllers[ex.id] ?? [];
      final sets = <({double weightKg, int reps})>[];
      for (final (wCtrl, rCtrl) in pairs) {
        final w = double.tryParse(wCtrl.text.replaceAll(',', '.'));
        final r = int.tryParse(rCtrl.text);
        if (w != null && r != null && r > 0) {
          sets.add((weightKg: w, reps: r));
        }
      }
      if (sets.isNotEmpty) {
        await widget.db.logSets(
            exerciseId: ex.id, date: widget.date, sets: sets);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    return AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      title: Text(widget.template.name,
          style: Theme.of(context).textTheme.titleLarge),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final ex in widget.exercises) ...[
                Text(ex.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.text1)),
                const SizedBox(height: 6),
                _SetRows(
                  pairs: widget.controllers[ex.id] ?? [],
                  t: t,
                  onAdd: () {
                    setState(() {
                      widget.controllers[ex.id]!.add((
                        TextEditingController(),
                        TextEditingController(),
                      ));
                    });
                  },
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _SetRows extends StatelessWidget {
  const _SetRows(
      {required this.pairs, required this.t, required this.onAdd});
  final List<(TextEditingController, TextEditingController)> pairs;
  final ThemeTokens t;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < pairs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text('${i + 1}.',
                    style: TextStyle(fontSize: 12, color: t.text3)),
                const SizedBox(width: 6),
                _NumField(ctrl: pairs[i].$1, hint: 'кг', width: 70),
                const SizedBox(width: 6),
                Text('×', style: TextStyle(color: t.text3)),
                const SizedBox(width: 6),
                _NumField(
                    ctrl: pairs[i].$2,
                    hint: 'повт',
                    width: 60,
                    isInt: true),
              ],
            ),
          ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(Icons.add, size: 14, color: t.accentPress),
                  const SizedBox(width: 4),
                  Text('Подход',
                      style: TextStyle(
                          fontSize: 12,
                          color: t.accentPress,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.ctrl,
    required this.hint,
    required this.width,
    this.isInt = false,
  });
  final TextEditingController ctrl;
  final String hint;
  final double width;
  final bool isInt;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              isInt ? RegExp(r'\d') : RegExp(r'[\d.,]'))
        ],
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: t.text1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: t.text4),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
              borderRadius: AppRadius.smAll,
              borderSide: BorderSide(color: t.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.smAll,
              borderSide: BorderSide(color: t.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.smAll,
              borderSide:
                  BorderSide(color: AppColors.accent, width: 1.5)),
          filled: true,
          fillColor: t.surfaceSunken,
        ),
      ),
    );
  }
}

// ─── Program dialog ───────────────────────────────────────────────────────────

class _ProgramDialog extends ConsumerStatefulWidget {
  const _ProgramDialog({required this.db});
  final AppDatabase db;

  @override
  ConsumerState<_ProgramDialog> createState() => _ProgramDialogState();
}

class _ProgramDialogState extends ConsumerState<_ProgramDialog> {
  int? _expandedTemplateId;
  final _newTemplateCtrl  = TextEditingController();
  final _newExerciseCtrl  = TextEditingController();

  @override
  void dispose() {
    _newTemplateCtrl.dispose();
    _newExerciseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t         = ThemeTokens.of(context);
    final templates = ref.watch(workoutTemplatesProvider).valueOrNull ?? [];
    final slots     = ref.watch(scheduleSlotsProvider).valueOrNull ?? [];

    return AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      title: Text('Программа', style: Theme.of(context).textTheme.titleLarge),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Templates ──
              Text('ШАБЛОНЫ', style: AppTypography.caps(color: t.text3)),
              const SizedBox(height: 8),
              if (templates.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Нет шаблонов',
                      style: TextStyle(fontSize: 13, color: t.text4)),
                ),
              for (final tmpl in templates)
                _TemplateItem(
                  template: tmpl,
                  expanded: _expandedTemplateId == tmpl.id,
                  onToggle: () => setState(() {
                    _expandedTemplateId =
                        _expandedTemplateId == tmpl.id ? null : tmpl.id;
                    _newExerciseCtrl.clear();
                  }),
                  onDelete: () async {
                    await widget.db.deleteWorkoutTemplate(tmpl.id);
                    if (_expandedTemplateId == tmpl.id) {
                      setState(() => _expandedTemplateId = null);
                    }
                  },
                  newExerciseCtrl: _newExerciseCtrl,
                  db: widget.db,
                  t: t,
                ),
              // Add template row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTemplateCtrl,
                      decoration: InputDecoration(
                        hintText: 'Название шаблона (Push, Pull…)',
                        hintStyle:
                            TextStyle(fontSize: 13, color: t.text4),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: AppRadius.smAll,
                            borderSide: BorderSide(color: t.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smAll,
                            borderSide: BorderSide(color: t.border)),
                        filled: true,
                        fillColor: t.surfaceSunken,
                      ),
                      style: TextStyle(fontSize: 13, color: t.text1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        final name = _newTemplateCtrl.text.trim();
                        if (name.isEmpty) return;
                        await widget.db.addWorkoutTemplate(name);
                        _newTemplateCtrl.clear();
                      },
                      child: Container(
                        height: 36,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: AppRadius.smAll,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Schedule ──
              Text('РАСПИСАНИЕ', style: AppTypography.caps(color: t.text3)),
              const SizedBox(height: 8),
              for (var dow = 1; dow <= 7; dow++)
                _ScheduleRow(
                  dow: dow,
                  label: _wdLabels[dow - 1],
                  templates: templates,
                  currentTemplateId: slots
                      .where((s) => s.dayOfWeek == dow)
                      .map((s) => s.workoutTemplateId)
                      .firstOrNull,
                  onChange: (tid) =>
                      widget.db.setScheduleSlot(dow, tid),
                  t: t,
                ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Готово'),
        ),
      ],
    );
  }
}

class _TemplateItem extends ConsumerWidget {
  const _TemplateItem({
    required this.template,
    required this.expanded,
    required this.onToggle,
    required this.onDelete,
    required this.newExerciseCtrl,
    required this.db,
    required this.t,
  });
  final WorkoutTemplateTableData template;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final TextEditingController newExerciseCtrl;
  final AppDatabase db;
  final ThemeTokens t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = expanded
        ? (ref.watch(exercisesForTemplateProvider(template.id)).valueOrNull ?? [])
        : <ExerciseTemplateTableData>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 16,
                    color: t.text3,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(template.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: t.text1)),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Icon(Icons.delete_outline,
                          size: 16, color: t.text4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: t.border),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final ex in exercises)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(ex.name,
                                style: TextStyle(
                                    fontSize: 13, color: t.text2)),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => db.deleteExercise(ex.id),
                              child: Icon(Icons.close,
                                  size: 14, color: t.text4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newExerciseCtrl,
                          decoration: InputDecoration(
                            hintText: 'Новое упражнение…',
                            hintStyle: TextStyle(
                                fontSize: 12, color: t.text4),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(
                                borderRadius: AppRadius.xsAll,
                                borderSide:
                                    BorderSide(color: t.border)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.xsAll,
                                borderSide:
                                    BorderSide(color: t.border)),
                          ),
                          style: TextStyle(
                              fontSize: 12, color: t.text1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            final name = newExerciseCtrl.text.trim();
                            if (name.isEmpty) return;
                            await db.addExercise(
                                templateId: template.id, name: name);
                            newExerciseCtrl.clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: t.accentTint,
                              borderRadius: AppRadius.xsAll,
                            ),
                            child: Icon(Icons.add,
                                size: 14, color: t.accentPress),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.dow,
    required this.label,
    required this.templates,
    required this.currentTemplateId,
    required this.onChange,
    required this.t,
  });
  final int dow;
  final String label;
  final List<WorkoutTemplateTableData> templates;
  final int? currentTemplateId;
  final void Function(int? templateId) onChange;
  final ThemeTokens t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.text3)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int?>(
              value: currentTemplateId,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              style: TextStyle(fontSize: 13, color: t.text1),
              dropdownColor: t.surface,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Отдых',
                      style: TextStyle(color: t.text3)),
                ),
                for (final tmpl in templates)
                  DropdownMenuItem<int?>(
                    value: tmpl.id,
                    child: Text(tmpl.name),
                  ),
              ],
              onChanged: (v) => onChange(v),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Day card ─────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.selected,
    required this.t,
    required this.onTap,
  });
  final _DayItem day;
  final bool selected;
  final ThemeTokens t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRest  = day.template == null;
    final isDone  = day.isDone;
    final isToday = day.isToday;

    if (isRest) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
              color: t.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_wdLabels[day.dow - 1],
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: t.text4)),
            const SizedBox(height: 2),
            Text(_fmtDate(day.date),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: t.text4)),
            const SizedBox(height: 16),
            Text('Отдых',
                style: TextStyle(fontSize: 13, color: t.text4)),
          ],
        ),
      );
    }

    final Color bg = isDone ? t.accentTint : t.surface;
    final Border border = isDone
        ? Border.all(color: t.borderSoft)
        : Border.all(
            color: selected ? t.accentPress : t.border,
            width: selected ? 2 : 1);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.lgAll,
            border: border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_wdLabels[day.dow - 1],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isDone ? t.accentPress : t.text3)),
                  if (isDone)
                    Icon(Icons.check_circle,
                        size: 12, color: t.accentPress),
                ],
              ),
              const SizedBox(height: 2),
              Text(_fmtDate(day.date),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDone ? t.accentPress : t.text1)),
              const SizedBox(height: 6),
              Text(day.template!.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDone ? t.accentPress : t.text1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Divider(height: 1, color: t.divider),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    isDone
                        ? 'ГОТОВО'
                        : isToday
                            ? 'СЕГОДНЯ'
                            : 'ПЛАН',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDone || isToday
                            ? t.accentPress
                            : t.text3),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward,
                      size: 11,
                      color: isDone || isToday
                          ? t.accentPress
                          : t.text3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav icon button ──────────────────────────────────────────────────────────

class _NavIconButton extends StatelessWidget {
  const _NavIconButton(
      {required this.icon, required this.t, required this.onTap});
  final IconData icon;
  final ThemeTokens t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: t.border),
            borderRadius: AppRadius.smAll,
            color: t.surface,
          ),
          child: Icon(icon, size: 18, color: t.text2),
        ),
      ),
    );
  }
}

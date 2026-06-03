import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/providers.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/db/database.dart';
import '../../../main.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/page_header.dart';

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
    await showAppModal<void>(
      context,
      maxWidth: 640,
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

    await showAppModal<void>(
      context,
      maxWidth: 920,
      builder: (ctx) => _WorkoutLogDialog(
        template: template,
        date: date,
        dateLabel: '${_wdFull[date.weekday - 1]} · ${_fmtDate(date)}',
        exercises: exercises,
        controllers: ctrls,
        lastSets: lastSets,
        db: database,
        onAskAI: () => context.go('/ai'),
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

    if (Platform.isIOS) {
      return _buildIos(context, t, days, selected, weekStart);
    }

    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPageHeader(
            title: 'Тренировки',
            subtitle: _fmtWeekRange(weekStart),
            actions: [
              _NavIconButton(
                  icon: Icons.chevron_left,
                  t: t,
                  onTap: () => setState(() => _weekOffset--)),
              const SizedBox(width: 8),
              _outlinedBtn('Сегодня', t: t,
                  onTap: () => setState(() {
                        _weekOffset = 0;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl3, AppSpacing.lg, AppSpacing.xl3, AppSpacing.md),
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

  // ── iOS layout ────────────────────────────────────────────────────────────

  Widget _buildIos(BuildContext context, ThemeTokens t,
      List<_DayItem> days, _DayItem selected, DateTime weekStart) {
    final todayItem = days.firstWhere(
      (d) => d.isToday,
      orElse: () => selected,
    );

    return Scaffold(
      backgroundColor: t.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header: title + week nav ──
          SliverToBoxAdapter(
            child: IosPageHeader(
              title: 'Тренировки',
              subtitle: _fmtWeekRange(weekStart),
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iosNavBtn(context, t, Icons.chevron_left,
                      () => setState(() => _weekOffset--)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() {
                      _weekOffset  = 0;
                      _selectedDow = DateTime.now().weekday;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: t.surface,
                        border: Border.all(color: t.border),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Text('Сегодня',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: t.text1)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _iosNavBtn(context, t, Icons.chevron_right,
                      () => setState(() => _weekOffset++)),
                ],
              ),
            ),
          ),

          // ── Day strip ──
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildDayStrip(context, t, days),
            ),
          ),

          // ── Today workout card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _iosTodayCard(context, t, todayItem),
            ),
          ),

          // ── Whole week section ──
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Row(children: [
                Text('ВСЯ НЕДЕЛЯ',
                    style: AppTypography.caps(color: t.text3)),
                const Spacer(),
                GestureDetector(
                  onTap: _showProgramDialog,
                  child: Text(
                    'Программа →',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: t.accent),
                  ),
                ),
              ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _iosWeekRow(context, t, days[i]),
                ),
                childCount: 7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _iosNavBtn(BuildContext context, ThemeTokens t,
      IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: AppRadius.smAll,
        ),
        child: Icon(icon, size: 18, color: t.text2),
      ),
    );
  }

  Widget _iosTodayCard(
      BuildContext context, ThemeTokens t, _DayItem day) {
    if (day.template == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: t.borderSoft),
        ),
        child: Row(children: [
          Icon(Icons.self_improvement_outlined, size: 22, color: t.text4),
          const SizedBox(width: 10),
          Text('День отдыха',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: t.text2)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: t.accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_wdLabels[day.dow - 1]} · ${_fmtDate(day.date)}',
            style: AppTypography.caps(color: t.text3),
          ),
          const SizedBox(height: 6),
          Text(
            day.template!.name.toUpperCase(),
            style: const TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800, height: 1.0),
          ),
          const SizedBox(height: 10),
          _ExercisePreview(templateId: day.template!.id),
          const SizedBox(height: 16),
          Row(children: [
            _ExerciseCountChip(templateId: day.template!.id, t: t),
            const Spacer(),
            if (!day.isDone)
              FilledButton(
                onPressed: () =>
                    _showWorkoutDialog(day.template!, day.date),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                child: const Text('Открыть',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: t.accentTint,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: t.accentPress),
                  const SizedBox(width: 6),
                  Text('Выполнено',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.accentPress)),
                ]),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _iosWeekRow(
      BuildContext context, ThemeTokens t, _DayItem day) {
    final hasWorkout = day.template != null;
    return GestureDetector(
      onTap: hasWorkout
          ? () => _showWorkoutDialog(day.template!, day.date)
          : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasWorkout ? t.accentTint : t.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: hasWorkout ? t.accent.withValues(alpha: 0.3) : t.borderSoft,
          ),
        ),
        child: Row(children: [
          // Date label
          SizedBox(
            width: 72,
            child: Text(
              '${_wdLabels[day.dow - 1]} · ${_fmtDate(day.date)}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: t.text3),
            ),
          ),
          const SizedBox(width: 8),
          if (!hasWorkout)
            Text('Отдых',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: t.text3))
          else ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day.template!.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.text1)),
                  _ExerciseCountText(
                      templateId: day.template!.id, t: t),
                ],
              ),
            ),
            _WorkoutStatusIcon(day: day, t: t),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: t.text3),
          ],
        ]),
      ),
    );
  }

  // ── Mobile day strip (horizontal chip row) ────────────────────────────────

  Widget _buildDayStrip(
      BuildContext context, ThemeTokens t, List<_DayItem> days) {
    return Row(
      children: List.generate(7, (i) {
        final day = days[i];
        final selected = day.dow == _selectedDow;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _selectedDow = day.dow),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? t.accentTint : Colors.transparent,
                borderRadius: AppRadius.smAll,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _wdLabels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.04 * 11,
                      color: selected ? t.accentPress : t.text3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.date.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'IBM Plex Mono',
                      color: day.isToday
                          ? t.accentPress
                          : selected
                              ? t.accentPress
                              : t.text1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (day.isToday)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      }),
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
                    FilledButton(
                      onPressed: () =>
                          _showWorkoutDialog(day.template!, day.date),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Начать тренировку'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
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

// ─── iOS helper widgets ───────────────────────────────────────────────────────

/// One-line exercise name preview for the today card.
class _ExercisePreview extends ConsumerWidget {
  const _ExercisePreview({required this.templateId});
  final int templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ThemeTokens.of(context);
    final exercises =
        ref.watch(exercisesForTemplateProvider(templateId)).valueOrNull ?? [];
    if (exercises.isEmpty) return const SizedBox.shrink();
    const maxShow = 3;
    final names  = exercises.take(maxShow).map((e) => e.name).join(' · ');
    final extra  = exercises.length > maxShow
        ? '  · ещё ${exercises.length - maxShow}'
        : '';
    return Text(
      '$names$extra',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13, color: t.text3),
    );
  }
}

/// "5 упр. · ≈45 мин" chip.
class _ExerciseCountChip extends ConsumerWidget {
  const _ExerciseCountChip({required this.templateId, required this.t});
  final int templateId;
  final ThemeTokens t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(exercisesForTemplateProvider(templateId)).valueOrNull?.length
            ?? 0;
    if (count == 0) return const SizedBox.shrink();
    final mins = (count * 9).clamp(20, 90);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.pill,
        border: Border.all(color: t.borderSoft),
      ),
      child: Text(
        '$count упр.  ·  ≈$mins мин',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: t.text2),
      ),
    );
  }
}

/// Small "X упр." text for week row.
class _ExerciseCountText extends ConsumerWidget {
  const _ExerciseCountText({required this.templateId, required this.t});
  final int templateId;
  final ThemeTokens t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(exercisesForTemplateProvider(templateId)).valueOrNull?.length
            ?? 0;
    return Text('$count упр.',
        style: TextStyle(fontSize: 12, color: t.text3));
  }
}

/// Trend / done icon shown at the right of a week row.
class _WorkoutStatusIcon extends StatelessWidget {
  const _WorkoutStatusIcon({required this.day, required this.t});
  final _DayItem day;
  final ThemeTokens t;

  @override
  Widget build(BuildContext context) {
    if (day.isDone) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: t.accentTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.trending_up, size: 16, color: t.accentPress),
      );
    }
    if (day.isToday) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.borderSoft),
        ),
        child: Icon(Icons.arrow_forward, size: 14, color: t.text3),
      );
    }
    // future / past without log
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.trending_down, size: 16,
          color: t.warning.withValues(alpha: 0.8)),
    );
  }
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

class _ExerciseCard extends ConsumerStatefulWidget {
  const _ExerciseCard({required this.exercise, required this.date});
  final ExerciseTemplateTableData exercise;
  final DateTime date;

  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
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
    // Re-fetch "прошлый раз" whenever this week's logged sets change
    // (e.g. right after the user saves a workout) so it never sticks on
    // "нет данных".
    ref.listen(loggedDatesProvider(_weekMonday(widget.date)), (_, __) {
      _load();
    });
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
    required this.dateLabel,
    required this.exercises,
    required this.controllers,
    required this.lastSets,
    required this.db,
    required this.onAskAI,
  });
  final WorkoutTemplateTableData template;
  final DateTime date;
  final String dateLabel;
  final List<ExerciseTemplateTableData> exercises;
  final Map<int, List<(TextEditingController, TextEditingController)>>
      controllers;
  final Map<int, String> lastSets;
  final AppDatabase db;
  final VoidCallback onAskAI;

  @override
  State<_WorkoutLogDialog> createState() => _WorkoutLogDialogState();
}

class _WorkoutLogDialogState extends State<_WorkoutLogDialog> {
  bool _saved = false;
  ({int exId, int set, bool isKg})? _focus;

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
    if (!mounted) return;
    setState(() => _saved = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) Navigator.pop(context);
  }

  void _addSet(int exId) {
    setState(() {
      widget.controllers[exId]!
          .add((TextEditingController(), TextEditingController()));
    });
  }

  void _removeSet(int exId, int index) {
    setState(() {
      final pair = widget.controllers[exId]!.removeAt(index);
      pair.$1.dispose();
      pair.$2.dispose();
    });
  }

  void _askAI() {
    Navigator.pop(context);
    widget.onAskAI();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
              _buildHeader(t),
              Divider(height: 1, color: t.divider),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(wide ? 24 : 16),
                  child: _buildExercises(t, wide),
                ),
              ),
              Divider(height: 1, color: t.divider),
              _focus == null ? _buildFooter(t) : _buildNumpad(t),
        ],
      ),
    );
  }

  // Hardware-keyboard input — active whenever a value cell is focused.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (_focus == null) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _numKey('back');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _numNext();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      _numTab();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _focus = null);
      return KeyEventResult.handled;
    }
    final ch = event.character;
    if (ch != null && ch.isNotEmpty) {
      if (RegExp(r'^[0-9]$').hasMatch(ch)) {
        _numKey(ch);
        return KeyEventResult.handled;
      }
      if (ch == '.' || ch == ',') {
        _numKey('.');
        return KeyEventResult.handled;
      }
      if (ch == '+' || ch == '=') {
        _numKey('+');
        return KeyEventResult.handled;
      }
      if (ch == '-' || ch == '_') {
        _numKey('-');
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _buildHeader(ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.template.name,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 2),
                Text(widget.dateLabel,
                    style:
                        AppTypography.mono(fontSize: 13, color: t.text3)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _askAI,
            icon: const Icon(Icons.auto_awesome_outlined, size: 16),
            label: const Text('Спросить ИИ'),
            style: TextButton.styleFrom(foregroundColor: t.accentPress),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: t.text3,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExercises(ThemeTokens t, bool wide) {
    final cards = [
      for (final ex in widget.exercises) _exerciseCard(ex, t),
    ];
    if (!wide) {
      return Column(
        children: [
          for (final c in cards)
            Padding(padding: const EdgeInsets.only(bottom: 16), child: c),
        ],
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[i]),
            const SizedBox(width: 16),
            Expanded(
                child:
                    i + 1 < cards.length ? cards[i + 1] : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }

  Widget _exerciseCard(ExerciseTemplateTableData ex, ThemeTokens t) {
    final last = widget.lastSets[ex.id] ?? '';
    final pairs = widget.controllers[ex.id] ?? [];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: t.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ex.name,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _askAI,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_outlined,
                          size: 14, color: t.accentPress),
                      const SizedBox(width: 4),
                      Text('Спросить',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: t.accentPress)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(last.isEmpty ? 'Прошлый раз: —' : 'Прошлый раз: $last',
              style: AppTypography.mono(fontSize: 12, color: t.text3)),
          const SizedBox(height: 10),
          for (var j = 0; j < pairs.length; j++) _setRow(ex.id, j, t),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _addSet(ex.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16, color: t.accentPress),
                    const SizedBox(width: 4),
                    Text('Подход',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: t.accentPress)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setRow(int exId, int j, ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text('#${j + 1}',
                style: AppTypography.mono(fontSize: 12, color: t.text3)),
          ),
          Expanded(child: _valCell(exId, j, true, t)),
          const SizedBox(width: 6),
          Text('кг', style: TextStyle(fontSize: 12, color: t.text3)),
          const SizedBox(width: 10),
          Expanded(child: _valCell(exId, j, false, t)),
          const SizedBox(width: 6),
          Text('повт', style: TextStyle(fontSize: 12, color: t.text3)),
          const SizedBox(width: 2),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _removeSet(exId, j),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: t.text4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tappable value cell (design `.val`) — opens the numpad instead of an
  // inline text field. Highlights with the accent when focused.
  Widget _valCell(int exId, int j, bool isKg, ThemeTokens t) {
    final (wCtrl, rCtrl) = widget.controllers[exId]![j];
    final raw = (isKg ? wCtrl : rCtrl).text.trim();
    final f = _focus;
    final focused =
        f != null && f.exId == exId && f.set == j && f.isKg == isKg;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _focus = (exId: exId, set: j, isKg: isKg)),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: focused ? t.accentTint : t.surfaceSunken,
            borderRadius: AppRadius.smAll,
            border: Border.all(
                color: focused ? t.accent : Colors.transparent, width: 1.5),
          ),
          child: Text(
            raw.isEmpty ? '—' : raw,
            style: AppTypography.mono(
                fontSize: 18,
                weight: FontWeight.w500,
                color: focused
                    ? t.accentPress
                    : (raw.isEmpty ? t.text4 : t.text1)),
          ),
        ),
      ),
    );
  }

  void _numKey(String k) {
    final f = _focus;
    if (f == null) return;
    final (wCtrl, rCtrl) = widget.controllers[f.exId]![f.set];
    final ctrl = f.isKg ? wCtrl : rCtrl;
    var v = ctrl.text.trim();
    String fmtKg(double n) {
      if (n < 0) n = 0;
      return n == n.roundToDouble()
          ? n.toInt().toString()
          : n.toStringAsFixed(1);
    }

    switch (k) {
      case 'back':
        v = v.isNotEmpty ? v.substring(0, v.length - 1) : '';
      case '+':
        final n =
            (double.tryParse(v.replaceAll(',', '.')) ?? 0) + (f.isKg ? 2.5 : 1);
        v = f.isKg ? fmtKg(n) : n.toInt().toString();
      case '-':
        final n =
            (double.tryParse(v.replaceAll(',', '.')) ?? 0) - (f.isKg ? 2.5 : 1);
        v = f.isKg ? fmtKg(n) : (n < 0 ? 0 : n.toInt()).toString();
      case '.':
        if (f.isKg && !v.contains('.')) v = v.isEmpty ? '0.' : '$v.';
      default:
        v = v.isEmpty ? k : v + k;
    }
    setState(() => ctrl.text = v);
  }

  void _numTab() {
    final f = _focus;
    if (f == null) return;
    setState(() => _focus = (exId: f.exId, set: f.set, isKg: !f.isKg));
  }

  void _numNext() {
    final f = _focus;
    if (f == null) return;
    final count = widget.controllers[f.exId]!.length;
    if (f.set < count - 1) {
      setState(() => _focus = (exId: f.exId, set: f.set + 1, isKg: true));
      return;
    }
    final idx = widget.exercises.indexWhere((e) => e.id == f.exId);
    if (idx >= 0 && idx < widget.exercises.length - 1) {
      setState(() =>
          _focus = (exId: widget.exercises[idx + 1].id, set: 0, isKg: true));
      return;
    }
    setState(() => _focus = null);
  }

  Widget _buildNumpad(ThemeTokens t) {
    final f = _focus!;
    Widget row(List<Widget> kids) => Padding(
        padding: const EdgeInsets.only(bottom: 8), child: Row(children: kids));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(f.isKg ? 'ВЕС · КГ' : 'ПОВТОРЫ',
                      style: AppTypography.caps(color: t.text3)),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _focus = null),
                      child: Icon(Icons.keyboard_arrow_down,
                          size: 22, color: t.text3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              row([
                _npKey(t, '7'),
                _npKey(t, '8'),
                _npKey(t, '9'),
                _npKey(t, '',
                    icon: Icons.backspace_outlined,
                    onTap: () => _numKey('back')),
              ]),
              row([
                _npKey(t, '4'),
                _npKey(t, '5'),
                _npKey(t, '6'),
                _npKey(t, f.isKg ? '+2.5' : '+1',
                    alt: true, onTap: () => _numKey('+')),
              ]),
              row([
                _npKey(t, '1'),
                _npKey(t, '2'),
                _npKey(t, '3'),
                _npKey(t, f.isKg ? '−2.5' : '−1',
                    alt: true, onTap: () => _numKey('-')),
              ]),
              row([
                _npKey(t, '.', enabled: f.isKg),
                _npKey(t, '0'),
                _npKey(t, '',
                    icon: Icons.keyboard_tab, alt: true, onTap: _numTab),
                _npKey(t, '', icon: Icons.check, go: true, onTap: _numNext),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _npKey(ThemeTokens t, String label,
      {VoidCallback? onTap,
      bool alt = false,
      bool go = false,
      bool enabled = true,
      IconData? icon}) {
    final Widget child;
    if (icon != null) {
      child = Icon(icon,
          size: go ? 22 : 18,
          color: go ? Theme.of(context).colorScheme.onPrimary : t.text2);
    } else {
      child = Text(label,
          style: alt
              ? TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: t.text2)
              : AppTypography.mono(fontSize: 20, color: t.text1));
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: MouseRegion(
            cursor:
                enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: enabled ? (onTap ?? () => _numKey(label)) : null,
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: go ? t.accent : t.surface,
                  borderRadius: AppRadius.smAll,
                  border: go ? null : Border.all(color: t.borderSoft),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      child: Row(
        children: [
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _saved ? null : _save,
            child: _saved
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check, size: 16),
                    SizedBox(width: 6),
                    Text('Сохранено'),
                  ])
                : const Text('Обновить'),
          ),
        ],
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
  String _view = 'library'; // 'library' | 'week'

  // Editor sub-view state.
  bool _editorOpen = false;
  int? _editId; // null = creating a new program
  int _editColor = 0xFF6B8F71;
  final _editNameCtrl = TextEditingController();
  List<_ExDraft> _editExs = [];

  // Program colour palette (stored as ARGB int on the template).
  static const List<int> _hueValues = [
    0xFF6B8F71, 0xFF6E8FB8, 0xFFC08552, 0xFF7FA08A,
    0xFFB5896E, 0xFF9A7AA0, 0xFFC77B7B, 0xFF5B9AA0,
  ];

  @override
  void dispose() {
    _editNameCtrl.dispose();
    for (final e in _editExs) {
      e.ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    final templates = ref.watch(workoutTemplatesProvider).valueOrNull ?? [];
    final slots = ref.watch(scheduleSlotsProvider).valueOrNull ?? [];

    return _editorOpen
        ? _editorView(t)
        : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Программы',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: t.text3,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Segmented switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: _segmented(t),
            ),
            Divider(height: 1, color: t.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                child: _view == 'library'
                    ? _library(t, templates)
                    : _week(t, templates, slots),
              ),
            ),
            Divider(height: 1, color: t.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              child: Row(
                children: [
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Готово'),
                  ),
                ],
              ),
            ),
          ],
        );
  }

  Widget _segmented(ThemeTokens t) {
    Widget seg(String key, String label) {
      final active = _view == key;
      return Expanded(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _view = key),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? t.surface : Colors.transparent,
                borderRadius: AppRadius.smAll,
                border: active ? Border.all(color: t.borderSoft) : null,
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? t.text1 : t.text3)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(children: [seg('library', 'Мои программы'), seg('week', 'Неделя')]),
    );
  }

  // ── Library view ──────────────────────────────────────────────
  Widget _library(ThemeTokens t, List<WorkoutTemplateTableData> templates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Пока нет программ. Создай первую ниже.',
                style: TextStyle(fontSize: 13, color: t.text4)),
          ),
        for (final tmpl in templates) _programCard(t, tmpl),
        const SizedBox(height: 4),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _openNew,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.smAll,
                border: Border.all(color: t.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: t.accentPress),
                  const SizedBox(width: 6),
                  Text('Создать программу',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: t.accentPress)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _programCard(ThemeTokens t, WorkoutTemplateTableData tmpl) {
    final exercises = ref.watch(exercisesForTemplateProvider(tmpl.id)).valueOrNull ??
        const <ExerciseTemplateTableData>[];
    final preview = exercises.map((e) => e.name).take(3).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: t.borderSoft),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openEdit(tmpl),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: Color(tmpl.color), borderRadius: AppRadius.xsAll),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(tmpl.name,
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                          ),
                          Text('${exercises.length} упр.',
                              style: AppTypography.mono(
                                  fontSize: 12, color: t.text3)),
                        ],
                      ),
                      if (preview.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(fontSize: 13, color: t.text2)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: t.text3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Editor open/save/close ────────────────────────────────────
  void _openNew() {
    for (final e in _editExs) {
      e.ctrl.dispose();
    }
    setState(() {
      _editorOpen = true;
      _editId = null;
      _editColor = _hueValues.first;
      _editNameCtrl.text = '';
      _editExs = [_ExDraft()];
    });
  }

  Future<void> _openEdit(WorkoutTemplateTableData tmpl) async {
    final exs = await ref.read(exercisesForTemplateProvider(tmpl.id).future);
    if (!mounted) return;
    for (final e in _editExs) {
      e.ctrl.dispose();
    }
    final drafts = exs.map((ex) {
      var sets = 3;
      var reps = 10;
      try {
        final list = jsonDecode(ex.defaultSetsJson) as List;
        if (list.isNotEmpty) {
          sets = list.length;
          reps = ((list.first as Map)['reps'] as num).toInt();
        }
      } catch (_) {}
      return _ExDraft(id: ex.id, name: ex.name, sets: sets, reps: reps);
    }).toList();
    setState(() {
      _editorOpen = true;
      _editId = tmpl.id;
      _editColor = tmpl.color;
      _editNameCtrl.text = tmpl.name;
      _editExs = drafts.isEmpty ? [_ExDraft()] : drafts;
    });
  }

  void _closeEditor() => setState(() {
        _editorOpen = false;
        _editId = null;
      });

  Future<void> _saveEditor() async {
    final name = _editNameCtrl.text.trim();
    if (name.isEmpty) return;
    final exs = _editExs
        .where((e) => e.ctrl.text.trim().isNotEmpty)
        .map((e) => (
              id: e.id,
              name: e.ctrl.text.trim(),
              sets: e.sets,
              reps: e.reps,
            ))
        .toList();
    final int id;
    if (_editId == null) {
      id = await widget.db.addWorkoutTemplate(name, color: _editColor);
    } else {
      id = _editId!;
      await widget.db.updateWorkoutTemplate(id, name: name, color: _editColor);
    }
    await widget.db.setTemplateExercises(id, exs);
    if (mounted) _closeEditor();
  }

  Future<void> _deleteFromEditor() async {
    if (_editId != null) await widget.db.deleteWorkoutTemplate(_editId!);
    if (mounted) _closeEditor();
  }

  void _addDraftExercise() =>
      setState(() => _editExs.add(_ExDraft()));

  void _removeDraftExercise(int i) => setState(() {
        _editExs[i].ctrl.dispose();
        _editExs.removeAt(i);
      });

  // ── Editor view ───────────────────────────────────────────────
  Widget _editorView(ThemeTokens t) {
    final isNew = _editId == null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 24),
                color: t.text2,
                onPressed: _closeEditor,
              ),
              Expanded(
                child: Text(isNew ? 'Новая программа' : 'Редактировать',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              if (isNew)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: t.text3,
                  onPressed: _closeEditor,
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: t.danger,
                  onPressed: _deleteFromEditor,
                ),
            ],
          ),
        ),
        Divider(height: 1, color: t.divider),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('НАЗВАНИЕ', style: AppTypography.caps(color: t.text3)),
                const SizedBox(height: 8),
                TextField(
                  controller: _editNameCtrl,
                  autofocus: isNew,
                  decoration: InputDecoration(
                    hintText: 'Напр. Push, Грудь+трицепс…',
                    hintStyle: TextStyle(fontSize: 15, color: t.text4),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: t.surfaceSunken,
                    border: OutlineInputBorder(
                        borderRadius: AppRadius.smAll,
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.smAll,
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.smAll,
                        borderSide: BorderSide(color: t.accent, width: 2)),
                  ),
                  style: TextStyle(fontSize: 15, color: t.text1),
                ),
                const SizedBox(height: 18),
                Text('ЦВЕТ', style: AppTypography.caps(color: t.text3)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final v in _hueValues)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => _editColor = v),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Color(v),
                              borderRadius: AppRadius.smAll,
                              border: Border.all(
                                  color: _editColor == v
                                      ? t.text1
                                      : Colors.transparent,
                                  width: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('УПРАЖНЕНИЯ', style: AppTypography.caps(color: t.text3)),
                const SizedBox(height: 10),
                for (var i = 0; i < _editExs.length; i++) _exDraftRow(t, i),
                const SizedBox(height: 4),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _addDraftExercise,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.smAll,
                        border: Border.all(color: t.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: t.accentPress),
                          const SizedBox(width: 6),
                          Text('Добавить упражнение',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: t.accentPress)),
                        ],
                      ),
                    ),
                  ),
                ),
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
                onPressed: _closeEditor,
                child: const Text('Отмена'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saveEditor,
                child: Text(isNew ? 'Создать' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _exDraftRow(ThemeTokens t, int i) {
    final e = _editExs[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: t.borderSoft),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: e.ctrl,
                decoration: InputDecoration(
                  hintText: 'Упражнение ${i + 1}',
                  hintStyle: TextStyle(fontSize: 14, color: t.text4),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: TextStyle(fontSize: 14, color: t.text1),
              ),
            ),
            const SizedBox(width: 10),
            _stepperLabeled(t, 'подх.', e.sets,
                (v) => setState(() => e.sets = v), 1, 12),
            const SizedBox(width: 10),
            _stepperLabeled(t, 'повт.', e.reps,
                (v) => setState(() => e.reps = v), 1, 50),
            const SizedBox(width: 4),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _removeDraftExercise(i),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: t.text4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperLabeled(ThemeTokens t, String label, int value,
      ValueChanged<int> onChange, int min, int max) {
    Widget btn(IconData icon, VoidCallback onTap) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 28,
              height: 30,
              child: Icon(icon, size: 15, color: t.text2),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: t.text3)),
        const SizedBox(width: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: t.border),
            borderRadius: AppRadius.smAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(Icons.remove,
                  () => onChange(value > min ? value - 1 : min)),
              SizedBox(
                width: 24,
                child: Text('$value',
                    textAlign: TextAlign.center,
                    style: AppTypography.mono(
                        fontSize: 14, weight: FontWeight.w600, color: t.text1)),
              ),
              btn(Icons.add, () => onChange(value < max ? value + 1 : max)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Week view ─────────────────────────────────────────────────
  Widget _week(ThemeTokens t, List<WorkoutTemplateTableData> templates,
      List<ScheduleSlotTableData> slots) {
    if (templates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Сначала создай программу во вкладке «Мои программы».',
            style: TextStyle(fontSize: 13, color: t.text4)),
      );
    }
    int? currentFor(int dow) => slots
        .where((s) => s.dayOfWeek == dow)
        .map((s) => s.workoutTemplateId)
        .firstOrNull;

    return Column(
      children: [
        for (var dow = 1; dow <= 7; dow++) ...[
          _weekRow(t, dow, templates, currentFor(dow)),
          if (dow < 7) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _weekRow(ThemeTokens t, int dow,
      List<WorkoutTemplateTableData> templates, int? currentId) {
    Widget pill(String label, Color? dot, bool sel, VoidCallback onTap) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? (dot ?? t.text2) : t.surfaceSunken,
              borderRadius: AppRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: sel ? Colors.white : dot,
                        borderRadius: AppRadius.xsAll),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: sel ? Colors.white : t.text2)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: t.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(_wdLabels[dow - 1],
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.text2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tmpl in templates)
                  pill(tmpl.name, Color(tmpl.color), currentId == tmpl.id,
                      () => widget.db.setScheduleSlot(dow, tmpl.id)),
                pill('Отдых', null, currentId == null,
                    () => widget.db.setScheduleSlot(dow, null)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable exercise row in the program editor.
class _ExDraft {
  _ExDraft({this.id, String name = '', this.sets = 3, this.reps = 10})
      : ctrl = TextEditingController(text: name);
  final int? id;
  final TextEditingController ctrl;
  int sets;
  int reps;
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

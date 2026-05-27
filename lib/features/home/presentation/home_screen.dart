import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _Period _period = _Period.week;

  // Populated from providers in build().
  List<WeightEntryTableData> _entries = [];
  ProfileTableData? _profile;
  List<GoalTableData> _goals = [];
  List<TaskItemTableData> _tasks = [];
  List<ScheduleSlotTableData> _slots = [];
  List<WorkoutTemplateTableData> _templates = [];
  List<DateTime> _workoutDates = [];

  // Dialog controllers — owned by state so they outlive dialog close animations.
  final _weightCtrl      = TextEditingController();
  final _goalLabelCtrl   = TextEditingController();
  final _goalStartCtrl   = TextEditingController();
  final _goalCurrentCtrl = TextEditingController();
  final _goalTargetCtrl  = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _goalLabelCtrl.dispose();
    _goalStartCtrl.dispose();
    _goalCurrentCtrl.dispose();
    _goalTargetCtrl.dispose();
    super.dispose();
  }

  ThemeTokens get _t => ThemeTokens.of(context);

  // ── Date helpers ─────────────────────────────────────────────

  static const _wd = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _mo = [
    'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
  ];
  static const _moShort = [
    'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
  ];
  static const _wdShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  static String _headerDate(DateTime d) =>
      '${_wd[d.weekday - 1]} · ${d.day} ${_mo[d.month - 1]} ${d.year}';

  static String _chartLabel(DateTime d) =>
      '${d.day}\n${_moShort[d.month - 1]}';

  static String _historyLabel(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final mon = d.month.toString().padLeft(2, '0');
    return '${_wdShort[d.weekday - 1]} $day.$mon';
  }

  // ── Derived data ─────────────────────────────────────────────

  List<WeightEntryTableData> get _chartEntries {
    final now = DateTime.now();
    final cutoff = switch (_period) {
      _Period.week => now.subtract(const Duration(days: 7)),
      _Period.month => now.subtract(const Duration(days: 30)),
      _Period.quarter => now.subtract(const Duration(days: 90)),
      _Period.all => DateTime(2000),
    };
    return _entries
        .where((e) => !e.date.isBefore(cutoff))
        .toList()
        .reversed
        .toList();
  }

  ({double min, double max}) _yBounds(List<WeightEntryTableData> data) {
    if (data.isEmpty) return (min: 70.0, max: 100.0);
    double lo = data.first.value, hi = lo;
    for (final e in data) {
      lo = math.min(lo, e.value);
      hi = math.max(hi, e.value);
    }
    final target = _profile?.targetWeightKg;
    if (target != null) {
      lo = math.min(lo, target);
      hi = math.max(hi, target);
    }
    final range = (hi - lo).clamp(1.0, double.infinity);
    return (min: lo - range * 0.2 - 0.5, max: hi + range * 0.2 + 0.5);
  }

  // ── Streak computation ────────────────────────────────────────

  static int _streak(List<DateTime> descDates) {
    if (descDates.isEmpty) return 0;
    final today = _midnight(DateTime.now());
    int count = 0;
    DateTime expected = today;
    for (final d in descDates) {
      final day = _midnight(d);
      if (day == expected) {
        count++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (day.isBefore(expected)) {
        break;
      }
    }
    return count;
  }

  static DateTime _midnight(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  int get _weightStreak {
    final dates = _entries.map((e) => _midnight(e.date)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return _streak(dates);
  }

  int get _workoutStreak => _streak(_workoutDates);

  int get _taskStreak {
    final dates = _tasks
        .where((t) => t.isDone && t.completedAt != null)
        .map((t) => _midnight(t.completedAt!))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return _streak(dates);
  }

  // ── Goal progress ─────────────────────────────────────────────

  static double _goalProgress(GoalTableData g) {
    final range = (g.targetValue - g.startValue).abs();
    if (range == 0) return 1.0;
    final progress = (g.currentValue - g.startValue).abs() / range;
    return progress.clamp(0.0, 1.0);
  }

  // ── Today plan ────────────────────────────────────────────────

  String get _todayWorkoutName {
    final dow = DateTime.now().weekday; // 1=Mon..7=Sun
    final slot =
        _slots.where((s) => s.dayOfWeek == dow).firstOrNull;
    if (slot == null) return 'Отдых';
    final tmpl = _templates
        .where((t) => t.id == slot.workoutTemplateId)
        .firstOrNull;
    return tmpl?.name ?? 'Тренировка';
  }

  // ── Tasks summary ─────────────────────────────────────────────

  int get _openTasksCount => _tasks.where((t) => !t.isDone).length;

  // ── Dialogs ───────────────────────────────────────────────────

  Future<void> _showLogWeight() async {
    final last = _entries.isNotEmpty ? _entries.first.value : null;
    _weightCtrl.text = last != null ? last.toStringAsFixed(1) : '';
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final t = ThemeTokens.of(ctx);
        return AlertDialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          title: Text('Записать вес',
              style: Theme.of(ctx).textTheme.titleLarge),
          content: TextField(
            controller: _weightCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            decoration: InputDecoration(
              suffixText: 'кг',
              hintText: '80.0',
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide(color: t.border),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdAll),
              ),
              onPressed: () {
                final raw = _weightCtrl.text.replaceAll(',', '.');
                final v = double.tryParse(raw);
                if (v != null && v > 0 && v < 500) {
                  final now = DateTime.now();
                  database.addWeightEntry(
                      value: v,
                      date: DateTime(now.year, now.month, now.day));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGoalDialog({GoalTableData? editing}) async {
    _goalLabelCtrl.text   = editing?.label ?? '';
    _goalStartCtrl.text   = editing != null ? editing.startValue.toStringAsFixed(1) : '';
    _goalCurrentCtrl.text = editing != null ? editing.currentValue.toStringAsFixed(1) : '';
    _goalTargetCtrl.text  = editing != null ? editing.targetValue.toStringAsFixed(1) : '';
    var unit = editing?.unit ?? 'kg';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final t = ThemeTokens.of(ctx);
        return StatefulBuilder(builder: (ctx, ss) {
          return AlertDialog(
            backgroundColor: t.surface,
            shape:
                RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
            title: Text(editing == null ? 'Добавить цель' : 'Редактировать',
                style: Theme.of(ctx).textTheme.titleLarge),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogField(ctx, _goalLabelCtrl, 'Название', t,
                      hint: 'Сбросить до 78 кг'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _dialogField(ctx, _goalStartCtrl, 'Старт', t,
                            hint: '85', numeric: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _dialogField(
                            ctx, _goalCurrentCtrl, 'Текущее', t,
                            hint: '82', numeric: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _dialogField(ctx, _goalTargetCtrl, 'Цель', t,
                            hint: '78', numeric: true)),
                  ]),
                  const SizedBox(height: 12),
                  Text('Единица',
                      style: TextStyle(
                          fontSize: 12,
                          color: t.text3,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['kg', 'lbs', 'rep', 'km', '%'].map((u) {
                      final sel = u == unit;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => ss(() => unit = u),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.accent : t.surfaceSunken,
                              borderRadius: AppRadius.pill,
                              border: sel
                                  ? null
                                  : Border.all(color: t.border),
                            ),
                            child: Text(u,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: sel ? Colors.white : t.text2,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              if (editing != null)
                TextButton(
                  onPressed: () async {
                    await database.deleteGoal(editing.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger),
                  child: const Text('Удалить'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll),
                ),
                onPressed: () async {
                  final label = _goalLabelCtrl.text.trim();
                  final start = double.tryParse(
                      _goalStartCtrl.text.replaceAll(',', '.'));
                  final current = double.tryParse(
                      _goalCurrentCtrl.text.replaceAll(',', '.'));
                  final target = double.tryParse(
                      _goalTargetCtrl.text.replaceAll(',', '.'));
                  if (label.isEmpty ||
                      start == null ||
                      current == null ||
                      target == null) return;
                  if (editing == null) {
                    await database.addGoal(
                        label: label,
                        startValue: start,
                        currentValue: current,
                        targetValue: target,
                        unit: unit);
                  } else {
                    await database.updateGoal(editing.id,
                        label: label,
                        startValue: start,
                        currentValue: current,
                        targetValue: target,
                        unit: unit);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _dialogField(BuildContext ctx, TextEditingController ctrl,
      String label, ThemeTokens t,
      {String? hint, bool numeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: t.text3,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]
              : null,
          style: TextStyle(fontSize: 14, color: t.text1),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.text4),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide(color: t.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide:
                  const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _t;
    _entries = ref.watch(weightEntriesProvider).valueOrNull ?? [];
    _profile = ref.watch(profileProvider).valueOrNull;
    _goals = ref.watch(goalsProvider).valueOrNull ?? [];
    _tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    _slots = ref.watch(scheduleSlotsProvider).valueOrNull ?? [];
    _templates = ref.watch(workoutTemplatesProvider).valueOrNull ?? [];
    _workoutDates = ref.watch(workoutDatesProvider).valueOrNull ?? [];

    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      backgroundColor: t.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? AppSpacing.xl3 : AppSpacing.lg,
          vertical: AppSpacing.xl2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, t),
            const SizedBox(height: AppSpacing.xl2),
            wide ? _desktopBody(context, t) : _mobileBody(context, t),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _header(BuildContext context, ThemeTokens t) {
    final name = _profile?.name.trim() ?? '';
    final greeting =
        name.isEmpty || name == 'User' ? 'Привет' : 'Привет, $name';
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting,
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 3),
            Text(_headerDate(DateTime.now()),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: t.text3)),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 22),
          color: t.text3,
          onPressed: () => context.go('/settings'),
        ),
      ],
    );
  }

  // ── Layouts ───────────────────────────────────────────────────

  Widget _desktopBody(BuildContext context, ThemeTokens t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(children: [
            _weightEntryCard(context, t),
            const SizedBox(height: 16),
            _weightChartCard(context, t),
            const SizedBox(height: 16),
            _historyCard(context, t),
          ]),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 300,
          child: Column(children: [
            _goalsCard(context, t),
            const SizedBox(height: 16),
            _streaksCard(context, t),
            const SizedBox(height: 16),
            _todayPlanCard(context, t),
            const SizedBox(height: 16),
            _tasksSummaryCard(context, t),
          ]),
        ),
      ],
    );
  }

  Widget _mobileBody(BuildContext context, ThemeTokens t) {
    return Column(children: [
      _goalsCard(context, t),
      const SizedBox(height: 12),
      _weightEntryCard(context, t),
      const SizedBox(height: 12),
      _weightChartCard(context, t),
      const SizedBox(height: 12),
      _streaksCard(context, t),
      const SizedBox(height: 12),
      _todayPlanCard(context, t),
      const SizedBox(height: 12),
      _tasksSummaryCard(context, t),
      const SizedBox(height: 12),
      _historyCard(context, t),
    ]);
  }

  // ── Weight entry card ─────────────────────────────────────────

  Widget _weightEntryCard(BuildContext context, ThemeTokens t) {
    final latest = _entries.isNotEmpty ? _entries.first : null;
    final prev = _entries.length >= 2 ? _entries[1] : null;
    final delta =
        (latest != null && prev != null) ? latest.value - prev.value : null;
    final currentStr =
        latest != null ? latest.value.toStringAsFixed(1) : '—';
    final units = _profile?.units == 'lbs' ? 'фунты' : 'кг';
    String subtitle;
    if (delta != null) {
      final sign = delta >= 0 ? '+' : '';
      subtitle =
          '${_historyLabel(prev!.date)}  ${prev.value.toStringAsFixed(1)}  ·  $sign${delta.toStringAsFixed(1)}';
    } else if (latest != null) {
      subtitle = 'первая запись';
    } else {
      subtitle = 'нет записей';
    }
    return _card(
      t: t,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ЗАПИСАТЬ ВЕС',
                  style: AppTypography.caps(color: t.text3)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(currentStr,
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: t.text1,
                          height: 1.0)),
                  if (latest != null) ...[
                    const SizedBox(width: 6),
                    Text(units,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: t.text3,
                                fontWeight: FontWeight.w400)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: t.text3)),
            ],
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ElevatedButton(
              onPressed: _showLogWeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdAll),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: const Text('Записать'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weight chart card ─────────────────────────────────────────

  Widget _weightChartCard(BuildContext context, ThemeTokens t) {
    final chart = _chartEntries;
    final latest = _entries.isNotEmpty ? _entries.first : null;
    final bounds = _yBounds(chart);
    String trendStr = '';
    Color trendColor = t.text3;
    IconData? trendIcon;
    if (chart.length >= 2) {
      final diff = chart.last.value - chart.first.value;
      trendColor =
          diff < 0 ? t.success : (diff > 0 ? t.warning : t.text3);
      trendIcon = diff < 0
          ? Icons.arrow_downward
          : (diff > 0 ? Icons.arrow_upward : Icons.remove);
      final sign = diff >= 0 ? '+' : '';
      final lbl = switch (_period) {
        _Period.week => '7 дней',
        _Period.month => '30 дней',
        _Period.quarter => '90 дней',
        _Period.all => 'всё время',
      };
      trendStr = '$sign${diff.toStringAsFixed(1)} за $lbl';
    }
    return _card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ВЕС', style: AppTypography.caps(color: t.text3)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                          latest != null
                              ? latest.value.toStringAsFixed(1)
                              : '—',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: t.text1,
                              height: 1.0)),
                      if (latest != null) ...[
                        const SizedBox(width: 5),
                        Text('кг',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: t.text3)),
                      ],
                      if (trendIcon != null) ...[
                        const SizedBox(width: 12),
                        Icon(trendIcon, size: 13, color: trendColor),
                        const SizedBox(width: 2),
                        Text(trendStr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: trendColor)),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _PeriodSelector(
                  value: _period,
                  onChanged: (p) => setState(() => _period = p)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: chart.length < 2
                ? Center(
                    child: Text(
                      chart.isEmpty
                          ? 'Нет данных'
                          : 'Нужно минимум 2 записи для графика',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: t.text4),
                      textAlign: TextAlign.center,
                    ),
                  )
                : LineChart(_buildChart(chart, bounds, t)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChart(
    List<WeightEntryTableData> entries,
    ({double min, double max}) bounds,
    ThemeTokens t,
  ) {
    final spots = List.generate(
        entries.length, (i) => FlSpot(i.toDouble(), entries[i].value));
    final n = entries.length;
    final step = n <= 7 ? 1 : n <= 14 ? 2 : n <= 31 ? 4 : 7;
    final target = _profile?.targetWeightKg;
    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 1,
            getTitlesWidget: (value, _) {
              final i = value.toInt();
              if (i < 0 || i >= entries.length) {
                return const SizedBox.shrink();
              }
              if (i % step != 0 && i != entries.length - 1) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_chartLabel(entries[i].date),
                    style: TextStyle(fontSize: 9, color: t.text3),
                    textAlign: TextAlign.center),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
      ),
      extraLinesData: target != null
          ? ExtraLinesData(horizontalLines: [
              HorizontalLine(
                y: target,
                color: t.text4,
                strokeWidth: 1,
                dashArray: [5, 6],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.bottomRight,
                  padding:
                      const EdgeInsets.only(right: 6, bottom: 4),
                  style: TextStyle(
                      fontSize: 10,
                      color: t.text4,
                      fontWeight: FontWeight.w500),
                  labelResolver: (_) =>
                      'цель ${target.toStringAsFixed(1)}',
                ),
              ),
            ])
          : const ExtraLinesData(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppColors.accent,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3.5,
              color: AppColors.accent,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accent.withValues(alpha: 0.18),
                AppColors.accent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      minX: 0,
      maxX: (entries.length - 1).toDouble(),
      minY: bounds.min,
      maxY: bounds.max,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) =>
              AppColors.accentPress.withValues(alpha: 0.9),
          getTooltipItems: (spots) => spots
              .map((s) => LineTooltipItem(
                    s.y.toStringAsFixed(1),
                    const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── History card ──────────────────────────────────────────────

  Widget _historyCard(BuildContext context, ThemeTokens t) {
    final last6 = _entries.take(6).toList();
    return _card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ИСТОРИЯ', style: AppTypography.caps(color: t.text3)),
              const Spacer(),
              if (last6.isNotEmpty)
                Text('последние ${last6.length}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: t.text3)),
            ],
          ),
          const SizedBox(height: 12),
          if (last6.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Нет записей',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: t.text4)),
            )
          else
            ...List.generate(last6.length, (i) {
              final entry = last6[i];
              final prev =
                  i + 1 < last6.length ? last6[i + 1] : null;
              final delta =
                  prev != null ? entry.value - prev.value : null;
              return _historyRow(context, entry, delta, t);
            }),
        ],
      ),
    );
  }

  Widget _historyRow(BuildContext context, WeightEntryTableData entry,
      double? delta, ThemeTokens t) {
    final Color dc;
    final String ds;
    if (delta == null) {
      dc = t.text3;
      ds = '—';
    } else if (delta > 0) {
      dc = t.warning;
      ds = '+${delta.toStringAsFixed(1)}';
    } else if (delta < 0) {
      dc = t.success;
      ds = delta.toStringAsFixed(1);
    } else {
      dc = t.text3;
      ds = '0.0';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(_historyLabel(entry.date),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: t.text2)),
          const Spacer(),
          Text(entry.value.toStringAsFixed(1),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.text1)),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text(ds,
                style: TextStyle(
                    fontSize: 13,
                    color: dc,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.right),
          ),
          const SizedBox(width: 6),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => database.deleteWeightEntry(entry.id),
              child: Icon(Icons.close, size: 14, color: t.text4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Goals card ────────────────────────────────────────────────

  Widget _goalsCard(BuildContext context, ThemeTokens t) {
    return _card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ЦЕЛИ', style: AppTypography.caps(color: t.text3)),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showGoalDialog(),
                  child: Icon(Icons.add, size: 18, color: t.text3),
                ),
              ),
            ],
          ),
          if (_goals.isEmpty) ...[
            const SizedBox(height: 16),
            Text('Добавьте первую цель',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: t.text4)),
          ] else
            ...List.generate(_goals.length, (i) {
              final g = _goals[i];
              return Column(
                children: [
                  const SizedBox(height: 16),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showGoalDialog(editing: g),
                      child: _goalRow(context, g, t),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _goalRow(
      BuildContext context, GoalTableData g, ThemeTokens t) {
    final progress = _goalProgress(g);
    final label =
        '${g.currentValue.toStringAsFixed(1)} / ${g.targetValue.toStringAsFixed(1)} ${g.unit}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(g.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500, color: t.text1)),
            ),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: t.text3)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.pill,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: t.surfaceSunken,
            valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? t.success : AppColors.accentPress),
          ),
        ),
        const SizedBox(height: 4),
        Text('${(progress * 100).round()}%',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: t.text3)),
      ],
    );
  }

  // ── Streaks card ──────────────────────────────────────────────

  Widget _streaksCard(BuildContext context, ThemeTokens t) {
    final ws = _weightStreak;
    final wos = _workoutStreak;
    final ts = _taskStreak;

    final chips = <String>[];
    if (ws > 0) chips.add('$ws ${_dayWord(ws)} с весом');
    if (wos > 0) chips.add('$wos ${_dayWord(wos)} тренировок');
    if (ts > 0) chips.add('$ts ${_dayWord(ts)} задач');

    return _card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('СТРИКИ', style: AppTypography.caps(color: t.text3)),
          const SizedBox(height: 12),
          chips.isEmpty
              ? Text('Начни сегодня!',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: t.text4))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips
                      .map((l) => _streakChip(l, t))
                      .toList(),
                ),
        ],
      ),
    );
  }

  static String _dayWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }

  Widget _streakChip(String label, ThemeTokens t) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: t.accentTint,
        borderRadius: AppRadius.pill,
        border: Border.all(color: t.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: t.accentPress)),
        ],
      ),
    );
  }

  // ── Today plan + Tasks summary ────────────────────────────────

  Widget _todayPlanCard(BuildContext context, ThemeTokens t) =>
      _summaryCard(context, 'СЕГОДНЯ ПО ПЛАНУ', _todayWorkoutName, t,
          onOpen: () => context.go('/train'));

  Widget _tasksSummaryCard(BuildContext context, ThemeTokens t) {
    final count = _openTasksCount;
    final label = count == 0
        ? 'Всё сделано'
        : '$count ${_taskWord(count)}';
    return _summaryCard(context, 'ЗАДАЧИ', label, t,
        onOpen: () => context.go('/tasks'));
  }

  static String _taskWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'задач';
    if (mod10 == 1) return 'задача';
    if (mod10 >= 2 && mod10 <= 4) return 'задачи';
    return 'задач';
  }

  Widget _summaryCard(BuildContext context, String label, String value,
      ThemeTokens t, {VoidCallback? onOpen}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caps(color: t.text3)),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: t.text1)),
            ],
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: OutlinedButton(
              onPressed: onOpen,
              style: OutlinedButton.styleFrom(
                foregroundColor: t.text1,
                side: BorderSide(color: t.border),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdAll),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: const Text('Открыть'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared card ───────────────────────────────────────────────

  Widget _card({required Widget child, required ThemeTokens t}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: t.borderSoft),
      ),
      child: child,
    );
  }
}

// ── Period selector ───────────────────────────────────────────

enum _Period { week, month, quarter, all }

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.value, required this.onChanged});

  final _Period value;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    const labels = ['7д', '30д', '90д', 'всё'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          final p = _Period.values[i];
          final active = p == value;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? t.surface : Colors.transparent,
                  borderRadius: AppRadius.pill,
                  border: active ? Border.all(color: t.border) : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? t.text1 : t.text3,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

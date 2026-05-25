import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/providers.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_tokens.dart';
import '../../../app/theme/typography.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _Period _period = _Period.week;

  ThemeTokens get _t => ThemeTokens.of(context);

  static const _weekPoints = <(String, double, double)>[
    ('Вс\n17', 0, 82.4),
    ('Пн\n18', 1, 82.1),
    ('Вт\n19', 2, 82.2),
    ('Ср\n20', 3, 82.0),
    ('Чт\n21', 4, 81.6),
    ('Пт\n22', 5, 81.7),
    ('Сб\n23', 6, 81.4),
  ];

  static const _history = <(String, double, double)>[
    ('сб 23.05', 81.4, -0.3),
    ('пт 22.05', 81.7, 0.1),
    ('чт 21.05', 81.6, -0.4),
    ('ср 20.05', 82.0, -0.2),
    ('вт 19.05', 82.2, 0.1),
    ('пн 18.05', 82.1, -0.3),
  ];

  @override
  Widget build(BuildContext context) {
    final t = _t;
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

  // ── Header ──────────────────────────────────────────────────

  Widget _header(BuildContext context, ThemeTokens t) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final name = profile?.name.trim() ?? '';
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
            Text('Суббота · 23 мая 2026',
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

  // ── Layouts ─────────────────────────────────────────────────

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

  // ── Cards ────────────────────────────────────────────────────

  Widget _weightEntryCard(BuildContext context, ThemeTokens t) {
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
                  Text('81.4',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: t.text1,
                          height: 1.0)),
                  const SizedBox(width: 6),
                  Text('кг',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              color: t.text3,
                              fontWeight: FontWeight.w400)),
                ],
              ),
              const SizedBox(height: 6),
              Text('вчера 81.7  ·  −0.3',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: t.text3)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: const Text('Записать'),
          ),
        ],
      ),
    );
  }

  Widget _weightChartCard(BuildContext context, ThemeTokens t) {
    final spots =
        _weekPoints.map((d) => FlSpot(d.$2, d.$3)).toList();

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
                  Text('ВЕС',
                      style: AppTypography.caps(color: t.text3)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('81.4',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: t.text1,
                              height: 1.0)),
                      const SizedBox(width: 5),
                      Text('кг',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: t.text3)),
                      const SizedBox(width: 12),
                      Icon(Icons.arrow_downward,
                          size: 13, color: t.success),
                      const SizedBox(width: 2),
                      Text('1.0 за 7 дней',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: t.success)),
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
            child: LineChart(_chartData(spots, t)),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(List<FlSpot> spots, ThemeTokens t) {
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
              if (i < 0 || i >= _weekPoints.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _weekPoints[i].$1,
                  style: TextStyle(fontSize: 10, color: t.text3),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 78,
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
              labelResolver: (_) => 'target 78',
            ),
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppColors.accent,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
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
      maxX: 6,
      minY: 76.5,
      maxY: 83.5,
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

  Widget _historyCard(BuildContext context, ThemeTokens t) {
    return _card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ИСТОРИЯ',
                  style: AppTypography.caps(color: t.text3)),
              const Spacer(),
              Text('последние 6',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: t.text3)),
            ],
          ),
          const SizedBox(height: 12),
          ..._history
              .map((d) => _historyRow(context, d.$1, d.$2, d.$3, t)),
        ],
      ),
    );
  }

  Widget _historyRow(BuildContext context, String date, double weight,
      double delta, ThemeTokens t) {
    final Color deltaColor;
    final String deltaStr;
    if (delta == 0) {
      deltaColor = t.text3;
      deltaStr = '—';
    } else if (delta > 0) {
      deltaColor = t.warning;
      deltaStr = '+${delta.toStringAsFixed(1)}';
    } else {
      deltaColor = t.success;
      deltaStr = delta.toStringAsFixed(1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(date,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: t.text2)),
          const Spacer(),
          Text(weight.toStringAsFixed(1),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.text1)),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text(deltaStr,
                style: TextStyle(
                    fontSize: 13,
                    color: deltaColor,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

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
              Icon(Icons.add, size: 18, color: t.text3),
            ],
          ),
          const SizedBox(height: 16),
          _goalRow(context, 'Сбросить до 78 кг', 0.51, '81.4 / 78', t),
          const SizedBox(height: 16),
          _goalRow(context, 'Становая 140', 0.50, '120 / 140', t),
        ],
      ),
    );
  }

  Widget _goalRow(BuildContext context, String title, double progress,
      String label, ThemeTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
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
            valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentPress),
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

  Widget _streaksCard(BuildContext context, ThemeTokens t) {
    const chips = ['12 дней с весом', 'Push 4 недели', '5 дней задач'];
    return _card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('СТРИКИ', style: AppTypography.caps(color: t.text3)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((l) => _streakChip(l, t)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _streakChip(String label, ThemeTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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

  Widget _todayPlanCard(BuildContext context, ThemeTokens t) {
    return _summaryCard(context, 'СЕГОДНЯ ПО ПЛАНУ', 'Push', t);
  }

  Widget _tasksSummaryCard(BuildContext context, ThemeTokens t) {
    return _summaryCard(context, 'ЗАДАЧИ', '3 на сегодня', t);
  }

  Widget _summaryCard(BuildContext context, String label, String value,
      ThemeTokens t) {
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
          OutlinedButton(
            onPressed: () {},
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
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

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

// ── Period selector ──────────────────────────────────────────

enum _Period { week, month, quarter, all }

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.value, required this.onChanged});

  final _Period value;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    const labels = ['7д', '30д', '90д', 'всё'];
    const periods = _Period.values;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          final active = periods[i] == value;
          return GestureDetector(
            onTap: () => onChanged(periods[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: active ? t.surface : Colors.transparent,
                borderRadius: AppRadius.pill,
                border: active
                    ? Border.all(color: t.border)
                    : null,
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
          );
        }),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Period _period = _Period.week;

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
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? AppSpacing.xl3 : AppSpacing.lg,
          vertical: AppSpacing.xl2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: AppSpacing.xl2),
            wide ? _desktopBody(context) : _mobileBody(context),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Привет, Алекс',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 3),
            Text('Суббота · 23 мая 2026',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.text3)),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 22),
          color: AppColors.text3,
          onPressed: () {},
        ),
      ],
    );
  }

  // ── Layouts ─────────────────────────────────────────────────

  Widget _desktopBody(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(children: [
            _weightEntryCard(context),
            const SizedBox(height: 16),
            _weightChartCard(context),
            const SizedBox(height: 16),
            _historyCard(context),
          ]),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 300,
          child: Column(children: [
            _goalsCard(context),
            const SizedBox(height: 16),
            _streaksCard(context),
            const SizedBox(height: 16),
            _todayPlanCard(context),
            const SizedBox(height: 16),
            _tasksSummaryCard(context),
          ]),
        ),
      ],
    );
  }

  Widget _mobileBody(BuildContext context) {
    return Column(children: [
      _goalsCard(context),
      const SizedBox(height: 12),
      _weightEntryCard(context),
      const SizedBox(height: 12),
      _weightChartCard(context),
      const SizedBox(height: 12),
      _streaksCard(context),
      const SizedBox(height: 12),
      _todayPlanCard(context),
      const SizedBox(height: 12),
      _tasksSummaryCard(context),
      const SizedBox(height: 12),
      _historyCard(context),
    ]);
  }

  // ── Cards ────────────────────────────────────────────────────

  Widget _weightEntryCard(BuildContext context) {
    return _card(
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ЗАПИСАТЬ ВЕС', style: AppTypography.caps(color: AppColors.text3)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('81.4',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                          height: 1.0)),
                  const SizedBox(width: 6),
                  Text('кг',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: AppColors.text3, fontWeight: FontWeight.w400)),
                ],
              ),
              const SizedBox(height: 6),
              Text('вчера 81.7  ·  −0.3',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.text3)),
            ],
          ),
          const Spacer(),
          _greenButton(
            label: 'Записать',
            icon: Icons.add,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _weightChartCard(BuildContext context) {
    final spots =
        _weekPoints.map((d) => FlSpot(d.$2, d.$3)).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ВЕС', style: AppTypography.caps(color: AppColors.text3)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text('81.4',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text1,
                              height: 1.0)),
                      const SizedBox(width: 5),
                      Text('кг',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.text3)),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_downward,
                          size: 13, color: AppColors.success),
                      const SizedBox(width: 2),
                      Text('1.0 за 7 дней',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.success)),
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
            child: LineChart(_chartData(spots)),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(List<FlSpot> spots) {
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
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.text3),
                  textAlign: TextAlign.center,
                ),
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
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 78,
            color: AppColors.text4,
            strokeWidth: 1,
            dashArray: [5, 6],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.text4,
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

  Widget _historyCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ИСТОРИЯ',
                  style: AppTypography.caps(color: AppColors.text3)),
              const Spacer(),
              Text('последние 6',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.text3)),
            ],
          ),
          const SizedBox(height: 12),
          ..._history.map((d) => _historyRow(context, d.$1, d.$2, d.$3)),
        ],
      ),
    );
  }

  Widget _historyRow(
      BuildContext context, String date, double weight, double delta) {
    final Color deltaColor;
    final String deltaStr;
    if (delta == 0) {
      deltaColor = AppColors.text3;
      deltaStr = '—';
    } else if (delta > 0) {
      deltaColor = AppColors.warning;
      deltaStr = '+${delta.toStringAsFixed(1)}';
    } else {
      deltaColor = AppColors.success;
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
                  ?.copyWith(color: AppColors.text2)),
          const Spacer(),
          Text(weight.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text1)),
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

  Widget _goalsCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ЦЕЛИ',
                  style: AppTypography.caps(color: AppColors.text3)),
              const Spacer(),
              const Icon(Icons.add, size: 18, color: AppColors.text3),
            ],
          ),
          const SizedBox(height: 16),
          _goalRow(context, 'Сбросить до 78 кг', 0.51, '81.4 / 78'),
          const SizedBox(height: 16),
          _goalRow(context, 'Становая 140', 0.50, '120 / 140'),
        ],
      ),
    );
  }

  Widget _goalRow(
      BuildContext context, String title, double progress, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500, color: AppColors.text1)),
            ),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.text3)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.pill,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.surfaceSunken,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.accentPress),
          ),
        ),
        const SizedBox(height: 4),
        Text('${(progress * 100).round()}%',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.text3)),
      ],
    );
  }

  Widget _streaksCard(BuildContext context) {
    const chips = ['12 дней с весом', 'Push 4 недели', '5 дней задач'];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('СТРИКИ',
              style: AppTypography.caps(color: AppColors.text3)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map(_streakChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _streakChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentPress)),
        ],
      ),
    );
  }

  Widget _todayPlanCard(BuildContext context) {
    return _summaryCard(context, 'СЕГОДНЯ ПО ПЛАНУ', 'Push');
  }

  Widget _tasksSummaryCard(BuildContext context) {
    return _summaryCard(context, 'ЗАДАЧИ', '3 на сегодня');
  }

  Widget _summaryCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.caps(color: AppColors.text3)),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.text1)),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text1,
              side: const BorderSide(color: AppColors.border),
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

  static Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: child,
    );
  }

  static Widget _greenButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: _primaryButtonStyle,
      child: Text(label),
    );
  }

  static final _primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    elevation: 0,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}

// ── Period selector ──────────────────────────────────────────

enum _Period { week, month, quarter, all }

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector(
      {required this.value, required this.onChanged});

  final _Period value;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['7д', '30д', '90д', 'всё'];
    const periods = _Period.values;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
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
                color: active
                    ? AppColors.surface
                    : Colors.transparent,
                borderRadius: AppRadius.pill,
                border: active
                    ? Border.all(color: AppColors.border)
                    : null,
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: active
                      ? AppColors.text1
                      : AppColors.text3,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

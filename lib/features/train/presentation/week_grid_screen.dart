import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_tokens.dart';
import '../../../app/theme/typography.dart';

// ─── Data models ────────────────────────────────────────────

enum _WorkoutType { push, pull, legs }

enum _DayStatus { done, rest, today, upcoming }

enum _Trend { up, flat, down }

class _DayData {
  const _DayData({
    required this.weekday,
    required this.date,
    required this.status,
    this.type,
    this.exercises = 0,
    this.minutes = 0,
    this.trend,
  });

  final String weekday;
  final String date;
  final _DayStatus status;
  final _WorkoutType? type;
  final int exercises;
  final int minutes;
  final _Trend? trend;
}

class _ExerciseData {
  const _ExerciseData(this.name, this.lastSets);

  final String name;
  final String lastSets;
}

// ─── Screen ─────────────────────────────────────────────────

class WeekGridScreen extends StatefulWidget {
  const WeekGridScreen({super.key});

  @override
  State<WeekGridScreen> createState() => _WeekGridScreenState();
}

class _WeekGridScreenState extends State<WeekGridScreen> {
  int _selectedIndex = 5; // Saturday

  ThemeTokens get _t => ThemeTokens.of(context);

  static const _days = <_DayData>[
    _DayData(
        weekday: 'ПН',
        date: '18.05',
        type: _WorkoutType.push,
        exercises: 5,
        minutes: 45,
        status: _DayStatus.done,
        trend: _Trend.up),
    _DayData(weekday: 'ВТ', date: '19.05', status: _DayStatus.rest),
    _DayData(
        weekday: 'СР',
        date: '20.05',
        type: _WorkoutType.pull,
        exercises: 4,
        minutes: 45,
        status: _DayStatus.done,
        trend: _Trend.flat),
    _DayData(weekday: 'ЧТ', date: '21.05', status: _DayStatus.rest),
    _DayData(
        weekday: 'ПТ',
        date: '22.05',
        type: _WorkoutType.legs,
        exercises: 6,
        minutes: 45,
        status: _DayStatus.done,
        trend: _Trend.down),
    _DayData(
        weekday: 'СБ',
        date: '23.05',
        type: _WorkoutType.push,
        exercises: 5,
        minutes: 45,
        status: _DayStatus.today),
    _DayData(weekday: 'ВС', date: '24.05', status: _DayStatus.rest),
  ];

  static const _todayExercises = <_ExerciseData>[
    _ExerciseData('Жим лёжа', '80×8 · 80×8 · 80×6'),
    _ExerciseData('Жим стоя', '40×10 · 40×10 · 40×8'),
    _ExerciseData('Разводки гантелей', '14×12 · 14×12 · 14×10'),
    _ExerciseData('Брусья', '0×12 · 0×10 · 0×8'),
    _ExerciseData('Трицепс на блоке', '35×12 · 35×12 · 35×10'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, t),
          Divider(height: 1, color: t.divider),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl3),
            child: _buildWeekGrid(context, t),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl3, 0, AppSpacing.xl3, AppSpacing.xl3),
              child: _buildWorkoutDetail(context, t),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ThemeTokens t) {
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
              Text('18 – 24 мая 2026',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: t.text3)),
            ],
          ),
          const Spacer(),
          _NavIconButton(icon: Icons.chevron_left, t: t, onTap: () {}),
          const SizedBox(width: 8),
          _outlinedSmallButton('Сегодня', t: t, onTap: () {}),
          const SizedBox(width: 8),
          _NavIconButton(icon: Icons.chevron_right, t: t, onTap: () {}),
          const SizedBox(width: 16),
          _outlinedSmallButton('≡  Программа', t: t, onTap: () {}),
        ],
      ),
    );
  }

  // ── Week grid ─────────────────────────────────────────────

  Widget _buildWeekGrid(BuildContext context, ThemeTokens t) {
    return Row(
      children: List.generate(_days.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _days.length - 1 ? 8 : 0),
            child: _DayCard(
              data: _days[i],
              selected: i == _selectedIndex,
              t: t,
              onTap: () => setState(() => _selectedIndex = i),
            ),
          ),
        );
      }),
    );
  }

  // ── Workout detail ────────────────────────────────────────

  Widget _buildWorkoutDetail(BuildContext context, ThemeTokens t) {
    final day = _days[_selectedIndex];

    if (day.status == _DayStatus.rest) {
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
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('СЕГОДНЯШНЯЯ ТРЕНИРОВКА',
            style: AppTypography.caps(color: t.text3)),
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
                      Text(_workoutName(day.type),
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: t.text1)),
                      const SizedBox(height: 4),
                      Text(
                          'Сб · ${day.date} · ${day.exercises} упр.',
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
                      minimumSize: const Size(0, 46),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdAll),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Начать тренировку'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _todayExercises.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _ExerciseCard(exercise: _todayExercises[i], t: t),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _workoutName(_WorkoutType? type) => switch (type) {
        _WorkoutType.push => 'Push',
        _WorkoutType.pull => 'Pull',
        _WorkoutType.legs => 'Legs',
        null => '',
      };

  static Widget _outlinedSmallButton(String label,
      {required ThemeTokens t, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    );
  }
}

// ─── Day card ────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.data,
    required this.selected,
    required this.t,
    required this.onTap,
  });

  final _DayData data;
  final bool selected;
  final ThemeTokens t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRest = data.status == _DayStatus.rest;
    final isDone = data.status == _DayStatus.done;
    final isToday = data.status == _DayStatus.today;

    if (isRest) return _restCard(context);

    final Color bg;
    final Border border;

    if (isDone) {
      bg = t.accentTint;
      border = Border.all(color: t.borderSoft);
    } else if (isToday) {
      bg = t.surface;
      border = Border.all(
          color: selected ? t.accentPress : t.border,
          width: selected ? 2 : 1);
    } else {
      bg = t.surface;
      border = Border.all(color: t.border);
    }

    return GestureDetector(
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
                Text(data.weekday,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isDone ? t.accentPress : t.text3)),
                if (data.trend != null) _trendIcon(data.trend!, t),
              ],
            ),
            const SizedBox(height: 2),
            Text(data.date,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDone ? t.accentPress : t.text1)),
            const SizedBox(height: 6),
            Text(_workoutName(data.type),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDone ? t.accentPress : t.text1)),
            const SizedBox(height: 4),
            Text('${data.exercises} упр.  ≈${data.minutes} мин',
                style: TextStyle(
                    fontSize: 11,
                    color: isDone ? t.accent : t.text3)),
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
                      color: isDone || isToday ? t.accentPress : t.text3),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward,
                    size: 11,
                    color: isDone || isToday ? t.accentPress : t.text3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _restCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.weekday,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: t.text4)),
          const SizedBox(height: 2),
          Text(data.date,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.text4)),
          const SizedBox(height: 20),
          Text('Отдых',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: t.text4)),
        ],
      ),
    );
  }

  Widget _trendIcon(_Trend trend, ThemeTokens t) => switch (trend) {
        _Trend.up => Icon(Icons.trending_up, size: 14, color: t.success),
        _Trend.flat =>
          Icon(Icons.trending_flat, size: 14, color: t.text3),
        _Trend.down => Icon(Icons.trending_down, size: 14, color: t.warning),
      };

  static String _workoutName(_WorkoutType? type) => switch (type) {
        _WorkoutType.push => 'Push',
        _WorkoutType.pull => 'Pull',
        _WorkoutType.legs => 'Legs',
        null => '',
      };
}

// ─── Exercise card ───────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.t});

  final _ExerciseData exercise;
  final ThemeTokens t;

  @override
  Widget build(BuildContext context) {
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
          Text(exercise.name,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.text1)),
          const SizedBox(height: 6),
          Text('прошлый раз: ${exercise.lastSets}',
              style: TextStyle(fontSize: 11, color: t.text3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Nav icon button ─────────────────────────────────────────

class _NavIconButton extends StatelessWidget {
  const _NavIconButton(
      {required this.icon, required this.t, required this.onTap});

  final IconData icon;
  final ThemeTokens t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

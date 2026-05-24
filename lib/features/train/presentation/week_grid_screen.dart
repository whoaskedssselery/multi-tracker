import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl3),
            child: _buildWeekGrid(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl3, 0, AppSpacing.xl3, AppSpacing.xl3),
              child: _buildWorkoutDetail(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
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
                      ?.copyWith(color: AppColors.text3)),
            ],
          ),
          const Spacer(),
          _NavIconButton(
              icon: Icons.chevron_left, onTap: () {}),
          const SizedBox(width: 8),
          _outlinedSmallButton('Сегодня', onTap: () {}),
          const SizedBox(width: 8),
          _NavIconButton(
              icon: Icons.chevron_right, onTap: () {}),
          const SizedBox(width: 16),
          _outlinedSmallButton('≡  Программа', onTap: () {}),
        ],
      ),
    );
  }

  // ── Week grid ─────────────────────────────────────────────

  Widget _buildWeekGrid(BuildContext context) {
    return Row(
      children: List.generate(_days.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: i < _days.length - 1 ? 8 : 0),
            child: _DayCard(
              data: _days[i],
              selected: i == _selectedIndex,
              onTap: () => setState(() => _selectedIndex = i),
            ),
          ),
        );
      }),
    );
  }

  // ── Workout detail ────────────────────────────────────────

  Widget _buildWorkoutDetail(BuildContext context) {
    final day = _days[_selectedIndex];

    if (day.status == _DayStatus.rest) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          children: [
            const Icon(Icons.self_improvement_outlined,
                size: 32, color: AppColors.text4),
            const SizedBox(height: 12),
            Text('День отдыха',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.text2)),
          ],
        ),
      );
    }

    final typeName = _workoutName(day.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('СЕГОДНЯШНЯЯ ТРЕНИРОВКА',
            style: AppTypography.caps(color: AppColors.text3)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(typeName,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text1)),
                      const SizedBox(height: 4),
                      Text(
                          'Сб · ${day.date} · ${day.exercises} упр.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.text3)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      _ExerciseCard(exercise: _todayExercises[i]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  static String _workoutName(_WorkoutType? type) {
    switch (type) {
      case _WorkoutType.push:
        return 'Push';
      case _WorkoutType.pull:
        return 'Pull';
      case _WorkoutType.legs:
        return 'Legs';
      case null:
        return '';
    }
  }

  static Widget _outlinedSmallButton(String label,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: AppRadius.smAll,
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text1)),
      ),
    );
  }
}

// ─── Day card ────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _DayData data;
  final bool selected;
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
      bg = AppColors.accentTint;
      border = Border.all(color: AppColors.borderSoft);
    } else if (isToday) {
      bg = selected ? AppColors.surface : AppColors.surface;
      border = Border.all(
          color: selected ? AppColors.accentPress : AppColors.border,
          width: selected ? 2 : 1);
    } else {
      bg = AppColors.surface;
      border = Border.all(color: AppColors.border);
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
                        color: isDone
                            ? AppColors.accentPress
                            : AppColors.text3)),
                if (data.trend != null) _trendIcon(data.trend!),
              ],
            ),
            const SizedBox(height: 2),
            Text(data.date,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDone ? AppColors.accentPress : AppColors.text1)),
            const SizedBox(height: 6),
            Text(_workoutName(data.type),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.accentPress : AppColors.text1)),
            const SizedBox(height: 4),
            Text('${data.exercises} упр.  ≈${data.minutes} мин',
                style: TextStyle(
                    fontSize: 11,
                    color: isDone ? AppColors.accent : AppColors.text3)),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
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
                      color: isDone
                          ? AppColors.accentPress
                          : isToday
                              ? AppColors.accentPress
                              : AppColors.text3),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward,
                    size: 11,
                    color: isDone || isToday
                        ? AppColors.accentPress
                        : AppColors.text3),
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
        color: AppColors.bg,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.weekday,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.text4)),
          const SizedBox(height: 2),
          Text(data.date,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text4)),
          const SizedBox(height: 20),
          Text('Отдых',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.text4)),
        ],
      ),
    );
  }

  Widget _trendIcon(_Trend trend) {
    switch (trend) {
      case _Trend.up:
        return const Icon(Icons.trending_up, size: 14, color: AppColors.success);
      case _Trend.flat:
        return const Icon(Icons.trending_flat, size: 14, color: AppColors.text3);
      case _Trend.down:
        return const Icon(Icons.trending_down,
            size: 14, color: AppColors.warning);
    }
  }

  static String _workoutName(_WorkoutType? type) {
    switch (type) {
      case _WorkoutType.push:
        return 'Push';
      case _WorkoutType.pull:
        return 'Pull';
      case _WorkoutType.legs:
        return 'Legs';
      case null:
        return '';
    }
  }
}

// ─── Exercise card ───────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final _ExerciseData exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text1)),
          const SizedBox(height: 6),
          Text('прошлый раз: ${exercise.lastSets}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.text3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Nav icon button ─────────────────────────────────────────

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: AppRadius.smAll,
          color: AppColors.surface,
        ),
        child: Icon(icon, size: 18, color: AppColors.text2),
      ),
    );
  }
}

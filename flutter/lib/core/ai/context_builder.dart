import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../main.dart';
import '../db/database.dart';

part 'context_builder.g.dart';

@riverpod
ContextBuilder contextBuilder(ContextBuilderRef ref) {
  return ContextBuilder(ref.watch(dbProvider));
}

class ContextBuilder {
  const ContextBuilder(this._db);
  final AppDatabase _db;

  Future<String> build(String filter) async {
    final today = DateTime.now();
    final todayStr = 'Сегодня: ${_fmt(today)} (${_weekday(today.weekday)})';
    final ctx = await switch (filter) {
      'train'  => _trainContext(),
      'weight' => _weightContext(),
      'tasks'  => _tasksContext(),
      _        => _allContext(),
    };
    return '$todayStr\n\n$ctx';
  }

  Future<String> _weightContext() async {
    final entries = await (_db.select(_db.weightEntryTable)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(30))
        .get();
    if (entries.isEmpty) return 'Данных о весе нет.';
    final lines = entries.map((e) => '${_fmt(e.date)}: ${e.value} кг');
    return 'Вес (последние ${entries.length} записей, новые первыми):\n'
        '${lines.join('\n')}';
  }

  Future<String> _tasksContext({int limit = 50}) async {
    final tasks = await (_db.select(_db.taskItemTable)
          ..where((t) => t.isDone.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm.asc(t.createdAt),
          ])
          ..limit(limit + 1))
        .get();
    final hasMore = tasks.length > limit;
    final displayed = hasMore ? tasks.take(limit).toList() : tasks;
    if (displayed.isEmpty) return 'Активных задач нет.';
    final lines = displayed.map((t) {
      final prio = t.priority == 'none' ? '' : '[${t.priority}] ';
      return '- $prio${t.body}';
    });
    final suffix = hasMore ? '\n(ещё задачи не показаны)' : '';
    return 'Активные задачи (${displayed.length}${hasMore ? '+' : ''}):\n'
        '${lines.join('\n')}$suffix';
  }

  Future<String> _trainContext({int days = 28}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final sets = await (_db.select(_db.setEntryTable)
          ..where((t) => t.date.isBiggerOrEqualValue(cutoff))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.asc(t.setIndex),
          ]))
        .get();
    if (sets.isEmpty) {
      return 'Тренировочных данных нет (нет записанных подходов за последние $days дней).';
    }

    // Actual date range of logged data
    final dates = sets.map((s) => s.date).toList();
    final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final latest   = dates.reduce((a, b) => a.isAfter(b)  ? a : b);

    final exerciseIds = sets.map((s) => s.exerciseTemplateId).toSet().toList();
    final exercises = await (_db.select(_db.exerciseTemplateTable)
          ..where((t) => t.id.isIn(exerciseIds)))
        .get();
    final nameMap = {for (final e in exercises) e.id: e.name};

    // Group: exerciseId → date → sets
    final byEx = <int, Map<String, List<String>>>{};
    for (final s in sets) {
      final d = _fmt(s.date);
      final w = s.weightKg == s.weightKg.roundToDouble()
          ? s.weightKg.toInt().toString()
          : s.weightKg.toStringAsFixed(1);
      byEx
          .putIfAbsent(s.exerciseTemplateId, () => {})
          .putIfAbsent(d, () => [])
          .add('${w}×${s.reps}');
    }

    final lines = <String>[];
    for (final entry in byEx.entries) {
      final name = nameMap[entry.key] ?? 'Упражнение ${entry.key}';
      lines.add(name);
      for (final session in entry.value.entries) {
        lines.add('  ${session.key}: ${session.value.join(', ')}');
      }
    }
    return 'Тренировки (данные с ${_fmt(earliest)} по ${_fmt(latest)}, '
        'всего ${_uniqueDays(sets)} тренировочных дней):\n${lines.join('\n')}';
  }

  Future<String> _allContext() async {
    // Tighter limits in combined mode to stay within smaller model token budgets.
    final results = await Future.wait([
      _weightContext(),
      _tasksContext(limit: 20),
      _trainContext(days: 14),
    ]);
    return results.join('\n\n');
  }

  // ── Helpers ──────────────────────────────────────────────────

  static String _fmt(DateTime d) =>
      '${d.year}-${_p(d.month)}-${_p(d.day)}';

  static String _p(int v) => v.toString().padLeft(2, '0');

  static String _weekday(int iso) => const [
        '', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'
      ][iso];

  static int _uniqueDays(List<SetEntryTableData> sets) {
    return sets
        .map((s) => '${s.date.year}-${s.date.month}-${s.date.day}')
        .toSet()
        .length;
  }
}

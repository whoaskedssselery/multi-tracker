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
    return switch (filter) {
      'train' => await _trainContext(),
      'weight' => await _weightContext(),
      'tasks' => await _tasksContext(),
      _ => await _allContext(),
    };
  }

  Future<String> _weightContext() async {
    final entries = await (_db.select(_db.weightEntryTable)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(30))
        .get();
    if (entries.isEmpty) return 'Нет данных о весе.';
    final lines = entries.map((e) {
      final d = '${e.date.year}-'
          '${e.date.month.toString().padLeft(2, '0')}-'
          '${e.date.day.toString().padLeft(2, '0')}';
      return '$d: ${e.value} кг';
    });
    return 'Вес (последние ${entries.length} записей, от новых к старым):\n'
        '${lines.join('\n')}';
  }

  Future<String> _tasksContext() async {
    final tasks = await (_db.select(_db.taskItemTable)
          ..where((t) => t.isDone.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    if (tasks.isEmpty) return 'Нет активных задач.';
    final lines = tasks.map((t) {
      final prio = t.priority == 'none' ? '' : '[${t.priority}] ';
      final due = t.dueAt != null
          ? ' (до ${t.dueAt!.day}.${t.dueAt!.month.toString().padLeft(2, '0')})'
          : '';
      return '- $prio${t.body}$due';
    });
    return 'Активные задачи (${tasks.length}):\n${lines.join('\n')}';
  }

  Future<String> _trainContext() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 28));
    final sets = await (_db.select(_db.setEntryTable)
          ..where((t) => t.date.isBiggerOrEqualValue(cutoff))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.asc(t.setIndex),
          ]))
        .get();
    if (sets.isEmpty) return 'Нет тренировочных данных за последние 4 недели.';

    final exerciseIds = sets.map((s) => s.exerciseTemplateId).toSet().toList();
    final exercises = await (_db.select(_db.exerciseTemplateTable)
          ..where((t) => t.id.isIn(exerciseIds)))
        .get();
    final nameMap = {for (final e in exercises) e.id: e.name};

    // Group: exerciseId → date → sets
    final byEx = <int, Map<String, List<String>>>{};
    for (final s in sets) {
      final d = '${s.date.year}-'
          '${s.date.month.toString().padLeft(2, '0')}-'
          '${s.date.day.toString().padLeft(2, '0')}';
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
    return 'Тренировки за последние 4 недели:\n${lines.join('\n')}';
  }

  Future<String> _allContext() async {
    final results = await Future.wait([
      _weightContext(),
      _tasksContext(),
      _trainContext(),
    ]);
    return results.join('\n\n');
  }
}

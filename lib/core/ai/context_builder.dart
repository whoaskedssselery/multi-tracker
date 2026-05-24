import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'context_builder.g.dart';

/// Builds context strings for the AI chat by reading from the DB
/// and formatting them as a human-readable summary.
@riverpod
ContextBuilder contextBuilder(ContextBuilderRef ref) {
  return ContextBuilder();
}

class ContextBuilder {
  // TODO: inject DB DAOs when implementing AI chat feature

  /// Build context for the given [filter].
  Future<String> build(String filter) async {
    return switch (filter) {
      'train'  => await _trainContext(),
      'weight' => await _weightContext(),
      'tasks'  => await _tasksContext(),
      _        => await _allContext(),
    };
  }

  Future<String> _trainContext() async {
    // TODO: query last 4 weeks of set entries grouped by exercise
    return '[Train context — TODO]';
  }

  Future<String> _weightContext() async {
    // TODO: query last 30 days of weight entries
    return '[Weight context — TODO]';
  }

  Future<String> _tasksContext() async {
    // TODO: query open tasks grouped by priority
    return '[Tasks context — TODO]';
  }

  Future<String> _allContext() async {
    final parts = await Future.wait([
      _trainContext(),
      _weightContext(),
      _tasksContext(),
    ]);
    return parts.join('\n\n');
  }
}

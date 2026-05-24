/// Gemini prompt templates
///
/// Each function returns a ready-to-send prompt string.
/// Fill in TODOs when implementing the respective feature.
library;

class AppPrompts {
  AppPrompts._();

  // ── System instruction ────────────────────────────────────────

  static const String systemInstruction = '''
You are a personal fitness and productivity coach embedded in the Multi-tracker app.
Be concise, data-driven, and friendly. Respond in the same language the user writes in.
When citing data from the app, format it clearly with dates and numbers.
Keep responses under 200 words unless the user asks for more detail.
''';

  // ── Workout / exercise analysis ───────────────────────────────

  /// Analyse progress for a single exercise given recent set history.
  /// [exerciseName] – e.g. "Bench Press"
  /// [historyJson] – JSON string of last N sessions: [{date, sets:[{weight,reps}]}]
  static String exerciseAnalysis({
    required String exerciseName,
    required String historyJson,
  }) {
    // TODO: refine prompt with actual data shape
    return '''
Analyse my progress on "$exerciseName".
Recent sessions (newest last):
$historyJson

Classify as one of: progress / plateau / regress.
Give a 1-sentence reason and a short actionable tip.
Reply in JSON: {"verdict":"progress|plateau|regress","explanation":"…","tip":"…"}
''';
  }

  // ── Chat context builders ─────────────────────────────────────

  /// Build a context preamble for chat, filtered by [filter].
  /// [filter] – 'all' | 'train' | 'weight' | 'tasks'
  /// [contextData] – pre-built context string from context_builder.dart
  static String chatWithContext({
    required String filter,
    required String contextData,
    required String userMessage,
  }) {
    // TODO: inject real contextData from ContextBuilder
    return '''
Context ($filter):
$contextData

User: $userMessage
''';
  }

  // ── Weight insights ───────────────────────────────────────────

  /// Generate an insight about recent weight trend.
  static String weightInsight({required String weightHistoryJson}) {
    // TODO: real prompt
    return '''
My weight log (kg, newest first):
$weightHistoryJson

In 1-2 sentences, comment on my trend and give one practical tip.
''';
  }

  // ── Task suggestions ──────────────────────────────────────────

  /// Suggest how to reprioritize tasks given a list.
  static String taskSuggestion({required String tasksJson}) {
    // TODO: real prompt
    return '''
My open tasks:
$tasksJson

Suggest a priority order for today in a short bulleted list.
''';
  }
}

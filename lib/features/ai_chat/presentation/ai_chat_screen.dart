import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/providers.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_tokens.dart';
import '../../../core/ai/context_builder.dart';
import '../../../core/ai/groq_client.dart';
import '../../../core/db/database.dart';
import '../../../main.dart';
import '../../../shared/widgets/page_header.dart';

// ─── Filter enum ────────────────────────────────────────────

enum _AiFilter { all, train, weight, tasks }

extension _AiFilterX on _AiFilter {
  String get key => switch (this) {
        _AiFilter.all => 'all',
        _AiFilter.train => 'train',
        _AiFilter.weight => 'weight',
        _AiFilter.tasks => 'tasks',
      };
  String get label => switch (this) {
        _AiFilter.all => 'Всё',
        _AiFilter.train => 'Тренировки',
        _AiFilter.weight => 'Вес',
        _AiFilter.tasks => 'Задачи',
      };
}

// ─── Screen ─────────────────────────────────────────────────

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  _AiFilter _filter = _AiFilter.all;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  static const _suggestions = [
    'Как у меня дела на неделе?',
    'Оцени мои тренировки',
    'Что с весом?',
  ];

  List<ChatMessageTableData> _msgs = [];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    _inputCtrl.clear();
    setState(() => _sending = true);

    try {
      // Persist user message
      await database.addChatMessage(
        role: 'user',
        content: text,
        contextFilter: _filter.key,
      );
      _scrollToBottom();

      // Build context and history (scoped to current filter)
      final contextStr =
          await ref.read(contextBuilderProvider).build(_filter.key);
      final history =
          (await database.getLastChatMessagesForFilter(_filter.key, limit: 20))
              .map((m) => ChatTurn(role: m.role, text: m.content))
              .toList();

      // Compose prompt with context preamble + user message
      final prompt =
          'Данные из приложения (фильтр: ${_filter.label}):\n$contextStr\n\nВопрос пользователя: $text';

      // Call Groq
      final client = ref.read(groqClientProvider);
      final response = await client.generateContent(
        prompt,
        history: history,
        systemInstruction:
            'Ты персональный фитнес- и продуктивность-тренер в приложении Multi-tracker. '
            'ВАЖНО: используй ТОЛЬКО данные из предоставленного контекста. '
            'Не придумывай и не предполагай факты, периоды или цифры, которых нет в данных. '
            'Если данных мало — честно скажи об этом. '
            'Будь лаконичен, конкретен и дружелюбен. '
            'Отвечай на том же языке, на котором пишет пользователь. '
            'При ссылке на данные называй точные даты и цифры из контекста. '
            'Не превышай 150 слов, если пользователь не просит подробнее.',
      );

      // Persist assistant response
      await database.addChatMessage(
        role: 'assistant',
        content: response.text,
        contextFilter: _filter.key,
      );
      _scrollToBottom();
    } on NoApiKeyException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Укажите Groq API ключ в Настройках'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on GroqException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.message}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    _msgs = ref.watch(chatMessagesForFilterProvider(_filter.key)).valueOrNull ?? [];

    if (Platform.isIOS) return _buildIos(context, t);

    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        children: [
          AppPageHeader(
            title: 'ИИ',
            actions: [
              _FilterBar(
                  value: _filter,
                  onChanged: (f) => setState(() => _filter = f)),
              if (_msgs.isNotEmpty) ...[
                const SizedBox(width: 12),
                _ClearButton(onTap: () async {
                  await database.clearChatHistoryForFilter(_filter.key);
                }),
              ],
            ],
          ),
          Expanded(child: _buildMessages(context, t)),
          if (_sending) _buildTypingIndicator(t),
          _buildSuggestions(context),
          _buildInput(context, t),
        ],
      ),
    );
  }

  // ── iOS layout ─────────────────────────────────────────────────

  Widget _buildIos(BuildContext context, ThemeTokens t) {
    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        children: [
          // Large title header with filter chips below
          IosPageHeader(
            title: 'AI',
            action: _msgs.isNotEmpty
                ? GestureDetector(
                    onTap: () async {
                      await database
                          .clearChatHistoryForFilter(_filter.key);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        'Очистить',
                        style: TextStyle(
                          fontSize: 14,
                          color: t.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : null,
            bottom: _FilterBar(
              value: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildMessages(context, t)),
          if (_sending) _buildTypingIndicator(t),
          _buildSuggestions(context),
          const SizedBox(height: 10),
          _buildIosInput(context, t),
        ],
      ),
    );
  }

  // ── iOS input bar ──────────────────────────────────────────────

  Widget _buildIosInput(BuildContext context, ThemeTokens t) {
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: t.border),
              ),
              child: Focus(
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    if (!_sending) _sendMessage();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(fontSize: 15, color: t.text1),
                  decoration: InputDecoration(
                    hintText: 'Спросить...',
                    hintStyle: TextStyle(fontSize: 15, color: t.text4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _sending
                    ? AppColors.accent.withAlpha(120)
                    : AppColors.accent,
                borderRadius: AppRadius.mdAll,
              ),
              child: const Icon(Icons.send_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Messages ──────────────────────────────────────────────

  Widget _buildMessages(BuildContext context, ThemeTokens t) {
    if (_msgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentPress],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.mdAll,
              ),
              child: const Center(
                child: Text('ИИ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Привет! Я твой ИИ-тренер.',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.text1)),
            const SizedBox(height: 6),
            Text('Спроси что-нибудь о тренировках, весе или задачах.',
                style: TextStyle(fontSize: 13, color: t.text3),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.lg),
      itemCount: _msgs.length,
      itemBuilder: (_, i) => _MessageBubble(message: _msgs[i]),
    );
  }

  // ── Typing indicator ──────────────────────────────────────

  Widget _buildTypingIndicator(ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentPress],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.smAll,
            ),
            child: const Center(
              child: Text('AI',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: t.borderSoft),
            ),
            child: const SizedBox(
              width: 36,
              child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestions ───────────────────────────────────────────

  Widget _buildSuggestions(BuildContext context) {
    if (_msgs.isNotEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl3),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _SuggestionChip(
          label: _suggestions[i],
          onTap: () => _inputCtrl.text = _suggestions[i],
        ),
      ),
    );
  }

  // ── Input ─────────────────────────────────────────────────

  Widget _buildInput(BuildContext context, ThemeTokens t) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: t.surfaceSunken,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: t.borderSoft),
              ),
              child: Focus(
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    if (!_sending) _sendMessage();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                controller: _inputCtrl,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(fontSize: 14, color: t.text1),
                decoration: InputDecoration(
                  hintText: 'Спросить...',
                  hintStyle: TextStyle(fontSize: 14, color: t.text4),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              ), // Focus
            ),
          ),
          const SizedBox(width: 10),
          MouseRegion(
            cursor: _sending
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _sending ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _sending
                      ? AppColors.accent.withAlpha(120)
                      : AppColors.accent,
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(Icons.arrow_upward,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clear button ────────────────────────────────────────────

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: AppRadius.pill,
            border: Border.all(color: t.border),
          ),
          child: Text('Очистить',
              style: TextStyle(
                  fontSize: 12, color: t.text3, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

// ─── Filter bar ──────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});

  final _AiFilter value;
  final ValueChanged<_AiFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_AiFilter.values.length, (i) {
        final f = _AiFilter.values[i];
        final active = f == value;
        return Padding(
          padding: EdgeInsets.only(left: i > 0 ? 6 : 0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : t.surface,
                  borderRadius: AppRadius.pill,
                  border: active ? null : Border.all(color: t.border),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : t.text2,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Message bubble ──────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessageTableData message;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentPress],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.smAll,
              ),
              child: const Center(
                child: Text('ИИ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isUser ? t.accentTint : t.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(
                      isUser ? AppRadius.lg : AppRadius.xs),
                  bottomRight: Radius.circular(
                      isUser ? AppRadius.xs : AppRadius.lg),
                ),
                border: isUser ? null : Border.all(color: t.borderSoft),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? t.accentPress : t.text1,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Suggestion chip ────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: AppRadius.pill,
            border: Border.all(color: t.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: t.text2,
                  fontWeight: FontWeight.w400)),
        ),
      ),
    );
  }
}


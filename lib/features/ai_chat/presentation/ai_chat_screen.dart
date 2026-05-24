import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';

// ─── Data models ────────────────────────────────────────────

enum _AiFilter { all, train, weight, tasks }

class _Message {
  const _Message({
    required this.text,
    required this.isUser,
    this.card,
  });

  final String text;
  final bool isUser;
  final _InlineCard? card;
}

class _InlineCard {
  const _InlineCard({required this.title, required this.body});

  final String title;
  final String body;
}

// ─── Screen ─────────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  _AiFilter _filter = _AiFilter.all;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _messages = <_Message>[
    _Message(
      text: 'Покажи мою прогрессию по жиму лёжа за апрель.',
      isUser: true,
    ),
    _Message(
      text:
          'За апрель ты сделал 4 push-сессии. Рабочий вес шёл 75 → 77.5 → 80 → 80 — линейный прогресс, потом плато на 80.',
      isUser: false,
      card: _InlineCard(
        title: 'Жим лёжа · 12 апр',
        body: '80 × 8  ·  80 × 8  ·  80 × 6',
      ),
    ),
    _Message(
      text: 'Что не так с плато?',
      isUser: true,
    ),
    _Message(
      text:
          'Похоже, нужно либо неделю разгрузить (80% работы), либо повысить частоту жима до 2× в неделю. Готов раскладку — попроси.',
      isUser: false,
    ),
  ];

  static const _suggestions = [
    'Как у меня дела на неделе?',
    'Оцени мои жимы',
    'Что с весом?',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _buildMessages(context)),
          _buildSuggestions(context),
          _buildInput(context),
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
          Text('AI',
              style: Theme.of(context).textTheme.headlineLarge),
          const Spacer(),
          _FilterBar(
              value: _filter,
              onChanged: (f) => setState(() => _filter = f)),
        ],
      ),
    );
  }

  // ── Messages ──────────────────────────────────────────────

  Widget _buildMessages(BuildContext context) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.lg),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
    );
  }

  // ── Suggestions ───────────────────────────────────────────

  Widget _buildSuggestions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.md),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions
            .map((s) => _SuggestionChip(
                label: s,
                onTap: () {
                  _inputCtrl.text = s;
                }))
            .toList(),
      ),
    );
  }

  // ── Input ─────────────────────────────────────────────────

  Widget _buildInput(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl3, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSunken,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: TextField(
                controller: _inputCtrl,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.text1),
                decoration: const InputDecoration(
                  hintText: 'Спросить...',
                  hintStyle: TextStyle(
                      fontSize: 14, color: AppColors.text4),
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
          const SizedBox(width: 10),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
            onTap: () {
              if (_inputCtrl.text.trim().isEmpty) return;
              _inputCtrl.clear();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accent,
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

// ─── Filter bar ──────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});

  final _AiFilter value;
  final ValueChanged<_AiFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Всё', 'Тренировки', 'Вес', 'Задачи'];
    const filters = _AiFilter.values;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final active = filters[i] == value;
        return Padding(
          padding: EdgeInsets.only(left: i > 0 ? 6 : 0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
            onTap: () => onChanged(filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color:
                    active ? AppColors.accent : AppColors.surface,
                borderRadius: AppRadius.pill,
                border: active
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : AppColors.text2,
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

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

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
                child: Text('AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.accentTint
                        : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft:
                          const Radius.circular(AppRadius.lg),
                      topRight:
                          const Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(
                          isUser ? AppRadius.lg : AppRadius.xs),
                      bottomRight: Radius.circular(
                          isUser ? AppRadius.xs : AppRadius.lg),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.borderSoft),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser
                          ? AppColors.accentPress
                          : AppColors.text1,
                      height: 1.5,
                    ),
                  ),
                ),
                if (message.card != null) ...[
                  const SizedBox(height: 8),
                  _InlineCardWidget(card: message.card!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Inline card ────────────────────────────────────────────

class _InlineCardWidget extends StatelessWidget {
  const _InlineCardWidget({required this.card});

  final _InlineCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2)),
          const SizedBox(height: 6),
          Text(card.body,
              style: AppTypography.mono(
                  fontSize: 13, color: AppColors.text1)),
        ],
      ),
    );
  }
}

// ─── Suggestion chip ────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip(
      {required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.pill,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.text2,
                fontWeight: FontWeight.w400)),
      ),
      ),
    );
  }
}

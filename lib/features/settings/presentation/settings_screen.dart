import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyCtrl =
      TextEditingController(text: '●●●●●●●●●●●●●●●●●●●●●●●●●●●●');
  bool _obscureKey = true;
  bool _notifEnabled = true;
  bool _morningReminder = true;
  String _theme = 'system';

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl3, vertical: AppSpacing.xl2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('Настройки',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xl3),

            // Profile
            _sectionLabel('ПРОФИЛЬ'),
            _card([
              _textRow('Имя', 'Алекс'),
              _divider(),
              _textRow('Целевой вес', '78 кг'),
              _divider(),
              _textRow('Рост', '180 см'),
            ]),
            const SizedBox(height: AppSpacing.xl2),

            // Appearance
            _sectionLabel('ВНЕШНИЙ ВИД'),
            _card([
              _themeRow(),
            ]),
            const SizedBox(height: AppSpacing.xl2),

            // AI
            _sectionLabel('AI — GEMINI'),
            _card([
              _apiKeyRow(),
              _divider(),
              _infoRow('Модель', 'gemini-2.0-flash'),
            ]),
            const SizedBox(height: AppSpacing.xl2),

            // Notifications
            _sectionLabel('УВЕДОМЛЕНИЯ'),
            _card([
              _switchRow('Уведомления', _notifEnabled,
                  (v) => setState(() => _notifEnabled = v)),
              _divider(),
              _switchRow('Утреннее напоминание', _morningReminder,
                  (v) => setState(() => _morningReminder = v)),
              _divider(),
              _infoRow('Время', '08:00'),
            ]),
            const SizedBox(height: AppSpacing.xl2),

            // Data
            _sectionLabel('ДАННЫЕ'),
            _card([
              _actionRow('Экспорт данных (CSV)', Icons.download_outlined,
                  () {}),
              _divider(),
              _actionRow('Экспорт данных (JSON)', Icons.code_outlined,
                  () {}),
              _divider(),
              _actionRow(
                  'Сбросить все данные',
                  Icons.delete_forever_outlined,
                  () => _confirmReset(context),
                  color: AppColors.danger),
            ]),
            const SizedBox(height: AppSpacing.xl2),

            // About
            _sectionLabel('О ПРИЛОЖЕНИИ'),
            _card([
              _infoRow('Версия', '0.1.0'),
              _divider(),
              _infoRow('Платформа', 'Windows'),
            ]),
            const SizedBox(height: AppSpacing.xl4),
          ],
        ),
      ),
    );
  }

  // ── Section helpers ──────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(label, style: AppTypography.caps(color: AppColors.text3)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(children: children),
    );
  }

  static Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: AppSpacing.xl),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }

  // ── Row types ────────────────────────────────────────────────

  Widget _textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: AppColors.text1)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontSize: 14, color: AppColors.text3)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.text4),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: AppColors.text1)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontSize: 14, color: AppColors.text3)),
        ],
      ),
    );
  }

  Widget _switchRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: AppColors.text1)),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
            activeTrackColor: AppColors.accentTint,
          ),
        ],
      ),
    );
  }

  Widget _actionRow(String label, IconData icon, VoidCallback onTap,
      {Color color = AppColors.text1}) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(fontSize: 14, color: color)),
            const Spacer(),
            Icon(Icons.chevron_right, size: 16, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _apiKeyRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: [
          const Text('Gemini API Key',
              style: TextStyle(fontSize: 14, color: AppColors.text1)),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _apiKeyCtrl,
              obscureText: _obscureKey,
              style: AppTypography.mono(fontSize: 12, color: AppColors.text3),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _obscureKey
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: AppColors.text3,
            ),
            onPressed: () => setState(() => _obscureKey = !_obscureKey),
          ),
        ],
      ),
    );
  }

  Widget _themeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          const Text('Тема',
              style: TextStyle(fontSize: 14, color: AppColors.text1)),
          const Spacer(),
          _ThemePicker(
            value: _theme,
            onChanged: (v) => setState(() => _theme = v),
          ),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: const Text('Сбросить все данные?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text(
            'Это действие удалит все записи веса, тренировки и задачи без возможности восстановления.',
            style: TextStyle(fontSize: 14, color: AppColors.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Сбросить',
                style: TextStyle(color: AppColors.danger,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные сброшены')),
      );
    }
  }
}

// ─── Theme picker ────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('light', 'Светлая'),
      ('dark', 'Тёмная'),
      ('system', 'Авто'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final active = o.$1 == value;
          return GestureDetector(
            onTap: () => onChanged(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.surface : Colors.transparent,
                borderRadius: AppRadius.pill,
                border: active ? Border.all(color: AppColors.border) : null,
              ),
              child: Text(o.$2,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppColors.text1 : AppColors.text3)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

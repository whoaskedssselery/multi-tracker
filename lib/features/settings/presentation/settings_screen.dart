import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/providers.dart';
import '../../../app/theme/breakpoints.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/theme_tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/db/database.dart';
import '../../../main.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _obscureKey = true;
  bool _pingLoading = false;

  ThemeTokens get _t => ThemeTokens.of(context);

  static const _groqModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'mixtral-8x7b-32768',
  ];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final profile = ref.watch(profileProvider).valueOrNull;
    final prefs = ref.watch(preferencesProvider).valueOrNull;
    final apiKey = ref.watch(groqApiKeyProvider).valueOrNull;
    final currentModel = prefs?.aiModel ?? _groqModels.first;
    final safeModel =
        _groqModels.contains(currentModel) ? currentModel : _groqModels.first;

    return Scaffold(
      backgroundColor: t.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl3, vertical: AppSpacing.xl2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Настройки',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xl3),

            // ── Profile ──────────────────────────────────────
            _sectionLabel('ПРОФИЛЬ'),
            _card([
              _editableRow('Имя', profile?.name ?? '—', t: t,
                  onTap: () => _FieldEditDialog.show(
                    context,
                    title: 'Имя',
                    initialValue: profile?.name ?? '',
                    onSave: (v) => ref.read(dbProvider).upsertProfile(
                      ProfileTableCompanion(name: Value(v)),
                    ),
                    validator: _validateName,
                  )),
              _divider(t),
              _editableRow(
                'Рост',
                profile?.heightCm != null ? '${profile!.heightCm} см' : '—',
                t: t,
                onTap: () => _FieldEditDialog.show(
                  context,
                  title: 'Рост',
                  initialValue: profile?.heightCm?.toString() ?? '',
                  suffix: 'см',
                  keyboardType: TextInputType.number,
                  onSave: (v) {
                    final n = int.tryParse(v.trim());
                    if (n == null) return Future.value();
                    return ref.read(dbProvider).upsertProfile(
                      ProfileTableCompanion(heightCm: Value(n)),
                    );
                  },
                  validator: _validateHeight,
                ),
              ),
              _divider(t),
              _editableRow(
                'Целевой вес',
                profile?.targetWeightKg != null
                    ? '${profile!.targetWeightKg} кг'
                    : '—',
                t: t,
                onTap: () => _FieldEditDialog.show(
                  context,
                  title: 'Целевой вес',
                  initialValue: profile?.targetWeightKg?.toString() ?? '',
                  suffix: 'кг',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSave: (v) {
                    final n =
                        double.tryParse(v.trim().replaceAll(',', '.'));
                    if (n == null) return Future.value();
                    return ref.read(dbProvider).upsertProfile(
                      ProfileTableCompanion(targetWeightKg: Value(n)),
                    );
                  },
                  validator: _validateWeight,
                ),
              ),
            ], t: t),
            const SizedBox(height: AppSpacing.xl2),

            // ── Appearance ───────────────────────────────────
            _sectionLabel('ВНЕШНИЙ ВИД'),
            _card([_themeRow(prefs?.themeMode ?? 'system', t)], t: t),
            const SizedBox(height: AppSpacing.xl2),

            // ── AI ───────────────────────────────────────────
            _sectionLabel('AI — GROQ'),
            _card([
              _apiKeySection(apiKey, safeModel, t),
              _divider(t),
              _modelRow(safeModel, t),
            ], t: t),
            const SizedBox(height: AppSpacing.xl2),

            // ── Notifications ────────────────────────────────
            _sectionLabel('УВЕДОМЛЕНИЯ'),
            _card([
              _switchRow(
                'Уведомления',
                prefs?.notificationsEnabled ?? true,
                t: t,
                onChanged: (v) => ref.read(dbProvider).upsertPreferences(
                  AppPreferencesTableCompanion(
                      notificationsEnabled: Value(v)),
                ),
              ),
            ], t: t),
            const SizedBox(height: AppSpacing.xl2),

            // ── Data ─────────────────────────────────────────
            _sectionLabel('ДАННЫЕ'),
            _card([
              _actionRow('Экспорт данных (CSV)',
                  Icons.download_outlined, () {}, t: t),
              _divider(t),
              _actionRow('Экспорт данных (JSON)',
                  Icons.code_outlined, () {}, t: t),
              _divider(t),
              _actionRow(
                'Сбросить все данные',
                Icons.delete_forever_outlined,
                () => _confirmReset(context),
                color: AppColors.danger,
                t: t,
              ),
            ], t: t),
            const SizedBox(height: AppSpacing.xl2),

            // ── About ────────────────────────────────────────
            _sectionLabel('О ПРИЛОЖЕНИИ'),
            _card([
              _infoRow('Версия', '0.1.0', t: t),
              _divider(t),
              _infoRow('Платформа', 'Windows', t: t),
            ], t: t),
            const SizedBox(height: AppSpacing.xl4),
          ],
        ),
      ),
    );
  }

  // ── Layout helpers ───────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(label, style: AppTypography.caps(color: _t.text3)),
    );
  }

  Widget _card(List<Widget> children, {required ThemeTokens t}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: t.borderSoft),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl),
      child: Divider(height: 1, color: t.divider),
    );
  }

  // ── Row types ────────────────────────────────────────────────

  Widget _editableRow(String label, String value,
      {required VoidCallback onTap, required ThemeTokens t}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: t.text1)),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 14, color: t.text3)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 16, color: t.text4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {required ThemeTokens t}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: t.text1)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 14, color: t.text3)),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value,
      {required ValueChanged<bool> onChanged, required ThemeTokens t}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: t.text1)),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
            activeTrackColor: t.accentTint,
          ),
        ],
      ),
    );
  }

  Widget _actionRow(String label, IconData icon, VoidCallback onTap,
      {Color? color, required ThemeTokens t}) {
    final c = color ?? t.text1;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, color: c)),
            const Spacer(),
            Icon(Icons.chevron_right,
                size: 16, color: c.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ── API key section ──────────────────────────────────────────

  Widget _apiKeySection(String? apiKey, String model, ThemeTokens t) {
    final hasKey = apiKey != null && apiKey.isNotEmpty;
    final displayed = hasKey
        ? (_obscureKey ? '●' * apiKey.length.clamp(0, 40) : apiKey)
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Groq API Key',
                  style: TextStyle(fontSize: 14, color: t.text1)),
              const Spacer(),
              if (hasKey) ...[
                GestureDetector(
                  onTap: () => setState(() => _obscureKey = !_obscureKey),
                  child: Icon(
                    _obscureKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 16,
                    color: t.text3,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showKeyEditor(context, apiKey),
                  child: Text(
                    hasKey ? 'Изменить' : 'Добавить',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            displayed,
            style: AppTypography.mono(fontSize: 12, color: t.text3),
            overflow: TextOverflow.ellipsis,
          ),
          if (hasKey) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed:
                    _pingLoading ? null : () => _pingGroq(apiKey, model),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: _pingLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Проверить'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Theme row ────────────────────────────────────────────────

  Widget _themeRow(String current, ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Text('Тема', style: TextStyle(fontSize: 14, color: t.text1)),
          const Spacer(),
          _ThemePicker(
            value: current,
            onChanged: (v) => ref.read(dbProvider).upsertPreferences(
              AppPreferencesTableCompanion(themeMode: Value(v)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Model row ────────────────────────────────────────────────

  Widget _modelRow(String current, ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Text('Модель', style: TextStyle(fontSize: 14, color: t.text1)),
          const Spacer(),
          DropdownButton<String>(
            value: current,
            underline: const SizedBox.shrink(),
            style: TextStyle(
                fontSize: 13, color: t.text3, fontWeight: FontWeight.w500),
            dropdownColor: t.surface,
            borderRadius: AppRadius.mdAll,
            items: _groqModels
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              ref.read(dbProvider).upsertPreferences(
                AppPreferencesTableCompanion(aiModel: Value(v)),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Key editor ───────────────────────────────────────────────

  Future<void> _showKeyEditor(BuildContext ctx, String? current) async {
    final ctrl = TextEditingController(text: current ?? '');
    final isDesktop =
        MediaQuery.sizeOf(ctx).width >= kDesktopBreakpoint;

    Future<void> save(BuildContext sheetCtx) async {
      await ref.read(groqApiKeyProvider.notifier).set(ctrl.text);
      if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
    }

    Widget body(BuildContext sheetCtx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            style: AppTypography.mono(fontSize: 13, color: _t.text1),
            decoration: InputDecoration(
              hintText: 'gsk_...',
              filled: true,
              fillColor: _t.surfaceSunken,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop(),
                child: const Text('Отмена'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => save(sheetCtx),
                child: const Text('Сохранить'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    }

    if (isDesktop) {
      await showDialog<void>(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Groq API Key'),
          content: SizedBox(width: 440, child: body(dialogCtx)),
          actionsPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        builder: (sheetCtx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
            left: AppSpacing.xl2,
            right: AppSpacing.xl2,
            top: AppSpacing.xl2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Groq API Key',
                  style: Theme.of(sheetCtx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600, fontSize: 17)),
              const SizedBox(height: AppSpacing.xl),
              body(sheetCtx),
            ],
          ),
        ),
      );
    }

    ctrl.dispose();
  }

  // ── Groq ping ────────────────────────────────────────────────

  // Always ping with the smallest free-tier model to avoid 403 from
  // premium-only models.
  static const _pingModel = 'llama-3.1-8b-instant';

  Future<void> _pingGroq(String apiKey, String _model) async {
    setState(() => _pingLoading = true);
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      ));
      await dio.post<dynamic>(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _pingModel,
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ],
          'max_tokens': 1,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ключ работает')));
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final body = e.response?.data;
      String? detail;
      if (body is Map) {
        final err = body['error'];
        if (err is Map) detail = err['message'] as String?;
      } else if (body is String && body.isNotEmpty) {
        detail = body;
      }
      final String msg;
      if (status == null) {
        msg = 'Нет ответа от сервера: ${e.message ?? e.type.name}';
      } else if (status == 401) {
        msg = 'Неверный ключ (401)';
      } else if (status == 403) {
        msg = detail ?? 'Доступ запрещён (403) — проверь тарифный план';
      } else if (status == 429) {
        msg = 'Превышен лимит запросов (429)';
      } else if (status == 400) {
        msg = 'Неверный запрос (400): ${detail ?? ""}';
      } else {
        msg = '${detail ?? e.message ?? e.type.name} ($status)';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $msg')));
    } catch (e) {
      // Non-Dio exceptions (SocketException, TlsException, etc.)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сетевая ошибка: $e')));
    } finally {
      if (mounted) setState(() => _pingLoading = false);
    }
  }

  // ── Reset ────────────────────────────────────────────────────

  Future<void> _confirmReset(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Сбросить все данные?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text(
          'Это действие удалит все записи веса, тренировки и задачи без возможности восстановления.',
          style: TextStyle(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Сбросить',
                style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Данные сброшены')));
    }
  }

  // ── Validators ───────────────────────────────────────────────

  static String? _validateName(String v) {
    if (v.trim().isEmpty) return 'Имя не может быть пустым';
    if (v.trim().length > 50) return 'Максимум 50 символов';
    return null;
  }

  static String? _validateHeight(String v) {
    final n = int.tryParse(v.trim());
    if (n == null) return 'Введите целое число';
    if (n < 50 || n > 250) return 'От 50 до 250 см';
    return null;
  }

  static String? _validateWeight(String v) {
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null) return 'Введите число';
    if (n < 20 || n > 300) return 'От 20 до 300 кг';
    return null;
  }
}

// ─── Field editor dialog ────────────────────────────────────

class _FieldEditDialog extends StatefulWidget {
  const _FieldEditDialog({
    required this.title,
    required this.initialValue,
    required this.onSave,
    required this.validator,
    this.suffix,
    this.keyboardType,
    this.isDesktop = true,
  });

  final String title;
  final String initialValue;
  final Future<void> Function(String) onSave;
  final String? Function(String) validator;
  final String? suffix;
  final TextInputType? keyboardType;
  final bool isDesktop;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String initialValue,
    required Future<void> Function(String) onSave,
    required String? Function(String) validator,
    String? suffix,
    TextInputType? keyboardType,
  }) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;
    final widget = _FieldEditDialog(
      title: title,
      initialValue: initialValue,
      onSave: onSave,
      validator: validator,
      suffix: suffix,
      keyboardType: keyboardType,
      isDesktop: isDesktop,
    );
    if (isDesktop) {
      return showDialog<void>(context: context, builder: (_) => widget);
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => widget,
      );
    }
  }

  @override
  State<_FieldEditDialog> createState() => _FieldEditDialogState();
}

class _FieldEditDialogState extends State<_FieldEditDialog> {
  late final TextEditingController _ctrl;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Always call setState so _isDirty is re-evaluated on every keystroke
  bool get _isDirty => _ctrl.text.trim() != widget.initialValue.trim();

  Future<void> _save() async {
    final v = _ctrl.text;
    final err = widget.validator(v);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.onSave(v.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка сохранения';
          _saving = false;
        });
      }
    }
  }

  Widget _buildField() {
    return TextField(
      controller: _ctrl,
      autofocus: true,
      keyboardType: widget.keyboardType,
      // Always rebuild so the Save button reacts to every keystroke
      onChanged: (_) => setState(() => _error = null),
      decoration: InputDecoration(
        suffixText: widget.suffix,
        errorText: _error,
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed: (_isDirty && !_saving) ? _save : null,
        child: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Text('Сохранить'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDesktop) {
      return AlertDialog(
        title: Text(widget.title),
        content: SizedBox(width: 360, child: _buildField()),
        actionsPadding: const EdgeInsets.all(16),
        actions: _buildActions(),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: AppSpacing.xl2,
        right: AppSpacing.xl2,
        top: AppSpacing.xl2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildField(),
          const SizedBox(height: AppSpacing.xl2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _buildActions(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ─── Theme picker ────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    const options = [
      ('light', 'Светлая'),
      ('dark', 'Тёмная'),
      ('system', 'Авто'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: active ? t.surface : Colors.transparent,
                borderRadius: AppRadius.pill,
                border: active ? Border.all(color: t.border) : null,
              ),
              child: Text(
                o.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? t.text1 : t.text3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

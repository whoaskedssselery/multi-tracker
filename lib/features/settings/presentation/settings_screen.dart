import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _obscureKey    = true;
  bool _pingLoading   = false;
  bool _exportLoading = false;
  final _keyCtrl = TextEditingController();

  ThemeTokens get _t => ThemeTokens.of(context);

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

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
                  Icons.download_outlined,
                  _exportLoading ? null : _exportCsv,
                  t: t),
              _divider(t),
              _actionRow('Экспорт данных (JSON)',
                  Icons.code_outlined,
                  _exportLoading ? null : _exportJson,
                  t: t),
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
              _infoRow('Платформа',
                  '${Platform.operatingSystem[0].toUpperCase()}${Platform.operatingSystem.substring(1)}',
                  t: t),
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

  Widget _actionRow(String label, IconData icon, VoidCallback? onTap,
      {Color? color, required ThemeTokens t}) {
    final enabled = onTap != null;
    final c = (color ?? t.text1).withValues(alpha: enabled ? 1.0 : 0.4);
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
          Row(
            children: [
              Expanded(
                child: Text(
                  displayed,
                  style: AppTypography.mono(fontSize: 12, color: t.text3),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasKey)
                Text(
                  '${apiKey.length} симв.',
                  style: TextStyle(fontSize: 11, color: t.text4),
                ),
            ],
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
    _keyCtrl.text = current ?? '';
    final isDesktop =
        MediaQuery.sizeOf(ctx).width >= kDesktopBreakpoint;

    Future<void> save(BuildContext sheetCtx) async {
      await ref.read(groqApiKeyProvider.notifier).set(_keyCtrl.text);
      if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
    }

    Widget body(BuildContext sheetCtx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _keyCtrl,
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

  }

  // ── Groq ping ────────────────────────────────────────────────

  // Always ping with the smallest free-tier model to avoid 403 from
  // premium-only models.
  static const _pingModel = 'llama-3.1-8b-instant';

  Future<void> _pingGroq(String rawKey, String _model) async {
    // Strip surrounding quotes in case user pasted from .env ("gsk_...")
    var apiKey = rawKey.trim();
    if (apiKey.length >= 2 && apiKey.startsWith('"') && apiKey.endsWith('"')) {
      apiKey = apiKey.substring(1, apiKey.length - 1).trim();
    }

    setState(() => _pingLoading = true);
    try {
      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      );
      req.headers.set('authorization', 'Bearer $apiKey');
      req.headers.set('content-type', 'application/json');
      req.write(
        '{"model":"$_pingModel","messages":[{"role":"user","content":"hi"}],"max_tokens":1}',
      );
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      client.close();

      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ключ работает')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка ${res.statusCode}: $body'),
          duration: const Duration(seconds: 10),
        ));
      }
    } catch (e) {
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
          'Это действие удалит все записи веса, тренировки, задачи и заметки без возможности восстановления.',
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
    if (ok == true) {
      await ref.read(dbProvider).clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Все данные удалены')));
      }
    }
  }

  // ── Export ───────────────────────────────────────────────────

  Future<void> _exportJson() async {
    setState(() => _exportLoading = true);
    try {
      final data = await ref.read(dbProvider).exportAllData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      await _saveOrShare(
        bytes: utf8.encode(json),
        fileName: 'multi_tracker_${_dateStamp()}.json',
        mimeType: 'application/json',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _exportLoading = true);
    try {
      final data = await ref.read(dbProvider).exportAllData();
      final buf = StringBuffer();

      buf.writeln('# WEIGHT');
      buf.writeln('date,value,note');
      for (final w in data['weight'] as List) {
        buf.writeln('${w['date']},${w['value']},${_csv(w['note']?.toString() ?? '')}');
      }
      buf.writeln();

      buf.writeln('# TASKS');
      buf.writeln('body,group,priority,isDone,completedAt,createdAt');
      for (final t in data['tasks'] as List) {
        final m = t as Map;
        buf.writeln(
            '${_csv(m['body'].toString())},${m['group']},${m['priority']},${m['isDone']},${m['completedAt'] ?? ''},${m['createdAt']}');
      }
      buf.writeln();

      buf.writeln('# NOTES');
      buf.writeln('title,isPinned,createdAt,updatedAt,body');
      for (final n in data['notes'] as List) {
        final m = n as Map;
        buf.writeln(
            '${_csv(m['title'].toString())},${m['isPinned']},${m['createdAt']},${m['updatedAt']},${_csv(m['body'].toString())}');
      }
      buf.writeln();

      buf.writeln('# GOALS');
      buf.writeln('label,startValue,currentValue,targetValue,unit');
      for (final g in data['goals'] as List) {
        final m = g as Map;
        buf.writeln(
            '${_csv(m['label'].toString())},${m['startValue']},${m['currentValue']},${m['targetValue']},${m['unit']}');
      }
      buf.writeln();

      buf.writeln('# WORKOUTS');
      buf.writeln('template,exercise,date,setIndex,weightKg,reps');
      for (final w in data['workouts'] as List) {
        final wm = w as Map;
        for (final e in wm['exercises'] as List) {
          final em = e as Map;
          for (final s in em['sets'] as List) {
            final sm = s as Map;
            buf.writeln(
                '${_csv(wm['name'].toString())},${_csv(em['name'].toString())},${sm['date']},${sm['setIndex']},${sm['weightKg']},${sm['reps']}');
          }
        }
      }

      await _saveOrShare(
        bytes: utf8.encode(buf.toString()),
        fileName: 'multi_tracker_${_dateStamp()}.csv',
        mimeType: 'text/csv',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  Future<void> _saveOrShare({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (Platform.isWindows) {
      final dir =
          await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}\\$fileName');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Сохранено: ${file.path}'),
          duration: const Duration(seconds: 6),
        ));
      }
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: fileName,
      );
    }
  }

  static String _csv(String v) {
    if (v.contains(',') ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static String _dateStamp() {
    final n = DateTime.now();
    return '${n.year}${_p(n.month)}${_p(n.day)}_${_p(n.hour)}${_p(n.minute)}';
  }

  static String _p(int v) => v.toString().padLeft(2, '0');

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
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
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
            ),
          );
        }).toList(),
      ),
    );
  }
}

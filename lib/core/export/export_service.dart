import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ── JSON export ───────────────────────────────────────────────

  Future<void> exportJson() async {
    // TODO: query all tables via DAOs and serialise to JSON
    final data = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'weights': [], // TODO
      'workouts': [], // TODO
      'tasks': [], // TODO
      'notes': [], // TODO
    };

    await _saveAndShare(
      content: const JsonEncoder.withIndent('  ').convert(data),
      filename: 'multi_tracker_${_dateSuffix()}.json',
      mimeType: 'application/json',
    );
  }

  // ── CSV export ────────────────────────────────────────────────

  Future<void> exportWeightCsv() async {
    // TODO: query weight_entries and format as CSV
    const csv = 'date,weight_kg\n'; // TODO: real rows
    await _saveAndShare(
      content: csv,
      filename: 'weight_${_dateSuffix()}.csv',
      mimeType: 'text/csv',
    );
  }

  Future<void> exportSetsCsv() async {
    // TODO: query set_entries and format as CSV
    const csv = 'date,exercise,set,weight_kg,reps\n'; // TODO: real rows
    await _saveAndShare(
      content: csv,
      filename: 'workouts_${_dateSuffix()}.csv',
      mimeType: 'text/csv',
    );
  }

  // ── helpers ───────────────────────────────────────────────────

  Future<void> _saveAndShare({
    required String content,
    required String filename,
    required String mimeType,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      text: 'Multi-tracker export',
    );
  }

  String _dateSuffix() {
    final now = DateTime.now();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

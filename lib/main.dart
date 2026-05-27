import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/db/database.dart';
import 'core/notifications/notifications_service.dart';

/// Global database instance — passed to providers via ProviderScope override
late final AppDatabase database;

/// Outbound proxy detected once at startup. Null means DIRECT connection.
/// On iOS the OS-level VPN handles routing transparently — stays null there.
String? _detectedProxy;

Future<void> main() async {
  // 1. Detect proxy before any HTTP calls are made.
  _detectedProxy = await _detectProxy();

  // 2. Install HttpOverrides (reads _detectedProxy synchronously per-request).
  //    • Sets a recognisable User-Agent to avoid WAF 403s on some services.
  //    • Routes external traffic through the detected proxy.
  //    • Always bypasses the proxy for loopback/LAN (Flutter VM Service etc.).
  HttpOverrides.global = _HttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();

  // 3. Open database
  database = AppDatabase();

  // 4. Init notifications (no permission prompt yet — we ask later in Settings)
  await NotificationsService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(database),
      ],
      child: const MultiTrackerApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Proxy detection
// ─────────────────────────────────────────────────────────────────────────────

/// Detects the HTTP/HTTPS proxy to use for external connections.
///
/// Priority:
///   1. HTTPS_PROXY / HTTP_PROXY environment variables (set before `flutter run`)
///   2. Windows system proxy from the registry (Clash/V2Ray "System Proxy" mode)
///   3. null → DIRECT connection
Future<String?> _detectProxy() async {
  // 1. Explicit env vars always win (works on all platforms, dev shortcut)
  for (final key in ['HTTPS_PROXY', 'https_proxy', 'HTTP_PROXY', 'http_proxy']) {
    final v = Platform.environment[key];
    if (v != null && v.isNotEmpty) return v;
  }

  // 2. Windows: read the system proxy Clash/V2Ray writes to the registry.
  //    macOS/iOS/Android VPNs operate at the OS network level and need no
  //    dart:io proxy configuration.
  if (Platform.isWindows) {
    return _readWindowsSystemProxy();
  }

  return null;
}

/// Reads the WinINet system proxy from the Windows registry.
///
/// Clash in "System Proxy" mode sets:
///   HKCU\…\Internet Settings  ProxyEnable = 0x1
///   HKCU\…\Internet Settings  ProxyServer = "127.0.0.1:10809"
///                              or "http=host:port;https=host:port"
Future<String?> _readWindowsSystemProxy() async {
  try {
    final result = await Process.run(
      'reg',
      [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      ],
      runInShell: false,
    );
    if (result.exitCode != 0) return null;
    final output = result.stdout as String;

    // ProxyEnable must be 0x1
    final enableMatch =
        RegExp(r'ProxyEnable\s+REG_DWORD\s+0x(\w+)').firstMatch(output);
    if (enableMatch == null) return null;
    final enabled = int.tryParse(enableMatch.group(1)!, radix: 16) ?? 0;
    if (enabled == 0) return null;

    // ProxyServer value
    final serverMatch =
        RegExp(r'ProxyServer\s+REG_SZ\s+(\S+)').firstMatch(output);
    if (serverMatch == null) return null;

    var raw = serverMatch.group(1)!.trim();

    // Handle "http=host:port;https=host:port;ftp=host:port" notation:
    // prefer the https entry, fall back to http.
    final httpsEntry = RegExp(r'https=([^;]+)').firstMatch(raw);
    if (httpsEntry != null) {
      raw = httpsEntry.group(1)!;
    } else {
      final httpEntry = RegExp(r'http=([^;]+)').firstMatch(raw);
      if (httpEntry != null) raw = httpEntry.group(1)!;
    }

    // Ensure the string is a valid URL for Uri.tryParse
    if (!raw.startsWith('http')) raw = 'http://$raw';
    return raw;
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Global database provider — override in main() with the real instance
final dbProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Provide AppDatabase via main.dart override'),
);

// ─────────────────────────────────────────────────────────────────────────────
// HttpOverrides
// ─────────────────────────────────────────────────────────────────────────────

class _HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'MultiTracker/1.0'
      ..findProxy = _findProxy;
  }

  static String _findProxy(Uri url) {
    final h = url.host.toLowerCase();

    // ── Always bypass proxy for loopback / private LAN addresses ──────────
    // This covers Flutter's VM Service WebSocket (127.0.0.1:PORT) and avoids
    // the "Connection upgraded to websocket, HTTP 503" error when a proxy is
    // active during `flutter run`.
    if (h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '::1' ||
        h.endsWith('.local') ||
        h.startsWith('192.168.') ||
        h.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(h)) {
      return 'DIRECT';
    }

    // ── Route external traffic through the detected proxy ─────────────────
    if (_detectedProxy != null) {
      final uri = Uri.tryParse(_detectedProxy!);
      if (uri != null) return 'PROXY ${uri.host}:${uri.port}';
    }

    return 'DIRECT';
  }
}

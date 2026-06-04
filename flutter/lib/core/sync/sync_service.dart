import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers/providers.dart';
import '../../main.dart';
import '../db/database.dart';
import '../storage/secure_storage.dart';
import 'supabase_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Low-level service: push / pull a full snapshot to a single `app_state` row.
// Strategy: snapshot last-write-wins. The whole DB is stored as one JSON blob
// per user; whoever writes last wins.
// ─────────────────────────────────────────────────────────────────────────────

enum SyncOutcome { notSignedIn, pulled, pushedInitial, upToDate }

class SyncService {
  SyncService(this._db);
  final AppDatabase _db;

  static const _table = 'app_state';
  // Hard cap on every network round-trip so a slow/blocked connection (e.g.
  // behind a proxy) can't leave sync hanging on "Сохранение…" forever.
  static const Duration _netTimeout = Duration(seconds: 20);

  SupabaseClient get _sb => Supabase.instance.client;

  User? get currentUser => _sb.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<void> signIn(String email, String password) =>
      _sb.auth.signInWithPassword(email: email.trim(), password: password);

  Future<void> signUp(String email, String password) =>
      _sb.auth.signUp(email: email.trim(), password: password);

  /// Sign out AND erase all local data (DB + Groq key + sync marker), so the
  /// device is left clean for the next account.
  Future<void> signOut() async {
    await _sb.auth.signOut();
    await _db.wipeLocal();
    await SecureStorageService.instance.clearGroqApiKey();
    await SecureStorageService.instance.clearLastSyncTs();
  }

  /// `updated_at` of the remote snapshot, or null if none / signed out.
  Future<DateTime?> remoteUpdatedAt() async {
    final user = currentUser;
    if (user == null) return null;
    final row = await _sb
        .from(_table)
        .select('updated_at')
        .eq('user_id', user.id)
        .maybeSingle();
    final ts = row?['updated_at'];
    return ts is String ? DateTime.tryParse(ts) : null;
  }

  /// Pull the remote snapshot into the local DB. Returns true if applied.
  Future<bool> pull() async {
    final user = currentUser;
    if (user == null) return false;
    final row = await _sb
        .from(_table)
        .select('data, updated_at')
        .eq('user_id', user.id)
        .maybeSingle()
        .timeout(_netTimeout);
    if (row == null || row['data'] == null) return false;
    final data = (row['data'] as Map).cast<String, dynamic>();
    await _applyPulled(data, row['updated_at']);
    return true;
  }

  /// Imports a fetched snapshot [data] into the local DB and records its
  /// [tsRaw] as the last-sync timestamp.
  Future<void> _applyPulled(Map<String, dynamic> data, dynamic tsRaw) async {
    await _db.importSnapshot(data);
    // Restore secrets that live outside the DB (Groq API key).
    final secrets = (data['secrets'] as Map?)?.cast<String, dynamic>();
    final groq = secrets?['groqApiKey'];
    if (groq is String && groq.isNotEmpty) {
      await SecureStorageService.instance.setGroqApiKey(groq);
    }
    if (tsRaw is String) {
      final dt = DateTime.tryParse(tsRaw);
      if (dt != null) await SecureStorageService.instance.setLastSyncTs(dt);
    }
  }

  /// True if the snapshot [data] contains any real user data. Counts the data
  /// tables AND a non-default profile (name / height / target weight), since
  /// the profile is genuine user data even though its row always exists.
  static bool _snapshotHasData(Map<String, dynamic>? data) {
    final t = (data?['tables'] as Map?)?.cast<String, dynamic>();
    if (t == null) return false;
    const meaningful = [
      'weight_entries',
      'task_items',
      'note_items',
      'goals',
      'workout_templates',
      'exercise_templates',
      'set_entries',
    ];
    for (final k in meaningful) {
      if ((t[k] as List?)?.isNotEmpty ?? false) return true;
    }
    final profile = t['profile'] as List?;
    if (profile != null && profile.isNotEmpty) {
      final p = (profile.first as Map);
      final name = p['name'];
      if ((name is String && name.isNotEmpty && name != 'User') ||
          p['heightCm'] != null ||
          p['targetWeightKg'] != null ||
          p['birthDate'] != null) {
        return true;
      }
    }
    return false;
  }

  /// Push the local DB up as the snapshot. Returns the new `updated_at`.
  Future<DateTime> push() async {
    final user = currentUser;
    if (user == null) throw StateError('Not signed in');
    final snap = await _db.exportSnapshot();
    // Include secrets that live outside the DB (Groq API key).
    snap['secrets'] = {
      'groqApiKey': await SecureStorageService.instance.groqApiKey,
    };
    final now = DateTime.now().toUtc();
    await _sb.from(_table).upsert({
      'user_id': user.id,
      'data': snap,
      'updated_at': now.toIso8601String(),
      'device': _deviceLabel(),
    }).timeout(_netTimeout);
    await SecureStorageService.instance.setLastSyncTs(now);
    return now;
  }

  /// Startup / resume / login reconcile.
  ///
  /// Decision is TIMESTAMP-driven (LWW): pull when the cloud snapshot is newer
  /// than what this device last synced (or it has never synced). This covers
  /// profile/preferences changes too — not just the data tables.
  ///
  /// Safety guard: an EMPTY cloud snapshot must never overwrite a populated
  /// local DB. In that single case we push local up instead (recovering the
  /// cloud from whichever device still has data).
  Future<SyncOutcome> reconcile() async {
    final user = currentUser;
    if (user == null) return SyncOutcome.notSignedIn;

    final row = await _sb
        .from(_table)
        .select('data, updated_at')
        .eq('user_id', user.id)
        .maybeSingle()
        .timeout(_netTimeout);

    // No cloud snapshot yet → upload local as the initial one.
    if (row == null) {
      await push();
      return SyncOutcome.pushedInitial;
    }

    final remoteData = row['data'] is Map
        ? (row['data'] as Map).cast<String, dynamic>()
        : null;
    final remoteTs = row['updated_at'] is String
        ? DateTime.tryParse(row['updated_at'] as String)
        : null;
    final last = await SecureStorageService.instance.lastSyncTs;

    final remoteIsNewer =
        last == null || (remoteTs != null && remoteTs.isAfter(last));
    if (remoteIsNewer && remoteData != null) {
      // Guard: empty cloud must not wipe a populated device — push instead.
      if (!_snapshotHasData(remoteData) && await _db.hasUserData()) {
        await push();
        return SyncOutcome.pushedInitial;
      }
      await _applyPulled(remoteData, row['updated_at']);
      return SyncOutcome.pulled;
    }
    return SyncOutcome.upToDate;
  }

  /// Pushes local up — EXCEPT when that would replace a populated cloud
  /// snapshot with an empty local DB (guards against accidental wipes from a
  /// manual "sync now" on a device that has no data yet).
  Future<void> pushSafe() async {
    final user = currentUser;
    if (user == null) return;
    if (await _db.hasUserData()) {
      await push();
      return;
    }
    // Local is empty — only push if the cloud is also empty/absent.
    final row = await _sb
        .from(_table)
        .select('data')
        .eq('user_id', user.id)
        .maybeSingle()
        .timeout(_netTimeout);
    final remoteData = row?['data'] is Map
        ? (row!['data'] as Map).cast<String, dynamic>()
        : null;
    if (!_snapshotHasData(remoteData)) {
      await push();
    }
  }

  static String _deviceLabel() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod controller: manages auth/sync state, auto-pushes on local DB
// changes (debounced), and pulls on app resume.
// ─────────────────────────────────────────────────────────────────────────────

class SyncState {
  const SyncState({
    this.configured = false,
    this.signedIn = false,
    this.email,
    this.busy = false,
    this.lastSynced,
    this.error,
    this.status,
  });

  final bool configured;
  final bool signedIn;
  final String? email;
  final bool busy;
  final DateTime? lastSynced;
  final String? error;
  final String? status; // transient human-readable status

  SyncState copyWith({
    bool? configured,
    bool? signedIn,
    String? email,
    bool? busy,
    DateTime? lastSynced,
    String? error,
    String? status,
    bool clearError = false,
  }) =>
      SyncState(
        configured: configured ?? this.configured,
        signedIn: signedIn ?? this.signedIn,
        email: email ?? this.email,
        busy: busy ?? this.busy,
        lastSynced: lastSynced ?? this.lastSynced,
        error: clearError ? null : (error ?? this.error),
        status: status ?? this.status,
      );
}

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(database));

final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);

class SyncController extends Notifier<SyncState> with WidgetsBindingObserver {
  late final SyncService _svc;
  Timer? _debounce;
  StreamSubscription<dynamic>? _dbSub;
  StreamSubscription<AuthState>? _authSub;
  bool _applyingRemote = false;
  bool _inFlight = false; // a push/reconcile network op is currently running
  bool _dirty = false; // local has edits not yet pushed → a pull must not wipe
  // Auto-push is blocked until the first reconcile after sign-in completes.
  // Otherwise a debounced push scheduled while signed-out (e.g. from startup
  // DB seeding) could fire right after sign-in and overwrite the cloud with
  // empty local data before the initial pull runs.
  bool _initialSyncDone = false;

  @override
  SyncState build() {
    _svc = ref.read(syncServiceProvider);

    ref.onDispose(() {
      _debounce?.cancel();
      _dbSub?.cancel();
      _authSub?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });

    if (!SupabaseConfig.isConfigured) {
      return const SyncState(configured: false);
    }

    WidgetsBinding.instance.addObserver(this);

    // React to login / logout.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      final user = _svc.currentUser;
      state = state.copyWith(
        signedIn: user != null,
        email: user?.email,
        clearError: true,
      );
      if (user != null) {
        _reconcile();
      }
    });

    // Auto-push on any local DB change (debounced), unless we're applying a
    // pulled snapshot right now, or the first post-login reconcile hasn't run.
    // Mark the DB dirty so a pull can't wipe these unpushed local edits.
    _dbSub = database.tableUpdates().listen((_) {
      if (_applyingRemote || !_initialSyncDone) return;
      _dirty = true;
      _schedulePush();
    });

    final user = _svc.currentUser;
    // Kick off an initial reconcile after first frame if already signed in.
    if (user != null) {
      Future.microtask(_reconcile);
    }
    // Load persisted lastSynced for display.
    SecureStorageService.instance.lastSyncTs.then((ts) {
      if (ts != null) state = state.copyWith(lastSynced: ts);
    });

    return SyncState(
      configured: true,
      signedIn: user != null,
      email: user?.email,
    );
  }

  // ── Lifecycle: pull on resume ────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed && _svc.isSignedIn) {
      _reconcile();
    }
  }

  // ── Public actions ───────────────────────────────────────────────────────

  /// Returns true on success so the caller (dialog) can close immediately,
  /// without waiting for the async auth listener to update [SyncState].
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(busy: true, clearError: true, status: 'Вход…');
    try {
      await _svc.signIn(email, password);
      // auth listener will fire reconcile + flip signedIn.
      state = state.copyWith(
          busy: false, signedIn: true, email: email.trim(), status: null);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(busy: false, error: e.message, status: null);
      return false;
    } catch (e) {
      state = state.copyWith(busy: false, error: '$e', status: null);
      return false;
    }
  }

  /// Returns true if a session is active right after sign-up (email
  /// confirmation disabled). If confirmation is required, returns false and
  /// sets a status asking the user to confirm their email.
  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(busy: true, clearError: true, status: 'Регистрация…');
    try {
      await _svc.signUp(email, password);
      if (_svc.isSignedIn) {
        state = state.copyWith(
            busy: false, signedIn: true, email: email.trim(), status: null);
        return true;
      }
      // No session → email confirmation is on. Tell the user.
      state = state.copyWith(
          busy: false,
          status: null,
          error: 'Подтвердите email, затем войдите.');
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(busy: false, error: e.message, status: null);
      return false;
    } catch (e) {
      state = state.copyWith(busy: false, error: '$e', status: null);
      return false;
    }
  }

  Future<void> signOut() async {
    _debounce?.cancel();
    _initialSyncDone = false; // re-gate auto-push for the next sign-in
    _dirty = false;
    await _svc.signOut();
    // Groq key was wiped from secure storage — refresh its provider.
    ref.invalidate(groqApiKeyProvider);
    state = state.copyWith(
        signedIn: false, email: null, lastSynced: null, status: null);
  }

  /// Manual "sync now" — reconcile (pull if remote newer) then push local.
  Future<void> syncNow() async {
    if (!_svc.isSignedIn || _inFlight) return;
    _inFlight = true;
    state = state.copyWith(busy: true, clearError: true, status: 'Синхронизация…');
    try {
      if (_dirty) {
        // Unpushed local edits → push them (don't pull-wipe).
        await _svc.pushSafe();
        _dirty = false;
      } else {
        final outcome = await _applyRemote(() => _svc.reconcile());
        if (outcome == SyncOutcome.pulled) {
          ref.invalidate(groqApiKeyProvider);
        } else {
          await _svc.pushSafe();
        }
      }
      _initialSyncDone = true;
      final ts = await SecureStorageService.instance.lastSyncTs;
      state = state.copyWith(busy: false, lastSynced: ts, status: null);
    } catch (e) {
      state = state.copyWith(busy: false, error: _friendly(e), status: null);
    } finally {
      _inFlight = false;
    }
  }

  // ── Internals ────────────────────────────────────────────────────────────

  void _schedulePush() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), _doPush);
  }

  Future<void> _doPush() async {
    if (!_svc.isSignedIn || !_initialSyncDone) return;
    // Never overlap network ops — if one is in flight, retry shortly.
    if (_inFlight) {
      _schedulePush();
      return;
    }
    _inFlight = true;
    try {
      state = state.copyWith(busy: true, status: 'Сохранение…');
      final ts = await _svc.push();
      _dirty = false; // local is now safely in the cloud
      state = state.copyWith(busy: false, lastSynced: ts, status: null);
    } catch (e) {
      state = state.copyWith(busy: false, error: _friendly(e), status: null);
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _reconcile() async {
    if (_inFlight) return; // a sync is already running
    _inFlight = true;
    state = state.copyWith(busy: true, clearError: true, status: 'Синхронизация…');
    try {
      if (_dirty) {
        // We have unpushed local edits — push them up instead of pulling, so a
        // pull can't wipe them. (Auto-push handles the common case; this covers
        // resume/auth-triggered reconciles racing fresh edits.)
        await _svc.pushSafe();
        _dirty = false;
        _initialSyncDone = true;
      } else {
        final outcome = await _applyRemote(() => _svc.reconcile());
        // A pull may have restored the Groq key — refresh its provider.
        if (outcome == SyncOutcome.pulled) {
          ref.invalidate(groqApiKeyProvider);
        }
        _initialSyncDone = true;
      }
      final ts = await SecureStorageService.instance.lastSyncTs;
      state = state.copyWith(busy: false, lastSynced: ts, status: null);
    } catch (e) {
      // Even on error, unblock auto-push so future edits still sync.
      _initialSyncDone = true;
      state = state.copyWith(busy: false, error: _friendly(e), status: null);
    } finally {
      _inFlight = false;
    }
  }

  /// Human-friendly error text (raw TimeoutException/SocketException are scary).
  static String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('TimeoutException') || s.contains('SocketException') ||
        s.contains('Failed host lookup') || s.contains('Connection')) {
      return 'Нет соединения — синхронизирую позже';
    }
    return s;
  }

  /// Runs [op] with the "applying remote" guard set, so the resulting local
  /// table-update events don't trigger an echo push.
  Future<T> _applyRemote<T>(Future<T> Function() op) async {
    _applyingRemote = true;
    try {
      return await op();
    } finally {
      // Clear after a short delay — Drift fires table-update events slightly
      // after the write transaction commits.
      Future.delayed(const Duration(milliseconds: 600), () {
        _applyingRemote = false;
      });
    }
  }
}

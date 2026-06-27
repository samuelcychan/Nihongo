import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../data/results_repository.dart';

/// Drains the local outbox (PRD offline requirement) whenever connectivity is
/// restored: listens to connectivity changes and calls [ResultsSink.syncPending]
/// so results captured offline are pushed to Supabase as soon as the device is
/// back online — no user action required.
class ConnectivitySync {
  // Public named params map to private fields, so initializing formals don't apply.
  // ignore_for_file: prefer_initializing_formals
  ConnectivitySync({
    required ResultsSink results,
    required String Function() learnerId,
    Connectivity? connectivity,
  })  : _results = results,
        _learnerId = learnerId,
        _connectivity = connectivity ?? Connectivity();

  final ResultsSink _results;
  final String Function() _learnerId;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  void start() {
    _sub = _connectivity.onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online) return;
      try {
        final n = await _results.syncPending(_learnerId());
        if (n > 0) debugPrint('ConnectivitySync: pushed $n queued result(s).');
      } catch (e) {
        debugPrint('ConnectivitySync: sync failed, will retry: $e');
      }
    });
  }

  Future<void> dispose() async => _sub?.cancel();
}

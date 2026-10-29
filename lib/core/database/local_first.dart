import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../error/failures.dart';
import '../network/connectivity_service.dart';
import 'app_database.dart';
import 'synced_table.dart';

/// Data kept on the device first and exchanged with the server when the
/// app can reach it.
abstract interface class Syncable {
  /// Fires when the data on the device changed, so screens read it again.
  Stream<void> get changes;

  /// Sends what's waiting here and fetches what's new there. Never
  /// throws: offline, it just tries again next time.
  Future<void> sync();

  /// Asks screens to read again (e.g. someone else signed in).
  void reload();
}

/// The [Syncable] plumbing for a repository: the [changes] stream, [sync]
/// running one exchange at a time — a call during a run makes one more
/// run after it, since there may be something new to send — and helpers
/// for reading and writing the device's copy ([read], [write]) and
/// exchanging a [SyncedTable] with the server ([exchangeTable]).
mixin LocalFirst implements Syncable {
  final _changes = StreamController<void>.broadcast();
  Future<void>? _running;
  bool _again = false;

  /// One round with the server: what's waiting here goes up, then what's
  /// there comes down. Throws when it can't finish.
  @protected
  Future<void> exchange();

  /// Short name for logs.
  @protected
  String get label;

  /// Who's signed in: the device's copy is theirs only.
  @protected
  String? get userId;

  @override
  Stream<void> get changes => _changes.stream;

  @protected
  void changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  void reload() => changed();

  @override
  Future<void> sync() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _run();
  }

  Future<void> _run() async {
    final net = ConnectivityService.instance;
    try {
      do {
        _again = false;
        if (!net.hasNetwork) return;
        try {
          await exchange();
          net.reportSuccess();
        } catch (e) {
          if (ConnectivityService.isNetworkError(e)) {
            net.reportFailure();
            return;
          }
          debugPrint('[$label] sync failed: $e');
        }
      } while (_again);
    } finally {
      _running = null;
    }
  }

  /// Runs [body] for the signed-in user, as an [Either].
  @protected
  Future<Either<Failure, T>> read<T>(
      Future<T> Function(String userId) body) async {
    final user = userId;
    if (user == null) return const Left(AuthFailure('Not authenticated'));
    try {
      return Right(await body(user));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Like [read], for a change: once it's saved on the device the screens
  /// hear of it and it goes up (when it can).
  @protected
  Future<Either<Failure, T>> write<T>(
      Future<T> Function(String userId) body) async {
    final res = await read(body);
    if (res.isRight()) {
      changed();
      unawaited(sync());
    }
    return res;
  }

  /// Sends [table]'s rows changed here — [push] for new and changed ones,
  /// [delete] for deleted ones — then takes in [fetchAll], every row the
  /// server has. A row the server refuses stays owed; the rest still go.
  @protected
  Future<void> exchangeTable<T>(
    SyncedTable<T> table,
    String userId, {
    required Future<void> Function(LocalRow<T> row) push,
    required Future<void> Function(String id) delete,
    required Future<List<T>> Function() fetchAll,
  }) async {
    for (final row in await table.pending(userId)) {
      final id = table.idOf(row.item);
      try {
        if (row.sync == SyncState.delete) {
          await delete(id);
          await table.forget(id, row.rev);
        } else {
          await push(row);
          await table.settle(id, row.rev);
        }
      } catch (e) {
        if (ConnectivityService.isNetworkError(e)) rethrow;
        debugPrint('[$label] ${row.sync.name} $id failed: $e');
      }
    }
    if (await table.merge(userId, await fetchAll(), complete: true)) {
      changed();
    }
  }

  @mustCallSuper
  void dispose() => _changes.close();
}

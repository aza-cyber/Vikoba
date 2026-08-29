/// A tiny, ordered, versioned migration runner for PostgreSQL.
///
/// Each [Migration] has a monotonically increasing [version] and runs at most
/// once — applied versions are recorded in `schema_migrations`. Pending
/// migrations run in ascending order; transactional ones roll back (and stop
/// the boot) if they throw, so the database never ends up half-migrated.
///
/// `schema.sql` is the v1 baseline (how you bootstrap a fresh database). Every
/// schema change *after* that is a new migration here — this is the single
/// source of truth for post-baseline changes, so there's no drift.
library;

import 'package:postgres/postgres.dart';

typedef MigrationUp = Future<void> Function(Session db);

class Migration {
  final int version;
  final String name;

  /// The change to apply. Receives the session to run against — for a
  /// transactional migration this is the transaction, so use it (not a global
  /// connection) for every statement.
  final MigrationUp up;

  /// Whether to wrap [up] in a transaction. Default true. The v1 baseline runs
  /// non-transactionally because it is deliberately idempotent and uses
  /// catch-and-continue for constraints that existing data may violate — a
  /// pattern incompatible with a single aborting transaction.
  final bool transactional;

  const Migration(this.version, this.name, this.up, {this.transactional = true});
}

/// Applies every migration whose [Migration.version] hasn't been recorded yet,
/// in ascending version order, recording each as it succeeds. Idempotent across
/// boots: already-applied versions are skipped.
Future<void> runMigrations(
  Connection db,
  List<Migration> migrations, {
  void Function(String message)? log,
}) async {
  await db.execute('CREATE TABLE IF NOT EXISTS schema_migrations ('
      'version INT PRIMARY KEY, name TEXT NOT NULL, applied_at BIGINT NOT NULL)');
  final rows = await db.execute('SELECT version FROM schema_migrations');
  final applied = rows.map((r) => r[0] as int).toSet();

  final pending = migrations.where((m) => !applied.contains(m.version)).toList()
    ..sort((a, b) => a.version.compareTo(b.version));
  if (pending.isEmpty) {
    log?.call('Schema is up to date (no pending migrations).');
    return;
  }
  for (final m in pending) {
    if (m.transactional) {
      await db.runTx((tx) async {
        await m.up(tx);
        await _record(tx, m);
      });
    } else {
      await m.up(db);
      await _record(db, m);
    }
    log?.call('Applied migration ${m.version} (${m.name}).');
  }
}

Future<void> _record(Session db, Migration m) async {
  await db.execute(
    Sql.named('INSERT INTO schema_migrations (version, name, applied_at) '
        'VALUES (@v, @n, @a)'),
    parameters: {
      'v': m.version,
      'n': m.name,
      'a': DateTime.now().millisecondsSinceEpoch,
    },
  );
}

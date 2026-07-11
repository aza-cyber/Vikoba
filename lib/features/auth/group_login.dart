import '../../core/data/repository.dart';
import '../../core/db/app_database.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/state/groups_store.dart';

/// The outcome of an offline, group-aware login: the group-scoped [AppState]
/// (its session started and ledger loaded) plus the member's resolved [role].
class GroupSession {
  final AppState state;
  final MemberRole role;
  const GroupSession(this.state, this.role);
}

/// Offline multi-tenancy — routes a member into *their* group at login.
///
/// The app keeps each group's members/savings/loans in an isolated SQLite file
/// (`vikoba_grp_<id>`), plus a default `vikoba` database for the built-in demo
/// group. Since a member only knows their phone + PIN (not which file they live
/// in), this tries those credentials against the default database first and
/// then every registered group's database, returning the first that matches.
///
/// [defaultState] is the already-open app-level state (on the default `vikoba`
/// database); it is reused when the member lives there, so a second connection
/// to the same file is never opened. For every other group a temporary
/// connection is opened and — when it doesn't match — closed again immediately,
/// so only the matched group's database stays open for the session.
///
/// Returns null if no group recognises the credentials.
Future<GroupSession?> resolveGroupLogin({
  required AppState defaultState,
  required List<VikobaGroup> groups,
  required String phone,
  required String password,
}) async {
  // 1) The default / demo group — reuse the connection that's already open.
  final defRole = await defaultState.login(phone: phone, password: password);
  if (defRole != null) return GroupSession(defaultState, defRole);

  // 2) Each registered group, in its own database file. We deliberately build
  //    the AppState from an empty snapshot and let login() load the ledger —
  //    this avoids AppState.open()'s seedIfEmpty(), which would inject the demo
  //    data into an otherwise-empty group database.
  for (final g in groups) {
    if (!g.active) continue;
    final db = AppDatabase.named('vikoba_grp_${g.id}');
    final repo = DriftRepository(db);
    final state = AppState(Snapshot.empty(), repo: repo);
    final role = await state.login(phone: phone, password: password);
    if (role != null) return GroupSession(state, role);
    await db.close(); // no match here — release the connection
  }
  return null;
}

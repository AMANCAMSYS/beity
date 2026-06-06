import 'package:drift/drift.dart';
import '../app_database.dart';

class InvitationsDao {
  InvitationsDao(this.db);

  final AppDatabase db;

  Future<List<LocalInvitation>> getHomeInvitations(String homeId) async {
    return (db.select(db.localInvitations)
          ..where((tbl) => tbl.homeId.equals(homeId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Stream<List<LocalInvitation>> watchHomeInvitations(String homeId) {
    return (db.select(db.localInvitations)
          ..where((tbl) => tbl.homeId.equals(homeId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<List<LocalInvitation>> getUserInvitations(String email) async {
    return (db.select(db.localInvitations)
          ..where(
            (tbl) => tbl.email.equals(email) & tbl.status.equals('pending'),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Stream<List<LocalInvitation>> watchUserInvitations(String email) {
    return (db.select(db.localInvitations)
          ..where(
            (tbl) => tbl.email.equals(email) & tbl.status.equals('pending'),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<LocalInvitation?> getInvitationByToken(String token) async {
    return (db.select(
      db.localInvitations,
    )..where((tbl) => tbl.token.equals(token))).getSingleOrNull();
  }

  Future<LocalInvitation?> getInvitationById(String id) async {
    return (db.select(
      db.localInvitations,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertInvitations(List<LocalInvitation> invitations) async {
    if (invitations.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localInvitations,
        invitations
            .map(
              (inv) => LocalInvitationsCompanion.insert(
                id: inv.id,
                homeId: inv.homeId,
                userId: Value(inv.userId),
                email: Value(inv.email),
                phone: Value(inv.phone),
                role: Value(inv.role),
                token: inv.token,
                status: Value(inv.status),
                invitedBy: inv.invitedBy,
                expiresAt: Value(inv.expiresAt),
                acceptedAt: Value(inv.acceptedAt),
                createdAt: Value(inv.createdAt),
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> deleteByEmail(String email) async {
    if (email.isEmpty) return;
    await (db.delete(
      db.localInvitations,
    )..where((tbl) => tbl.email.equals(email))).go();
  }

  Future<void> updateStatus({
    required String invitationId,
    required String status,
    DateTime? acceptedAt,
  }) async {
    await (db.update(
      db.localInvitations,
    )..where((tbl) => tbl.id.equals(invitationId))).write(
      LocalInvitationsCompanion(
        status: Value(status),
        acceptedAt: Value(acceptedAt),
      ),
    );
  }

  Future<void> deleteByHomeId(String homeId) async {
    await (db.delete(
      db.localInvitations,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
  }

  Future<void> deleteAll() async {
    await db.delete(db.localInvitations).go();
  }
}

import 'package:drift/drift.dart';
import '../app_database.dart';

class NotificationsDao {
  NotificationsDao(this.db);

  final AppDatabase db;

  Future<List<LocalNotification>> getNotifications({
    required String userId,
    String? homeId,
    String? category,
    bool unreadOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = db.select(db.localNotifications)
      ..where(
        (tbl) =>
            tbl.userId.equals(userId) &
            (homeId == null
                ? const Constant(true)
                : tbl.homeId.equals(homeId)) &
            (category == null
                ? const Constant(true)
                : tbl.category.equals(category)) &
            (unreadOnly ? tbl.isRead.equals(false) : const Constant(true)),
      )
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Stream<List<LocalNotification>> watchNotifications({
    required String userId,
    String? homeId,
    bool unreadOnly = false,
    int limit = 50,
  }) {
    final query = db.select(db.localNotifications)
      ..where(
        (tbl) =>
            tbl.userId.equals(userId) &
            (homeId == null
                ? const Constant(true)
                : tbl.homeId.equals(homeId)) &
            (unreadOnly ? tbl.isRead.equals(false) : const Constant(true)),
      )
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return query.watch();
  }

  Future<int> getUnreadCount(String userId) async {
    final rows =
        await (db.select(db.localNotifications)..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isRead.equals(false),
            ))
            .get();
    return rows.length;
  }

  Stream<int> watchUnreadCount(String userId) {
    final query = db.select(db.localNotifications)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isRead.equals(false));
    return query.watch().map((rows) => rows.length);
  }

  Future<void> upsertNotifications(
    List<LocalNotification> notifications,
  ) async {
    if (notifications.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        db.localNotifications,
        notifications
            .map(
              (n) => LocalNotificationsCompanion.insert(
                id: n.id,
                userId: n.userId,
                homeId: n.homeId,
                title: n.title,
                body: n.body,
                type: n.type,
                category: n.category,
                actorId: Value(n.actorId),
                targetRoute: Value(n.targetRoute),
                referenceId: Value(n.referenceId),
                referenceType: Value(n.referenceType),
                isRead: Value(n.isRead),
                batchKey: Value(n.batchKey),
                createdAt: n.createdAt,
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    await (db.update(db.localNotifications)
          ..where((tbl) => tbl.id.isIn(notificationIds)))
        .write(const LocalNotificationsCompanion(isRead: Value(true)));
  }

  Future<void> markAllAsRead(String userId) async {
    await (db.update(
          db.localNotifications,
        )..where((tbl) => tbl.userId.equals(userId) & tbl.isRead.equals(false)))
        .write(const LocalNotificationsCompanion(isRead: Value(true)));
  }

  Future<void> deleteByHomeId(String homeId) async {
    await (db.delete(
      db.localNotifications,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
  }

  Future<void> deleteById(String notificationId) async {
    await (db.delete(
      db.localNotifications,
    )..where((tbl) => tbl.id.equals(notificationId))).go();
  }

  Future<void> deleteByUserId(String userId) async {
    await (db.delete(
      db.localNotifications,
    )..where((tbl) => tbl.userId.equals(userId))).go();
  }

  Future<void> deleteAll() async {
    await db.delete(db.localNotifications).go();
  }
}

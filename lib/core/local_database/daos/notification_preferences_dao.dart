import 'package:drift/drift.dart';
import '../app_database.dart';

class NotificationPreferencesDao {
  NotificationPreferencesDao(this.db);

  final AppDatabase db;

  Future<LocalNotificationPreference?> getPreference({
    required String userId,
    required String homeId,
  }) async {
    return (db.select(db.localNotificationPreferences)..where(
          (tbl) => tbl.userId.equals(userId) & tbl.homeId.equals(homeId),
        ))
        .getSingleOrNull();
  }

  Stream<LocalNotificationPreference?> watchPreference({
    required String userId,
    required String homeId,
  }) {
    return (db.select(db.localNotificationPreferences)..where(
          (tbl) => tbl.userId.equals(userId) & tbl.homeId.equals(homeId),
        ))
        .watchSingleOrNull();
  }

  Future<void> upsertPreference(LocalNotificationPreference pref) async {
    await db
        .into(db.localNotificationPreferences)
        .insertOnConflictUpdate(
          LocalNotificationPreferencesCompanion.insert(
            id: pref.id,
            userId: pref.userId,
            homeId: pref.homeId,
            itemAdded: Value(pref.itemAdded),
            itemCompleted: Value(pref.itemCompleted),
            lowStock: Value(pref.lowStock),
            expiryAlert: Value(pref.expiryAlert),
            expenseAdded: Value(pref.expenseAdded),
            taskAssigned: Value(pref.taskAssigned),
            taskDue: Value(pref.taskDue),
            createdAt: Value(pref.createdAt),
            updatedAt: Value(pref.updatedAt),
          ),
        );
  }

  Future<void> updateField({
    required String userId,
    required String homeId,
    required String field,
    required bool value,
  }) async {
    final companion = switch (field) {
      'item_added' => LocalNotificationPreferencesCompanion(
        itemAdded: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
      'item_completed' => LocalNotificationPreferencesCompanion(
        itemCompleted: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
      'low_stock' => LocalNotificationPreferencesCompanion(
        lowStock: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
      'expiry_alert' => LocalNotificationPreferencesCompanion(
        expiryAlert: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
      'expense_added' => LocalNotificationPreferencesCompanion(
        expenseAdded: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
      'task_assigned' => LocalNotificationPreferencesCompanion(
        taskAssigned: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
      'task_due' => LocalNotificationPreferencesCompanion(
        taskDue: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
      _ => throw ArgumentError('Invalid field: $field'),
    };

    await (db.update(db.localNotificationPreferences)..where(
          (tbl) => tbl.userId.equals(userId) & tbl.homeId.equals(homeId),
        ))
        .write(companion);
  }

  Future<void> deleteByHomeId(String homeId) async {
    await (db.delete(
      db.localNotificationPreferences,
    )..where((tbl) => tbl.homeId.equals(homeId))).go();
  }

  Future<void> deleteByUserId(String userId) async {
    await (db.delete(
      db.localNotificationPreferences,
    )..where((tbl) => tbl.userId.equals(userId))).go();
  }

  Future<void> deleteAll() async {
    await db.delete(db.localNotificationPreferences).go();
  }
}

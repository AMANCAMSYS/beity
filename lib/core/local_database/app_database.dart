import 'package:drift/drift.dart';

import 'database_connection.dart';

part 'app_database.g.dart';

const String localStateSynced = 'synced';
const String localStatePendingCreate = 'pending_create';
const String localStatePendingUpdate = 'pending_update';
const String localStatePendingDelete = 'pending_delete';
const String localStateSyncFailed = 'sync_failed';
const String localStateConflicted = 'conflicted';

const String mutationStatusPending = 'pending';
const String mutationStatusSyncing = 'syncing';
const String mutationStatusCompleted = 'completed';
const String mutationStatusFailed = 'failed';
const String mutationStatusCancelled = 'cancelled';

const String operationInsert = 'insert';
const String operationUpdate = 'update';
const String operationDelete = 'delete';
const String operationRestore = 'restore';
const String operationRpc = 'rpc';

class LocalUsers extends Table {
  @override
  String get tableName => 'local_users';

  TextColumn get id => text()();
  TextColumn get fullName => text().named('full_name')();
  TextColumn get email => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get avatarUrl => text().named('avatar_url').nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get dialect => text().nullable()();
  TextColumn get language => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  DateTimeColumn get lastSeenAt =>
      dateTime().named('last_seen_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalHomes extends Table {
  @override
  String get tableName => 'local_homes';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get ownerId => text().named('owner_id')();
  TextColumn get defaultCurrency =>
      text().named('default_currency').withDefault(const Constant('TRY'))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  IntColumn get memberCount => integer().named('member_count').nullable()();
  TextColumn get currentUserRole =>
      text().named('current_user_role').nullable()();
  DateTimeColumn get lastOpenedAt =>
      dateTime().named('last_opened_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalHomeMembers extends Table {
  @override
  String get tableName => 'local_home_members';

  TextColumn get id => text()();
  TextColumn get homeId => text().named('home_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get role => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get joinedAt => dateTime().named('joined_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  TextColumn get updatedBy => text().named('updated_by').nullable()();
  TextColumn get createdBy => text().named('created_by').nullable()();
  TextColumn get userName => text().named('user_name').nullable()();
  TextColumn get userEmail => text().named('user_email').nullable()();
  TextColumn get userAvatarUrl => text().named('user_avatar_url').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalShoppingLists extends Table {
  @override
  String get tableName => 'local_shopping_lists';

  TextColumn get id => text()();
  TextColumn get homeId => text().named('home_id')();
  TextColumn get title => text()();
  TextColumn get type => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get icon =>
      text().nullable().withDefault(const Constant('shopping_cart'))();
  TextColumn get createdBy => text().named('created_by')();
  TextColumn get updatedBy => text().named('updated_by').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  DateTimeColumn get inventoryTransferredAt =>
      dateTime().named('inventory_transferred_at').nullable()();
  TextColumn get localState => text()
      .named('local_state')
      .withDefault(const Constant(localStateSynced))();
  DateTimeColumn get localUpdatedAt =>
      dateTime().named('local_updated_at').withDefault(currentDateAndTime)();
  TextColumn get syncError => text().named('sync_error').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalShoppingItems extends Table {
  @override
  String get tableName => 'local_shopping_items';

  TextColumn get id => text()();
  TextColumn get listId => text().named('list_id')();
  TextColumn get homeId => text().named('home_id')();
  TextColumn get productId => text().named('product_id').nullable()();
  TextColumn get name => text()();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  RealColumn get purchasedQuantity =>
      real().named('purchased_quantity').withDefault(const Constant(0))();
  TextColumn get unitId => text().named('unit_id').nullable()();
  TextColumn get categoryId => text().named('category_id').nullable()();
  TextColumn get priority => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get assignedTo => text().named('assigned_to').nullable()();
  TextColumn get createdBy => text().named('created_by')();
  TextColumn get updatedBy => text().named('updated_by').nullable()();
  TextColumn get completedBy => text().named('completed_by').nullable()();
  DateTimeColumn get completedAt =>
      dateTime().named('completed_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  RealColumn get estimatedPrice => real().named('estimated_price').nullable()();
  TextColumn get currency => text().nullable()();
  TextColumn get localState => text()
      .named('local_state')
      .withDefault(const Constant(localStateSynced))();
  DateTimeColumn get localUpdatedAt =>
      dateTime().named('local_updated_at').withDefault(currentDateAndTime)();
  TextColumn get syncError => text().named('sync_error').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalItemTemplates extends Table {
  @override
  String get tableName => 'local_item_templates';

  TextColumn get id => text()();
  TextColumn get homeId => text().named('home_id')();
  TextColumn get name => text()();
  RealColumn get defaultQuantity =>
      real().named('default_quantity').withDefault(const Constant(1))();
  TextColumn get defaultUnitId => text().named('default_unit_id').nullable()();
  TextColumn get defaultCategoryId =>
      text().named('default_category_id').nullable()();
  IntColumn get usageCount =>
      integer().named('usage_count').withDefault(const Constant(0))();
  TextColumn get createdBy => text().named('created_by')();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalCategories extends Table {
  @override
  String get tableName => 'local_categories';

  TextColumn get id => text()();
  TextColumn get homeId => text().named('home_id').nullable()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();
  TextColumn get createdBy => text().named('created_by').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalUnits extends Table {
  @override
  String get tableName => 'local_units';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get symbol => text().nullable()();
  TextColumn get type => text().nullable()();
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalActivityLogs extends Table {
  @override
  String get tableName => 'local_activity_logs';

  TextColumn get id => text()();
  TextColumn get homeId => text().named('home_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get actorName => text().named('actor_name').nullable()();
  TextColumn get action => text()();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id').nullable()();
  TextColumn get entityDisplayName => text().named('entity_name').nullable()();
  TextColumn get metadataJson => text().named('metadata_json').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalShoppingModeSessions extends Table {
  @override
  String get tableName => 'local_shopping_mode_sessions';

  TextColumn get id => text()();
  TextColumn get shoppingListId => text().named('shopping_list_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get homeId => text().named('home_id')();
  DateTimeColumn get startedAt => dateTime().named('started_at')();
  DateTimeColumn get endedAt => dateTime().named('ended_at').nullable()();
  IntColumn get itemsPurchasedCount =>
      integer().named('items_purchased_count').withDefault(const Constant(0))();
  IntColumn get itemsTotalCount =>
      integer().named('items_total_count').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  TextColumn get localState => text()
      .named('local_state')
      .withDefault(const Constant(localStateSynced))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalSyncCursors extends Table {
  @override
  String get tableName => 'local_sync_cursors';

  TextColumn get homeId => text().named('home_id')();
  TextColumn get syncedTableName => text().named('table_name')();
  DateTimeColumn get lastServerUpdatedAt =>
      dateTime().named('last_server_updated_at').nullable()();
  BoolColumn get initialSyncDone =>
      boolean().named('initial_sync_done').withDefault(const Constant(false))();
  DateTimeColumn get lastAttemptAt =>
      dateTime().named('last_attempt_at').nullable()();
  DateTimeColumn get lastSuccessAt =>
      dateTime().named('last_success_at').nullable()();
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  Set<Column> get primaryKey => {homeId, syncedTableName};
}

class LocalPendingMutations extends Table {
  @override
  String get tableName => 'local_pending_mutations';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get idempotencyKey => text().named('idempotency_key').unique()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get homeId => text().named('home_id').nullable()();
  TextColumn get scope => text().withDefault(const Constant('home'))();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text().named('payload_json')();
  DateTimeColumn get baseUpdatedAt =>
      dateTime().named('base_updated_at').nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get nextRetryAt =>
      dateTime().named('next_retry_at').nullable()();
  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant(mutationStatusPending))();
  TextColumn get lastError => text().named('last_error').nullable()();
}

class LocalStoreMeta extends Table {
  @override
  String get tableName => 'local_store_meta';

  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get userId => text().named('user_id').nullable()();
  TextColumn get homeId => text().named('home_id').nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

class LocalNotifications extends Table {
  @override
  String get tableName => 'local_notifications';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get homeId => text().named('home_id')();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get type => text()();
  TextColumn get category => text()();
  TextColumn get actorId => text().named('actor_id').nullable()();
  TextColumn get targetRoute => text().named('target_route').nullable()();
  TextColumn get referenceId => text().named('reference_id').nullable()();
  TextColumn get referenceType => text().named('reference_type').nullable()();
  BoolColumn get isRead =>
      boolean().named('is_read').withDefault(const Constant(false))();
  TextColumn get batchKey => text().named('batch_key').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalNotificationPreferences extends Table {
  @override
  String get tableName => 'local_notification_preferences';

  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get homeId => text().named('home_id')();
  BoolColumn get itemAdded =>
      boolean().named('item_added').withDefault(const Constant(true))();
  BoolColumn get itemCompleted =>
      boolean().named('item_completed').withDefault(const Constant(true))();
  BoolColumn get lowStock =>
      boolean().named('low_stock').withDefault(const Constant(true))();
  BoolColumn get expiryAlert =>
      boolean().named('expiry_alert').withDefault(const Constant(true))();
  BoolColumn get expenseAdded =>
      boolean().named('expense_added').withDefault(const Constant(true))();
  BoolColumn get taskAssigned =>
      boolean().named('task_assigned').withDefault(const Constant(true))();
  BoolColumn get taskDue =>
      boolean().named('task_due').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalInvitations extends Table {
  @override
  String get tableName => 'local_invitations';

  TextColumn get id => text()();
  TextColumn get homeId => text().named('home_id')();
  TextColumn get userId => text().named('user_id').nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('member'))();
  TextColumn get token => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get invitedBy => text().named('invited_by')();
  DateTimeColumn get expiresAt => dateTime().named('expires_at').nullable()();
  DateTimeColumn get acceptedAt => dateTime().named('accepted_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LocalUsers,
    LocalHomes,
    LocalHomeMembers,
    LocalShoppingLists,
    LocalShoppingItems,
    LocalItemTemplates,
    LocalCategories,
    LocalUnits,
    LocalActivityLogs,
    LocalShoppingModeSessions,
    LocalSyncCursors,
    LocalPendingMutations,
    LocalStoreMeta,
    LocalNotifications,
    LocalNotificationPreferences,
    LocalInvitations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openDatabaseConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(localNotifications);
        await m.createTable(localNotificationPreferences);
        await m.createTable(localInvitations);
        await _createV2Indexes();
      }
      if (from < 3) {
        await m.addColumn(localPendingMutations, localPendingMutations.scope);
        await m.addColumn(localInvitations, localInvitations.userId);
        await _createV3Indexes();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<void> _createIndexes() async {
    for (final statement in _indexStatements) {
      await customStatement(statement);
    }
  }

  Future<void> _createV2Indexes() async {
    for (final statement in _v2IndexStatements) {
      await customStatement(statement);
    }
  }

  Future<void> _createV3Indexes() async {
    for (final statement in _v3IndexStatements) {
      await customStatement(statement);
    }
  }
}

const List<String> _indexStatements = [
  'CREATE INDEX IF NOT EXISTS idx_local_users_email ON local_users(email)',
  'CREATE INDEX IF NOT EXISTS idx_local_homes_owner ON local_homes(owner_id)',
  'CREATE INDEX IF NOT EXISTS idx_local_homes_deleted ON local_homes(deleted_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_homes_last_opened ON local_homes(last_opened_at)',
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_local_home_members_home_user ON local_home_members(home_id, user_id)',
  'CREATE INDEX IF NOT EXISTS idx_local_home_members_user_active ON local_home_members(user_id, status, deleted_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_home_members_home_active ON local_home_members(home_id, status, deleted_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_shopping_lists_home_status ON local_shopping_lists(home_id, status, deleted_at, updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_shopping_lists_home_deleted ON local_shopping_lists(home_id, deleted_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_shopping_lists_state ON local_shopping_lists(local_state)',
  'CREATE INDEX IF NOT EXISTS idx_local_shopping_items_home_list_status ON local_shopping_items(home_id, list_id, status, deleted_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_shopping_items_list_status_name ON local_shopping_items(list_id, status, name)',
  'CREATE INDEX IF NOT EXISTS idx_local_shopping_items_home_updated ON local_shopping_items(home_id, updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_shopping_items_category ON local_shopping_items(category_id)',
  'CREATE INDEX IF NOT EXISTS idx_local_shopping_items_unit ON local_shopping_items(unit_id)',
  'CREATE INDEX IF NOT EXISTS idx_local_shopping_items_state ON local_shopping_items(local_state)',
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_local_item_templates_home_name ON local_item_templates(home_id, name)',
  'CREATE INDEX IF NOT EXISTS idx_local_item_templates_usage ON local_item_templates(home_id, usage_count)',
  'CREATE INDEX IF NOT EXISTS idx_local_categories_home_type_sort ON local_categories(home_id, type, sort_order)',
  'CREATE INDEX IF NOT EXISTS idx_local_categories_default_type ON local_categories(is_default, type)',
  'CREATE INDEX IF NOT EXISTS idx_local_categories_home_updated ON local_categories(home_id, updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_units_type ON local_units(type)',
  'CREATE INDEX IF NOT EXISTS idx_local_units_default ON local_units(is_default)',
  'CREATE INDEX IF NOT EXISTS idx_local_activity_logs_home_created ON local_activity_logs(home_id, created_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_activity_logs_entity ON local_activity_logs(entity_type, entity_id, created_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_sessions_user_active ON local_shopping_mode_sessions(user_id, ended_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_sessions_home_started ON local_shopping_mode_sessions(home_id, started_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_sessions_list_started ON local_shopping_mode_sessions(shopping_list_id, started_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_sync_cursors_done ON local_sync_cursors(initial_sync_done)',
  'CREATE INDEX IF NOT EXISTS idx_local_pending_mutations_status_retry ON local_pending_mutations(status, next_retry_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_pending_mutations_home_status ON local_pending_mutations(home_id, status)',
  'CREATE INDEX IF NOT EXISTS idx_local_pending_mutations_entity ON local_pending_mutations(entity_type, entity_id)',
  'CREATE INDEX IF NOT EXISTS idx_local_store_meta_user ON local_store_meta(user_id)',
  'CREATE INDEX IF NOT EXISTS idx_local_store_meta_home ON local_store_meta(home_id)',
];

const List<String> _v2IndexStatements = [
  'CREATE INDEX IF NOT EXISTS idx_local_notifications_user_read_created ON local_notifications(user_id, is_read, created_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_notifications_home_created ON local_notifications(home_id, created_at)',
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_local_notif_prefs_user_home ON local_notification_preferences(user_id, home_id)',
  'CREATE INDEX IF NOT EXISTS idx_local_invitations_home_status ON local_invitations(home_id, status, created_at)',
  'CREATE INDEX IF NOT EXISTS idx_local_invitations_email_status ON local_invitations(email, status, expires_at)',
];

const List<String> _v3IndexStatements = [
  'CREATE INDEX IF NOT EXISTS idx_local_pending_mutations_scope ON local_pending_mutations(scope)',
  'CREATE INDEX IF NOT EXISTS idx_local_invitations_user_id ON local_invitations(user_id)',
];

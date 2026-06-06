enum ActionType {
  listCreated,
  listRenamed,
  listArchived,
  listDeleted,
  itemAdded,
  itemUpdated,
  itemPurchased,
  itemUnpurchased,
  itemDeleted,
  memberJoined,
  memberRemoved,
  memberRoleChanged,
  invitationAccepted,
  aiItemsAdded;

  String get translationKey {
    final snackCase = name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    return 'action_$snackCase';
  }

  String get value {
    switch (this) {
      case ActionType.listCreated:
        return 'list_created';
      case ActionType.listRenamed:
        return 'list_renamed';
      case ActionType.listArchived:
        return 'list_archived';
      case ActionType.listDeleted:
        return 'list_deleted';
      case ActionType.itemAdded:
        return 'item_added';
      case ActionType.itemUpdated:
        return 'item_updated';
      case ActionType.itemPurchased:
        return 'item_purchased';
      case ActionType.itemUnpurchased:
        return 'item_unpurchased';
      case ActionType.itemDeleted:
        return 'item_deleted';
      case ActionType.memberJoined:
        return 'member_joined';
      case ActionType.memberRemoved:
        return 'member_removed';
      case ActionType.memberRoleChanged:
        return 'member_role_changed';
      case ActionType.invitationAccepted:
        return 'invitation_accepted';
      case ActionType.aiItemsAdded:
        return 'ai_items_added';
    }
  }

  @Deprecated('Use LocalizedActionType.getLocalizedName(context) instead')
  String get displayName => translationKey;

  static ActionType fromString(String value) {
    switch (value) {
      case 'list_created':
        return ActionType.listCreated;
      case 'list_renamed':
        return ActionType.listRenamed;
      case 'list_archived':
        return ActionType.listArchived;
      case 'list_deleted':
        return ActionType.listDeleted;
      case 'item_added':
        return ActionType.itemAdded;
      case 'item_updated':
        return ActionType.itemUpdated;
      case 'item_purchased':
        return ActionType.itemPurchased;
      case 'item_unpurchased':
        return ActionType.itemUnpurchased;
      case 'item_deleted':
        return ActionType.itemDeleted;
      case 'member_joined':
        return ActionType.memberJoined;
      case 'member_removed':
        return ActionType.memberRemoved;
      case 'member_role_changed':
        return ActionType.memberRoleChanged;
      case 'invitation_accepted':
        return ActionType.invitationAccepted;
      case 'ai_items_added':
        return ActionType.aiItemsAdded;
      default:
        return ActionType.listCreated;
    }
  }
}

enum EntityType {
  shoppingList,
  shoppingItem,
  homeMember,
  invitation,
  task,
  expense,
  inventoryItem,
  category,
  unit,
  shoppingModeSession,
  notification,
  notificationPreference,
  home,
  unknown;

  String get translationKey {
    final snackCase = name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    return 'entity_type_$snackCase';
  }

  String get value {
    switch (this) {
      case EntityType.shoppingList:
        return 'shopping_list';
      case EntityType.shoppingItem:
        return 'shopping_item';
      case EntityType.homeMember:
        return 'home_member';
      case EntityType.invitation:
        return 'invitation';
      case EntityType.task:
        return 'task';
      case EntityType.expense:
        return 'expense';
      case EntityType.inventoryItem:
        return 'inventory_item';
      case EntityType.category:
        return 'category';
      case EntityType.unit:
        return 'unit';
      case EntityType.shoppingModeSession:
        return 'shopping_mode_session';
      case EntityType.notification:
        return 'notification';
      case EntityType.notificationPreference:
        return 'notification_preference';
      case EntityType.home:
        return 'home';
      case EntityType.unknown:
        return 'unknown';
    }
  }

  @Deprecated('Use LocalizedEntityType.getLocalizedName(context) instead')
  String get displayName => translationKey;

  static EntityType fromString(String value) {
    switch (value) {
      case 'shopping_list':
        return EntityType.shoppingList;
      case 'shopping_item':
        return EntityType.shoppingItem;
      case 'home_member':
        return EntityType.homeMember;
      case 'invitation':
        return EntityType.invitation;
      case 'task':
      case 'tasks':
        return EntityType.task;
      case 'expense':
      case 'expenses':
        return EntityType.expense;
      case 'inventory_item':
      case 'inventory_items':
        return EntityType.inventoryItem;
      case 'category':
      case 'categories':
        return EntityType.category;
      case 'unit':
      case 'units':
        return EntityType.unit;
      case 'shopping_mode_session':
      case 'shopping_mode_sessions':
        return EntityType.shoppingModeSession;
      case 'notification':
      case 'notifications':
        return EntityType.notification;
      case 'notification_preference':
      case 'notification_preferences':
        return EntityType.notificationPreference;
      case 'home':
      case 'homes':
        return EntityType.home;
      default:
        return EntityType.unknown;
    }
  }
}

class ActivityLog {
  final String id;
  final String homeId;
  final String userId;
  final String? actorName;
  final ActionType action;
  final EntityType entityType;
  final String? entityId;
  final String? entityName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.homeId,
    required this.userId,
    this.actorName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.entityName,
    this.metadata,
    required this.createdAt,
  });

  @Deprecated(
    'Use LocalizedActivityLog.getLocalizedDescription(context) instead',
  )
  String get actionDescription => action.translationKey;

  ActivityLog copyWith({
    String? id,
    String? homeId,
    String? userId,
    String? actorName,
    ActionType? action,
    EntityType? entityType,
    String? entityId,
    String? entityName,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      userId: userId ?? this.userId,
      actorName: actorName ?? this.actorName,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityName: entityName ?? this.entityName,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ActivityActor {
  final String userId;
  final String? displayName;

  const ActivityActor({required this.userId, this.displayName});
}

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

  String get displayName {
    switch (this) {
      case ActionType.listCreated:
        return 'إنشاء قائمة';
      case ActionType.listRenamed:
        return 'تعديل اسم القائمة';
      case ActionType.listArchived:
        return 'أرشفة قائمة';
      case ActionType.listDeleted:
        return 'حذف قائمة';
      case ActionType.itemAdded:
        return 'إضافة منتج';
      case ActionType.itemUpdated:
        return 'تعديل منتج';
      case ActionType.itemPurchased:
        return 'شراء منتج';
      case ActionType.itemUnpurchased:
        return 'إلغاء شراء';
      case ActionType.itemDeleted:
        return 'حذف منتج';
      case ActionType.memberJoined:
        return 'انضمام عضو';
      case ActionType.memberRemoved:
        return 'إزالة عضو';
      case ActionType.memberRoleChanged:
        return 'تغيير دور';
      case ActionType.invitationAccepted:
        return 'قبول دعوة';
      case ActionType.aiItemsAdded:
        return 'إضافة اقتراحات ذكية';
    }
  }

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
  invitation;

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
    }
  }

  String get displayName {
    switch (this) {
      case EntityType.shoppingList:
        return 'قائمة تسوق';
      case EntityType.shoppingItem:
        return 'منتج';
      case EntityType.homeMember:
        return 'عضو';
      case EntityType.invitation:
        return 'دعوة';
    }
  }

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
      default:
        return EntityType.shoppingList;
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

  String get actionDescription {
    switch (action) {
      case ActionType.listCreated:
        return 'أنشأ قائمة "$entityName"';
      case ActionType.listRenamed:
        final oldName = metadata?['old_name'] ?? '';
        final newName = metadata?['new_name'] ?? entityName;
        return 'غيّر اسم القائمة من "$oldName" إلى "$newName"';
      case ActionType.listArchived:
        return 'أرشف قائمة "$entityName"';
      case ActionType.listDeleted:
        return 'حذف قائمة "$entityName"';
      case ActionType.itemAdded:
        return 'أضاف "$entityName"';
      case ActionType.itemUpdated:
        return 'عدّل "$entityName"';
      case ActionType.itemPurchased:
        return 'اشترى "$entityName"';
      case ActionType.itemUnpurchased:
        return 'ألغى شراء "$entityName"';
      case ActionType.itemDeleted:
        return 'حذف "$entityName"';
      case ActionType.memberJoined:
        return 'انضم إلى المنزل';
      case ActionType.memberRemoved:
        return 'تمت إزالته من المنزل';
      case ActionType.memberRoleChanged:
        final oldRole = metadata?['old_role'] ?? '';
        final newRole = metadata?['new_role'] ?? '';
        return 'غيّر دوره من "$oldRole" إلى "$newRole"';
      case ActionType.invitationAccepted:
        return 'قبل الدعوة';
      case ActionType.aiItemsAdded:
        final count = metadata?['items_count'] ?? 0;
        return 'أضاف $count من الاقتراحات الذكية';
    }
  }

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

  const ActivityActor({
    required this.userId,
    this.displayName,
  });
}

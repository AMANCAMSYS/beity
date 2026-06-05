import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sawa/features/activity_logs/data/models/activity_log_model.dart';
import 'package:sawa/features/activity_logs/domain/entities/activity_log.dart';
import 'package:sawa/features/auth/data/models/user_model.dart';
import 'package:sawa/features/categories/data/models/category_model.dart';
import 'package:sawa/features/categories/data/models/unit_model.dart';
import 'package:sawa/features/categories/domain/entities/category.dart';
import 'package:sawa/features/categories/domain/entities/unit.dart';
import 'package:sawa/features/homes/data/models/home_member_model.dart';
import 'package:sawa/features/homes/data/models/home_model.dart';
import 'package:sawa/features/shopping_lists/data/models/item_template_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_item_model.dart';
import 'package:sawa/features/shopping_lists/data/models/shopping_list_model.dart';
import 'package:sawa/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:sawa/features/invitations/data/models/invitation_model.dart';
import 'package:sawa/features/invitations/domain/entities/invitation.dart';
import 'package:sawa/features/notifications/data/models/notification_model.dart';
import 'package:sawa/features/notifications/data/models/notification_preference_model.dart';
import 'package:sawa/features/notifications/domain/entities/notification.dart';
import 'package:sawa/features/notifications/domain/entities/notification_preference.dart';
import 'package:sawa/features/shopping_mode/data/models/shopping_mode_session_model.dart';

import 'app_database.dart';

extension UserModelLocalMapper on UserModel {
  LocalUsersCompanion toLocalCompanion({DateTime? lastSeenAt}) {
    return LocalUsersCompanion(
      id: Value(id),
      fullName: Value(fullName),
      email: Value(email),
      phone: Value(phone),
      avatarUrl: Value(avatarUrl),
      country: Value(country),
      dialect: Value(dialect),
      language: Value(language),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSeenAt: Value(lastSeenAt ?? DateTime.now()),
    );
  }
}

extension LocalUserModelMapper on LocalUser {
  UserModel toUserModel() {
    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      country: country,
      dialect: dialect,
      language: language,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updatedAt,
    );
  }
}

extension HomeModelLocalMapper on HomeModel {
  LocalHomesCompanion toLocalCompanion({
    String? currentUserRole,
    DateTime? lastOpenedAt,
  }) {
    return LocalHomesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      ownerId: Value(ownerId),
      defaultCurrency: Value(defaultCurrency ?? 'TRY'),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
      memberCount: Value(memberCount),
      currentUserRole: Value(currentUserRole),
      lastOpenedAt: Value(lastOpenedAt),
    );
  }
}

extension LocalHomeModelMapper on LocalHome {
  HomeModel toHomeModel() {
    return HomeModel(
      id: id,
      name: name,
      type: type,
      ownerId: ownerId,
      defaultCurrency: defaultCurrency,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      memberCount: memberCount,
    );
  }
}

extension HomeMemberModelLocalMapper on HomeMemberModel {
  LocalHomeMembersCompanion toLocalCompanion() {
    return LocalHomeMembersCompanion(
      id: Value(id),
      homeId: Value(homeId),
      userId: Value(userId),
      role: Value(role),
      status: Value(status),
      joinedAt: Value(joinedAt),
      deletedAt: Value(deletedAt),
      userName: Value(userName),
      userEmail: Value(userEmail),
    );
  }
}

extension LocalHomeMemberModelMapper on LocalHomeMember {
  HomeMemberModel toHomeMemberModel() {
    return HomeMemberModel(
      id: id,
      homeId: homeId,
      userId: userId,
      role: role,
      status: status,
      joinedAt: joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: deletedAt,
      userName: userName,
      userEmail: userEmail,
    );
  }
}

extension ShoppingListModelLocalMapper on ShoppingListModel {
  LocalShoppingListsCompanion toLocalCompanion({
    String localState = localStateSynced,
    DateTime? localUpdatedAt,
    String? syncError,
  }) {
    return LocalShoppingListsCompanion(
      id: Value(id),
      homeId: Value(homeId),
      title: Value(name),
      type: Value(description),
      status: Value(status.name),
      icon: Value(icon),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
      inventoryTransferredAt: Value(inventoryTransferredAt),
      localState: Value(localState),
      localUpdatedAt: Value(localUpdatedAt ?? DateTime.now()),
      syncError: Value(syncError),
    );
  }
}

extension LocalShoppingListModelMapper on LocalShoppingList {
  ShoppingListModel toShoppingListModel() {
    return ShoppingListModel(
      id: id,
      homeId: homeId,
      name: title,
      description: type,
      icon: icon ?? 'shopping_cart',
      createdBy: createdBy,
      status: _parseShoppingListStatus(status),
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      inventoryTransferredAt: inventoryTransferredAt,
    );
  }
}

extension ShoppingItemModelLocalMapper on ShoppingItemModel {
  LocalShoppingItemsCompanion toLocalCompanion({
    required String homeId,
    String localState = localStateSynced,
    DateTime? localUpdatedAt,
    String? syncError,
  }) {
    return LocalShoppingItemsCompanion(
      id: Value(id),
      listId: Value(shoppingListId),
      homeId: Value(homeId),
      name: Value(name),
      quantity: Value(quantity),
      purchasedQuantity: Value(purchasedQuantity),
      unitId: Value(unitId),
      categoryId: Value(categoryId),
      note: Value(notes),
      status: Value(isPurchased ? 'completed' : 'pending'),
      createdBy: Value(createdBy),
      completedBy: Value(purchasedBy),
      completedAt: Value(purchasedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
      estimatedPrice: Value(price),
      currency: Value(currency),
      localState: Value(localState),
      localUpdatedAt: Value(localUpdatedAt ?? DateTime.now()),
      syncError: Value(syncError),
    );
  }
}

extension LocalShoppingItemModelMapper on LocalShoppingItem {
  ShoppingItemModel toShoppingItemModel() {
    return ShoppingItemModel(
      id: id,
      shoppingListId: listId,
      name: name,
      quantity: quantity,
      purchasedQuantity: purchasedQuantity,
      unitId: unitId,
      categoryId: categoryId,
      price: estimatedPrice,
      currency: currency,
      notes: note,
      isPurchased: status == 'completed',
      purchasedBy: completedBy,
      purchasedAt: completedAt,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension ItemTemplateModelLocalMapper on ItemTemplateModel {
  LocalItemTemplatesCompanion toLocalCompanion() {
    return LocalItemTemplatesCompanion(
      id: Value(id),
      homeId: Value(homeId),
      name: Value(name),
      defaultQuantity: Value(defaultQuantity),
      defaultUnitId: Value(defaultUnitId),
      defaultCategoryId: Value(defaultCategoryId),
      usageCount: Value(usageCount),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

extension LocalItemTemplateModelMapper on LocalItemTemplate {
  ItemTemplateModel toItemTemplateModel() {
    return ItemTemplateModel(
      id: id,
      homeId: homeId,
      name: name,
      defaultQuantity: defaultQuantity,
      defaultUnitId: defaultUnitId,
      defaultCategoryId: defaultCategoryId,
      usageCount: usageCount,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension CategoryModelLocalMapper on CategoryModel {
  LocalCategoriesCompanion toLocalCompanion() {
    return LocalCategoriesCompanion(
      id: Value(id),
      homeId: Value(homeId),
      name: Value(name),
      type: Value(type.name),
      icon: Value(icon),
      color: Value(color),
      sortOrder: Value(sortOrder),
      isDefault: Value(isDefault),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
    );
  }
}

extension LocalCategoryModelMapper on LocalCategory {
  CategoryModel toCategoryModel() {
    return CategoryModel(
      id: id,
      homeId: homeId,
      name: name,
      type: _parseCategoryType(type),
      icon: icon,
      color: color,
      sortOrder: sortOrder,
      isDefault: isDefault,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension UnitModelLocalMapper on UnitModel {
  LocalUnitsCompanion toLocalCompanion() {
    return LocalUnitsCompanion(
      id: Value(id),
      name: Value(name),
      symbol: Value(symbol),
      type: Value(type.name),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
    );
  }
}

extension LocalUnitModelMapper on LocalUnit {
  UnitModel toUnitModel() {
    return UnitModel(
      id: id,
      name: name,
      symbol: symbol ?? '',
      type: _parseUnitType(type),
      isDefault: isDefault,
      createdAt: createdAt,
    );
  }
}

extension ActivityLogModelLocalMapper on ActivityLogModel {
  LocalActivityLogsCompanion toLocalCompanion() {
    return LocalActivityLogsCompanion(
      id: Value(id),
      homeId: Value(homeId),
      userId: Value(userId),
      actorName: Value(actorName),
      action: Value(action.value),
      entityType: Value(entityType.value),
      entityId: Value(entityId),
      entityDisplayName: Value(entityName),
      metadataJson: Value(metadata == null ? null : jsonEncode(metadata)),
      createdAt: Value(createdAt),
    );
  }
}

extension LocalActivityLogModelMapper on LocalActivityLog {
  ActivityLogModel toActivityLogModel() {
    return ActivityLogModel(
      id: id,
      homeId: homeId,
      userId: userId,
      actorName: actorName,
      action: ActionType.fromString(action),
      entityType: EntityType.fromString(entityType),
      entityId: entityId,
      entityName: entityDisplayName,
      metadata: metadataJson == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(metadataJson!) as Map),
      createdAt: createdAt,
    );
  }
}

extension ShoppingModeSessionModelLocalMapper on ShoppingModeSessionModel {
  LocalShoppingModeSessionsCompanion toLocalCompanion({
    String localState = localStateSynced,
  }) {
    return LocalShoppingModeSessionsCompanion(
      id: Value(id),
      shoppingListId: Value(shoppingListId),
      userId: Value(userId),
      homeId: Value(homeId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      itemsPurchasedCount: Value(itemsPurchasedCount),
      itemsTotalCount: Value(itemsTotalCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      localState: Value(localState),
    );
  }
}

extension LocalShoppingModeSessionModelMapper on LocalShoppingModeSession {
  ShoppingModeSessionModel toShoppingModeSessionModel() {
    return ShoppingModeSessionModel(
      id: id,
      shoppingListId: shoppingListId,
      userId: userId,
      homeId: homeId,
      startedAt: startedAt,
      endedAt: endedAt,
      itemsPurchasedCount: itemsPurchasedCount,
      itemsTotalCount: itemsTotalCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

ShoppingListStatus _parseShoppingListStatus(String value) {
  switch (value) {
    case 'completed':
      return ShoppingListStatus.completed;
    case 'archived':
      return ShoppingListStatus.archived;
    case 'cancelled':
      return ShoppingListStatus.cancelled;
    case 'active':
    default:
      return ShoppingListStatus.active;
  }
}

CategoryType _parseCategoryType(String value) {
  switch (value) {
    case 'inventory':
      return CategoryType.inventory;
    case 'expense':
      return CategoryType.expense;
    case 'shopping':
    default:
      return CategoryType.shopping;
  }
}

UnitType _parseUnitType(String? value) {
  switch (value) {
    case 'weight':
      return UnitType.weight;
    case 'volume':
      return UnitType.volume;
    case 'length':
      return UnitType.length;
    case 'count':
    default:
      return UnitType.count;
  }
}

// ---------------------------------------------------------------------------
// Notification mappers
// ---------------------------------------------------------------------------

extension NotificationModelLocalMapper on NotificationModel {
  LocalNotification toLocalRow() {
    return LocalNotification(
      id: id,
      userId: userId,
      homeId: homeId,
      title: title,
      body: body,
      type: type,
      category: category,
      actorId: actorId,
      targetRoute: targetRoute,
      referenceId: referenceId,
      referenceType: referenceType,
      isRead: isRead,
      batchKey: batchKey,
      createdAt: createdAt,
    );
  }
}

extension LocalNotificationMapper on LocalNotification {
  NotificationModel toNotificationModel() {
    return NotificationModel(
      id: id,
      userId: userId,
      homeId: homeId,
      title: title,
      body: body,
      type: type,
      category: category,
      actorId: actorId,
      targetRoute: targetRoute,
      referenceId: referenceId,
      referenceType: referenceType,
      isRead: isRead,
      batchKey: batchKey,
      createdAt: createdAt,
    );
  }

  AppNotification toAppNotification() {
    return AppNotification(
      id: id,
      userId: userId,
      homeId: homeId,
      category: category,
      type: type,
      title: title,
      body: body,
      actorId: actorId,
      targetRoute: targetRoute,
      referenceId: referenceId,
      referenceType: referenceType,
      isRead: isRead,
      batchKey: batchKey,
      createdAt: createdAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Preferences mappers
// ---------------------------------------------------------------------------

extension NotificationPreferencesModelLocalMapper
    on NotificationPreferencesModel {
  LocalNotificationPreference toLocalRow() {
    return LocalNotificationPreference(
      id: id,
      userId: userId,
      homeId: homeId,
      itemAdded: itemAdded,
      itemCompleted: itemCompleted,
      lowStock: lowStock,
      expiryAlert: expiryAlert,
      expenseAdded: expenseAdded,
      taskAssigned: taskAssigned,
      taskDue: taskDue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension LocalNotificationPreferenceMapper on LocalNotificationPreference {
  NotificationPreferencesModel toNotificationPreferencesModel() {
    return NotificationPreferencesModel(
      id: id,
      userId: userId,
      homeId: homeId,
      itemAdded: itemAdded,
      itemCompleted: itemCompleted,
      lowStock: lowStock,
      expiryAlert: expiryAlert,
      expenseAdded: expenseAdded,
      taskAssigned: taskAssigned,
      taskDue: taskDue,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  NotificationPreferences toNotificationPreferences() {
    return NotificationPreferences(
      id: id,
      userId: userId,
      homeId: homeId,
      itemAdded: itemAdded,
      itemCompleted: itemCompleted,
      lowStock: lowStock,
      expiryAlert: expiryAlert,
      expenseAdded: expenseAdded,
      taskAssigned: taskAssigned,
      taskDue: taskDue,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Invitation mappers
// ---------------------------------------------------------------------------

extension InvitationModelLocalMapper on InvitationModel {
  LocalInvitation toLocalRow({String? userId}) {
    return LocalInvitation(
      id: id,
      homeId: homeId,
      userId: userId,
      email: email,
      phone: phone,
      role: role,
      token: token,
      status: status.name,
      invitedBy: invitedBy,
      expiresAt: expiresAt,
      acceptedAt: acceptedAt,
      createdAt: createdAt,
    );
  }
}

extension LocalInvitationMapper on LocalInvitation {
  InvitationModel toInvitationModel() {
    return InvitationModel(
      id: id,
      homeId: homeId,
      email: email,
      phone: phone,
      role: role,
      token: token,
      status: _parseInvitationStatus(status),
      invitedBy: invitedBy,
      expiresAt: expiresAt,
      acceptedAt: acceptedAt,
      createdAt: createdAt,
    );
  }
}

InvitationStatus _parseInvitationStatus(String value) {
  switch (value) {
    case 'accepted':
      return InvitationStatus.accepted;
    case 'expired':
      return InvitationStatus.expired;
    case 'cancelled':
      return InvitationStatus.cancelled;
    case 'pending':
    default:
      return InvitationStatus.pending;
  }
}

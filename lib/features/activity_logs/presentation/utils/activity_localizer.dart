import 'package:flutter/material.dart';
import '../../domain/entities/activity_log.dart';
import 'package:beity/core/localization/app_localizations.dart';

extension LocalizedActionType on ActionType {
  String getLocalizedName(BuildContext context) {
    switch (this) {
      case ActionType.listCreated:
        return context.translate('action_list_created');
      case ActionType.listRenamed:
        return context.translate('action_list_renamed');
      case ActionType.listArchived:
        return context.translate('action_list_archived');
      case ActionType.listDeleted:
        return context.translate('action_list_deleted');
      case ActionType.itemAdded:
        return context.translate('action_item_added');
      case ActionType.itemUpdated:
        return context.translate('action_item_updated');
      case ActionType.itemPurchased:
        return context.translate('action_item_purchased');
      case ActionType.itemUnpurchased:
        return context.translate('action_item_unpurchased');
      case ActionType.itemDeleted:
        return context.translate('action_item_deleted');
      case ActionType.memberJoined:
        return context.translate('action_member_joined');
      case ActionType.memberRemoved:
        return context.translate('action_member_removed');
      case ActionType.memberRoleChanged:
        return context.translate('action_member_role_changed');
      case ActionType.invitationAccepted:
        return context.translate('action_invitation_accepted');
      case ActionType.aiItemsAdded:
        return context.translate('action_ai_items_added');
    }
  }
}

extension LocalizedEntityType on EntityType {
  String getLocalizedName(BuildContext context) {
    switch (this) {
      case EntityType.shoppingList:
        return context.translate('entity_shopping_list');
      case EntityType.shoppingItem:
        return context.translate('entity_shopping_item');
      case EntityType.homeMember:
        return context.translate('entity_home_member');
      case EntityType.invitation:
        return context.translate('entity_invitation');
    }
  }
}

extension LocalizedActivityLog on ActivityLog {
  String getLocalizedDescription(BuildContext context) {
    switch (action) {
      case ActionType.listCreated:
        return context.translate('desc_list_created', arguments: {'entityName': entityName ?? ''});
      case ActionType.listRenamed:
        final oldName = metadata?['old_name']?.toString() ?? '';
        final newName = metadata?['new_name']?.toString() ?? entityName ?? '';
        return context.translate('desc_list_renamed', arguments: {'oldName': oldName, 'newName': newName});
      case ActionType.listArchived:
        return context.translate('desc_list_archived', arguments: {'entityName': entityName ?? ''});
      case ActionType.listDeleted:
        return context.translate('desc_list_deleted', arguments: {'entityName': entityName ?? ''});
      case ActionType.itemAdded:
        return context.translate('desc_item_added', arguments: {'entityName': entityName ?? ''});
      case ActionType.itemUpdated:
        return context.translate('desc_item_updated', arguments: {'entityName': entityName ?? ''});
      case ActionType.itemPurchased:
        return context.translate('desc_item_purchased', arguments: {'entityName': entityName ?? ''});
      case ActionType.itemUnpurchased:
        return context.translate('desc_item_unpurchased', arguments: {'entityName': entityName ?? ''});
      case ActionType.itemDeleted:
        return context.translate('desc_item_deleted', arguments: {'entityName': entityName ?? ''});
      case ActionType.memberJoined:
        return context.translate('desc_member_joined');
      case ActionType.memberRemoved:
        return context.translate('desc_member_removed');
      case ActionType.memberRoleChanged:
        final oldRole = metadata?['old_role']?.toString() ?? '';
        final newRole = metadata?['new_role']?.toString() ?? '';
        return context.translate('desc_member_role_changed', arguments: {'oldRole': oldRole, 'newRole': newRole});
      case ActionType.invitationAccepted:
        return context.translate('desc_invitation_accepted');
      case ActionType.aiItemsAdded:
        final count = metadata?['items_count']?.toString() ?? '0';
        return context.translate('desc_ai_items_added', arguments: {'count': count});
    }
  }
}

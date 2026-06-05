import 'dart:convert';

import 'package:sawa/core/local_database/daos/homes_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/role_permission_model.dart';
import '../../../homes/data/models/home_member_model.dart';
import 'role_repository.dart';

class SupabaseRoleRepository implements RoleRepository {
  final SupabaseClient _client;
  final HomesDao _metaDao;

  SupabaseRoleRepository(this._client, {HomesDao? metaDao})
    : _metaDao = metaDao ?? HomesDao(LocalDatabaseService.instance);

  static const _rolePermissionsMetaKey = 'role_permissions:all';

  @override
  Future<HomeMemberModel> changeMemberRole({
    required String homeId,
    required String userId,
    required String newRole,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    // Check if current user is owner
    final currentMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (currentMembership == null || currentMembership['role'] != 'owner') {
      throw Exception('only_owner_can_change_roles');
    }

    // Check if target is owner (cannot demote owner)
    final targetMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', userId)
        .maybeSingle();

    if (targetMembership != null && targetMembership['role'] == 'owner') {
      throw Exception('cannot_change_owner_role');
    }

    // Update role
    final response = await _client
        .from('home_members')
        .update({
          'role': newRole,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': user.id,
        })
        .eq('home_id', homeId)
        .eq('user_id', userId)
        .select()
        .single();

    // Log activity
    await _client.from('activity_logs').insert({
      'home_id': homeId,
      'user_id': user.id,
      'action': 'role_changed',
      'entity_type': 'home_member',
      'entity_id': userId,
      'metadata': {'new_role': newRole},
    });

    return HomeMemberModel.fromJson(response);
  }

  @override
  Future<void> removeMember({
    required String homeId,
    required String userId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    // Check permissions
    final currentMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (currentMembership == null) {
      throw Exception('not_member_of_home');
    }

    final targetMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', userId)
        .maybeSingle();

    if (targetMembership == null) {
      throw Exception('member_not_found');
    }

    // Cannot remove owner
    if (targetMembership['role'] == 'owner') {
      throw Exception('cannot_remove_owner');
    }

    // Admin cannot remove admin
    if (currentMembership['role'] == 'admin' &&
        targetMembership['role'] == 'admin') {
      throw Exception('admin_cannot_remove_admin');
    }

    // Cannot remove self
    if (userId == user.id) {
      throw Exception('cannot_remove_self');
    }

    // Soft delete member
    await _client
        .from('home_members')
        .update({
          'status': 'inactive',
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': user.id,
        })
        .eq('home_id', homeId)
        .eq('user_id', userId);

    // Log activity
    await _client.from('activity_logs').insert({
      'home_id': homeId,
      'user_id': user.id,
      'action': 'member_removed',
      'entity_type': 'home_member',
      'entity_id': userId,
    });
  }

  @override
  Future<void> transferOwnership({
    required String homeId,
    required String newOwnerId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    // Check if current user is owner
    final currentMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (currentMembership == null || currentMembership['role'] != 'owner') {
      throw Exception('only_owner_can_transfer_ownership');
    }

    // Check if new owner is a member
    final newOwnerMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', newOwnerId)
        .maybeSingle();

    if (newOwnerMembership == null) {
      throw Exception('new_owner_must_be_member');
    }

    await _client.rpc(
      'transfer_home_ownership',
      params: {'p_home_id': homeId, 'p_new_owner_id': newOwnerId},
    );

    // Log activity
    await _client.from('activity_logs').insert({
      'home_id': homeId,
      'user_id': user.id,
      'action': 'ownership_transferred',
      'entity_type': 'home',
      'entity_id': homeId,
      'metadata': {'new_owner_id': newOwnerId},
    });
  }

  @override
  Future<List<HomeMemberModel>> getHomeMembers({required String homeId}) async {
    final response = await _client
        .from('home_members')
        .select('*, users:user_id(id, full_name, email, avatar_url)')
        .eq('home_id', homeId)
        .order('joined_at', ascending: true);

    return (response as List)
        .map((json) => HomeMemberModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<RolePermissionModel>> getRolePermissions({
    required String role,
  }) async {
    final cached = await _getCachedRolePermissions(role: role);
    if (cached.isNotEmpty) return cached;

    try {
      final response = await _client
          .from('role_permissions')
          .select()
          .eq('role', role);

      final permissions = (response as List)
          .map((json) => RolePermissionModel.fromJson(json))
          .toList();
      await _mergeCachedRolePermissions(permissions);
      return permissions;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<Map<String, List<RolePermissionModel>>> getAllRolePermissions() async {
    final cached = await _getCachedRolePermissions();
    if (cached.isNotEmpty) return _groupPermissionsByRole(cached);

    try {
      final response = await _client.from('role_permissions').select();

      final permissions = (response as List)
          .map((json) => RolePermissionModel.fromJson(json))
          .toList();
      await _saveRolePermissions(permissions);
      return _groupPermissionsByRole(permissions);
    } catch (_) {
      return _groupPermissionsByRole(cached);
    }
  }

  @override
  Future<bool> hasPermission({
    required String homeId,
    required String userId,
    required String permission,
  }) async {
    final membership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', userId)
        .maybeSingle();

    if (membership == null) return false;

    final role = membership['role'] as String;

    final cachedPermissions = await getRolePermissions(role: role);
    for (final cachedPermission in cachedPermissions) {
      if (cachedPermission.permission == permission) {
        return cachedPermission.allowed;
      }
    }

    return false;
  }

  @override
  Stream<List<HomeMemberModel>> watchHomeMembers({required String homeId}) {
    return _client
        .from('home_members')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('joined_at', ascending: true)
        .map(
          (response) =>
              response.map((json) => HomeMemberModel.fromJson(json)).toList(),
        );
  }

  Future<List<RolePermissionModel>> _getCachedRolePermissions({
    String? role,
  }) async {
    try {
      final raw = await _metaDao.getMeta(_rolePermissionsMetaKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final permissions = decoded
          .whereType<Map>()
          .map(
            (json) =>
                RolePermissionModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .where((permission) => role == null || permission.role == role)
          .toList();
      return permissions;
    } catch (_) {
      return [];
    }
  }

  Future<void> _mergeCachedRolePermissions(
    List<RolePermissionModel> permissions,
  ) async {
    if (permissions.isEmpty) return;
    final existing = await _getCachedRolePermissions();
    final merged = {
      for (final permission in existing) permission.id: permission,
      for (final permission in permissions) permission.id: permission,
    }.values.toList();
    await _saveRolePermissions(merged);
  }

  Future<void> _saveRolePermissions(
    List<RolePermissionModel> permissions,
  ) async {
    try {
      await _metaDao.setMeta(
        _rolePermissionsMetaKey,
        jsonEncode(
          permissions.map((permission) => permission.toJson()).toList(),
        ),
      );
    } catch (_) {}
  }

  Map<String, List<RolePermissionModel>> _groupPermissionsByRole(
    List<RolePermissionModel> permissions,
  ) {
    final grouped = <String, List<RolePermissionModel>>{};
    for (final permission in permissions) {
      grouped.putIfAbsent(permission.role, () => []).add(permission);
    }
    return grouped;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/role_permission_model.dart';
import '../../../homes/data/models/home_member_model.dart';
import 'role_repository.dart';

class SupabaseRoleRepository implements RoleRepository {
  final SupabaseClient _client;

  SupabaseRoleRepository(this._client);

  @override
  Future<HomeMemberModel> changeMemberRole({
    required String homeId,
    required String userId,
    required String newRole,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check if current user is owner
    final currentMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', user.id)
        .single();

    if (currentMembership == null || currentMembership['role'] != 'owner') {
      throw Exception('فقط المالك يمكنه تغيير الأدوار');
    }

    // Check if target is owner (cannot demote owner)
    final targetMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', userId)
        .single();

    if (targetMembership != null && targetMembership['role'] == 'owner') {
      throw Exception('لا يمكن تغيير دور المالك');
    }

    // Update role
    final response = await _client
        .from('home_members')
        .update({
          'role': newRole,
          'updated_at': DateTime.now().toIso8601String(),
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
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check permissions
    final currentMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', user.id)
        .single();

    if (currentMembership == null) {
      throw Exception('أنت لست عضواً في هذا المنزل');
    }

    final targetMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', userId)
        .single();

    if (targetMembership == null) {
      throw Exception('العضو غير موجود');
    }

    // Cannot remove owner
    if (targetMembership['role'] == 'owner') {
      throw Exception('لا يمكن إزالة المالك');
    }

    // Admin cannot remove admin
    if (currentMembership['role'] == 'admin' &&
        targetMembership['role'] == 'admin') {
      throw Exception('لا يمكن للمدير إزالة مدير آخر');
    }

    // Cannot remove self
    if (userId == user.id) {
      throw Exception('لا يمكن إزالة نفسك، يجب نقل الملكية أولاً');
    }

    // Remove member
    await _client
        .from('home_members')
        .delete()
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
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    // Check if current user is owner
    final currentMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', user.id)
        .single();

    if (currentMembership == null || currentMembership['role'] != 'owner') {
      throw Exception('فقط المالك يمكنه نقل الملكية');
    }

    // Check if new owner is a member
    final newOwnerMembership = await _client
        .from('home_members')
        .select('role')
        .eq('home_id', homeId)
        .eq('user_id', newOwnerId)
        .single();

    if (newOwnerMembership == null) {
      throw Exception('المالك الجديد يجب أن يكون عضواً في المنزل');
    }

    // Update current owner to admin
    await _client
        .from('home_members')
        .update({
          'role': 'admin',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('home_id', homeId)
        .eq('user_id', user.id);

    // Update new owner
    await _client
        .from('home_members')
        .update({
          'role': 'owner',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('home_id', homeId)
        .eq('user_id', newOwnerId);

    // Update home owner_id
    await _client.from('homes').update({
      'owner_id': newOwnerId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', homeId);

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
  Future<List<HomeMemberModel>> getHomeMembers(
      {required String homeId}) async {
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
  Future<List<RolePermissionModel>> getRolePermissions(
      {required String role}) async {
    final response = await _client
        .from('role_permissions')
        .select()
        .eq('role', role);

    return (response as List)
        .map((json) => RolePermissionModel.fromJson(json))
        .toList();
  }

  @override
  Future<Map<String, List<RolePermissionModel>>>
      getAllRolePermissions() async {
    final response = await _client.from('role_permissions').select();

    final Map<String, List<RolePermissionModel>> permissions = {};
    for (final json in response as List) {
      final perm = RolePermissionModel.fromJson(json);
      permissions.putIfAbsent(perm.role, () => []).add(perm);
    }

    return permissions;
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

    final perm = await _client
        .from('role_permissions')
        .select('allowed')
        .eq('role', role)
        .eq('permission', permission)
        .maybeSingle();

    return perm != null && perm['allowed'] == true;
  }

  @override
  Stream<List<HomeMemberModel>> watchHomeMembers({required String homeId}) {
    return _client
        .from('home_members')
        .stream(primaryKey: ['id'])
        .eq('home_id', homeId)
        .order('joined_at', ascending: true)
        .map((response) =>
            response.map((json) => HomeMemberModel.fromJson(json)).toList());
  }
}

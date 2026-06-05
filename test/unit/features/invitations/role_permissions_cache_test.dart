import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/core/local_database/daos/homes_dao.dart';
import 'package:sawa/features/invitations/data/models/role_permission_model.dart';
import 'package:sawa/features/invitations/data/repositories/supabase_role_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockHomesDao extends Mock implements HomesDao {}

void main() {
  group('SupabaseRoleRepository role permissions cache', () {
    test('getRolePermissions returns cached role permissions first', () async {
      final client = MockSupabaseClient();
      final metaDao = MockHomesDao();
      final repository = SupabaseRoleRepository(client, metaDao: metaDao);

      when(() => metaDao.getMeta('role_permissions:all')).thenAnswer(
        (_) async => jsonEncode([
          _permissionJson(id: 'admin_manage', role: 'admin', allowed: true),
          _permissionJson(id: 'member_manage', role: 'member', allowed: false),
        ]),
      );

      final permissions = await repository.getRolePermissions(role: 'admin');

      expect(permissions, hasLength(1));
      expect(permissions.single.role, 'admin');
      expect(permissions.single.permission, 'manage_members');
      expect(permissions.single.allowed, isTrue);
      verifyNever(() => client.from('role_permissions'));
    });

    test('getAllRolePermissions groups cached permissions by role', () async {
      final client = MockSupabaseClient();
      final metaDao = MockHomesDao();
      final repository = SupabaseRoleRepository(client, metaDao: metaDao);

      when(() => metaDao.getMeta('role_permissions:all')).thenAnswer(
        (_) async => jsonEncode([
          _permissionJson(id: 'owner_manage', role: 'owner', allowed: true),
          _permissionJson(id: 'admin_manage', role: 'admin', allowed: true),
        ]),
      );

      final grouped = await repository.getAllRolePermissions();

      expect(grouped.keys, containsAll(['owner', 'admin']));
      expect(grouped['owner'], hasLength(1));
      expect(grouped['admin'], hasLength(1));
      verifyNever(() => client.from('role_permissions'));
    });
  });
}

Map<String, dynamic> _permissionJson({
  required String id,
  required String role,
  required bool allowed,
}) {
  return RolePermissionModel(
    id: id,
    role: role,
    permission: 'manage_members',
    allowed: allowed,
    createdAt: DateTime.utc(2026, 6, 3),
  ).toJson();
}

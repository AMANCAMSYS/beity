import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const schemaPath = 'supabase/migrations/20260601182913_remote_schema.sql';
  const localFirstMigrationPath =
      'supabase/migrations/20260603015710_local_first_indexes_realtime_rls.sql';

  late String schemaSql;
  late String localFirstSql;

  setUpAll(() {
    schemaSql = File(schemaPath).readAsStringSync();
    localFirstSql = File(localFirstMigrationPath).readAsStringSync();
  });

  group('Phase 1 RLS repairs', () {
    test('keeps critical writes protected from viewers', () {
      for (final policy in [
        'Home members can create items (Viewer protected)',
        'Members can insert expenses (Viewer protected)',
        'Home members can create tasks (Viewer protected)',
        'Users can add inventory items (Viewer protected)',
      ]) {
        expect(
          schemaSql,
          matches(
            RegExp(
              'CREATE POLICY "${RegExp.escape(policy)}".*?'
              'is_not_viewer',
              dotAll: true,
            ),
          ),
        );
      }
    });

    test('keeps shopping list writes attributed to the caller', () {
      expect(
        schemaSql,
        matches(
          RegExp(
            'CREATE POLICY "Home members can create lists".*?'
            'created_by.*?auth.*?uid',
            dotAll: true,
          ),
        ),
      );
    });

    test('keeps local-first sync tables under RLS', () {
      for (final table in [
        'homes',
        'home_members',
        'shopping_lists',
        'shopping_items',
        'item_templates',
        'categories',
        'units',
        'activity_logs',
        'shopping_mode_sessions',
      ]) {
        expect(
          localFirstSql,
          contains('ALTER TABLE public.$table ENABLE ROW LEVEL SECURITY;'),
        );
      }
    });

    test('allows members to sync tombstone rows for local-first tables', () {
      for (final policy in [
        'Users can sync homes including deleted',
        'Users can sync members including deleted',
        'Users can sync lists including deleted',
        'Users can sync items including deleted',
        'Users can sync categories including deleted',
      ]) {
        expect(localFirstSql, contains('CREATE POLICY "$policy"'));
      }

      expect(localFirstSql, contains('hm.user_id = auth.uid()'));
    });
  });
}

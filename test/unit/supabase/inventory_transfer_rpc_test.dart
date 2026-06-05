import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260603000000_inventory_transferred_at.sql';
  const lintFixMigrationPath =
      'supabase/migrations/20260603020947_fix_inventory_transfer_lint.sql';

  late String sql;
  late String lintFixSql;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    lintFixSql = File(lintFixMigrationPath).readAsStringSync();
  });

  test('transfer RPC removes old overload and grants new signature', () {
    expect(
      sql,
      contains(
        'DROP FUNCTION IF EXISTS "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid")',
      ),
    );
    expect(
      sql,
      contains(
        'GRANT EXECUTE ON FUNCTION "public"."transfer_items_to_inventory"("p_items" "jsonb", "p_home_id" "uuid", "p_list_id" "uuid") TO "authenticated"',
      ),
    );
  });

  test('transfer RPC is list-scoped and idempotent', () {
    expect(sql, contains('AND status IN (\'active\', \'completed\')'));
    expect(sql, contains('AND inventory_transferred_at IS NULL'));
    expect(sql, contains('RETURNING id INTO v_list_id'));
    expect(sql, contains('RAISE EXCEPTION \'List is not transferable\''));
    expect(sql, contains('FROM public.shopping_items si'));
    expect(sql, contains('si.list_id = p_list_id'));
  });

  test('transfer RPC lint fix validates p_items while keeping list source', () {
    expect(lintFixSql, contains('jsonb_typeof(p_items)'));
    expect(lintFixSql, contains('Items payload must be an array'));
    expect(lintFixSql, contains('FROM public.shopping_items si'));
    expect(lintFixSql, contains('si.list_id = p_list_id'));
  });
}

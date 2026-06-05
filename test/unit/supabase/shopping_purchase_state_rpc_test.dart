import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath = 'supabase/migrations/20260601182913_remote_schema.sql';

  late String sql;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
  });

  test(
    'purchase state RPC updates quantity and completion fields atomically',
    () {
      expect(
        sql,
        contains(
          'CREATE OR REPLACE FUNCTION "public"."set_shopping_item_purchase_state"',
        ),
      );
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('Permission denied: not a home member'));
      expect(sql, contains('purchased_quantity = p_purchased_quantity'));
      expect(sql, contains("v_status := 'completed'"));
      expect(sql, contains("v_status := 'in_progress'"));
      expect(sql, contains("v_status := 'pending'"));
      expect(sql, contains('completed_at = v_completed_at'));
      expect(sql, contains('completed_by = v_completed_by'));
      expect(sql, contains('updated_by = auth.uid()'));
      expect(
        sql,
        contains(
          'GRANT ALL ON FUNCTION "public"."set_shopping_item_purchase_state"',
        ),
      );
    },
  );
}

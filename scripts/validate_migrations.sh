#!/bin/bash
# scripts/validate_migrations.sh
# Checks if Supabase migrations can be cleanly applied.

set -e

echo "🔍 Validating Supabase migrations..."

# Basic sanity checks for common mistakes
if grep -q "shopping_item_templates" supabase/migrations/*.sql; then
  echo "❌ ERROR: Found reference to 'shopping_item_templates'. The correct table name is 'item_templates'."
  exit 1
fi

echo "🚀 Running dry-run db reset on local Supabase container..."
# Try to reset the local database. If a migration is broken, this will fail.
if supabase db reset --local; then
  echo "✅ Migrations applied successfully without errors!"
else
  echo "❌ ERROR: Migration failed. Check the error output above."
  exit 1
fi

# OpenCode Prompt: SAWA Audit Remediation Plan & Implementation

You are working in `/home/omar/Desktop/Sawa` on the SAWA project.

Act as a senior Flutter, Riverpod, Supabase, PostgreSQL/RLS, and Edge Functions engineer. Your task is to turn the audit report into an implementation plan, then start implementing the highest-priority fixes safely.

## Must Read First

Read these files before making changes:

1. `AGENTS.md`
2. `system_audit_report.md`
3. `specs/016-ai-phase/plan.md`
4. Supabase migrations under `supabase/migrations/`
5. Relevant Flutter files under `lib/features/`
6. Edge Functions under `supabase/functions/`

Respect all project rules:

- Feature-first clean architecture.
- Do not bypass home membership checks.
- Every Supabase table must have RLS policies.
- Every write action must include `created_by` or `updated_by` where relevant.
- Arabic RTL support must remain intact.
- Do not introduce inventory/expenses/tasks/AI expansion beyond fixing existing broken/security-critical behavior.
- Prefer small, isolated changes.
- Add tests for repositories, use cases, and critical UI/security flows where feasible.

## Goal

Implement the findings from `system_audit_report.md` in a safe order.

First produce a short implementation plan, then begin implementation immediately starting with Critical issues.

## Priority Order

### Phase 1: Critical Security & Data Integrity Fixes

Implement these first:

1. Secure Edge Functions:
   - `supabase/functions/send-notification/index.ts`
   - `supabase/functions/generate-shopping-suggestions/index.ts`
   - Add JWT verification using Supabase Auth.
   - Add active home membership checks before any service-role read/write or external API call.
   - Return `401` for missing/invalid tokens.
   - Return `403` for non-members.
   - Do not trust client-provided user IDs.

2. Secure sensitive RPCs:
   - Fix `calculate_home_balances`.
   - Fix `has_unsettled_balances`.
   - Revoke execution from `anon`.
   - Grant only to `authenticated`.
   - Add `SET search_path = public, pg_temp`.
   - Add `auth.uid()` and active home membership checks.
   - Use schema-qualified table references.

3. Secure invitations:
   - Fix `accept_invitation`.
   - Add `SET search_path = public, pg_temp`.
   - Revoke from `anon`.
   - Grant only to `authenticated`.
   - Ensure invitation email matches authenticated user email.
   - Ensure invitation is pending and unexpired.
   - Prevent direct table update from being used to accept invitations.
   - Keep decline/cancel safe without allowing sensitive column mutation.

4. Fix sign-out local cleanup:
   - Capture current user ID before Supabase sign-out.
   - Clear offline queue and local home data for that captured user.
   - Do not clear only `anonymous` keys.
   - Make sign-out idempotent and safe if token removal fails.

5. Fix offline queue sync:
   - Use real table names: `shopping_items`, `shopping_lists`, etc.
   - Store and query queue entries by the real active `homeId`, not `listId` or `itemId`.
   - Use DB-compatible payload fields.
   - Make queued shopping item actions sync end-to-end.

### Phase 2: High-Priority App/DB Contract Fixes

After Phase 1, continue with:

1. Add `updated_by` to shopping list/item update/delete/mark-purchased writes.
2. Fix `shopping_lists` update bug where description is written to `type`.
3. Fix role/member repository schema mismatch with `home_members.updated_at`.
4. Change member removal to soft delete if that matches current DB triggers and policies.
5. Fix tasks completion to set `completed_by` and `completed_at`.
6. Align task RPC names between Flutter and migrations.
7. Fix notifications Edge Functions schema mismatch:
   - Replace `profiles` with `users`.
   - Align `notification_preferences` with actual columns.
8. Resolve units mismatch:
   - Either make units read-only in UI or add proper DB ownership/RLS.

### Phase 3: Realtime, Riverpod, and Performance

Then:

1. Convert realtime `StreamProvider.family` providers to `autoDispose` where appropriate.
2. Ensure Supabase channels/presence subscriptions are closed on dispose.
3. Invalidate home-scoped providers when active home changes.
4. Add important DB indexes from the report.
5. Add or update tests for security-critical flows.

## Required Workflow

1. Inspect current code and migrations before editing.
2. Produce an implementation plan with checkboxes.
3. Implement Phase 1 first.
4. Prefer migrations for DB/RLS changes instead of editing old migration history unless this repo convention requires otherwise.
5. Keep changes focused and small.
6. Do not remove unrelated user changes.
7. After each phase:
   - Run available tests/analyzer if tools exist.
   - If Flutter/Supabase CLI is unavailable, state that clearly.
   - Summarize changed files and remaining risks.

## Implementation Details To Use

### Edge Function Auth Helper Pattern

Use a helper similar to:

```ts
async function requireUser(req: Request, supabaseAdmin: SupabaseClient) {
  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '');

  if (!token) {
    return { response: new Response(JSON.stringify({ error: 'Missing authorization token' }), { status: 401 }) };
  }

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) {
    return { response: new Response(JSON.stringify({ error: 'Invalid authorization token' }), { status: 401 }) };
  }

  return { user: data.user };
}
```

And a membership helper similar to:

```ts
async function requireActiveHomeMember(
  supabaseAdmin: SupabaseClient,
  homeId: string,
  userId: string,
) {
  const { data, error } = await supabaseAdmin
    .from('home_members')
    .select('role')
    .eq('home_id', homeId)
    .eq('user_id', userId)
    .eq('status', 'active')
    .is('deleted_at', null)
    .maybeSingle();

  if (error || !data) {
    return new Response(JSON.stringify({ error: 'Access denied' }), { status: 403 });
  }

  return null;
}
```

Adapt this to existing Edge Function code style. Do not duplicate large helpers unnecessarily if a shared local helper pattern already exists.

### RPC Security Requirements

Every `SECURITY DEFINER` function touched must:

- Include `SET search_path = public, pg_temp`.
- Schema-qualify table references.
- Check `auth.uid()` unless it is strictly a trigger-only function.
- Check active membership for home-scoped data.
- Not be granted to `anon` unless intentionally public and safe.

### Offline Queue Requirements

Entity-to-table mapping must be explicit:

```dart
extension EntityTypeTable on EntityType {
  String get tableName => switch (this) {
        EntityType.shoppingItem => 'shopping_items',
        EntityType.shoppingList => 'shopping_lists',
        EntityType.home => 'homes',
        EntityType.invitation => 'invitations',
      };
}
```

Do not use `entry.entityType.name` as a table name.

Queued entries must be scoped by actual `homeId`.

### Sign-Out Requirement

Capture the user ID before signing out:

```dart
final userId = _repo.currentUser?.id;
```

Then clear user-scoped local data using that captured ID, not the current Supabase user after sign-out.

## Deliverables

When done with the first implementation pass, provide:

1. The plan you followed.
2. Files changed.
3. Migrations added.
4. Tests run and results.
5. Any remaining blockers.
6. Any manual Supabase deployment steps required.

Begin now.


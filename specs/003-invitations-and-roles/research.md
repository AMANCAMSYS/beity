# Research: Invitations and Roles

**Date**: 2026-05-12  
**Feature**: SPEC 03 - Invitations and Roles

## Research Tasks

### 1. Invitation Flow Architecture

**Decision**: Use Supabase PostgreSQL for invitation storage with RLS policies  
**Rationale**: 
- Consistent with existing Supabase infrastructure
- RLS ensures data isolation between homes
- Realtime subscriptions for live updates

**Alternatives considered**:
- Firebase Firestore: Rejected due to existing Supabase investment
- Custom backend: Rejected due to complexity

### 2. Role-Based Access Control (RBAC)

**Decision**: Implement customizable role permissions stored in database  
**Rationale**:
- Flexible for future requirements
- Can be managed without code changes
- Supports the clarification "customizable permissions per role"

**Alternatives considered**:
- Hardcoded permissions: Rejected due to lack of flexibility
- Firebase Custom Claims: Rejected due to Supabase architecture

### 3. Notification System

**Decision**: Use Firebase FCM for push notifications + Supabase Realtime for in-app  
**Rationale**:
- FCM already in tech stack (AGENTS.md)
- Supabase Realtime for real-time invitation updates
- Dual approach ensures delivery

**Alternatives considered**:
- Email only: Rejected per clarification (need push)
- OneSignal: Rejected due to existing FCM dependency

### 4. Invitation Expiry

**Decision**: Database cron job to auto-cancel expired invitations  
**Rationale**:
- Supabase pg_cron available
- Runs independently of app
- Can send notifications on expiry

**Alternatives considered**:
- Client-side check: Rejected due to reliability concerns
- Manual cleanup: Rejected due to poor UX

### 5. Ownership Transfer

**Decision**: Direct transfer via owner selection  
**Rationale**:
- Simplest user experience
- Aligns with clarification
- No voting complexity

**Alternatives considered**:
- Admin voting: Rejected per clarification
- Auto-transfer to oldest admin: Rejected per clarification

### 6. Duplicate Invitation Prevention

**Decision**: Database unique constraint on (home_id, invitee_email) for pending status  
**Rationale**:
- Database-level enforcement
- Prevents race conditions
- Clean error handling

**Alternatives considered**:
- Application-level check: Rejected due to race condition risk

## Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Storage | Supabase PostgreSQL | Existing infrastructure |
| Auth | Supabase RLS | Data isolation |
| Notifications | FCM + Realtime | Dual delivery |
| Expiry | pg_cron | Reliable automation |
| Transfer | Direct selection | Simple UX |
| Dedup | DB constraint | Race condition prevention |

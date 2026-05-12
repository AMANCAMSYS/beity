# Research: Categories and Units

**Date**: 2026-05-12  
**Feature**: SPEC 04 - Categories and Units

## Research Tasks

### 1. Bilingual Support Architecture

**Decision**: Use separate columns (name_ar, name_en) for bilingual support  
**Rationale**: 
- Simple to implement and query
- No JSON parsing overhead
- Clear fallback logic (display Arabic if English is empty)

**Alternatives considered**:
- JSON column with language keys: Rejected due to query complexity
- Separate translations table: Rejected due to over-engineering for 2 languages
- Single column with auto-detection: Rejected due to reliability concerns

### 2. Default vs Custom Categories/Units

**Decision**: Use `is_default` flag to distinguish default from custom  
**Rationale**:
- Clear separation of system vs user data
- Prevents accidental modification of defaults
- Allows filtering by default/custom status

**Alternatives considered**:
- Separate tables: Rejected due to duplication
- `home_id = null` for defaults: Rejected due to RLS complexity

### 3. Category/Unit Deletion Strategy

**Decision**: Set products to NULL (uncategorized/no unit) when category/unit is deleted  
**Rationale**:
- Preserves product data
- User can re-categorize later
- Simple implementation

**Alternatives considered**:
- Cascade delete: Rejected due to data loss
- Prevent deletion: Rejected due to poor UX
- Set to default category/unit: Rejected due to ambiguity

### 4. RLS Policy Design

**Decision**: Users can view all defaults + custom items for their homes  
**Rationale**:
- Defaults are global and read-only
- Custom items are home-scoped
- Follows existing RLS patterns

**Alternatives considered**:
- Home-only access: Rejected due to missing defaults
- Public read, home-scoped write: Considered but current approach is cleaner

### 5. Category Types

**Decision**: Support three category types: shopping, inventory, expense  
**Rationale**:
- Aligns with existing database schema
- Supports future features (inventory, expenses)
- Clear separation of concerns

**Alternatives considered**:
- Single type: Rejected due to future extensibility needs
- User-defined types: Rejected due to complexity

## Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Bilingual Support | Separate columns | Simple, clear fallback |
| Default vs Custom | is_default flag | Clear separation |
| Deletion Strategy | Set to NULL | Preserves data |
| RLS Design | Defaults + home-scoped | Follows patterns |
| Category Types | 3 types | Future extensibility |

# Local SQLite Schema

هذه الوثيقة تصف الجداول المحلية المطلوبة. يجب تنفيذها في Drift tables ثم توليد الكود بـ `build_runner`.

## Enums محلية

استخدم text columns لهذه القيم حتى تبقى متوافقة مع Supabase:

- `local_state`: `synced`, `pending_create`, `pending_update`, `pending_delete`, `sync_failed`, `conflicted`
- `mutation_status`: `pending`, `syncing`, `completed`, `failed`, `cancelled`
- `operation`: `insert`, `update`, `delete`, `restore`, `rpc`

## Core MVP Tables

### `local_users`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase user id |
| `full_name` | text | مطلوب |
| `email` | text | مطلوب |
| `phone` | text nullable |  |
| `avatar_url` | text nullable |  |
| `country` | text nullable |  |
| `dialect` | text nullable |  |
| `language` | text nullable |  |
| `created_at` | datetime nullable |  |
| `updated_at` | datetime nullable |  |
| `last_seen_at` | datetime nullable | محلي |

Indexes:

- primary key: `id`
- `email`

### `local_homes`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase home id |
| `name` | text | مطلوب |
| `type` | text | family, couple, shared_house... |
| `owner_id` | text | user id |
| `default_currency` | text | default TRY |
| `created_at` | datetime nullable |  |
| `updated_at` | datetime nullable |  |
| `deleted_at` | datetime nullable | soft delete |
| `member_count` | integer nullable | للعرض السريع |
| `current_user_role` | text nullable | owner/admin/member/viewer |
| `last_opened_at` | datetime nullable | محلي |

Indexes:

- primary key: `id`
- `owner_id`
- `deleted_at`
- `last_opened_at`

### `local_home_members`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase membership id |
| `home_id` | text | مطلوب |
| `user_id` | text | مطلوب |
| `role` | text | owner/admin/member/viewer |
| `status` | text | active/inactive/pending |
| `joined_at` | datetime nullable |  |
| `deleted_at` | datetime nullable |  |
| `updated_at` | datetime nullable |  |
| `updated_by` | text nullable |  |
| `created_by` | text nullable |  |
| `user_name` | text nullable | denormalized |
| `user_email` | text nullable | denormalized |
| `user_avatar_url` | text nullable | denormalized |

Indexes:

- primary key: `id`
- unique: `home_id`, `user_id`
- `user_id`, `status`, `deleted_at`
- `home_id`, `status`, `deleted_at`

### `local_shopping_lists`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase list id أو uuid محلي قبل الرفع |
| `home_id` | text | مطلوب |
| `title` | text | مطلوب |
| `type` | text nullable | grocery/pharmacy/hardware/other |
| `status` | text | active/completed/archived/cancelled |
| `icon` | text nullable | default shopping_cart |
| `created_by` | text | مطلوب |
| `updated_by` | text nullable |  |
| `created_at` | datetime nullable |  |
| `updated_at` | datetime nullable |  |
| `deleted_at` | datetime nullable | soft delete |
| `inventory_transferred_at` | datetime nullable | موجود في المشروع |
| `local_state` | text | default synced |
| `local_updated_at` | datetime | آخر تعديل محلي |
| `sync_error` | text nullable | آخر خطأ |

Indexes:

- primary key: `id`
- `home_id`, `status`, `deleted_at`, `updated_at`
- `home_id`, `deleted_at`
- `local_state`

### `local_shopping_items`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase item id أو uuid محلي |
| `list_id` | text | مطلوب |
| `home_id` | text | مطلوب لتسريع queries |
| `product_id` | text nullable |  |
| `name` | text | مطلوب |
| `quantity` | real | default 1 |
| `purchased_quantity` | real | default 0 |
| `unit_id` | text nullable |  |
| `category_id` | text nullable |  |
| `priority` | text nullable | low/medium/high/urgent |
| `note` | text nullable |  |
| `status` | text | pending/completed/cancelled/in_progress |
| `assigned_to` | text nullable |  |
| `created_by` | text | مطلوب |
| `updated_by` | text nullable |  |
| `completed_by` | text nullable |  |
| `completed_at` | datetime nullable |  |
| `created_at` | datetime nullable |  |
| `updated_at` | datetime nullable |  |
| `deleted_at` | datetime nullable | soft delete |
| `estimated_price` | real nullable |  |
| `currency` | text nullable |  |
| `local_state` | text | default synced |
| `local_updated_at` | datetime | آخر تعديل محلي |
| `sync_error` | text nullable | آخر خطأ |

Indexes:

- primary key: `id`
- `home_id`, `list_id`, `status`, `deleted_at`
- `list_id`, `status`, `name`
- `home_id`, `updated_at`
- `category_id`
- `unit_id`
- `local_state`

### `local_item_templates`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase id |
| `home_id` | text | مطلوب |
| `name` | text | مطلوب |
| `default_quantity` | real | default 1 |
| `default_unit_id` | text nullable |  |
| `default_category_id` | text nullable |  |
| `usage_count` | integer | default 0 |
| `created_by` | text | مطلوب |
| `created_at` | datetime nullable |  |
| `updated_at` | datetime nullable |  |

Indexes:

- primary key: `id`
- unique: `home_id`, `name`
- `home_id`, `usage_count`
- `home_id`, `name`

### `local_categories`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase id |
| `home_id` | text nullable | null للتصنيفات الافتراضية |
| `name` | text | مطلوب |
| `type` | text | shopping/inventory/expense |
| `icon` | text nullable |  |
| `color` | text nullable |  |
| `sort_order` | integer | default 0 |
| `is_default` | boolean | default false |
| `created_by` | text nullable |  |
| `created_at` | datetime nullable |  |
| `updated_at` | datetime nullable |  |
| `deleted_at` | datetime nullable |  |

Indexes:

- primary key: `id`
- `home_id`, `type`, `sort_order`
- `is_default`, `type`
- `home_id`, `updated_at`

### `local_units`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase id |
| `name` | text | مطلوب |
| `symbol` | text nullable |  |
| `type` | text nullable | weight/volume/count/length |
| `is_default` | boolean | default false |
| `created_at` | datetime nullable |  |

Indexes:

- primary key: `id`
- `type`
- `is_default`

### `local_activity_logs`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase id |
| `home_id` | text | مطلوب |
| `user_id` | text | actor id |
| `actor_name` | text nullable | denormalized |
| `action` | text | مطلوب |
| `entity_type` | text | مطلوب |
| `entity_id` | text nullable |  |
| `entity_name` | text nullable |  |
| `metadata_json` | text nullable | JSON string |
| `created_at` | datetime | مطلوب |

Indexes:

- primary key: `id`
- `home_id`, `created_at`
- `entity_type`, `entity_id`, `created_at`

### `local_shopping_mode_sessions`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | Supabase id أو uuid محلي |
| `shopping_list_id` | text | مطلوب |
| `user_id` | text | مطلوب |
| `home_id` | text | مطلوب |
| `started_at` | datetime | مطلوب |
| `ended_at` | datetime nullable | null للجلسة النشطة |
| `items_purchased_count` | integer | default 0 |
| `items_total_count` | integer | default 0 |
| `created_at` | datetime nullable |  |
| `updated_at` | datetime nullable |  |
| `local_state` | text | default synced |

Indexes:

- primary key: `id`
- `user_id`, `ended_at`
- `home_id`, `started_at`
- `shopping_list_id`, `started_at`

## Sync Infrastructure Tables

### `local_sync_cursors`

| العمود | النوع | ملاحظات |
|---|---|---|
| `home_id` | text | home أو global |
| `table_name` | text | اسم الجدول |
| `last_server_updated_at` | datetime nullable | آخر timestamp من السيرفر |
| `initial_sync_done` | boolean | default false |
| `last_attempt_at` | datetime nullable |  |
| `last_success_at` | datetime nullable |  |
| `last_error` | text nullable |  |

Indexes:

- primary key composite: `home_id`, `table_name`
- `initial_sync_done`

### `local_pending_mutations`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | integer | autoincrement |
| `idempotency_key` | text | uuid |
| `user_id` | text | مطلوب |
| `home_id` | text nullable | global لبعض العمليات |
| `entity_type` | text | shopping_item, shopping_list... |
| `entity_id` | text | مطلوب |
| `operation` | text | insert/update/delete/restore/rpc |
| `payload_json` | text | JSON string |
| `base_updated_at` | datetime nullable | للتعارضات |
| `created_at` | datetime | مطلوب |
| `next_retry_at` | datetime nullable | backoff |
| `retry_count` | integer | default 0 |
| `status` | text | pending/syncing/completed/failed/cancelled |
| `last_error` | text nullable |  |

Indexes:

- unique: `idempotency_key`
- `status`, `next_retry_at`
- `home_id`, `status`
- `entity_type`, `entity_id`

### `local_store_meta`

| العمود | النوع | ملاحظات |
|---|---|---|
| `key` | text | primary key |
| `value` | text | string/json |
| `user_id` | text nullable |  |
| `home_id` | text nullable |  |
| `updated_at` | datetime | مطلوب |

Indexes:

- primary key: `key`
- `user_id`
- `home_id`

## Phase 2 Tables

### `local_notifications`

أعمدة مطابقة للجدول السيرفري:

`id`, `user_id`, `home_id`, `title`, `body`, `type`, `entity_type`, `entity_id`, `is_read`, `created_at`, `category`, `actor_id`, `target_route`, `reference_id`, `reference_type`, `batch_key`.

Indexes:

- `user_id`, `is_read`, `created_at`
- `home_id`, `created_at`

### `local_notification_preferences`

`id`, `user_id`, `home_id`, `item_added`, `item_completed`, `low_stock`, `expiry_alert`, `expense_added`, `task_due`, `created_at`, `updated_at`.

Indexes:

- unique: `user_id`, `home_id`

### `local_invitations`

`id`, `home_id`, `email`, `phone`, `role`, `token`, `status`, `invited_by`, `expires_at`, `accepted_at`, `created_at`.

Indexes:

- `home_id`, `status`, `created_at`
- `email`, `status`, `expires_at`

### `local_tasks`

`id`, `home_id`, `title`, `description`, `due_date`, `category_id`, `assigned_to`, `status`, `recurrence_type`, `completed_by`, `completed_at`, `created_by`, `created_at`, `updated_at`, `deleted_at`, `archived_at`, `updated_by`, `local_state`, `local_updated_at`, `sync_error`.

Indexes:

- `home_id`, `deleted_at`, `archived_at`, `status`
- `assigned_to`, `status`
- `due_date`
- `local_state`

### `local_task_comments`

`id`, `task_id`, `content`, `created_by`, `created_at`, `local_state`, `sync_error`.

Indexes:

- `task_id`, `created_at`

## Phase 3 Tables

هذه الجداول لا تنفذ قبل استقرار MVP، لكنها يجب أن تتبع نفس النمط:

- `local_inventory_items`
- `local_inventory_transactions`
- `local_expenses`
- `local_expense_splits`
- `local_settlements`
- `local_products`

كل جدول منها يجب أن يحتوي أعمدة Supabase نفسها، إضافة إلى:

- `local_state`
- `local_updated_at`
- `sync_error`

## جداول لا تحفظ كاملة

| جدول Supabase | القرار المحلي |
|---|---|
| `device_tokens` | token الحالي فقط في meta إذا لزم |
| `rate_limit_log` | لا يحفظ محلياً |
| `sync_operations_log` | لا يحفظ محلياً؛ استخدم `local_pending_mutations` |
| `beta_feedback` | pending write-only فقط |
| `role_permissions` | cache محدود ونادر |
| AI suggestions | transient إلا إذا أضيف history |


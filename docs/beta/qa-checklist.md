# SAWA v0.2.0-preview QA Checklist

## Pre-Release Verification

### Build & Static Analysis
- [ ] `flutter analyze lib/` passes with 0 errors
- [ ] `flutter test` passes with all tests green (58 tests)
- [ ] App builds successfully for Android (debug)
- [ ] App builds successfully for iOS (debug)

### Auth & Session
- [ ] Fresh install shows login screen
- [ ] New user registration works
- [ ] Login with valid credentials succeeds
- [ ] Login with invalid credentials shows Arabic error message
- [ ] Logout clears all cached data
- [ ] Login with different account shows no previous user data
- [ ] Session persists across app restart
- [ ] Unauthenticated user is redirected to login from any route

### Home Management
- [ ] New user with no homes sees onboarding screen
- [ ] Create home with name and type works
- [ ] Home appears in home selector dropdown
- [ ] Switching homes updates all data (lists, items, activity)
- [ ] Homes list shows loading, empty, and error states
- [ ] Pull-to-refresh works on homes list

### Invitations & Members
- [ ] Send invitation to email works
- [ ] Invitation appears in recipient's invitations list
- [ ] Accept invitation adds user to home
- [ ] Decline invitation removes it from list
- [ ] Home members screen shows all active members
- [ ] Member roles (owner, admin, member) display correctly
- [ ] Empty state shows when no invitations exist
- [ ] Error state shows with retry on failure

### Shopping Lists
- [ ] Create shopping list with name works
- [ ] List appears in active lists tab
- [ ] List shows item count and progress
- [ ] Archive list moves it to archived tab
- [ ] Delete list with confirmation works
- [ ] Rename list works
- [ ] Empty state shows when no lists exist
- [ ] Loading spinner shows while fetching
- [ ] Error state with retry shows on failure

### Shopping Items
- [ ] Add item with name works
- [ ] Add item with quantity, unit, category, notes works
- [ ] Item appears in list immediately (optimistic UI)
- [ ] Mark item as purchased works
- [ ] Unmark item as purchased works
- [ ] Edit item details works
- [ ] Delete item with undo snackbar works
- [ ] Items grouped by category display correctly
- [ ] Search/filter items works
- [ ] Empty state shows when list is empty
- [ ] Soft-deleted items do not appear in active lists

### Shopping Mode
- [ ] Shopping mode opens from list detail
- [ ] Large touch targets for item toggling
- [ ] Progress bar updates on item toggle
- [ ] Connection status indicator shows

### Realtime Sync
- [ ] Changes from Device A appear on Device B within 2 seconds
- [ ] Presence indicators show who is viewing a list
- [ ] No duplicate items after realtime update
- [ ] Reconnection after network loss syncs correctly
- [ ] Subscriptions are cancelled on logout

### Offline Queue
- [ ] App shows offline status when disconnected
- [ ] Actions queued while offline
- [ ] Queue syncs automatically on reconnect
- [ ] Queue is user-scoped (no cross-user leakage)
- [ ] Pending count shows in UI
- [ ] Failed items show retry option
- [ ] Queue clears on logout

### Activity Logs
- [ ] Activity feed shows recent actions
- [ ] Activity detail shows full context
- [ ] Empty state shows when no activity
- [ ] List-specific activity filter works

### Notifications
- [ ] Notification center shows all notifications
- [ ] Unread count badge displays
- [ ] Mark all as read works
- [ ] Empty state shows when no notifications
- [ ] Error state with retry shows on failure
- [ ] Notification preferences toggle works

### Categories & Units
- [ ] Categories list shows all home categories
- [ ] Create category works
- [ ] Units list shows all units
- [ ] Create unit works
- [ ] Empty states show when no categories/units

### Profile
- [ ] Profile screen shows current user info
- [ ] Update profile name works
- [ ] Update profile phone works

### Navigation
- [ ] Bottom navigation switches tabs correctly
- [ ] Drawer menu navigates to all screens
- [ ] Back navigation works as expected
- [ ] Deep links from notifications work
- [ ] Logout redirects to login and clears stack
- [ ] "إدارة الأدوار" button in HomeMembersScreen works
- [ ] "دعوات هذا المنزل" button in HomeMembersScreen works
- [ ] Categories FAB navigates to create screen
- [ ] Units FAB navigates to create screen
- [ ] "إضافة سريعة" button in ShoppingListDetailScreen works
- [ ] Edit button in InventoryItemDetailScreen works
- [ ] "ملخص المصروفات" button in ExpenseListScreen works
- [ ] "الأرصدة" button in ExpenseListScreen works

### Inventory (enableInventory: true)
- [ ] Inventory screen accessible from Drawer
- [ ] Inventory screen shows items grouped by category
- [ ] Add inventory item FAB works
- [ ] Add inventory item form submits correctly
- [ ] Inventory item detail screen shows all info
- [ ] Edit button in inventory item detail navigates to edit screen
- [ ] Edit inventory item form submits correctly
- [ ] Delete inventory item with confirmation works
- [ ] Quantity adjuster (+/-) works
- [ ] Low stock badge displays correctly
- [ ] Empty state shows when no items

### Expenses (enableExpenses: true)
- [ ] Expenses screen accessible from Drawer with "تجريبي" badge
- [ ] Expense list shows all expenses
- [ ] FAB navigates to add expense screen
- [ ] Add expense form submits correctly
- [ ] Tapping expense navigates to detail screen
- [ ] Expense detail shows splits and delete option
- [ ] "ملخص المصروفات" button navigates to summary screen
- [ ] "الأرصدة" button navigates to balances screen
- [ ] Filter dialog works (date range)
- [ ] Empty state shows when no expenses

### Tasks (enableTasks: true)
- [ ] Tasks screen accessible from Drawer
- [ ] Task list shows tasks with tabs (مهامي / كل المهام)
- [ ] FAB navigates to add task screen
- [ ] Add task form submits correctly
- [ ] Tapping task navigates to detail screen
- [ ] Task detail shows edit and delete options
- [ ] Mark task as complete works
- [ ] Archived tasks screen accessible
- [ ] Empty state shows when no tasks

### Feature Flags
- [ ] enableInventory=false hides inventory from Drawer and Settings
- [ ] enableExpenses=false hides expenses from Drawer and Settings
- [ ] enableTasks=false hides tasks from Drawer and Settings
- [ ] AI shows as "قريبًا" (disabled) in Drawer

### Arabic & RTL
- [ ] All screens display Arabic text correctly
- [ ] RTL layout applied to forms and lists
- [ ] Mixed Arabic/English content renders correctly
- [ ] Date/time formatting in Arabic

## Device Matrix (Manual)
- [ ] Android physical device
- [ ] Android emulator
- [ ] iOS simulator (if available)
- [ ] RTL locale device

## Performance
- [ ] Home screen loads in < 2 seconds
- [ ] Shopping list loads in < 1 second
- [ ] Add item completes in < 500ms
- [ ] No visible jank during scrolling
- [ ] App doesn't crash on rapid navigation

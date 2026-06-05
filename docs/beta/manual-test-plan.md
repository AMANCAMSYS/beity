# SAWA v0.2.0-preview Manual Test Plan

## Environment Setup
- **Device A**: Primary test device (Android/iOS)
- **Device B**: Secondary device for realtime sync tests
- **Account 1**: testuser1@example.com / TestPass123!
- **Account 2**: testuser2@example.com / TestPass456!
- **Network**: Stable WiFi + ability to toggle airplane mode

---

## TC-01: Login / Logout with Different Accounts

### TC-01a: Fresh Login
1. Install app on clean device
2. Launch app
3. **Verify**: Login screen appears with email/password fields
4. Enter Account 1 credentials
5. Tap "تسجيل الدخول" (Login)
6. **Verify**: Redirected to home screen or onboarding

### TC-01b: Logout
1. Open drawer menu
2. Tap "تسجيل الخروج" (Logout)
3. **Verify**: Redirected to login screen
4. **Verify**: Login fields are empty

### TC-01c: Account Switching Data Isolation
1. Login as Account 1
2. Note the home name and shopping lists visible
3. Logout
4. Login as Account 2
5. **Verify**: Account 2's homes are shown (not Account 1's)
6. **Verify**: No shopping lists from Account 1 appear
7. **Verify**: Home selector shows Account 2's homes only

### TC-01d: Invalid Login
1. Enter wrong password
2. Tap login
3. **Verify**: Red snackbar with Arabic error message appears
4. **Verify**: Stays on login screen

---

## TC-02: Home Creation

### TC-02a: First Home (Onboarding)
1. Login with new account (no homes)
2. **Verify**: Onboarding screen appears with "مرحباً بك في سوا"
3. Tap "إنشاء منزل جديد" (Create new home)
4. Enter home name: "منزلي الأول"
5. Select home type: "family"
6. Tap create
7. **Verify**: Redirected to home dashboard
8. **Verify**: Home name appears in header dropdown

### TC-02b: Additional Home
1. Open drawer → "إدارة المنازل" (Manage homes)
2. Tap + FAB
3. Enter name: "بيت الصيف"
4. Create
5. **Verify**: New home appears in homes list
6. **Verify**: Can switch between homes via dropdown

---

## TC-03: Member Invitation

**Requires**: Two accounts, one home owned by Account 1

### TC-03a: Send Invitation
1. Login as Account 1
2. Navigate to drawer → "إدارة الأعضاء" (Manage members)
3. Tap invite button
4. Enter Account 2's email
5. Select role: "member"
6. Send invitation
7. **Verify**: Success message appears
8. **Verify**: Invitation appears in home's pending invitations

### TC-03b: Receive and Accept Invitation
1. Login as Account 2 (on Device B)
2. Navigate to "دعواتي" (My invitations)
3. **Verify**: Invitation from Account 1's home appears
4. Tap "قبول" (Accept)
5. **Verify**: Invitation disappears from pending
6. Navigate to home selector
7. **Verify**: Account 1's home now appears in Account 2's homes

### TC-03c: Decline Invitation
1. Send another invitation to Account 2
2. Account 2 opens invitations
3. Tap "رفض" (Decline)
4. **Verify**: Invitation removed
5. **Verify**: Home does NOT appear in Account 2's homes

---

## TC-04: Shopping List Creation

### TC-04a: Create List
1. From home dashboard, tap "قوائم المشتريات" tab
2. Tap + FAB
3. Enter list name: "بقالة الأسبوع"
4. Select icon (optional)
5. Create
6. **Verify**: List appears in active lists
7. **Verify**: List shows 0 items

### TC-04b: Empty State
1. Navigate to a home with no lists
2. **Verify**: Empty state shows "لا توجد قوائم"
3. **Verify**: "إنشاء قائمة" button is visible

### TC-04c: Archive and Delete
1. Long-press or swipe a list
2. Select "أرشفة" (Archive)
3. **Verify**: List moves to archived tab
4. Switch to archived tab
5. **Verify**: List appears there
6. Delete the list
7. Confirm deletion
8. **Verify**: List removed from archived tab

---

## TC-05: Shopping Item Add / Edit / Complete / Delete

**Requires**: At least one shopping list

### TC-05a: Add Item
1. Open a shopping list
2. Tap + FAB "إضافة منتج"
3. Enter name: "حليب"
4. Set quantity: 2
5. Select unit: "لتر" (optional)
6. Select category: "ألبان" (optional)
7. Add notes: "بدون دسم" (optional)
8. Save
9. **Verify**: Item appears in list under correct category
10. **Verify**: Item shows quantity and unit

### TC-05b: Edit Item
1. Tap on item "حليب"
2. Change quantity to 3
3. Change notes to "قليل الدسم"
4. Save
5. **Verify**: Item shows updated quantity and notes

### TC-05c: Mark as Purchased
1. Tap checkbox on "حليب"
2. **Verify**: Item moves to "purchased" section
3. **Verify**: Item shows strikethrough or different styling
4. **Verify**: Progress bar updates

### TC-05d: Unmark as Purchased
1. Tap checkbox again on purchased item
2. **Verify**: Item moves back to unpurchased section

### TC-05e: Delete Item with Undo
1. Swipe item or tap delete
2. **Verify**: Snackbar appears with "تم حذف" + undo button
3. Wait 5 seconds
4. **Verify**: Item is permanently removed
5. Repeat delete, tap "تراجع" (Undo) within 5 seconds
6. **Verify**: Item reappears in list

### TC-05f: Search and Filter
1. Add multiple items to list
2. Tap search icon
3. Type partial item name
4. **Verify**: Only matching items shown
5. Clear search
6. Tap category filter chip
7. **Verify**: Only items in that category shown

---

## TC-06: Realtime Sync Between Two Devices

**Requires**: Two devices, same home, both users are members

### TC-06a: Item Addition Sync
1. Device A: Open shopping list "بقالة الأسبوع"
2. Device B: Open same shopping list
3. Device A: Add item "خبز"
4. Device B: **Verify** "خبz" appears within 2 seconds without manual refresh

### TC-06b: Item Toggle Sync
1. Device A: Mark "خبز" as purchased
2. Device B: **Verify** "خبز" moves to purchased section
3. Device B: Unmark "خبز"
4. Device A: **Verify** "خبز" moves back to unpurchased

### TC-06c: Presence Indicators
1. Both devices open same list
2. **Verify**: Both devices show presence indicator (avatar/initials)
3. Close list on Device A
4. Device B: **Verify** presence indicator for Device A disappears

### TC-06d: Reconnection After Network Loss
1. Device A: Enable airplane mode
2. Device A: Add item "ماء"
3. Device A: Disable airplane mode
4. Device B: **Verify** "ماء" appears after reconnection

---

## TC-07: Offline Queue Sync

### TC-07a: Queue While Offline
1. Enable airplane mode
2. Open shopping list
3. Add item "تفاح"
4. **Verify**: Item appears in UI (optimistic)
5. **Verify**: Offline indicator shows
6. **Verify**: Pending sync count shows

### TC-07b: Sync on Reconnect
1. Disable airplane mode
2. **Verify**: Pending items sync automatically
3. **Verify**: Offline indicator disappears
4. Open same list on Device B
5. **Verify**: "تفاح" appears

### TC-07c: User Isolation
1. Login as Account 1, go offline, add items
2. Logout while still offline
3. Login as Account 2
4. **Verify**: No queued items from Account 1 visible
5. Go online as Account 2
6. **Verify**: Account 1's items do NOT sync under Account 2

---

## TC-08: Notification Basic Flow

### TC-08a: Notification on Item Change
1. Account 1 and Account 2 share a home
2. Account 1 adds item to shared list
3. Account 2: **Verify** notification appears (may take up to 30 seconds)
4. Account 2: Open notification center
5. **Verify** notification shows correct item name and list

### TC-08b: Mark as Read
1. Open notification center with unread notifications
2. Tap a notification
3. **Verify**: Notification marked as read (no longer bold/highlighted)
4. Tap "Mark all read"
5. **Verify**: All notifications marked as read
6. **Verify**: Badge count resets to 0

### TC-08c: Empty State
1. Open notification center with no notifications
2. **Verify**: Empty state shows "No notifications yet"

---

## TC-09: Account Switching Data Isolation (Full Flow)

### TC-09a: Complete Isolation Test
1. Login as Account 1
2. Create home "منزل أ"
3. Create list "قائمة أ" with items "تفاح، موز"
4. Note the data visible
5. Logout
6. Login as Account 2
7. Create home "منزل ب"
8. Create list "قائمة ب" with items "خبز، حليب"
9. **Verify**: No data from Account 1 visible anywhere
10. Logout
11. Login as Account 1
12. **Verify**: "منزل أ", "قائمة أ", "تفاح، موز" all still present
13. **Verify**: No data from Account 2 visible

### TC-09b: Shared Device Test
1. On same device, Account 1 logs in and uses app
2. Account 1 logs out
3. Account 2 logs in on same device
4. **Verify**: SharedPreferences are user-scoped
5. **Verify**: No cached data from Account 1 in Account 2's session

---

## TC-10: Edge Cases

### TC-10a: Rapid Navigation
1. Quickly tap between bottom nav tabs
2. **Verify**: No crashes or blank screens
3. **Verify**: Correct content loads for each tab

### TC-10b: Background/Foreground
1. Open shopping list
2. Send app to background for 30 seconds
3. Return to foreground
4. **Verify**: Data is still displayed
5. **Verify**: Realtime reconnects and shows any missed changes

### TC-10c: Empty Home
1. Create a new home
2. Navigate to home dashboard
3. **Verify**: Empty state for no lists
4. **Verify**: "إنشاء قائمة" CTA is visible

### TC-10d: Long List Performance
1. Add 50+ items to a shopping list
2. Scroll through the list
3. **Verify**: Smooth scrolling, no jank
4. **Verify**: All items render correctly

---

## TC-11: Inventory Management

### TC-11a: View Inventory
1. Open Drawer → "المخزون"
2. **Verify**: Inventory screen loads with items grouped by category
3. **Verify**: Empty state shows if no items

### TC-11b: Add Inventory Item
1. From inventory screen, tap + FAB
2. Enter name: "زيت زيتون"
3. Set quantity: 2
4. Select category (optional)
5. Set min quantity: 1 (optional)
6. Save
7. **Verify**: Item appears in inventory list
8. **Verify**: Item shows correct quantity

### TC-11c: Edit Inventory Item
1. Tap on inventory item to view details
2. Tap edit icon in AppBar
3. Change quantity to 3
4. Change min quantity to 2
5. Save
6. **Verify**: Detail screen shows updated values

### TC-11d: Delete Inventory Item
1. Open inventory item detail
2. Tap delete icon
3. Confirm deletion
4. **Verify**: Item removed from list

### TC-11e: Quantity Adjustment
1. From inventory list, tap + or - on item
2. **Verify**: Quantity updates immediately
3. **Verify**: Low stock badge appears when quantity <= min

---

## TC-12: Expenses Management

### TC-12a: View Expenses
1. Open Drawer → "المصروفات"
2. **Verify**: Expenses screen loads with "تجريبي" badge
3. **Verify**: Empty state shows if no expenses

### TC-12b: Add Expense
1. From expenses screen, tap + FAB
2. Enter amount: 150.00
3. Enter description: "مشتريات بقالة"
4. Select date (optional)
5. Save
6. **Verify**: Expense appears in list

### TC-12c: View Expense Detail
1. Tap on an expense in the list
2. **Verify**: Detail screen shows amount, description, date, splits
3. **Verify**: Delete option available

### TC-12d: Expense Summary
1. From expenses screen, tap pie chart icon
2. **Verify**: Summary screen loads with period selector
3. **Verify**: Category breakdown displays

### TC-12e: Balances
1. From expenses screen, tap wallet icon
2. **Verify**: Balances screen loads
3. **Verify**: Shows who owes whom

---

## TC-13: Tasks Management

### TC-13a: View Tasks
1. Open Drawer → "المهام"
2. **Verify**: Task list loads with tabs (مهامي / كل المهام)
3. **Verify**: Empty state shows if no tasks

### TC-13b: Add Task
1. From task list, tap + FAB
2. Enter title: "شراء حليب"
3. Enter description (optional): "من السوبرماركت"
4. Set due date (optional)
5. Assign to member (optional)
6. Save
7. **Verify**: Task appears in list
8. **Verify**: Task shows correct due date color (red=overdue, orange=today, grey=future)

### TC-13c: Complete Task
1. Tap checkbox on task
2. **Verify**: Task marked as completed
3. **Verify**: Task moves to completed section or shows strikethrough

### TC-13d: Task Detail
1. Tap on task to view details
2. **Verify**: All task info displayed (title, description, assignee, due date, recurrence)
3. **Verify**: Edit and delete options available

### TC-13e: Archived Tasks
1. From task list, navigate to archived tasks
2. **Verify**: Archived tasks screen loads
3. **Verify**: Can view and restore archived tasks

---

## TC-14: Feature Flag Verification

### TC-14a: All Features Enabled
1. Verify `enableInventory: true` in code
2. Verify `enableExpenses: true` in code
3. Verify `enableTasks: true` in code
4. Verify `enableAi: false` in code
5. **Verify**: Drawer shows المخزون, المصروفات, المهام
6. **Verify**: Drawer shows "المساعد الذكي" as disabled with "قريبًا"
7. **Verify**: Settings tab shows المخزون, المصروفات, المهام

### TC-14b: Navigation Completeness
1. Open Drawer
2. Tap each item and verify it navigates to correct screen
3. **Verify**: No dead routes or blank screens
4. **Verify**: All FABs have working onPressed handlers

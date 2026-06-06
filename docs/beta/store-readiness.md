# SAWA Store Readiness Checklist

> **Last Updated:** 2026-06-05
> **Target Platform:** Google Play Store (Android)

---

## App Identity

### App Name
- **English:** SAWA - Shared Shopping Lists
- **Arabic:** سوا - قوائم التسوق المشتركة

### Package Name
- `com.sawa.sawa`

### Version
- **Current:** 1.0.0+2003
- **Target Release:** 1.0.0 (build number TBD at release)

---

## App Descriptions

### Short Description (80 chars max)

**English:**
> Share shopping lists with your family in real-time. Fast, simple, always in sync.

**Arabic:**
> شارك قوائم التسوق مع عيلتك بالوقت الحقيقي. سريع، بسيط، دائمًا متزامن.

### Full Description (4000 chars max)

**English:**
> SAWA makes household shopping effortless by letting families share shopping lists in real-time.
>
> **Key Features:**
> - Create and share shopping lists with your household members
> - Add items in seconds with smart suggestions and categories
> - Real-time sync — everyone sees changes instantly
> - Shopping Mode — large buttons and progress tracking for in-store use
> - Works offline — add items without internet, syncs when you're back
> - Activity log — see who added or purchased what
> - Push notifications — get notified when someone updates a shared list
> - Multi-home support — manage separate lists for different households
>
> **Built for Families:**
> SAWA understands that shopping is a team effort. Whether you're a parent managing the weekly groceries or roommates splitting household supplies, SAWA keeps everyone on the same page.
>
> **Fast & Reliable:**
> Add an item in under 3 seconds. Changes appear on all devices instantly. Even without internet, your changes are saved and synced automatically when you reconnect.
>
> **Arabic First:**
> SAWA is built with Arabic as its primary language, with full right-to-left (RTL) support. Also available in English and Turkish.

**Arabic:**
> سوا يجعل تسوّق المنزل أسهل بمشاركة قوائم التسوق مع عائلتك في الوقت الحقيقي.
>
> **الميزات الرئيسية:**
> - إنشاء ومشاركة قوائم التسوق مع أفراد المنزل
> - إضافة المنتجات في ثوانٍ مع الاقتراحات الذكية والتصنيفات
> - مزامنة فورية — الجميع يرى التغييرات لحظيًا
> - وضع التسوق — أزرار كبيرة وتتبع التقدم للاستخدام في المتجر
> - يعمل بدون إنترنت — أضف المنتجات بلا اتصال، يُزامن تلقائيًا عند العودة
> - سجل النشاطات — شاهد من أضاف أو اشترى ماذا
> - إشعارات فورية — توصلك إشعار عند تحديث قائمة مشتركة
> - دعم منازل متعددة — أدر قوائم منفصلة لأسر مختلفة
>
> **مصمم للعائلات:**
> سوا يفهم أن التسوق عمل جماعي. سواء كنت والدًا يدير مشتريات الأسبوع أو زملاء يتقاسمون مستلزمات المنزل، سوا يبقي الجميع على نفس الصفحة.
>
> **سريع وموثوق:**
> أضف منتجًا في أقل من 3 ثوانٍ. التغييرات تظهر على جميع الأجهزة فورًا. حتى بدون إنترنت، تُحفظ تغييراتك وتُزامن تلقائيًا عند استعادة الاتصال.
>
> **العربية أولاً:**
> سوا مبني بالعربية كلغة أساسية، مع دعم كامل للكتابة من اليمين لليسار. متوفر أيضًا بالإنجليزية والتركية.

---

## Categorization

- **Category:** Shopping
- **Content Rating:** Everyone (no mature content)
- **Contains Ads:** No
- **In-App Purchases:** None (free app)

---

## Privacy Policy

### Requirement
Google Play requires a privacy policy URL. The policy must cover:
- What data is collected (email, device info, shopping list content)
- How data is used (sync, notifications, crash reporting)
- Data sharing (Supabase hosting, Firebase Crashlytics)
- User rights (data deletion, account removal)

### Privacy Policy URL
- **Placeholder:** `https://sawa-app.com/privacy` (to be created before publication)
- **Hosting Options:**
  - GitHub Pages in the SAWA repository
  - Dedicated domain
  - In-app HTML page (backup)

### Data Collection Summary

| Data Type | Purpose | Retention |
|-----------|---------|-----------|
| Email address | Authentication, invitations | Until account deletion |
| Device info | Crash reporting, support | 90 days |
| Shopping list content | Core functionality | Until user deletes |
| Push notification tokens | Notification delivery | Until logout |
| Crash logs | Bug fixing | 90 days |
| Feedback submissions | Product improvement | Indefinite (anonymized) |

---

## Contact & Support

- **Support Email:** support@sawa-app.com (to be created)
- **Developer Email:** dev@sawa-app.com (to be created)
- **Website:** https://sawa-app.com (to be created)

### In-App Support
- Feedback button in drawer menu (already implemented)
- Bug report includes device info and recent logs automatically
- App version visible in Settings

---

## Screenshots Requirements

### Google Play Requirements
- Minimum 2 screenshots
- Recommended 4-8 screenshots
- JPEG or PNG, 16:9 or 9:16 ratio
- Minimum dimension: 320px, Maximum: 3840px

### Required Screenshots (Arabic RTL)

| # | Screen | Content |
|---|--------|---------|
| 1 | Home dashboard | Home with multiple shopping lists |
| 2 | Shopping list detail | List with items grouped by category |
| 3 | Shopping Mode | Large buttons, progress bar, purchased items |
| 4 | Add item flow | Quick add with suggestions |
| 5 | Realtime sync | Two devices showing same list (split view) |
| 6 | Member invitation | Invite flow and member management |
| 7 | Notifications | Notification center with activity |
| 8 | Offline mode | Offline indicator and queued items |

### Feature Graphic
- **Size:** 1024 x 500 px
- **Content:** SAWA logo + "قوائم التسوق المشتركة" + key visual
- **Style:** Clean, Arabic-first, Material 3 design

### App Icon
- Already generated via `flutter_launcher_icons`
- Verify 512x512 high-res icon for Play Store

---

## Technical Requirements

### Pre-Submission Checklist
- [ ] Target latest Android API level (API 34+)
- [ ] 64-bit support (already configured)
- [ ] App Bundle (AAB) format for release
- [ ] Signing with release keystore
- [ ] ProGuard/R8 minification enabled
- [ ] No debug logging in release build
- [ ] Crashlytics enabled and tested
- [ ] Network security config (HTTPS only)

### Permissions Declaration
- **Internet:** Required for Supabase sync
- **Notifications:** Required for push notifications
- **No other dangerous permissions required**

---

## Localization

| Language | Status | Notes |
|----------|--------|-------|
| Arabic (ar) | Primary | Full RTL support |
| English (en) | Complete | Full translation |
| Turkish (tr) | Complete | Full translation |

### Store Listing Languages
- Arabic (primary)
- English (secondary)

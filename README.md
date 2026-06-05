# سوا - SAWA 🏠

[![Flutter](https://img.shields.io/badge/Flutter-v3.33+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State--Management-Riverpod-8A2BE2)](https://riverpod.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-green?logo=supabase&logoColor=white)](https://supabase.com)
[![Analysis](https://img.shields.io/badge/flutter--analyze-passing-brightgreen)](https://github.com)
[![Tests](https://img.shields.io/badge/tests-139%20%2F%20139%20passed-brightgreen)](https://github.com)

**سوا (SAWA)** هو تطبيق ذكي ومتكامل لإدارة المنزل المشترك، يركز بشكل أساسي على تسهيل وتنظيم المشتريات اليومية عبر قوائم تسوق تفاعلية ولحظية، مع مزايا متكاملة لتتبع المخزون المنزلي، وإدارة المصاريف المشتركة، وجدولة المهام اليومية، والاستعانة بالذكاء الاصطناعي الذكي لاقتراح الوجبات وقوائم الشراء.

---

## 🌍 اللغات المدعومة / Supported Languages
- **العربية (Arabic) 🇸🇦** - واجهة كاملة بتصميم RTL متناسق.
- **English 🇺🇸**
- **Türkçe 🇹🇷**

---

## ✨ المزايا الأساسية / Core Features

### 🛒 1. قوائم التسوق ووضع التسوق (Shopping Lists & Shopping Mode)
- **إدارة قوائم متعددة**: دعم لإنشاء وتعديل وأرشفة قوائم تسوق متعددة (نشطة ومؤرشفة).
- **التعاون اللحظي (Presence & Realtime)**: حضور لحظي للأعضاء داخل نفس القائمة لتبادل الشراء الفوري دون تعارض.
- **وضع التسوق العملي (Shopping Mode)**: واجهة مخصصة ومريحة للاستخدام بيد واحدة داخل المتجر مع شريط تقدم وحذف تلقائي للمكتمل.
- **المزامنة دون اتصال (Offline Queue)**: حفظ العمليات محلياً ومزامنتها تلقائياً عند عودة الشبكة.
- **إرسال المشتريات للمخزون**: تحويل المنتجات المشتراة بضغطة واحدة إلى مستودع المنزل.

### 📦 2. إدارة المخزون (Inventory Management)
- **لوحة متابعة ذكية**: تتبع كميات المنتجات المتوفرة، والمنخفضة (Low Stock)، والتنبيه بالنقص.
- **التحكم بالكميات والوحدات**: زيادة أو إنقاص الكمية بسهولة اعتماداً على نوع الوحدة (كجم، لتر، قطعة).

### 💳 3. المصاريف والديون المشتركة (Expenses & Balances)
- **تقسيم احترافي (Split Selector)**: دعم كامل للتقسيم بالتساوي، الحصص، أو المخصص.
- **الأرصدة والتسويات**: حساب الديون المستحقة بين الأعضاء لتصفية الحسابات بشكل دوري.
- **إحصائيات ذكية**: عرض ملخص المصاريف حسب التصنيف والأعضاء بشكل رسومي جذاب.

### 📅 4. المهام المشتركة (Shared Tasks)
- **جدولة وتكرار**: تعيين المهام المنزلية مع إمكانية التكرار التلقائي (يومي، أسبوعي، شهري).
- **تعيين الأعضاء والتعليقات**: تعيين مهام لأعضاء محددين مع دعم كامل لكتابة الملاحظات والتعليقات التوضيحية.

### 🤖 5. المساعد الذكي (AI Suggestions)
- **اقتراح المشتريات والوصفات**: مدعوم بنموذج Gemini الصوري واللوحي لاقتراح مشتريات أو إعداد وصفات معتمدة على المكونات المتوفرة في المخزون حالياً.
- **التكامل الآمن**: اتصال محمي وخاص بجدول المستخدمين عبر Supabase Edge Functions.

---

## 🏗️ البنية والتقنيات المستخدمة / Architecture & Tech Stack

التطبيق يعتمد على **معمارية نظيفة تركز على الميزات (Feature-First Clean Architecture)** لعزل المكونات وضمان سهولة الصيانة والتوسع:

- **UI & Widgets**: شاشات تفاعلية بتصميم وجمالية عصرية بالكامل ودعم RTL.
- **State Management**: مكتبة `Riverpod` لإدارة الحالة ومزامنة البيانات.
- **Router**: مكتبة `GoRouter` مع Route Guards لحماية الشاشات وحالة Feature Flags.
- **Backend & Realtime**: قواعد بيانات `Supabase` (Auth, Postgres, Realtime, Edge Functions).
- **Offline Cache**: تخزين آمن للمعلومات وتخزين محلي مؤقت لإتمام العمليات في الأوفلاين.
- **Monitoring**: مكتبة `FCM` للإشعارات، مع `Crashlytics` لمتابعة الأداء وتسجيل الأخطاء.

---

## 🛠️ دليل البدء والتشغيل / Getting Started

### المتطلبات الأساسية
- Flutter SDK v3.33.0+
- Dart SDK v3.6.0+
- حساب Supabase مفعل.

### 1. إعداد المتغيرات البيئية
قم بإنشاء ملف `.env` في المسار الرئيسي للمشروع وأضف المفاتيح الخاصة بك:
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 2. تحميل الحزم والاعتماديات
```bash
flutter pub get
```

### 3. توليد الأكواد المعيارية (JSON Serialization & Riverpod Generators)
```bash
dart run build_runner build
```

### 4. تشغيل التطبيق
```bash
flutter run
```

### 5. فحص جودة الكود
```bash
flutter analyze
```

### 6. تشغيل الاختبارات المؤتمتة
```bash
flutter test
```

---

## 📈 جودة واستقرار التطبيق / Quality & Stability Status
- **Static Analysis**: يجتاز فحص `flutter analyze` بالكامل وبنجاح (0 warnings, 0 errors).
- **Automated Tests**: نجاح **139 / 139** اختباراً مؤتمتاً بنسبة **100%** تغطي كافة اليوزكيس، موفرات البيانات، حساب الأرصدة، شاشات المصاريف وعلامات الميزات.

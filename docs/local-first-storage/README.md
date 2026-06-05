# خطة التخزين المحلي الدائم في SAWA

هذه الوثائق تحول النقاش حول تقليل سحب البيانات من Supabase إلى خطة تنفيذية واضحة. الهدف أن تصبح بيانات التطبيق التي يحتاجها المستخدم في الاستخدام اليومي محفوظة محلياً على الهاتف بشكل دائم، مع مزامنة ذكية مع Supabase عند الحاجة فقط.

## الهدف

- عرض البيانات فوراً من الهاتف عند فتح التطبيق.
- تقليل طلبات Supabase غير الضرورية.
- دعم العمل بدون إنترنت بدقة عالية.
- حماية بيانات كل مستخدم ومنزل من الاختلاط.
- تحديد واضح لمتى تبقى البيانات ومتى تُحذف.
- تجهيز بنية عامة تشمل كل الجداول، مع تنفيذ مرحلي يبدأ بالـ MVP.

## القرار الفني

اعتماد `Drift/SQLite` كقاعدة بيانات محلية دائمة بدلاً من تخزين بيانات التطبيق في `SharedPreferences`.

الأسباب:

- بيانات SAWA علاقية: منازل، أعضاء، قوائم، عناصر، تصنيفات، وحدات، سجلات.
- Drift يدعم streams تلقائية للواجهة، transactions، migrations، وqueries typed.
- `SharedPreferences` مناسب للإعدادات الصغيرة فقط، وليس للبيانات الحرجة أو الكبيرة.
- ملفات Isar الموجودة حالياً في المشروع بقايا غير مفعلة ولا تحتوي تنفيذ حقيقي.

## الملفات

- [architecture-plan.md](architecture-plan.md): الخطة المعمارية الكاملة، المراحل، قواعد المزامنة، وسياسة حذف البيانات.
- [local-schema.md](local-schema.md): كل الجداول المحلية، الأعمدة، الفهارس، وتصنيف كل جدول.
- [data-coverage-audit.md](data-coverage-audit.md): خريطة دقيقة لكل بيانات يطلبها التطبيق، وما هو محفوظ في Drift وما بقي remote-first أو SharedPreferences.
- [implementation-tasks.md](implementation-tasks.md): قائمة tasks تفصيلية قابلة للتنفيذ من موديل أرخص.
- [manual-verification-checklist.md](manual-verification-checklist.md): اختبارات يدوية مرتبة يجب تنفيذها قبل فتح Phase 17.
- [supabase-sync-notes.md](supabase-sync-notes.md): تعديلات Supabase المطلوبة للمزامنة الذكية.

## فحص التغطية

قبل إضافة أي repository أو مسار Supabase جديد، حدث [data-coverage-audit.md](data-coverage-audit.md) ثم شغل:

```bash
/home/omar/flutter/bin/dart run scripts/check_local_data_coverage.dart
```

السكربت يفشل إذا وجد جدولاً مستخدماً عبر `.from('table')` داخل `lib/core` أو `lib/features` وغير مذكور في وثيقة التغطية.

## قاعدة مهمة

لا يتم تنفيذ inventory أو expenses أو tasks قبل استقرار core shared shopping-list MVP. لكن البنية المحلية يجب أن تكون قابلة للتوسع لهذه الجداول لاحقاً حتى لا نعيد بناء النظام من الصفر.

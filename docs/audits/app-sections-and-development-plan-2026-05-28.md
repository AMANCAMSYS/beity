# تقرير التدقيق اليدوي وفحص الكود لتطبيق بيتي (Beity)

> **تاريخ التقرير:** 2026-05-28  
> **حالة التدقيق:** تدقيق يدوي عميق للكود (Deep Manual Code Review)  
> **الأهداف الفنية:** رصد وتوثيق جميع التناقضات المنطقية، الميزات غير المكتملة، تسريبات الأمان، المشكلات الهيكلية، وخطوات الإصلاح الفوري.  

---

## 1. المشاكل والتعارضات المنطقية الحرجة (Critical Logical Inconsistencies)

خلال الفحص اليدوي الدقيق والعميق لملفات الكود، تم الكشف عن **مشكلتين حرجتين للغاية** تؤديان إلى تعطل وظائف أساسية في التطبيق بشكل صامت أو جعلها غير قابلة للاستخدام تماماً.

### 🔴 المشكلة الأولى: تعارض مسارات GoRouter وتعطل إضافة اقتراحات التسوق (Critical UI/UX & Routing Bug)

#### 🔍 التحليل والأدلة:
1. في ملف التوجيه الرئيسي [app_router.dart](file:///home/omar/Desktop/Beity/lib/app/router/app_router.dart#L250-L270)، تم ربط المسار الخاص باقتراحات التسوق الذكية بالشاشة العامة للمساعد:
   ```dart
   GoRoute(
     path: '/shopping-list/:id/ai-suggestions',
     builder: (context, state) {
       final extra = state.extra as Map<String, dynamic>? ?? {};
       return AiAssistantScreen( // <-- يوجه هنا!
         listId: state.pathParameters['id']!,
         listTitle: extra['listTitle'] ?? 'قائمة',
         homeId: extra['homeId'] ?? '',
         homeType: extra['homeType'] ?? 'family',
         existingItemNames: (extra['existingItemNames'] as List<dynamic>?)?.cast<String>() ?? [],
       );
     },
   )
   ```
2. ولكن في مجلد شاشات الذكاء الاصطناعي، توجد شاشة مخصصة واحترافية للغاية تم بناؤها بالكامل لتلبية تدفق قوائم التسوق وهي [ai_suggestions_screen.dart](file:///home/omar/Desktop/Beity/lib/features/ai_suggestions/presentation/screens/ai_suggestions_screen.dart). هذه الشاشة تدعم المكونات التالية:
   * عرض صندوق إدخال الطلب الذكي (`AiPromptInput`).
   * عرض قائمة تفاعلية تفصيلية (`AiSuggestionsList`) وداخلها بطاقات تلامسية (`AiSuggestionTile`) تحتوي على **صناديق اختيار (Checkboxes)** ومؤشرات ذكية للعناصر المكررة في القائمة بالفعل (`Already in list`).
   * شريط سفلي متكامل يحتوي على أزرار "إلغاء" و "إضافة العناصر المحددة (N)"، ومترجم بالكامل للغة العربية والانجليزية.
3. **النتيجة الكارثية:** شاشة [ai_suggestions_screen.dart](file:///home/omar/Desktop/Beity/lib/features/ai_suggestions/presentation/screens/ai_suggestions_screen.dart) **مهملة تماماً (Orphaned)** ولا يتم استدعاؤها أو توجيه المستخدم إليها من أي مكان في التطبيق!
4. **وحتى أسوأ من ذلك:** عند ذهاب المستخدم إلى شاشة المساعد العام [ai_assistant_screen.dart](file:///home/omar/Desktop/Beity/lib/features/ai_suggestions/presentation/screens/ai_assistant_screen.dart#L373-L416) وعرض اقتراحات التسوق (`AiShoppingSuggestionsResponse`)، يعرض الكود العناصر داخل Container عادي مع أيقونة إضافة ثابتة:
   ```dart
   const Icon(Icons.add_circle_outline, color: AppColors.primary)
   ```
   هذا الـ Container **لا يحتوي على أي GestureDetector أو InkWell أو onTap**، ولا توجد أي صناديق اختيار، كما أن زر الإضافة السفلي (FAB) مخفي تماماً ولا يظهر إلا في حالة وصفات الطعام فقط!
   
#### 💥 الأثر الفعلي:
* لا يستطيع المستخدم بأي حال من الأحوال إضافة اقتراحات التسوق الذكية التي يجلبها الذكاء الاصطناعي إلى قائمة تسوقه! يضغط المستخدم على العناصر وعلى أيقونة الإضافة ولا يحدث أي شيء على الإطلاق، مما يجعل الميزة الرئيسية لـ MVP الذكاء الاصطناعي معطلة برمجياً.

#### 🛠️ الإصلاح المقترح:
تعديل ملف [app_router.dart](file:///home/omar/Desktop/Beity/lib/app/router/app_router.dart) وتوجيه المسار `/shopping-list/:id/ai-suggestions` ليعرض شاشة الاقتراحات المخصصة [AiSuggestionsScreen](file:///home/omar/Desktop/Beity/lib/features/ai_suggestions/presentation/screens/ai_suggestions_screen.dart) بدلاً من الشاشة العامة:
```dart
      GoRoute(
        path: '/shopping-list/:id/ai-suggestions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AiSuggestionsScreen( // <-- الإصلاح هنا!
            listId: state.pathParameters['id']!,
            listTitle: extra['listTitle'] ?? 'قائمة',
            homeId: extra['homeId'] ?? '',
            homeType: extra['homeType'] ?? 'family',
            existingItemNames: (extra['existingItemNames'] as List<dynamic>?)?.cast<String>() ?? [],
          );
        },
```

---

### 🔴 المشكلة الثانية: استدعاء دالة قاعدة بيانات مفقودة للمهام المتكررة (Missing Supabase RPC for Tasks)

#### 🔍 التحليل والأدلة:
1. في واجهة قائمة المهام [task_list_screen.dart](file:///home/omar/Desktop/Beity/lib/features/tasks/presentation/screens/task_list_screen.dart#L350)، عند اكتمال مهمة متكررة (`task.isRecurring`)، يتم استدعاء دالة المستودع:
   ```dart
   await repository.createNextRecurringTask(taskId: task.id);
   ```
2. في ملف مستودع البيانات [task_remote_datasource.dart](file:///home/omar/Desktop/Beity/lib/features/tasks/data/datasources/task_remote_datasource.dart#L196-L209)، تقوم الدالة باستدعاء RPC في قاعدة البيانات باسم `create_next_recurring_task`:
   ```dart
   Future<String?> createNextRecurringTask({required String taskId}) async {
     try {
       final response = await _client.rpc(
         'create_next_recurring_task',
         params: {'p_task_id': taskId},
       );
       return response as String?;
     } catch (_) {
       // RPC does not exist yet; recurring tasks not supported in current schema
       return null;
     }
   }
   ```
3. عند فحص جميع ملفات المهاجرات وقاعدة البيانات تحت `supabase/migrations/` بالكامل، **لم يتم العثور على أي أثر للدالة `create_next_recurring_task`!**
4. **النتيجة الكارثية:** تم إخفاء خطأ الاستدعاء صامتاً داخل جملة الـ `catch (_)` في الكود البرمجي للعميل، مما يعطي انطباعاً للمستخدم بأن المهمة اكتملت بنجاح، لكن خادم قاعدة البيانات **لا يقوم بجدولة أو إنشاء المهمة المتكررة القادمة مطلقاً!**

#### 💥 الأثر الفعلي:
* تعطل ميزة المهام المتكررة بالكامل (المهام اليومية، الأسبوعية، والشهرية) وعدم قدرتها على توليد نفسها بعد اكتمالها، مما يجعل رحلة إدارة المهام غير مكتملة هيكلياً خلف الواجهات البصرية.

#### 🛠️ الإصلاح المقترح:
إنشاء مهاجرة جديدة على Supabase لتعريف الدالة `create_next_recurring_task` وحساب تاريخ الاستحقاق التالي بناءً على نوع التكرار (`daily`, `weekly`, `monthly`) وإدخال المهمة الجديدة متضمنة كافة الأعمدة والعلاقات وأدوات الحماية.

---

## 2. المشكلات الفنية الهيكلية المتوسطة (Medium Architectural Issues)

### 🟡 المشكلة الثالثة: فجوة التصفية للمحذوفات مؤقتاً في سياسات SELECT (Database RLS Mismatch)

#### 🔍 التحليل والأدلة:
* تعتمد واجهات Flutter البرمجية ومستودعات البيانات بشكل كامل على آلية الحذف المؤقت (Soft Delete)؛ حيث يتم تحديث حقل `deleted_at` وتعيين قيمته بالوقت الحالي، ويقوم الكود بتصفيتها يدوياً بفلتر `.filter('deleted_at', 'is', null)`.
* ولكن في سياسات جدار الحماية RLS في قاعدة البيانات (مثل سياسات جداول `tasks`, `inventory_items`, `expenses`, `shopping_items`)، تسمح سياسات الـ `SELECT` لجميع الأعضاء بقراءة كافة الصفوف بشكل مطلق طالما ينتمون للمنزل، دون إجبار شرط `deleted_at IS NULL` على مستوى خادم قاعدة البيانات.

#### 💥 الأثر الفعلي:
* لو قام مستخدم بالاستعلام عن البيانات مباشرة عبر API أو من خلال قنوات Realtime دون فلترة واضحة، ستصل البيانات المحذوفة مؤقتاً للعميل، مما يمثل عبئاً إضافياً في معالجة البيانات وثغرة برمجية طفيفة في اتساق حالة الواجهات.

#### 🛠️ الإصلاح المقترح:
تضمين شرط `deleted_at IS NULL` بشكل افتراضي داخل سياسات الـ RLS لجداول المهام والمصاريف وقوائم التسوق.

### 🟡 المشكلة الرابعة: مجلدات برمجية فارغة مشوشة للهيكل (Dead Folders)
* يوجد مجلدان فارغان تماماً تحت شجرة العمل:
  1. `lib/features/screens`
  2. `lib/features/presentation`
* **الأثر:** يسببان تشتتاً لمهندسي البرمجيات أثناء صيانة الكود وتحديد المجلدات.
* **الإصلاح:** حذف المجلدين فوراً.

---

## 3. خطة العمل العلاجية الفورية (Step-by-Step Resolution Plan)

لإيصال التطبيق لحالة الكمال الفني الحقيقي وإصلاح التعارضات المنطقية اليدوية بنجاح، نقترح تطبيق التعديلات التالية بالتتابع:

### 📥 المرحلة 1: إصلاح التوجيه والتوصيل لـ AI Suggestions
* **الإجراء:** تعديل [app_router.dart](file:///home/omar/Desktop/Beity/lib/app/router/app_router.dart) لتغيير شاشة التوجيه للمسار `/shopping-list/:id/ai-suggestions` من `AiAssistantScreen` إلى الشاشة الاحترافية المكتملة `AiSuggestionsScreen`.
* **التحقق:** تشغيل واجهة تفاعل قوائم التسوق وضغط زر "الاقتراحات الذكية"، والتأكد من فتح الشاشة الصحيحة الداعمة للاختيار والإضافة بنجاح للمشتريات.

### 📥 المرحلة 2: بناء ودفع مهاجرة RPC المهام المتكررة
* **الإجراء:** إنشاء مهاجرة جديدة باسم `supabase/migrations/20260528154500_add_create_next_recurring_task_rpc.sql` تحتوي على كود SQL الآمن لإنشاء دالة التكرار وتأمينها بـ `security definer` وضبط الـ `search_path`.
* **التحقق:** إكمال مهمة متكررة على التطبيق والتأكد من توليد المهمة القادمة فوراً وبشكل لحظي في قاعدة البيانات.

### 📥 المرحلة 3: تنظيف الملفات
* **الإجراء:** حذف المجلدات الفارغة المحددة برمجياً.

---

# 🚀 كود PostgreSQL المقترح لـ RPC المهام المتكررة:

```sql
create or replace function public.create_next_recurring_task(p_task_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_task public.tasks%rowtype;
  v_next_due_date date;
  v_new_task_id uuid;
begin
  -- 1. تحقق من هوية وجلسة المستخدم
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  -- 2. جلب تفاصيل المهمة الحالية والتحقق من صلاحية الوصول والعضوية النشطة
  select * into v_task
  from public.tasks
  where id = p_task_id
    and deleted_at is null;

  if not found then
    raise exception 'Task not found';
  end if;

  if not exists (
    select 1
    from public.home_members
    where home_id = v_task.home_id
      and user_id = auth.uid()
      and status = 'active'
      and deleted_at is null
  ) then
    raise exception 'Access denied: not an active member of this home';
  end if;

  -- 3. التحقق من كون المهمة متكررة بالفعل ولها تاريخ استحقاق
  if v_task.recurrence_type is null or v_task.due_date is null then
    return null;
  end if;

  -- 4. احتساب تاريخ الاستحقاق القادم بدقة
  case v_task.recurrence_type
    when 'daily' then
      v_next_due_date := v_task.due_date + interval '1 day';
    when 'weekly' then
      v_next_due_date := v_task.due_date + interval '1 week';
    when 'monthly' then
      v_next_due_date := v_task.due_date + interval '1 month';
    else
      return null;
  end case;

  -- 5. إدخال المهمة المتكررة الجديدة
  insert into public.tasks (
    home_id,
    title,
    description,
    due_date,
    category_id,
    assigned_to,
    recurrence_type,
    created_by
  )
  values (
    v_task.home_id,
    v_task.title,
    v_task.description,
    v_next_due_date,
    v_task.category_id,
    v_task.assigned_to,
    v_task.recurrence_type,
    auth.uid()
  )
  returning id into v_new_task_id;

  return v_new_task_id;
end;
$$;

-- منح صلاحيات التنفيذ للأعضاء المصادقين فقط
revoke all on function public.create_next_recurring_task(uuid) from anon, authenticated;
grant execute on function public.create_next_recurring_task(uuid) to authenticated;
```

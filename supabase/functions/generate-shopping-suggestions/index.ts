import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

declare const Deno: any;

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function requireUser(req: Request, admin: SupabaseClient) {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");

  if (!token) {
    return {
      response: new Response(
        JSON.stringify({ type: 'error', error: "Missing authorization token", message_ar: "مطلوب مصادقة" }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      ),
    };
  }

  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) {
    return {
      response: new Response(
        JSON.stringify({ type: 'error', error: "Invalid authorization token", message_ar: "رمز المصادقة غير صالح" }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      ),
    };
  }

  return { user: data.user };
}

async function requireActiveHomeMember(
  admin: SupabaseClient,
  homeId: string,
  userId: string,
): Promise<Response | null> {
  const { data, error } = await admin
    .from("home_members")
    .select("role")
    .eq("home_id", homeId)
    .eq("user_id", userId)
    .eq("status", "active")
    .is("deleted_at", null)
    .maybeSingle();

  if (error || !data) {
    return new Response(
      JSON.stringify({ type: 'error', error: "Access denied", message_ar: "مرفوض" }),
      { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }

  return null;
}

// --- Valid Enums ---
const VALID_MODES = [
  'shopping_suggestions',
  'what_to_cook',
  'recipe_ingredients',
  'cook_by_vegetables',
  'cook_by_spices',
  'cook_by_available',
  'budget_meals',
  'healthy_meals',
  'quick_meals',
  'kids_meals',
  'guest_meals',
  'weekly_meal_plan',
  'ramadan_list',
  'travel_list',
  'cleaning_list',
];

const VALID_MEAL_TYPES = ['breakfast', 'lunch', 'dinner', 'snack', 'dessert'];
const VALID_BUDGET_LEVELS = ['low', 'medium', 'high'];
const VALID_SKILL_LEVELS = ['beginner', 'intermediate', 'advanced'];
const VALID_DIETS = ['none', 'healthy', 'vegetarian', 'high_protein', 'low_carb', 'kid_friendly', 'no_frying'];
const VALID_CUISINES = ['arabic', 'turkish', 'italian', 'indian', 'asian', 'international', 'any'];

// --- PII Detection ---
function containsPII(text: string): boolean {
  const emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/;
  const phoneRegex = /(\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}/;
  const uuidRegex = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi;
  return emailRegex.test(text) || phoneRegex.test(text) || uuidRegex.test(text);
}

function stripPII(text: string): string {
  return text
    .replace(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, '[REMOVED]')
    .replace(/(\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}/g, '[REMOVED]')
    .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '[REMOVED]');
}

// --- System Prompt Builder ---
function buildSystemPrompt(mode: string, context: any, language: string): string {
  const lang = language === 'ar' ? 'Arabic' : 'English';
  
  let modeInstruction = '';
  
  switch (mode) {
    case 'shopping_suggestions': modeInstruction = 'Suggest grocery items. Type: shopping_suggestions.'; break;
    case 'what_to_cook': modeInstruction = 'Suggest meal ideas. Type: meal_suggestions.'; break;
    case 'recipe_ingredients': modeInstruction = 'Full ingredient list & steps for a meal. Type: recipe_ingredients.'; break;
    case 'cook_by_vegetables': modeInstruction = 'Meals using specific vegetables. Type: meal_suggestions.'; break;
    case 'cook_by_spices': modeInstruction = 'Meals based on spices. Type: meal_suggestions.'; break;
    case 'cook_by_available': modeInstruction = 'Pantry meals with minimal extras. Type: pantry_based_meals.'; break;
    case 'budget_meals': modeInstruction = 'Cheap/economical meals. Type: meal_suggestions.'; break;
    case 'healthy_meals': modeInstruction = 'Low fat/sugar healthy meals. Type: meal_suggestions.'; break;
    case 'quick_meals': modeInstruction = 'Meals under 30 mins. Type: meal_suggestions.'; break;
    case 'kids_meals': modeInstruction = 'Mild, child-friendly meals. Type: meal_suggestions.'; break;
    case 'guest_meals': modeInstruction = 'Impressive meals for guests. Type: meal_suggestions.'; break;
    case 'weekly_meal_plan': modeInstruction = '7-day meal plan (Sat-Fri). Type: weekly_meal_plan.'; break;
    case 'ramadan_list': modeInstruction = 'Ramadan (Iftar/Suhoor) items. Type: meal_suggestions.'; break;
    case 'travel_list': modeInstruction = 'Travel-friendly supplies. Type: shopping_suggestions.'; break;
    case 'cleaning_list': modeInstruction = 'Cleaning supplies. Type: shopping_suggestions.'; break;
  }

  // Build context section
  let contextSection = '';
  if (context.homeType) contextSection += `\n- Home Type: ${context.homeType}`;
  if (context.listTitle) contextSection += `\n- Shopping List Title: ${context.listTitle}`;
  if (context.servings) contextSection += `\n- Number of servings: ${context.servings}`;
  if (context.preferredCuisine && context.preferredCuisine !== 'any') contextSection += `\n- Preferred cuisine: ${context.preferredCuisine}`;
  if (context.dietaryPreference && context.dietaryPreference !== 'none') contextSection += `\n- Dietary preference: ${context.dietaryPreference}`;
  if (context.budgetLevel) contextSection += `\n- Budget level: ${context.budgetLevel}`;
  if (context.maxPreparationTimeMinutes) contextSection += `\n- Max preparation time: ${context.maxPreparationTimeMinutes} minutes`;
  if (context.mealType) contextSection += `\n- Meal type: ${context.mealType}`;
  if (context.cookingSkillLevel) contextSection += `\n- Cooking skill: ${context.cookingSkillLevel}`;
  if (context.occasion) contextSection += `\n- Occasion: ${context.occasion}`;
  
  if (Array.isArray(context.existingShoppingItems) && context.existingShoppingItems.length > 0) {
    contextSection += `\n- Items already in shopping list: ${context.existingShoppingItems.join(', ')}`;
  }
  if (Array.isArray(context.inventoryItems) && context.inventoryItems.length > 0) {
    contextSection += `\n- Items available in home inventory: ${context.inventoryItems.join(', ')}`;
  }
  if (Array.isArray(context.availableVegetables) && context.availableVegetables.length > 0) {
    contextSection += `\n- Available vegetables: ${context.availableVegetables.join(', ')}`;
  }
  if (Array.isArray(context.availableSpices) && context.availableSpices.length > 0) {
    contextSection += `\n- Available spices: ${context.availableSpices.join(', ')}`;
  }
  if (Array.isArray(context.availableProteins) && context.availableProteins.length > 0) {
    contextSection += `\n- Available proteins: ${context.availableProteins.join(', ')}`;
  }
  if (Array.isArray(context.availableCarbs) && context.availableCarbs.length > 0) {
    contextSection += `\n- Available carbs: ${context.availableCarbs.join(', ')}`;
  }
  if (Array.isArray(context.excludedIngredients) && context.excludedIngredients.length > 0) {
    contextSection += `\n- Excluded ingredients (avoid these): ${context.excludedIngredients.join(', ')}`;
  }

  return `You are a professional cooking/grocery assistant for "Beity" app.
Language: ${lang}. If 'ar', use Arabic for all text fields.

Mode: ${mode} (${modeInstruction})
Context: ${contextSection || 'None'}

CRITICAL RULES:
1. ONLY answer questions related to cooking, recipes, groceries, meal planning, and kitchen management.
2. If the user asks about ANY unrelated topic, return: { "type": "not_related", "message": "عذراً، يمكنني مساعدتك فقط في أمور الطبخ والمقاضي وإدارة المنزل." }
3. ${
  (context.promptDepth || 0) >= 3
    ? 'DO NOT ask clarifying questions anymore. The user has provided enough details. Provide the FINAL results (suggestions or plan) IMMEDIATELY.'
    : 'If the prompt is vague, general, or short (e.g., "للضيوف", "غداء", "أفكار", "شيء سريع"), you MUST NOT provide final results yet. Instead, return: { "type": "clarifying_questions", "questions": ["توضيح بسيط لاستكمال الطلب"], "quickOptions": ["اقتراح نصي لتخصيص 1", "اقتراح نصي لتخصيص 2", ...] } to help the user specify their request.'
}
4. For "quickOptions", provide 3-4 creative and specific text suggestions (like "عشاء رومانسي إيطالي" or "كبسة سعودية سريعة") that the user can pick to narrow down their general request.
5. Return ONLY valid JSON. No markdown formatting, no conversational filler.
6. Maximize relevance to provided Context (Inventory/Shopping List).

RESPONSE SCHEMAS:
- clarifying_questions: { "type": "clarifying_questions", "questions": ["string"], "quickOptions": ["string"] }
- shopping_suggestions: { "type": "shopping_suggestions", "suggestions": [{ "name": "string", "quantity": number, "unit": "string", "category": "string", "reason": "string" }] }
- meal_suggestions: { "type": "meal_suggestions", "summary": "string", "meals": [{ "name": "string", "description": "string", "difficulty": "string", "estimatedTimeMinutes": number, "servings": number, "mealType": "string", "cuisine": "string", "budgetLevel": "string", "mainIngredients": ["string"], "whyThisMeal": "string", "tags": ["string"] }] }
- recipe_ingredients: { "type": "recipe_ingredients", "meal": { "name": "string", "description": "string", "servings": number, "estimatedTimeMinutes": number, "difficulty": "string", "cuisine": "string" }, "ingredients": [{ "name": "string", "quantity": number, "unit": "string", "category": "string", "required": true, "status": "missing|available|already_in_list|optional|unknown", "reason": "string", "note": "string" }], "optionalIngredients": [{ "name": "string", "quantity": number, "unit": "string", "category": "string", "required": false, "status": "optional", "reason": "string" }], "cookingStepsPreview": ["string"], "shoppingSummary": { "availableCount": number, "missingCount": number, "alreadyInListCount": number } }
- weekly_meal_plan: { "type": "weekly_meal_plan", "summary": "string", "days": [{ "day": "string", "meals": [{ "name": "string", "mealType": "string", "description": "string", "mainIngredients": ["string"], "estimatedTimeMinutes": number }] }] }
- pantry_based_meals: { "type": "pantry_based_meals", "summary": "string", "meals": [{ "name": "string", "description": "string", "difficulty": "string", "estimatedTimeMinutes": number, "servings": number, "cuisine": "string", "availableIngredients": ["string"], "missingIngredients": ["string"], "whyThisMeal": "string", "tags": ["string"] }] }

IMPORTANT: For recipe_ingredients, set status to "available" if in inventory, "already_in_list" if in shopping list, "missing" otherwise.`;
}

// --- Response Validation ---
function validateAndSanitizeResponse(parsed: any): any {
  const type = parsed.type;
  
  if (!type || typeof type !== 'string') {
    return { type: 'error', message: 'Invalid response type' };
  }

  switch (type) {
    case 'clarifying_questions': {
      const questions = Array.isArray(parsed.questions) ? parsed.questions.slice(0, 5) : [];
      const quickOptions = Array.isArray(parsed.quickOptions) ? parsed.quickOptions.slice(0, 8) : [];
      return { type, questions, quickOptions };
    }
    
    case 'shopping_suggestions': {
      const suggestions = Array.isArray(parsed.suggestions) ? parsed.suggestions.slice(0, 20) : [];
      return {
        type,
        suggestions: suggestions.map((s: any) => sanitizeSuggestion(s)).filter((s: any) => s.name),
      };
    }
    
    case 'meal_suggestions': {
      const meals = Array.isArray(parsed.meals) ? parsed.meals.slice(0, 10) : [];
      return {
        type,
        summary: typeof parsed.summary === 'string' ? parsed.summary : '',
        meals: meals.map((m: any) => sanitizeMeal(m)).filter((m: any) => m.name),
      };
    }
    
    case 'recipe_ingredients': {
      const ingredients = Array.isArray(parsed.ingredients) ? parsed.ingredients.slice(0, 40) : [];
      const optionalIngredients = Array.isArray(parsed.optionalIngredients) ? parsed.optionalIngredients.slice(0, 20) : [];
      return {
        type,
        meal: sanitizeMealInfo(parsed.meal),
        ingredients: ingredients.map((i: any) => sanitizeIngredient(i)).filter((i: any) => i.name),
        optionalIngredients: optionalIngredients.map((i: any) => sanitizeIngredient(i, false)).filter((i: any) => i.name),
        cookingStepsPreview: Array.isArray(parsed.cookingStepsPreview) ? parsed.cookingStepsPreview.slice(0, 10) : [],
        shoppingSummary: {
          availableCount: typeof parsed.shoppingSummary?.availableCount === 'number' ? parsed.shoppingSummary.availableCount : 0,
          missingCount: typeof parsed.shoppingSummary?.missingCount === 'number' ? parsed.shoppingSummary.missingCount : 0,
          alreadyInListCount: typeof parsed.shoppingSummary?.alreadyInListCount === 'number' ? parsed.shoppingSummary.alreadyInListCount : 0,
        },
      };
    }
    
    case 'weekly_meal_plan': {
      const days = Array.isArray(parsed.days) ? parsed.days.slice(0, 7) : [];
      return {
        type,
        summary: typeof parsed.summary === 'string' ? parsed.summary : '',
        days: days.map((d: any) => ({
          day: typeof d.day === 'string' ? d.day : '',
          meals: Array.isArray(d.meals) ? d.meals.slice(0, 5).map((m: any) => sanitizeDayMeal(m)).filter((m: any) => m.name) : [],
        })),
      };
    }
    
    case 'not_related':
      return { type: 'not_related', message: typeof parsed.message === 'string' ? parsed.message : 'هذا الطلب خارج تخصصي.' };

    case 'pantry_based_meals': {
      const meals = Array.isArray(parsed.meals) ? parsed.meals.slice(0, 10) : [];
      return {
        type,
        summary: typeof parsed.summary === 'string' ? parsed.summary : '',
        meals: meals.map((m: any) => ({
          name: safeStr(m.name, 100),
          description: safeStr(m.description, 300),
          difficulty: safeStr(m.difficulty, 50),
          estimatedTimeMinutes: safeNum(m.estimatedTimeMinutes, 30),
          servings: safeNum(m.servings, 4),
          cuisine: safeStr(m.cuisine, 50),
          availableIngredients: Array.isArray(m.availableIngredients) ? m.availableIngredients.slice(0, 20) : [],
          missingIngredients: Array.isArray(m.missingIngredients) ? m.missingIngredients.slice(0, 20) : [],
          whyThisMeal: safeStr(m.whyThisMeal, 200),
          tags: Array.isArray(m.tags) ? m.tags.slice(0, 5) : [],
        })).filter((m: any) => m.name),
      };
    }
    
    default:
      return { type: 'error', message: 'Unknown response type' };
  }
}

function safeStr(val: any, maxLen: number): string {
  if (typeof val !== 'string') return '';
  return val.trim().substring(0, maxLen);
}

function safeNum(val: any, defaultVal: number): number {
  if (typeof val === 'number' && val > 0) return val;
  return defaultVal;
}

function sanitizeSuggestion(s: any): any {
  if (!s || typeof s !== 'object') return { name: '' };
  return {
    name: safeStr(s.name, 100),
    quantity: safeNum(s.quantity, 1),
    unit: safeStr(s.unit, 50) || undefined,
    category: safeStr(s.category, 50) || undefined,
    reason: safeStr(s.reason, 200) || undefined,
  };
}

function sanitizeMeal(m: any): any {
  if (!m || typeof m !== 'object') return { name: '' };
  return {
    name: safeStr(m.name, 100),
    description: safeStr(m.description, 300),
    difficulty: safeStr(m.difficulty, 50),
    estimatedTimeMinutes: safeNum(m.estimatedTimeMinutes, 30),
    servings: safeNum(m.servings, 4),
    mealType: safeStr(m.mealType, 30),
    cuisine: safeStr(m.cuisine, 50),
    budgetLevel: safeStr(m.budgetLevel, 20),
    mainIngredients: Array.isArray(m.mainIngredients) ? m.mainIngredients.slice(0, 10).map((i: any) => safeStr(i, 50)) : [],
    whyThisMeal: safeStr(m.whyThisMeal, 200),
    tags: Array.isArray(m.tags) ? m.tags.slice(0, 5).map((t: any) => safeStr(t, 30)) : [],
  };
}

function sanitizeMealInfo(meal: any): any {
  if (!meal) return { name: '', description: '', servings: 4, estimatedTimeMinutes: 30, difficulty: '', cuisine: '' };
  return {
    name: safeStr(meal.name, 100),
    description: safeStr(meal.description, 300),
    servings: safeNum(meal.servings, 4),
    estimatedTimeMinutes: safeNum(meal.estimatedTimeMinutes, 30),
    difficulty: safeStr(meal.difficulty, 50),
    cuisine: safeStr(meal.cuisine, 50),
  };
}

function sanitizeIngredient(i: any, required = true): any {
  if (!i || typeof i !== 'object') return { name: '' };
  const validStatuses = ['available', 'missing', 'already_in_list', 'optional', 'unknown'];
  let status = safeStr(i.status, 30);
  if (!validStatuses.includes(status)) status = required ? 'missing' : 'optional';
  
  return {
    name: safeStr(i.name, 100),
    quantity: safeNum(i.quantity, 1),
    unit: safeStr(i.unit, 50) || undefined,
    category: safeStr(i.category, 50) || undefined,
    required: required,
    status: status,
    reason: safeStr(i.reason, 200) || undefined,
    note: safeStr(i.note, 200) || undefined,
  };
}

function sanitizeDayMeal(m: any): any {
  if (!m || typeof m !== 'object') return { name: '' };
  return {
    name: safeStr(m.name, 100),
    mealType: safeStr(m.mealType, 30),
    description: safeStr(m.description, 300),
    mainIngredients: Array.isArray(m.mainIngredients) ? m.mainIngredients.slice(0, 10).map((i: any) => safeStr(i, 50)) : [],
    estimatedTimeMinutes: safeNum(m.estimatedTimeMinutes, 30),
  };
}

// --- Main Handler ---
Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    // Verify JWT
    const authResult = await requireUser(req, supabaseAdmin);
    if ("response" in authResult) {
      return authResult.response;
    }

    const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY");

    if (!DEEPSEEK_API_KEY) {
      console.error("Missing DEEPSEEK_API_KEY in Supabase Secrets");
      return new Response(
        JSON.stringify({ type: 'error', error: "Configuration Error", message_ar: "مفتاح DeepSeek غير مفعّل حاليًا" }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const MODEL = Deno.env.get("DEEPSEEK_MODEL") || "deepseek-chat";

    const body = await req.json();
    const {
      mode, userPrompt, language,
      homeType, listTitle, existingShoppingItems, inventoryItems,
      servings, preferredCuisine, dietaryPreference, budgetLevel,
      maxPreparationTimeMinutes, availableVegetables, availableSpices,
      availableProteins, availableCarbs, excludedIngredients,
      occasion, mealType, cookingSkillLevel,
      // Legacy support
      prompt: legacyPrompt, existingItems: legacyExistingItems,
    } = body;

    // Support legacy mode (old clients sending prompt instead of userPrompt)
    const effectiveMode = mode || 'shopping_suggestions';
    const effectivePrompt = userPrompt || legacyPrompt || '';
    const effectiveLanguage = language || 'ar';
    const effectiveExistingItems = existingShoppingItems || legacyExistingItems || [];

    // Validation
    if (!effectivePrompt || typeof effectivePrompt !== 'string' || effectivePrompt.trim().length === 0) {
      return new Response(
        JSON.stringify({ type: 'error', error: "اكتب ما تريد اقتراحه أولًا", message_ar: "اكتب ما تريد اقتراحه أولًا" }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (effectivePrompt.length > 500) {
      return new Response(
        JSON.stringify({ type: 'error', error: "Prompt exceeds 500 characters", message_ar: "النص طويل جدًا (الحد الأقصى 500 حرف)" }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (effectiveLanguage !== 'ar' && effectiveLanguage !== 'en') {
      return new Response(
        JSON.stringify({ type: 'error', error: "Invalid language", message_ar: "اللغة غير مدعومة" }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!VALID_MODES.includes(effectiveMode)) {
      return new Response(
        JSON.stringify({ type: 'error', error: "Invalid mode", message_ar: "الوضع غير مدعوم" }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Strip PII from prompt
    const cleanPrompt = stripPII(effectivePrompt);

    // Build context (sanitized, no PII)
    const context = {
      homeType: safeStr(homeType, 50),
      listTitle: safeStr(listTitle, 100),
      existingShoppingItems: Array.isArray(effectiveExistingItems) ? effectiveExistingItems.slice(0, 50).map((i: any) => String(i).trim()) : [],
      inventoryItems: Array.isArray(inventoryItems) ? inventoryItems.slice(0, 50).map((i: any) => String(i).trim()) : [],
      servings: safeNum(servings, 0) || undefined,
      preferredCuisine: VALID_CUISINES.includes(preferredCuisine) ? preferredCuisine : undefined,
      dietaryPreference: VALID_DIETS.includes(dietaryPreference) ? dietaryPreference : undefined,
      budgetLevel: VALID_BUDGET_LEVELS.includes(budgetLevel) ? budgetLevel : undefined,
      maxPreparationTimeMinutes: safeNum(maxPreparationTimeMinutes, 0) || undefined,
      mealType: VALID_MEAL_TYPES.includes(mealType) ? mealType : undefined,
      cookingSkillLevel: VALID_SKILL_LEVELS.includes(cookingSkillLevel) ? cookingSkillLevel : undefined,
      occasion: safeStr(occasion, 100) || undefined,
      availableVegetables: Array.isArray(availableVegetables) ? availableVegetables.slice(0, 20) : [],
      availableSpices: Array.isArray(availableSpices) ? availableSpices.slice(0, 20) : [],
      availableProteins: Array.isArray(availableProteins) ? availableProteins.slice(0, 20) : [],
      availableCarbs: Array.isArray(availableCarbs) ? availableCarbs.slice(0, 20) : [],
      excludedIngredients: Array.isArray(excludedIngredients) ? excludedIngredients.slice(0, 20) : [],
      promptDepth: (cleanPrompt.match(/-/g) || []).length,
    };

    const systemPrompt = buildSystemPrompt(effectiveMode, context, effectiveLanguage);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 25000); // 25s timeout

    const response = await fetch(
      "https://api.deepseek.com/chat/completions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${DEEPSEEK_API_KEY}`,
          "Content-Type": "application/json",
        },
        signal: controller.signal,
        body: JSON.stringify({
          model: MODEL,
          messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: cleanPrompt }
          ],
          response_format: { type: 'json_object' },
          max_tokens: 2000,
          temperature: 0.7,
        })
      }
    ).finally(() => clearTimeout(timeoutId));

    if (!response.ok) {
      const errTxt = await response.text();
      console.error("DeepSeek API Error:", response.status, errTxt);
      let apiErrorMessage = "تعذر إنشاء الاقتراحات، حاول مرة أخرى";
      try {
        const errJson = JSON.parse(errTxt);
        apiErrorMessage = errJson.error?.message || apiErrorMessage;
      } catch(_) {}

      return new Response(
        JSON.stringify({ type: 'error', error: apiErrorMessage, message_ar: `خطأ من مزود الذكاء الاصطناعي: ${apiErrorMessage}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const result = await response.json();
    
    // Check for OpenRouter-specific errors in a 200 OK response
    if (result.error) {
      console.error("OpenRouter API returned an error:", result.error);
      return new Response(
        JSON.stringify({ 
          type: 'error', 
          error: result.error.message || "Model error", 
          message_ar: "مزود الذكاء الاصطناعي مشغول حالياً، يرجى المحاولة بعد قليل." 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!result.choices || result.choices.length === 0 || !result.choices[0].message) {
      console.error("OpenRouter returned empty choices:", result);
      return new Response(
        JSON.stringify({ 
          type: 'error', 
          error: "Empty response from model", 
          message_ar: "تعذر الحصول على إجابة من المساعد، حاول مرة أخرى." 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    let parsed: any;
    try {
      const content = result.choices[0].message.content || "";
      if (!content) throw new Error("Empty content");

      // Robust JSON extraction: find the first '{' and the last '}'
      const firstBrace = content.indexOf('{');
      const lastBrace = content.lastIndexOf('}');
      
      if (firstBrace === -1 || lastBrace === -1) {
        throw new Error("No JSON object found in response");
      }

      const jsonStr = content.substring(firstBrace, lastBrace + 1);
      parsed = JSON.parse(jsonStr);
    } catch (e) {
      console.error("Failed to parse AI response as JSON:", e);
      console.error("Raw content that failed to parse:", result.choices[0].message.content);
      
      return new Response(
        JSON.stringify({ 
          type: 'error', 
          error: "Invalid JSON format from AI", 
          message_ar: "حدث خطأ في معالجة إجابة المساعد، يرجى المحاولة مرة أخرى." 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate and sanitize the response
    const sanitized = validateAndSanitizeResponse(parsed);

    // Legacy compatibility: if old client expects "suggestions" array at root
    if (effectiveMode === 'shopping_suggestions' && sanitized.type === 'shopping_suggestions') {
      return new Response(
        JSON.stringify({ ...sanitized, suggestions: sanitized.suggestions }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify(sanitized),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ type: 'error', error: "حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.", message_ar: "حدث خطأ غير متوقع. يرجى المحاولة لاحقاً." }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

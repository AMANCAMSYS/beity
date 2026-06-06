// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { suggestionMessages } from "../_shared/templates.ts";

declare const Deno: any;

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Localized message resolver
function getMessage(key: string, lang: string): string {
  const l = (lang === 'tr' || lang === 'en' || lang === 'ar') ? lang : 'ar';

  const selectedMessages =
    l === 'tr'
      ? suggestionMessages.tr
      : l === 'en'
        ? suggestionMessages.en
        : suggestionMessages.ar;

  const message = new Map(Object.entries(selectedMessages)).get(key);
  if (message != null) {
    return message;
  }

  const fallbackMessage = new Map(Object.entries(suggestionMessages.ar)).get(key);
  if (fallbackMessage != null) {
    return fallbackMessage;
  }

  return key;
}

async function requireUser(req: Request, admin: SupabaseClient, lang: string) {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");

  if (!token) {
    return {
      response: new Response(
        JSON.stringify({ type: 'error', error: "Missing authorization token", message_ar: getMessage('missing_auth', lang) }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      ),
    };
  }

  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) {
    return {
      response: new Response(
        JSON.stringify({ type: 'error', error: "Invalid authorization token", message_ar: getMessage('invalid_auth', lang) }),
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
  lang: string,
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
      JSON.stringify({ type: 'error', error: "Access denied", message_ar: getMessage('access_denied', lang) }),
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
function buildSystemPrompt(mode: string, context: any, language: string, userTerms: Record<string, string>): string {
  let lang = 'Arabic';
  if (language === 'en') lang = 'English';
  if (language === 'tr') lang = 'Turkish';

  let modeInstruction = '';

  switch (mode) {
    case 'shopping_suggestions': modeInstruction = 'Suggest shopping-list items for groceries, household supplies, cleaning, baby care, stationery, clothing, electronics, hardware, sports/fitness, travel, and other home needs. Type: shopping_suggestions.'; break;
    case 'what_to_cook': modeInstruction = 'Suggest meal ideas. Type: meal_suggestions.'; break;
    case 'recipe_ingredients': modeInstruction = 'Full ingredient list & steps for a meal. Type: recipe_ingredients. You MUST generate real, detailed cooking instructions step-by-step in the steps/st array. Do not use generic fallback text.'; break;
    case 'cook_by_vegetables': modeInstruction = 'Meals using specific vegetables. Type: meal_suggestions.'; break;
    case 'cook_by_spices': modeInstruction = 'Meals based on spices. Type: meal_suggestions.'; break;
    case 'cook_by_available': modeInstruction = 'Pantry meals with minimal extras. Type: pantry_based_meals.'; break;
    case 'budget_meals': modeInstruction = 'Cheap/economical meals. Type: meal_suggestions.'; break;
    case 'healthy_meals': modeInstruction = 'Low fat/sugar healthy meals. Type: meal_suggestions.'; break;
    case 'quick_meals': modeInstruction = 'Meals under 30 mins. Type: meal_suggestions.'; break;
    case 'kids_meals': modeInstruction = 'Mild, child-friendly meals. Type: meal_suggestions.'; break;
    case 'guest_meals': modeInstruction = 'Impressive meals for guests. Type: meal_suggestions.'; break;
    case 'weekly_meal_plan': modeInstruction = '7-day meal plan (Sat-Fri). Type: weekly_meal_plan.'; break;
    case 'ramadan_list': modeInstruction = 'Ramadan grocery shopping list for Iftar and Suhoor. Type: shopping_suggestions.'; break;
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
  if (Array.isArray(context.excludedIngredients) && context.excludedIngredients.length > 0) {
    contextSection += `\n- Excluded ingredients (avoid these): ${context.excludedIngredients.join(', ')}`;
  }

  // Add userTerms mappings
  let userTermsSection = '';
  if (userTerms && Object.keys(userTerms).length > 0) {
    userTermsSection = `\n- Preferred User Ingredient Names Mapping (user_terms):\n${JSON.stringify(userTerms, null, 2)}`;
  }

  let dialectInstruction = '';
  if (context.dialect || context.country) {
    const d = context.dialect || '';
    const c = context.country || '';
    dialectInstruction = `
Dialect/Tone & Naming Preferences:
- Country location of user: ${c}
- Preferred AI dialect/dialect: ${d} (e.g. Gulf/Saudi dialect, Egyptian dialect, Levantine dialect, Turkish)
- CRITICAL: You MUST use the exact localized names, dialect, and naming conventions for ingredients and dishes for this country and dialect (e.g. if Saudi/Gulf: use Gulf terms like "طماطم", "كوسا", "باذنجان", "رز"; if Egypt: use Egyptian terms like "طماطم" or "قوطة", "كوسة", "بتنجان"; if Turkey: use Turkish standard names). Write all recipes, descriptions, and instructions in the chosen dialect/tone (${d}) rather than standard formal Arabic where appropriate, keeping it friendly, premium, and natural for that specific region.`;
  }

  return `You are a professional home-shopping and cooking assistant for "SAWA" app.
Language: ${lang}. If 'ar', use Arabic for all text fields. If 'tr', use Turkish for all text fields.
${dialectInstruction}

Mode: ${mode} (${modeInstruction})
Context: ${contextSection || 'None'}${userTermsSection}

CRITICAL RULES:
1. ONLY answer questions related to shopping-list planning, home supplies, cooking, recipes, groceries, meal planning, and home management. Shopping-list topics include groceries, cleaning supplies, baby care, stationery, clothing, electronics, hardware/tools, sports/fitness equipment, travel supplies, and similar household purchases.
2. If the user asks about ANY unrelated topic, return: { "type": "not_related", "message": "${getMessage('unrelated_topic', language)}" }
3. If the prompt is completely vague, empty, or lacks any shopping, household, culinary, or grocery context (e.g., just 'مرحباً', 'أهلاً', or 'hello'), you may ask clarifying questions: return '{ "type": "clarifying_questions", "questions": ["string"], "quickOptions": ["string"] }' with a customized, helpful question and 3 customized, relevant quick choices. However, for any shopping-list, home-supplies, culinary, or grocery topic (e.g., 'قائمة رمضان', 'عشاء سريع', 'للضيوف', 'وجبة أطفال', 'أدوات رياضية للبيت', 'معدات تنظيف', 'أفكار'), you MUST NOT ask clarifying questions. Directly generate and return the final results (shopping suggestions, meals, or recipes) immediately.
4. Return ONLY valid, highly-compressed JSON. No markdown formatting, no conversational filler.
5. Maximize relevance to the user's request. Carefully scale quantities ("q") based on family size, duration, or use case mentioned by the user. For food, use cooking quantities; for non-food items, use realistic count units like "حبة", "قطعة", "علبة", "رزمة", or "زوج". Ensure the suggestions are highly diverse, realistic, and comprehensive to cover the request.
6. Use stable, standard snake_case keys in the "k" field when useful. For cooking modes, prefer common generic food keys (e.g., 'tomato', 'onion', 'chicken', 'rice_basmati', 'milk', 'egg'). For shopping suggestions outside food, use generic item keys (e.g., 'dumbbell', 'resistance_band', 'charger', 'screwdriver', 'notebook'). Do not create overly specific keys unless absolutely necessary.
7. Use the exact preferred names from the provided "user_terms" mapping inside item names ("n"), recipe ingredient names, display names, and cooking steps ("st") if their corresponding key is used.
8. NEVER include status, availability, reason, or comparisons with the user's inventory/lists. Do not output fields like "status" or "reason". The app client will perform matching locally.
9. If the Mode is 'shopping_suggestions', you MUST return a response of type 'shopping_suggestions'. Even if the user asks for a specific recipe, meal, sports setup, cleaning kit, school kit, repair kit, or travel kit, do not return another type. Instead, suggest the required shopping items in the 'shopping_suggestions' format.

RESPONSE SCHEMAS (Use the following compressed schemas to minimize tokens. You MUST output fully valid JSON with correct colons and brackets. NEVER output empty braces or syntax anomalies):
- clarifying_questions: { "type": "clarifying_questions", "questions": ["سؤال توضيحي؟"], "quickOptions": ["خيار 1", "خيار 2"] }
- shopping_suggestions: { "type": "shopping_suggestions", "sug": [{ "n": "طماطم", "q": 2.5, "u": "كيلو", "category": "خضروات" }, { "n": "دمبل", "q": 2, "u": "قطعة", "category": "أدوات رياضية" }, { "n": "حبل مقاومة", "q": 1, "u": "قطعة", "category": "أدوات رياضية" }] }
- meal_suggestions: {
    "type": "meal_suggestions",
    "sum": "ملخص الاقتراحات",
    "meals": [{
      "id": "meal_1",
      "n": "اسم الوجبة",
      "d": "وصف الوجبة",
      "t": 30,
      "srv": 4,
      "df": "easy",
      "ing": [{ "k": "tomato", "n": "طماطم", "q": 2, "u": "حبة", "r": true }],
      "st": ["الخطوة الأولى"]
    }]
  }
- recipe_ingredients: {
    "type": "recipe_ingredients",
    "m": { "n": "اسم الوجبة", "d": "وصفها", "srv": 4, "t": 30, "df": "easy" },
    "ing": [{ "k": "tomato", "n": "طماطم", "q": 2, "u": "حبة", "r": true }],
    "opt_ing": [{ "k": "pepper", "n": "فلفل", "q": 1, "u": "حبة", "r": false }],
    "st": ["الخطوة الأولى"]
  }
- weekly_meal_plan: { "type": "weekly_meal_plan", "sum": "ملخص", "days": [{ "day": "السبت", "meals": [{ "n": "فطور صحي", "mealType": "breakfast", "d": "وصف الفطور", "ing": ["بيض", "جبن"], "t": 15 }] }] }
- pantry_based_meals: { "type": "pantry_based_meals", "sum": "ملخص", "meals": [{ "n": "وجبة سهلة", "d": "وصف", "df": "easy", "t": 20, "srv": 2, "av_ing": ["طماطم"], "mis_ing": ["بصل"], "whyThisMeal": "لأنها سهلة وسريعة", "tags": ["سريعة"] }] }
`;
}

// --- Response Validation ---
function validateAndSanitizeResponse(parsed: any, lang: string): any {
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
      const rawSugList = parsed.sug || parsed.suggestions || [];
      const sugList = Array.isArray(rawSugList) ? rawSugList.slice(0, 150) : []; // Increased to 150 to allow diverse and comprehensive lists
      return {
        type,
        sug: sugList.map((s: any) => sanitizeIngredient(s)).filter((s: any) => s.n),
      };
    }

    case 'meal_suggestions': {
      const rawMealsList = parsed.meals || parsed.m || [];
      const meals = Array.isArray(rawMealsList) ? rawMealsList.slice(0, 10) : [];
      return {
        type,
        sum: typeof parsed.sum === 'string' ? parsed.sum : (typeof parsed.summary === 'string' ? parsed.summary : ''),
        meals: meals.map((m: any) => sanitizeMeal(m)).filter((m: any) => m.n),
      };
    }

    case 'recipe_ingredients': {
      const rawIng = parsed.ing || parsed.ingredients || [];
      const rawOptIng = parsed.opt_ing || parsed.optionalIngredients || [];
      const rawSteps = parsed.st || parsed.cookingStepsPreview || parsed.steps || [];
      const ingredients = Array.isArray(rawIng) ? rawIng.slice(0, 40) : [];
      const optionalIngredients = Array.isArray(rawOptIng) ? rawOptIng.slice(0, 20) : [];

      return {
        type,
        m: sanitizeMealInfo(parsed.m || parsed.meal),
        ing: ingredients.map((i: any) => sanitizeIngredient(i, true)).filter((i: any) => i.n),
        opt_ing: optionalIngredients.map((i: any) => sanitizeIngredient(i, false)).filter((i: any) => i.n),
        st: Array.isArray(rawSteps) ? rawSteps.slice(0, 15).map((step: any) => String(step).trim()) : [],
      };
    }

    case 'weekly_meal_plan': {
      const days = Array.isArray(parsed.days) ? parsed.days.slice(0, 7) : [];
      return {
        type,
        sum: typeof parsed.sum === 'string' ? parsed.sum : (typeof parsed.summary === 'string' ? parsed.summary : ''),
        days: days.map((d: any) => ({
          day: typeof d.day === 'string' ? d.day : '',
          meals: Array.isArray(d.meals) ? d.meals.slice(0, 5).map((m: any) => sanitizeDayMeal(m)).filter((m: any) => m.n) : [],
        })),
      };
    }

    case 'not_related':
      return { type: 'not_related', message: typeof parsed.message === 'string' ? parsed.message : getMessage('not_related_fallback', lang) };

    case 'pantry_based_meals': {
      const meals = Array.isArray(parsed.meals) ? parsed.meals.slice(0, 10) : [];
      return {
        type,
        sum: typeof parsed.sum === 'string' ? parsed.sum : (typeof parsed.summary === 'string' ? parsed.summary : ''),
        meals: meals.map((m: any) => ({
          n: safeStr(m.n || m.name, 100),
          d: safeStr(m.d || m.description, 300),
          df: safeStr(m.df || m.difficulty, 50),
          t: safeNum(m.t || m.estimatedTimeMinutes, 30),
          srv: safeNum(m.srv || m.servings, 4),
          cuisine: safeStr(m.cuisine, 50),
          av_ing: Array.isArray(m.av_ing || m.availableIngredients) ? (m.av_ing || m.availableIngredients).slice(0, 20) : [],
          mis_ing: Array.isArray(m.mis_ing || m.missingIngredients) ? (m.mis_ing || m.missingIngredients).slice(0, 20) : [],
          whyThisMeal: safeStr(m.whyThisMeal, 200),
          tags: Array.isArray(m.tags) ? m.tags.slice(0, 5) : [],
        })).filter((m: any) => m.n),
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

function sanitizeIngredient(s: any, required = true): any {
  if (!s || typeof s !== 'object') return { n: '' };

  return {
    k: safeStr(s.k || s.foodKey || s.food_key, 50) || undefined,
    n: safeStr(s.n || s.name, 100),
    q: safeNum(s.q ?? s.quantity, 1),
    u: safeStr(s.u || s.unit, 50) || undefined,
    category: safeStr(s.category, 50) || undefined,
    r: typeof s.r === 'boolean' ? s.r : (typeof s.required === 'boolean' ? s.required : required),
  };
}

function sanitizeMeal(m: any): any {
  if (!m || typeof m !== 'object') return { n: '' };
  const rawIng = m.ing || m.mainIngredients || [];
  let ingredients: any[] = [];
  if (Array.isArray(rawIng)) {
    if (rawIng.length > 0 && typeof rawIng[0] === 'object') {
      ingredients = rawIng.map((i: any) => sanitizeIngredient(i)).filter((i: any) => i.n);
    } else {
      ingredients = rawIng.map((i: any) => safeStr(i, 50)).filter((s: string) => s.length > 0);
    }
  }

  return {
    id: safeStr(m.id, 20) || undefined,
    n: safeStr(m.n || m.name, 100),
    d: safeStr(m.d || m.description, 300),
    df: safeStr(m.df || m.difficulty, 50),
    t: safeNum(m.t || m.estimatedTimeMinutes, 30),
    srv: safeNum(m.srv || m.servings, 4),
    mealType: safeStr(m.mealType, 30),
    cuisine: safeStr(m.cuisine, 50),
    budgetLevel: safeStr(m.budgetLevel, 20),
    ing: ingredients,
    st: Array.isArray(m.st || m.steps || m.cookingStepsPreview)
      ? (m.st || m.steps || m.cookingStepsPreview).slice(0, 15).map((step: any) => String(step).trim())
      : undefined,
    whyThisMeal: safeStr(m.whyThisMeal, 200),
    tags: Array.isArray(m.tags) ? m.tags.slice(0, 5).map((t: any) => safeStr(t, 30)) : [],
  };
}

function sanitizeMealInfo(meal: any): any {
  if (!meal) return { n: '', d: '', srv: 4, t: 30, df: '', cuisine: '' };
  return {
    n: safeStr(meal.n || meal.name, 100),
    d: safeStr(meal.d || meal.description, 300),
    srv: safeNum(meal.srv || meal.servings, 4),
    t: safeNum(meal.t || meal.estimatedTimeMinutes || meal.time, 30),
    df: safeStr(meal.df || meal.difficulty, 50),
    cuisine: safeStr(meal.cuisine, 50),
  };
}

function sanitizeDayMeal(m: any): any {
  if (!m || typeof m !== 'object') return { n: '' };
  return {
    n: safeStr(m.n || m.name, 100),
    mealType: safeStr(m.mealType, 30),
    d: safeStr(m.d || m.description, 300),
    ing: Array.isArray(m.ing || m.mainIngredients) ? (m.ing || m.mainIngredients).slice(0, 10).map((i: any) => safeStr(i, 50)) : [],
    t: safeNum(m.t || m.estimatedTimeMinutes, 30),
  };
}

const RATE_LIMIT_MAX = 10;       // max requests

async function checkRateLimitDB(
  admin: SupabaseClient,
  userId: string,
  endpoint: string,
  maxRequests: number,
  lang: string,
): Promise<Response | null> {
  const windowStart = new Date();
  windowStart.setSeconds(0, 0);

  const { data, error } = await admin.rpc("check_and_increment_rate_limit", {
    p_user_id: userId,
    p_endpoint: endpoint,
    p_window_start: windowStart.toISOString(),
    p_max_requests: maxRequests,
  });

  if (error) {
    console.error(JSON.stringify({ event: "rate_limit_rpc_failed", endpoint, error: error.message }));
    return new Response(
      JSON.stringify({
        type: 'error',
        error: 'Rate limit unavailable',
        message_ar: getMessage('api_error_fallback', lang),
      }),
      { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }

  if (data === false) {
    return new Response(
      JSON.stringify({
        type: 'error',
        error: 'Rate limit exceeded',
        message_ar: getMessage('rate_limit', lang),
      }),
      { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
  return null;
}

// --- Main Handler ---
Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  // Pre-parse language from req body clone for auth errors localization
  let reqLang = 'ar';
  try {
    const clone = req.clone();
    const body = await clone.json();
    if (body && body.language) {
      reqLang = body.language;
    }
  } catch (_) { }

  try {
    // Verify JWT
    const authResult = await requireUser(req, supabaseAdmin, reqLang);
    if ("response" in authResult) {
      return authResult.response;
    }

    // Rate limiting
    const rateLimitError = await checkRateLimitDB(
      supabaseAdmin,
      authResult.user.id,
      'generate-shopping-suggestions',
      RATE_LIMIT_MAX,
      reqLang,
    );
    if (rateLimitError) return rateLimitError;

    const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY");

    if (!DEEPSEEK_API_KEY) {
      console.error(JSON.stringify({ event: "deepseek_config_missing" }));
      return new Response(
        JSON.stringify({ type: 'error', error: "Configuration Error", message_ar: getMessage('config_error', reqLang) }),
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
      user_terms, userTerms,
      country, dialect,
      // Legacy support
      prompt: legacyPrompt, existingItems: legacyExistingItems,
    } = body;

    // Support legacy mode (old clients sending prompt instead of userPrompt)
    const effectiveMode = mode || 'shopping_suggestions';
    const effectivePrompt = userPrompt || legacyPrompt || '';
    const effectiveLanguage = language || 'ar';
    const effectiveExistingItems = existingShoppingItems || legacyExistingItems || [];
    const effectiveUserTerms = user_terms || userTerms || {};

    // Validation
    if (!effectivePrompt || typeof effectivePrompt !== 'string' || effectivePrompt.trim().length === 0) {
      return new Response(
        JSON.stringify({ type: 'error', error: "Empty prompt", message_ar: getMessage('empty_prompt', effectiveLanguage) }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (effectivePrompt.length > 500) {
      return new Response(
        JSON.stringify({ type: 'error', error: "Prompt exceeds 500 characters", message_ar: getMessage('prompt_too_long', effectiveLanguage) }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (effectiveLanguage !== 'ar' && effectiveLanguage !== 'en' && effectiveLanguage !== 'tr') {
      return new Response(
        JSON.stringify({ type: 'error', error: "Invalid language", message_ar: getMessage('invalid_language', effectiveLanguage) }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!VALID_MODES.includes(effectiveMode)) {
      return new Response(
        JSON.stringify({ type: 'error', error: "Invalid mode", message_ar: getMessage('invalid_mode', effectiveLanguage) }),
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
      country: safeStr(country, 10),
      dialect: safeStr(dialect, 50),
    };

    // Verify the user has access to active home before continuing
    const homeIdHeader = req.headers.get("x-home-id") || body.homeId || body.home_id;
    if (!homeIdHeader) {
      return new Response(
        JSON.stringify({ type: 'error', error: "Missing homeId", message_ar: "معرف المنزل مفقود" }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const membershipError = await requireActiveHomeMember(supabaseAdmin, homeIdHeader, authResult.user.id, effectiveLanguage);
    if (membershipError) {
      return membershipError;
    }

    const listId = body.listId || body.list_id;
    if (listId) {
      const { data: listData, error: listError } = await supabaseAdmin
        .from('shopping_lists')
        .select('home_id')
        .eq('id', listId)
        .single();

      if (listError || !listData || listData.home_id !== homeIdHeader) {
         return new Response(
          JSON.stringify({ type: 'error', error: "Invalid listId or homeId mismatch", message_ar: "القائمة غير صالحة أو لا تنتمي لهذا المنزل" }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    const systemPrompt = buildSystemPrompt(effectiveMode, context, effectiveLanguage, effectiveUserTerms);

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
          max_tokens: 5000,
          temperature: 0.7,
        })
      }
    ).finally(() => clearTimeout(timeoutId));

    if (!response.ok) {
      const errTxt = await response.text();
      console.error(JSON.stringify({ event: "deepseek_api_error", status: response.status }));
      let apiErrorMessage = getMessage('api_error_fallback', effectiveLanguage);
      try {
        const errJson = JSON.parse(errTxt);
        apiErrorMessage = errJson.error?.message || apiErrorMessage;
      } catch (_) { }

      return new Response(
        JSON.stringify({
          type: 'error',
          error: apiErrorMessage,
          message_ar: getMessage('ai_provider_error', effectiveLanguage).replace('{error}', apiErrorMessage)
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const result = await response.json();

    // Check for API-specific errors in response payload
    if (result.error) {
      console.error(JSON.stringify({ event: "ai_provider_error", error: result.error.message || "unknown" }));
      return new Response(
        JSON.stringify({
          type: 'error',
          error: result.error.message || "Model error",
          message_ar: getMessage('provider_busy', effectiveLanguage)
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!result.choices || result.choices.length === 0 || !result.choices[0].message) {
      console.error(JSON.stringify({ event: "ai_empty_choices" }));
      return new Response(
        JSON.stringify({
          type: 'error',
          error: "Empty response from model",
          message_ar: getMessage('empty_ai_response', effectiveLanguage)
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    let parsed: any;
    try {
      const message = result.choices[0].message;
      if (message.refusal) {
        throw new Error("Model refused the request: " + message.refusal);
      }
      const content = message.content || "";
      if (!content) throw new Error("Empty content");

      // Robust JSON extraction: find the first '{' and the last '}'
      const firstBrace = content.indexOf('{');
      const lastBrace = content.lastIndexOf('}');

      if (firstBrace === -1 || lastBrace === -1) {
        throw new Error("No JSON object found in response");
      }

      let jsonStr = content.substring(firstBrace, lastBrace + 1);
      // Clean up common LLM JSON syntax anomalies
      jsonStr = jsonStr.replace(/,(\s*[\]}])/g, '$1'); // Trailing commas
      parsed = JSON.parse(jsonStr);
    } catch (e) {
      console.error(JSON.stringify({ event: "ai_json_parse_failed", error: e instanceof Error ? e.message : String(e) }));

      return new Response(
        JSON.stringify({
          type: 'error',
          error: "Invalid JSON format from AI: " + String(e),
          message_ar: getMessage('json_parse_error', effectiveLanguage)
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate and sanitize the response
    const sanitized = validateAndSanitizeResponse(parsed, effectiveLanguage);

    // Legacy compatibility: if old client expects "suggestions" array at root
    if (effectiveMode === 'shopping_suggestions' && sanitized.type === 'shopping_suggestions') {
      return new Response(
        JSON.stringify({ ...sanitized, suggestions: sanitized.sug }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify(sanitized),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error(JSON.stringify({ event: "shopping_suggestions_unhandled", error: err instanceof Error ? err.message : String(err) }));
    return new Response(
      JSON.stringify({
        type: 'error',
        error: err instanceof Error ? err.message : "Unexpected error",
        message_ar: getMessage('unexpected_error', reqLang)
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

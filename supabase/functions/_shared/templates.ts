// Notification content templates for Beity Backend
export interface NotificationTemplate {
  title: string;
  body: string;
}

export const templates: Record<string, Record<string, NotificationTemplate>> = {
  ar: {
    item_added: { 
      title: "{actor} أضاف {item}", 
      body: "{actor} أضاف {item} إلى {list}" 
    },
    item_completed: { 
      title: "{actor} اشترى {item}", 
      body: "{actor} وضع علامة شراء على {item} في {list}" 
    },
    item_updated: { 
      title: "{actor} حدّث {item}", 
      body: "{actor} حدّث {item} في {list}" 
    },
    member_joined: { 
      title: "عضو جديد انضم للمنزل", 
      body: "{actor} انضم إلى {home}" 
    },
    invitation_received: { 
      title: "دعوة انضمام جديدة", 
      body: "تمت دعوتك للانضمام إلى {home} بواسطة {actor}" 
    },
  },
  en: {
    item_added: { 
      title: "{actor} added {item}", 
      body: "{actor} added {item} to {list}" 
    },
    item_completed: { 
      title: "{actor} purchased {item}", 
      body: "{actor} marked {item} as purchased in {list}" 
    },
    item_updated: { 
      title: "{actor} updated {item}", 
      body: "{actor} updated {item} in {list}" 
    },
    member_joined: { 
      title: "New member joined", 
      body: "{actor} joined {home}" 
    },
    invitation_received: { 
      title: "New invitation", 
      body: "You've been invited to join {home} by {actor}" 
    },
  },
  tr: {
    item_added: { 
      title: "{actor}, {item} ekledi", 
      body: "{actor}, {list} listesine {item} ekledi" 
    },
    item_completed: { 
      title: "{actor}, {item} satın aldı", 
      body: "{actor}, {list} listesinde {item} ürününü satın alındı olarak işaretledi" 
    },
    item_updated: { 
      title: "{actor}, {item} güncelledi", 
      body: "{actor}, {list} listesinde {item} ürününü güncelledi" 
    },
    member_joined: { 
      title: "Yeni üye katıldı", 
      body: "{actor}, {home} evine katıldı" 
    },
    invitation_received: { 
      title: "Yeni davet", 
      body: "{actor} sizi {home} evine davet etti" 
    },
  },
};

// General system messages and AI Suggestion API validation error messages
export const suggestionMessages: Record<string, Record<string, string>> = {
  ar: {
    missing_auth: "مطلوب مصادقة",
    invalid_auth: "رمز المصادقة غير صالح",
    access_denied: "مرفوض",
    config_error: "مفتاح DeepSeek غير مفعّل حاليًا",
    empty_prompt: "اكتب ما تريد اقتراحه أولًا",
    prompt_too_long: "النص طويل جدًا (الحد الأقصى 500 حرف)",
    invalid_language: "اللغة غير مدعومة",
    invalid_mode: "الوضع غير مدعوم",
    unrelated_topic: "عذراً، يمكنني مساعدتك فقط في أمور الطبخ والمقاضي وإدارة المنزل.",
    clarifying_question: "توضيح بسيط لاستكمال الطلب",
    option_1: "عشاء رومانسي إيطالي",
    option_2: "كبسة سعودية سريعة",
    option_3: "أفكار فطور صحي للأطفال",
    not_related_fallback: "هذا الطلب خارج تخصصي.",
    provider_busy: "مزود الذكاء الاصطناعي مشغول حالياً، يرجى المحاولة بعد قليل.",
    empty_ai_response: "تعذر الحصول على إجابة من المساعد، حاول مرة أخرى.",
    json_parse_error: "حدث خطأ في معالجة إجابة المساعد، قد يكون ذلك بسبب أن القائمة المطلوبة طويلة جداً. يرجى محاولة تقسيم الطلب.",
    unexpected_error: "حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.",
    api_error_fallback: "تعذر إنشاء الاقتراحات، حاول مرة أخرى",
    ai_provider_error: "خطأ من مزود الذكاء الاصطناعي: {error}",
    rate_limit: "لقد تجاوزت الحد الأقصى للطلبات. يرجى الانتظار دقيقة واحدة.",
  },
  en: {
    missing_auth: "Authentication required",
    invalid_auth: "Invalid authentication token",
    access_denied: "Access denied",
    config_error: "DeepSeek API key is not currently activated",
    empty_prompt: "Please write what you want to suggest first",
    prompt_too_long: "Text is too long (maximum 500 characters)",
    invalid_language: "Language not supported",
    invalid_mode: "Mode not supported",
    unrelated_topic: "Sorry, I can only help you with cooking, groceries, and home management.",
    clarifying_question: "A simple clarification to complete your request",
    option_1: "Romantic Italian dinner",
    option_2: "Quick Saudi Kabsa",
    option_3: "Healthy breakfast ideas for kids",
    not_related_fallback: "This request is outside my specialty.",
    provider_busy: "AI provider is currently busy, please try again shortly.",
    empty_ai_response: "Could not get an answer from the assistant, please try again.",
    json_parse_error: "An error occurred while processing the assistant's response. This may be because the requested list is too long. Please try splitting your request.",
    unexpected_error: "An unexpected error occurred. Please try again later.",
    api_error_fallback: "Could not generate suggestions, please try again",
    ai_provider_error: "Error from AI provider: {error}",
    rate_limit: "You have exceeded the request limit. Please wait a minute.",
  },
  tr: {
    missing_auth: "Kimlik doğrulaması gerekli",
    invalid_auth: "Geçersiz kimlik doğrulama belirteci",
    access_denied: "Erişim reddedildi",
    config_error: "DeepSeek API anahtarı şu anda etkinleştirilmemiş",
    empty_prompt: "Lütfen önce ne önermek istediğinizi yazın",
    prompt_too_long: "Metin çok uzun (en fazla 500 karakter)",
    invalid_language: "Dil desteklenmiyor",
    invalid_mode: "Mod desteklenmiyor",
    unrelated_topic: "Üzgünüm, size sadece yemek pişirme, market alışverişi ve ev yönetimi konularında yardımcı olabilirim.",
    clarifying_question: "Talebi tamamlamak için küçük bir açıklama",
    option_1: "Romantik İtalyan yemeği",
    option_2: "Pratik Suudi Kabsası",
    option_3: "Çocuklar için sağlıklı kahvaltı fikirleri",
    not_related_fallback: "Bu talep benim uzmanlık alanımın dışındadır.",
    provider_busy: "Yapay zeka sağlayıcısı şu anda meşgul, lütfen biraz sonra tekrar deneyin.",
    empty_ai_response: "Asistandan yanıt alınamadı, lütfen tekrar deneyin.",
    json_parse_error: "Asistan yanıtı işlenirken bir hata oluştu. Bunun nedeni istenen listenin çok uzun olması olabilir, lütfen talebinizi bölmeyi deneyin.",
    unexpected_error: "Beklenmedik bir hata oluştu. Lütfen daha sonra tekrar deneyin.",
    api_error_fallback: "Öneriler oluşturulamadı, lütfen tekrar deneyin",
    ai_provider_error: "Yapay zeka sağlayıcı hatası: {error}",
    rate_limit: "İstek limitini aştınız. Lütfen bir dakika bekleyin.",
  },
};

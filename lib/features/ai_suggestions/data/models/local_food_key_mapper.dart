/// Represents the result of matching an ingredient name to a standardized food key.
class FoodKeyMatch {
  final String foodKey;
  final double confidence;
  final String
  method; // 'exact' | 'synonym' | 'normalized' | 'partial' | 'similarity' | 'unknown'

  const FoodKeyMatch({
    required this.foodKey,
    required this.confidence,
    required this.method,
  });

  @override
  String toString() =>
      'FoodKeyMatch(key: $foodKey, confidence: $confidence, method: $method)';
}

/// Helper class to map open ingredient names into standardized stable snake_case food keys.
class LocalFoodKeyMapper {
  // Pre-compiled stable mappings of common kitchen ingredients to their food keys
  static const Map<String, String> _synonymsMap = {
    // Tomato
    'tomato': 'tomato',
    'tomatoes': 'tomato',
    'طماطم': 'tomato',
    'بندورة': 'tomato',
    'طماطه': 'tomato',
    'طماطة': 'tomato',
    'domates': 'tomato',

    // Chicken
    'chicken': 'chicken',
    'دجاج': 'chicken',
    'دجاجه': 'chicken',
    'فرخة': 'chicken',
    'tavuk': 'chicken',

    // Rice
    'rice': 'rice_basmati',
    'pirinç': 'rice_basmati',
    'أرز': 'rice_basmati',
    'رز': 'rice_basmati',
    'أرز بسمتي': 'rice_basmati',
    'رز بسمتي': 'rice_basmati',

    // Onion
    'onion': 'onion',
    'onions': 'onion',
    'بصل': 'onion',
    'soğan': 'onion',

    // Garlic
    'garlic': 'garlic',
    'ثوم': 'garlic',
    'sarımsak': 'garlic',

    // Milk
    'milk': 'milk',
    'حليب': 'milk',
    'لبن': 'milk',
    'süt': 'milk',

    // Egg
    'egg': 'egg',
    'eggs': 'egg',
    'بيض': 'egg',
    'بيضة': 'egg',
    'yumurta': 'egg',

    // Potato
    'potato': 'potato',
    'potatoes': 'potato',
    'بطاطس': 'potato',
    'بطاطا': 'potato',
    'patates': 'potato',

    // Cucumber
    'cucumber': 'cucumber',
    'cucumbers': 'cucumber',
    'خيار': 'cucumber',
    'salatalık': 'cucumber',

    // Yogurt
    'yogurt': 'yogurt',
    'زبادي': 'yogurt',
    'yoğurt': 'yogurt',

    // Mint
    'mint': 'mint',
    'نعناع': 'mint',
    'nane': 'mint',

    // Lemon
    'lemon': 'lemon',
    'lemons': 'lemon',
    'ليمون': 'lemon',
    'limon': 'lemon',

    // Beef/Meat
    'beef': 'beef',
    'meat': 'beef',
    'لحم': 'beef',
    'لحمة': 'beef',
    'et': 'beef',

    // Water
    'water': 'water',
    'ماء': 'water',
    'مياه': 'water',
    'su': 'water',

    // Salt
    'salt': 'salt',
    'ملح': 'salt',
    'tuz': 'salt',

    // Pepper
    'pepper': 'black_pepper',
    'black pepper': 'black_pepper',
    'فلفل': 'black_pepper',
    'فلفل أسود': 'black_pepper',
    'فلفل اسود': 'black_pepper',
    'biber': 'black_pepper',

    // Sugar
    'sugar': 'sugar',
    'سكر': 'sugar',
    'şeker': 'sugar',

    // Olive Oil
    'oil': 'olive_oil',
    'olive oil': 'olive_oil',
    'زيت': 'olive_oil',
    'زيت زيتون': 'olive_oil',
    'yağ': 'olive_oil',

    // Butter
    'butter': 'butter',
    'زبدة': 'butter',
    'tereyağı': 'butter',

    // Cheese
    'cheese': 'cheese',
    'جبن': 'cheese',
    'جبنة': 'cheese',
    'peynir': 'cheese',

    // Flour
    'flour': 'flour',
    'دقيق': 'flour',
    'طحين': 'flour',
    'un': 'flour',
  };

  /// Normalizes the input text by lowering, removing diacritics, and standardization.
  static String normalize(String text) {
    var s = text.toLowerCase().trim();
    // Remove Arabic diacritics (tashkeel)
    s = s.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    // Normalize Arabic letters
    s = s.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
    s = s.replaceAll('ة', 'ه').replaceAll('ى', 'ي');
    // Remove common descriptive stop words that skew food key matching
    final stopwords = [
      'جرام',
      'كوب',
      'ملعقة',
      'كيس',
      'علبة',
      'حبة',
      'قطع',
      'قطعة',
      'كيلو',
      'حبات',
      'مفروم',
      'مقطع',
      'طازج',
      'ناعم',
      'ملح',
      'فلفل',
      'بهارات',
      'ماء',
      'زيت',
      'chopped',
      'sliced',
      'fresh',
      'ground',
      'powder',
      'grams',
      'kg',
      'cup',
      'cups',
      'spoon',
      'spoons',
    ];
    for (final word in stopwords) {
      s = s.replaceAll(word, '');
    }
    // Clean non-word characters and compact extra spaces
    s = s.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Normalizes raw AI-generated keys to ensure they correspond to generic keys.
  static String normalizeFoodKey(String aiKey) {
    final cleaned = aiKey.toLowerCase().trim().replaceAll(' ', '_');
    if (cleaned == 'tomatoes') {
      return 'tomato';
    }
    if (cleaned == 'fresh_tomato' ||
        cleaned == 'red_tomato' ||
        cleaned == 'fresh_red_tomatoes') {
      return 'tomato';
    }
    if (cleaned == 'rice' ||
        cleaned == 'white_rice' ||
        cleaned == 'basmati_rice') {
      return 'rice_basmati';
    }
    if (cleaned == 'onions') {
      return 'onion';
    }
    if (cleaned == 'eggs') {
      return 'egg';
    }
    if (cleaned == 'potatoes') {
      return 'potato';
    }
    if (cleaned == 'cucumbers') {
      return 'cucumber';
    }
    if (cleaned == 'lemons') {
      return 'lemon';
    }
    if (cleaned == 'black_pepper' || cleaned == 'pepper') {
      return 'black_pepper';
    }
    if (cleaned == 'olive_oil' || cleaned == 'cooking_oil') {
      return 'olive_oil';
    }
    return cleaned;
  }

  /// Evaluates the match of a given name against the standard dictionary.
  static FoodKeyMatch match(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) {
      return const FoodKeyMatch(
        foodKey: 'unknown',
        confidence: 0.0,
        method: 'unknown',
      );
    }

    // 1. Exact check on raw value (ignoring casing)
    final loweredName = name.toLowerCase();
    if (_synonymsMap.containsKey(loweredName)) {
      return FoodKeyMatch(
        foodKey: _synonymsMap[loweredName]!,
        confidence: 1.0,
        method: 'exact',
      );
    }

    // 2. Normalized check
    final normName = normalize(name);
    if (_synonymsMap.containsKey(normName)) {
      return FoodKeyMatch(
        foodKey: _synonymsMap[normName]!,
        confidence: 0.95,
        method: 'normalized',
      );
    }

    // 3. Synonym matching on normalized substrings
    for (final entry in _synonymsMap.entries) {
      final normKeyName = normalize(entry.key);
      if (normKeyName.isNotEmpty &&
          (normName == normKeyName ||
              normName.contains(normKeyName) ||
              normKeyName.contains(normName))) {
        return FoodKeyMatch(
          foodKey: entry.value,
          confidence: 0.85,
          method: 'synonym',
        );
      }
    }

    // 4. String similarity as a fallback using Dice's coefficient
    String bestKey = '';
    double bestScore = 0.0;
    for (final entry in _synonymsMap.entries) {
      final score = _diceCoefficient(normName, normalize(entry.key));
      if (score > bestScore) {
        bestScore = score;
        bestKey = entry.value;
      }
    }

    // Rule: confidence threshold of 0.75
    if (bestScore >= 0.75) {
      return FoodKeyMatch(
        foodKey: bestKey,
        confidence: bestScore,
        method: 'similarity',
      );
    }

    // Low confidence: generate a fallback customized key or return unknown
    return FoodKeyMatch(
      foodKey: 'custom:${normName.replaceAll(' ', '_')}',
      confidence: 0.3,
      method: 'unknown',
    );
  }

  /// Calculates Dice's coefficient similarity between two strings.
  static double _diceCoefficient(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.length < 2 || str2.length < 2) return 0.0;

    final Map<String, int> profile1 = _getBigramMap(str1);
    final Map<String, int> profile2 = _getBigramMap(str2);

    int intersection = 0;
    for (final token in profile1.keys) {
      if (profile2.containsKey(token)) {
        intersection += (profile1[token]! < profile2[token]!)
            ? profile1[token]!
            : profile2[token]!;
      }
    }

    final int totalBigrams =
        _getBigramsCount(profile1) + _getBigramsCount(profile2);
    if (totalBigrams == 0) return 0.0;
    return (2.0 * intersection) / totalBigrams;
  }

  static Map<String, int> _getBigramMap(String str) {
    final Map<String, int> bigrams = {};
    for (int i = 0; i < str.length - 1; i++) {
      final bigram = str.substring(i, i + 2);
      bigrams[bigram] = (bigrams[bigram] ?? 0) + 1;
    }
    return bigrams;
  }

  static int _getBigramsCount(Map<String, int> profile) {
    int sum = 0;
    for (final count in profile.values) {
      sum += count;
    }
    return sum;
  }
}

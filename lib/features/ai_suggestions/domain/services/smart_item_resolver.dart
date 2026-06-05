import 'dart:math' as math;

import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/entities/unit.dart';
import '../../../shopping_lists/domain/entities/item_template.dart';
import '../entities/ai_recipe_ingredient.dart';

class SmartItemResolution {
  final String? categoryId;
  final String? unitId;
  final double categoryConfidence;
  final double unitConfidence;
  final String? matchedCategoryName;
  final String? matchedUnitName;
  final String matchSource;
  final List<String> reasons;

  const SmartItemResolution({
    this.categoryId,
    this.unitId,
    this.categoryConfidence = 0,
    this.unitConfidence = 0,
    this.matchedCategoryName,
    this.matchedUnitName,
    this.matchSource = 'none',
    this.reasons = const [],
  });
}

class CategoryRule {
  final String key;
  final List<String> categoryAliases;
  final List<String> keywords;
  final List<String> strongPhrases;
  final List<String> ambiguousKeywords;

  const CategoryRule({
    required this.key,
    required this.categoryAliases,
    required this.keywords,
    this.strongPhrases = const [],
    this.ambiguousKeywords = const [],
  });
}

class UnitRule {
  final String key;
  final UnitType type;
  final List<String> aliases;

  const UnitRule({
    required this.key,
    required this.type,
    required this.aliases,
  });
}

class MatchScore implements Comparable<MatchScore> {
  final String key;
  final String? id;
  final String? matchedName;
  final double score;
  final double confidence;
  final String source;
  final List<String> reasons;

  const MatchScore({
    required this.key,
    this.id,
    this.matchedName,
    required this.score,
    required this.confidence,
    required this.source,
    this.reasons = const [],
  });

  @override
  int compareTo(MatchScore other) => score.compareTo(other.score);
}

class SmartItemResolver {
  static const double minimumCategoryConfidence = 0.45;
  static const double minimumUnitConfidence = 0.45;
  static const double _minimumTemplateConfidence = 0.78;
  static const double _minimumLocalCategoryConfidence = 0.42;
  static const double _minimumLocalUnitConfidence = 0.42;

  static SmartItemResolution resolve({
    required AiRecipeIngredient ingredient,
    required List<ItemTemplate> templates,
    required List<Category> categories,
    required List<Unit> units,
  }) {
    final itemName = ingredient.displayName ?? ingredient.name;
    final reasons = <String>[];

    final templateMatch = _matchTemplate(ingredient, templates);
    if (templateMatch != null) {
      reasons.addAll(templateMatch.reasons);
    }

    final categoryIntent = _resolveCategoryIntent(ingredient);
    final categoryRule = categoryIntent == null
        ? null
        : _categoryRulesByKey[categoryIntent.key];

    MatchScore? categoryMatch;
    if (categoryIntent != null &&
        categoryIntent.confidence >= minimumCategoryConfidence) {
      categoryMatch = _matchUserCategory(
        rule: _categoryRulesByKey[categoryIntent.key]!,
        categories: categories,
        intentConfidence: categoryIntent.confidence,
      );
      reasons.addAll(categoryIntent.reasons);
      if (categoryMatch == null) {
        reasons.add(
          'لم يتم العثور على تصنيف محلي مناسب لـ ${categoryIntent.key}.',
        );
      } else {
        reasons.addAll(categoryMatch.reasons);
      }
    } else {
      reasons.add('ثقة التصنيف أقل من الحد المطلوب للعنصر "$itemName".');
    }

    final unitIntent = _resolveUnitIntent(
      ingredient: ingredient,
      categoryRule: categoryRule,
    );
    MatchScore? unitMatch;
    if (unitIntent != null && unitIntent.confidence >= minimumUnitConfidence) {
      unitMatch = _matchUserUnit(
        desiredKeys: [unitIntent.key],
        units: units,
        sourceConfidence: unitIntent.confidence,
        source: unitIntent.source,
      );

      if (unitMatch == null && unitIntent.source == 'fallback_unit') {
        final fallbacks = _fallbackUnitKeysFor(ingredient, categoryRule);
        unitMatch = _matchUserUnit(
          desiredKeys: fallbacks,
          units: units,
          sourceConfidence: unitIntent.confidence,
          source: unitIntent.source,
        );
      }

      reasons.addAll(unitIntent.reasons);
      if (unitMatch == null) {
        reasons.add(
          'لم يتم العثور على وحدة محلية مناسبة لـ ${unitIntent.key}.',
        );
      } else {
        reasons.addAll(unitMatch.reasons);
      }
    } else {
      reasons.add('لم يتم تحديد وحدة آمنة للعنصر "$itemName".');
    }

    final templateCategoryId = templateMatch?.source == 'template'
        ? _templateById(templateMatch!.id, templates)?.defaultCategoryId
        : null;
    final templateUnitId = templateMatch?.source == 'template'
        ? _templateById(templateMatch!.id, templates)?.defaultUnitId
        : null;

    final categoryId = templateCategoryId ?? categoryMatch?.id;
    final unitId = templateUnitId ?? unitMatch?.id;
    final matchedCategoryName =
        _categoryNameById(categories, categoryId) ??
        (templateCategoryId == null ? categoryMatch?.matchedName : null);
    final matchedUnitName =
        _unitNameById(units, unitId) ??
        (templateUnitId == null ? unitMatch?.matchedName : null);

    final categoryConfidence = templateCategoryId != null
        ? templateMatch!.confidence
        : categoryMatch?.confidence ?? 0;
    final unitConfidence = templateUnitId != null
        ? templateMatch!.confidence
        : unitMatch?.confidence ?? 0;

    final sourceParts = <String>{
      if (templateMatch != null) 'template',
      if (categoryMatch != null) categoryMatch.source,
      if (unitMatch != null) unitMatch.source,
    };

    return SmartItemResolution(
      categoryId: categoryId,
      unitId: unitId,
      categoryConfidence: _roundConfidence(categoryConfidence),
      unitConfidence: _roundConfidence(unitConfidence),
      matchedCategoryName: matchedCategoryName,
      matchedUnitName: matchedUnitName,
      matchSource: sourceParts.isEmpty ? 'none' : sourceParts.join('+'),
      reasons: _dedupe(reasons),
    );
  }

  static String normalize(String value) {
    var text = value.trim().toLowerCase();
    if (text.isEmpty) return '';

    const replacements = <String, String>{
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ٱ': 'ا',
      'ؤ': 'و',
      'ئ': 'ي',
      'ء': '',
      'ة': 'ه',
      'ى': 'ي',
      'ک': 'ك',
      'ی': 'ي',
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    text = text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll(RegExp(r'([a-z\u0621-\u064A])([0-9])'), r'$1 $2')
        .replaceAll(RegExp(r'([0-9])([a-z\u0621-\u064A])'), r'$1 $2')
        .replaceAll(RegExp(r'[^a-z0-9\u0621-\u064A]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return text;
  }

  static List<String> tokenize(
    String value, {
    bool forCategory = false,
    bool removeSoftStopwords = true,
  }) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return const [];

    final stopwords = <String>{
      if (removeSoftStopwords) ..._softStopwords,
      if (forCategory) ..._measurementStopwords,
    };

    return normalized
        .split(' ')
        .where((token) => token.isNotEmpty && !stopwords.contains(token))
        .toList();
  }

  static MatchScore? _matchTemplate(
    AiRecipeIngredient ingredient,
    List<ItemTemplate> templates,
  ) {
    if (templates.isEmpty) return null;

    final itemName = ingredient.displayName ?? ingredient.name;
    final itemNormalized = normalize(itemName);
    final itemTokens = tokenize(itemName, forCategory: true).toSet();
    if (itemNormalized.isEmpty || itemTokens.isEmpty) return null;

    MatchScore? best;
    for (final template in templates) {
      final templateNormalized = normalize(template.name);
      final templateTokens = tokenize(template.name, forCategory: true).toSet();
      if (templateNormalized.isEmpty || templateTokens.isEmpty) continue;

      var score = 0.0;
      final reasons = <String>[];

      if (templateNormalized == itemNormalized) {
        score += 18;
        reasons.add(
          'تمت مطابقة القالب المحلي "${template.name}" بالاسم الكامل.',
        );
      } else if (_shareProductSynonymGroup(itemTokens, templateTokens)) {
        score += 16;
        reasons.add(
          'تمت مطابقة القالب المحلي "${template.name}" عبر مرادف قوي.',
        );
      } else {
        final overlap = _jaccard(itemTokens, templateTokens);
        if (overlap >= 0.86) {
          score += 15;
          reasons.add(
            'تمت مطابقة القالب المحلي "${template.name}" بتشابه عال.',
          );
        } else if (_containsNormalizedPhrase(
              itemNormalized,
              templateNormalized,
            ) ||
            _containsNormalizedPhrase(templateNormalized, itemNormalized)) {
          score += 12;
          reasons.add(
            'تمت مطابقة القالب المحلي "${template.name}" باحتواء الاسم.',
          );
        }
      }

      if (score == 0) continue;
      score += math.min(template.usageCount * 0.2, 2);

      final confidence = _clamp(score / 18);
      final candidate = MatchScore(
        key: 'template',
        id: template.id,
        matchedName: template.name,
        score: score,
        confidence: confidence,
        source: 'template',
        reasons: reasons,
      );

      if (best == null || candidate.score > best.score) {
        best = candidate;
      }
    }

    if (best == null || best.confidence < _minimumTemplateConfidence) {
      return null;
    }
    return best;
  }

  static MatchScore? _resolveCategoryIntent(AiRecipeIngredient ingredient) {
    final textParts = [
      ingredient.displayName,
      ingredient.name,
      ingredient.category,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

    final normalizedText = normalize(textParts);
    final tokens = tokenize(textParts, forCategory: true);
    if (normalizedText.isEmpty || tokens.isEmpty) return null;

    final tokenSet = tokens.toSet();
    final candidates = <MatchScore>[];

    for (final rule in _categoryRules) {
      var score = 0.0;
      final reasons = <String>[];

      // Strong phrases handle multi-word products like dish soap, baby wipes,
      // office paper, and sports shoes before broad single-word keywords.
      for (final phrase in rule.strongPhrases) {
        final phraseTokens = tokenize(phrase, forCategory: true);
        if (phraseTokens.isEmpty) continue;
        final phraseNormalized = normalize(phrase);

        if (normalizedText == phraseNormalized) {
          score += 14;
          reasons.add('تطابق كامل مع عبارة "$phrase" ضمن قاعدة ${rule.key}.');
        } else if (_containsTokenPhrase(tokens, phraseTokens)) {
          score += 12;
          reasons.add('تطابق عبارة "$phrase" ضمن قاعدة ${rule.key}.');
        } else if (_containsNormalizedPhrase(
          normalizedText,
          phraseNormalized,
        )) {
          score += 3;
          reasons.add('تطابق جزئي مع عبارة "$phrase" ضمن قاعدة ${rule.key}.');
        }
      }

      for (final keyword in rule.keywords) {
        final keywordTokens = tokenize(keyword, forCategory: true);
        if (keywordTokens.isEmpty) continue;
        final keywordNormalized = normalize(keyword);

        if (keywordTokens.length == 1 &&
            tokenSet.contains(keywordTokens.first)) {
          score += 10;
          reasons.add('تطابق كلمة "$keyword" ضمن قاعدة ${rule.key}.');
        } else if (_containsTokenPhrase(tokens, keywordTokens)) {
          score += 7;
          reasons.add('تطابق مرادف/عبارة "$keyword" ضمن قاعدة ${rule.key}.');
        } else if (keywordNormalized.length > 2 &&
            _containsNormalizedPhrase(normalizedText, keywordNormalized)) {
          score += 3;
          reasons.add('تطابق جزئي مع "$keyword" ضمن قاعدة ${rule.key}.');
        }
      }

      for (final alias in rule.categoryAliases) {
        final aliasTokens = tokenize(alias, forCategory: true);
        if (aliasTokens.isEmpty) continue;
        if (_containsTokenPhrase(tokens, aliasTokens)) {
          score += 5;
          reasons.add('تطابق اسم تصنيف مقترح "$alias" ضمن قاعدة ${rule.key}.');
        }
      }

      final ambiguityPenalty = _ambiguityPenalty(rule, tokenSet);
      if (ambiguityPenalty > 0) {
        score -= ambiguityPenalty;
        reasons.add('تم تخفيض الثقة بسبب كلمة مشتركة بين أكثر من تصنيف.');
      }

      score += _contextBoost(rule, tokenSet, normalizedText);

      if (score <= 0) continue;
      candidates.add(
        MatchScore(
          key: rule.key,
          score: score,
          confidence: _clamp(score / 22),
          source: 'smart_category',
          reasons: reasons,
        ),
      );
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.score.compareTo(a.score));

    final best = candidates.first;
    final second = candidates.length > 1 ? candidates[1] : null;
    if (second != null &&
        best.score - second.score < 4 &&
        second.confidence >= 0.38) {
      final confidence = _clamp((best.score - 3) / 22);
      return MatchScore(
        key: best.key,
        score: best.score - 3,
        confidence: confidence,
        source: best.source,
        reasons: [
          ...best.reasons,
          'النتيجة قريبة من تصنيف آخر؛ تم تخفيض الثقة لتجنب اختيار عشوائي.',
        ],
      );
    }

    return best;
  }

  static MatchScore? _matchUserCategory({
    required CategoryRule rule,
    required List<Category> categories,
    required double intentConfidence,
  }) {
    if (categories.isEmpty) return null;

    MatchScore? best;
    final aliases = rule.categoryAliases
        .map(normalize)
        .where((a) => a.isNotEmpty)
        .toList();

    for (final category in categories) {
      if (category.type != CategoryType.shopping) continue;

      final categoryName = normalize(category.name);
      final categoryTokens = tokenize(category.name, forCategory: true).toSet();
      if (categoryName.isEmpty || categoryTokens.isEmpty) continue;

      var score = 0.0;
      final reasons = <String>[];

      for (final alias in aliases) {
        final aliasTokens = alias
            .split(' ')
            .where((token) => token.isNotEmpty)
            .toSet();
        if (aliasTokens.isEmpty) continue;

        if (categoryName == alias) {
          score += 12;
          reasons.add('تصنيف المستخدم "${category.name}" يطابق "$alias".');
        } else if (_containsNormalizedPhrase(categoryName, alias) ||
            _containsNormalizedPhrase(alias, categoryName)) {
          score += 6;
          reasons.add('تصنيف المستخدم "${category.name}" قريب من "$alias".');
        }

        final similarity = _jaccard(categoryTokens, aliasTokens);
        if (similarity >= 0.5) {
          score += 5 * similarity;
        } else if (categoryTokens.intersection(aliasTokens).isNotEmpty) {
          score += 2;
        }
      }

      if (category.isDefault) score += 0.5;
      if (score <= 0) continue;

      final localConfidence = _clamp(score / 14);
      final combinedConfidence = math.min(intentConfidence, localConfidence);
      final candidate = MatchScore(
        key: rule.key,
        id: category.id,
        matchedName: category.name,
        score: score,
        confidence: combinedConfidence,
        source: 'smart_category',
        reasons: reasons,
      );

      if (best == null || candidate.score > best.score) {
        best = candidate;
      }
    }

    if (best == null || best.confidence < _minimumLocalCategoryConfidence) {
      return null;
    }
    return best;
  }

  static MatchScore? _resolveUnitIntent({
    required AiRecipeIngredient ingredient,
    required CategoryRule? categoryRule,
  }) {
    final explicitUnit = ingredient.unit?.trim() ?? '';
    if (explicitUnit.isNotEmpty) {
      final explicitMatch = _matchUnitRuleFromText(
        explicitUnit,
        source: 'ai_unit',
      );
      if (explicitMatch != null) {
        if (!_shouldTreatUnitAsProductSpec(
          explicitMatch.key,
          ingredient,
          categoryRule,
        )) {
          return explicitMatch;
        }
        return MatchScore(
          key:
              _firstOrNull(_fallbackUnitKeysFor(ingredient, categoryRule)) ??
              'piece',
          score: 9,
          confidence: 0.55,
          source: 'fallback_unit',
          reasons: [
            'تم اعتبار الوحدة "$explicitUnit" جزءاً من وصف المنتج وليس كمية شراء.',
          ],
        );
      }
    }

    final leadingUnit = _matchLeadingUnitFromName(ingredient);
    if (leadingUnit != null &&
        !_shouldTreatUnitAsProductSpec(
          leadingUnit.key,
          ingredient,
          categoryRule,
        )) {
      return leadingUnit;
    }

    final fallbackKeys = _fallbackUnitKeysFor(ingredient, categoryRule);
    if (fallbackKeys.isEmpty) return null;

    return MatchScore(
      key: fallbackKeys.first,
      score: 8,
      confidence: _fallbackUnitConfidence(ingredient, categoryRule),
      source: 'fallback_unit',
      reasons: ['تم اختيار وحدة افتراضية آمنة حسب نوع المنتج.'],
    );
  }

  static MatchScore? _matchUserUnit({
    required List<String> desiredKeys,
    required List<Unit> units,
    required double sourceConfidence,
    required String source,
  }) {
    if (desiredKeys.isEmpty || units.isEmpty) return null;

    MatchScore? best;
    for (var index = 0; index < desiredKeys.length; index++) {
      final rule = _unitRulesByKey[desiredKeys[index]];
      if (rule == null) continue;

      final aliases = rule.aliases
          .map(normalize)
          .where((alias) => alias.isNotEmpty)
          .toList();
      for (final unit in units) {
        var score = 0.0;
        final reasons = <String>[];
        final unitTexts = <String>[unit.name, unit.symbol];

        for (final rawText in unitTexts) {
          final unitText = normalize(rawText);
          if (unitText.isEmpty) continue;

          for (final alias in aliases) {
            if (unitText == alias) {
              score += 12;
              reasons.add('وحدة المستخدم "${unit.name}" تطابق "$alias".');
            } else if (_containsNormalizedPhrase(unitText, alias) ||
                _containsNormalizedPhrase(alias, unitText)) {
              score += 5;
              reasons.add('وحدة المستخدم "${unit.name}" قريبة من "$alias".');
            } else {
              final similarity = _jaccard(
                unitText.split(' ').toSet(),
                alias.split(' ').toSet(),
              );
              if (similarity >= 0.5) {
                score += 4 * similarity;
              }
            }
          }
        }

        if (score > 0 && unit.type == rule.type) score += 2;
        if (score > 0 && unit.isDefault) score += 0.4;
        score -= index * 0.35;
        if (score <= 0) continue;

        final localConfidence = _clamp(score / 14);
        final confidence = math.min(sourceConfidence, localConfidence);
        final candidate = MatchScore(
          key: rule.key,
          id: unit.id,
          matchedName: unit.name,
          score: score,
          confidence: confidence,
          source: source,
          reasons: reasons,
        );

        if (best == null || candidate.score > best.score) {
          best = candidate;
        }
      }
    }

    if (best == null || best.confidence < _minimumLocalUnitConfidence) {
      return null;
    }
    return best;
  }

  static MatchScore? _matchUnitRuleFromText(
    String text, {
    required String source,
  }) {
    final normalizedText = normalize(text);
    final tokens = tokenize(text, removeSoftStopwords: false);
    if (normalizedText.isEmpty || tokens.isEmpty) return null;

    MatchScore? best;
    for (final rule in _unitRules) {
      var score = 0.0;
      final reasons = <String>[];

      for (final alias in rule.aliases) {
        final aliasNormalized = normalize(alias);
        final aliasTokens = tokenize(alias, removeSoftStopwords: false);
        if (aliasNormalized.isEmpty || aliasTokens.isEmpty) continue;

        if (normalizedText == aliasNormalized) {
          score += 12;
          reasons.add('الوحدة النصية "$text" تطابق "$alias".');
        } else if (aliasTokens.length == 1 &&
            tokens.contains(aliasTokens.first)) {
          score += 10;
          reasons.add('الوحدة النصية "$text" تحتوي "$alias".');
        } else if (_containsTokenPhrase(tokens, aliasTokens)) {
          score += 9;
          reasons.add('الوحدة النصية "$text" تطابق عبارة "$alias".');
        } else if (aliasNormalized.length > 2 &&
            _containsNormalizedPhrase(normalizedText, aliasNormalized)) {
          score += 6;
          reasons.add('الوحدة النصية "$text" قريبة من "$alias".');
        }
      }

      if (score <= 0) continue;
      final candidate = MatchScore(
        key: rule.key,
        score: score,
        confidence: _clamp(score / 12),
        source: source,
        reasons: reasons,
      );

      if (best == null || candidate.score > best.score) {
        best = candidate;
      }
    }

    if (best == null || best.confidence < minimumUnitConfidence) return null;
    return best;
  }

  static MatchScore? _matchLeadingUnitFromName(AiRecipeIngredient ingredient) {
    final name = ingredient.displayName ?? ingredient.name;
    final tokens = tokenize(name, removeSoftStopwords: false);
    if (tokens.isEmpty) return null;

    final firstMeaningful = tokens.firstWhere(
      (token) => !_isNumericToken(token),
      orElse: () => '',
    );
    if (firstMeaningful.isEmpty) return null;

    final firstIndex = tokens.indexOf(firstMeaningful);
    if (firstIndex > 1) return null;

    final text = firstIndex == 0
        ? firstMeaningful
        : '${tokens[firstIndex - 1]} $firstMeaningful';
    final match = _matchUnitRuleFromText(text, source: 'name_leading_unit');
    if (match == null) return null;

    return MatchScore(
      key: match.key,
      score: match.score,
      confidence: math.min(match.confidence, 0.82),
      source: match.source,
      reasons: ['تم استخراج الوحدة من بداية اسم المنتج.'],
    );
  }

  static bool _shouldTreatUnitAsProductSpec(
    String unitKey,
    AiRecipeIngredient ingredient,
    CategoryRule? categoryRule,
  ) {
    if (!_productSpecUnitKeys.contains(unitKey)) return false;
    if (categoryRule == null ||
        !_countPreferredCategoryKeys.contains(categoryRule.key)) {
      return false;
    }

    final text = [
      ingredient.displayName,
      ingredient.name,
      ingredient.unit,
    ].whereType<String>().join(' ');

    return _hasMeasurementWithNumber(text) ||
        (categoryRule.key == 'sports' &&
            _hasAnyToken(text, ['دمبل', 'اثقال', 'dumbbell', 'weights']));
  }

  static List<String> _fallbackUnitKeysFor(
    AiRecipeIngredient ingredient,
    CategoryRule? categoryRule,
  ) {
    if (categoryRule == null) return const [];

    final text = [
      ingredient.displayName,
      ingredient.name,
      ingredient.category,
    ].whereType<String>().join(' ');
    final tokens = tokenize(text, forCategory: true).toSet();

    switch (categoryRule.key) {
      case 'meat_seafood':
      case 'produce':
        return const ['kg'];
      case 'dairy':
        if (_intersects(tokens, ['بيض', 'egg', 'eggs'])) return const ['piece'];
        if (_intersects(tokens, [
          'حليب',
          'لبن',
          'روب',
          'زبادي',
          'milk',
          'yogurt',
        ])) {
          return const ['liter', 'box'];
        }
        return const ['kg', 'piece'];
      case 'pantry':
        if (_intersects(tokens, [
          'زيت',
          'خل',
          'ماء',
          'عصير',
          'oil',
          'vinegar',
          'water',
          'juice',
        ])) {
          return const ['liter', 'bottle', 'ml'];
        }
        if (_intersects(tokens, [
          'ارز',
          'رز',
          'سكر',
          'ملح',
          'دقيق',
          'طحين',
          'مكرونه',
          'معكرونه',
          'rice',
          'sugar',
          'salt',
          'flour',
          'pasta',
        ])) {
          return const ['kg', 'box', 'bag'];
        }
        if (_intersects(tokens, [
          'شاي',
          'قهوه',
          'بهارات',
          'توابل',
          'spice',
          'tea',
          'coffee',
        ])) {
          return const ['box', 'g'];
        }
        return const [];
      case 'cleaning':
        if (_intersects(tokens, ['مناديل', 'فاين', 'tissue', 'wipes'])) {
          return const ['box', 'bundle'];
        }
        if (_intersects(tokens, ['مسحوق', 'بودره', 'detergent', 'powder'])) {
          return const ['box', 'bag'];
        }
        if (_intersects(tokens, [
          'صابون',
          'شامبو',
          'منظف',
          'كلور',
          'معقم',
          'مطهر',
          'soap',
          'shampoo',
          'cleaner',
          'bleach',
          'sanitizer',
        ])) {
          return const ['bottle', 'liter', 'box'];
        }
        return const ['box', 'piece'];
      case 'hardware':
      case 'electronics':
      case 'clothing':
      case 'sports':
        return const ['piece'];
      case 'stationery':
        if (_intersects(tokens, ['ورق', 'paper'])) {
          return const ['bundle', 'box', 'piece'];
        }
        if (_intersects(tokens, ['حبر', 'ink'])) {
          return const ['bottle', 'piece'];
        }
        return const ['piece', 'box'];
      case 'baby':
        if (_intersects(tokens, [
          'حفاضات',
          'حفاظات',
          'مناديل',
          'diapers',
          'wipes',
        ])) {
          return const ['box', 'bundle'];
        }
        if (_intersects(tokens, ['حليب', 'formula', 'بودره', 'powder'])) {
          return const ['box'];
        }
        return const ['piece', 'box'];
      default:
        return const [];
    }
  }

  static double _fallbackUnitConfidence(
    AiRecipeIngredient ingredient,
    CategoryRule? categoryRule,
  ) {
    if (categoryRule == null) return 0;

    final name = ingredient.displayName ?? ingredient.name;
    final tokens = tokenize(name, forCategory: true).toSet();

    if (categoryRule.key == 'meat_seafood' || categoryRule.key == 'produce') {
      return 0.68;
    }
    if (_countPreferredCategoryKeys.contains(categoryRule.key)) {
      return 0.62;
    }
    if (_intersects(tokens, [
      'مناديل',
      'حفاضات',
      'حفاظات',
      'صابون',
      'شامبو',
      'زيت',
      'حليب',
      'بيض',
    ])) {
      return 0.58;
    }
    return 0.48;
  }

  static double _ambiguityPenalty(CategoryRule rule, Set<String> tokenSet) {
    var penalty = 0.0;
    for (final keyword in rule.ambiguousKeywords) {
      final normalized = normalize(keyword);
      if (normalized.isNotEmpty && tokenSet.contains(normalized)) {
        penalty += 3;
      }
    }
    return penalty;
  }

  static double _contextBoost(
    CategoryRule rule,
    Set<String> tokenSet,
    String normalizedText,
  ) {
    var boost = 0.0;

    if (rule.key == 'clothing' &&
        _intersects(tokenSet, ['حذاء', 'جزمه', 'شبشب', 'shoes', 'shoe']) &&
        _intersects(tokenSet, ['رياضي', 'رياضه', 'sport', 'sports'])) {
      boost += 8;
    }

    if (rule.key == 'sports' &&
        _intersects(tokenSet, ['حذاء', 'جزمه', 'شبشب', 'shoes', 'shoe'])) {
      boost -= 8;
    }

    if (rule.key == 'pantry' &&
        (_containsNormalizedPhrase(normalizedText, normalize('فلفل أسود')) ||
            _containsNormalizedPhrase(
              normalizedText,
              normalize('black pepper'),
            ))) {
      boost += 7;
    }

    if (rule.key == 'produce' &&
        (_containsNormalizedPhrase(normalizedText, normalize('فلفل رومي')) ||
            _containsNormalizedPhrase(
              normalizedText,
              normalize('bell pepper'),
            ))) {
      boost += 7;
    }

    if (rule.key == 'stationery' &&
        _intersects(tokenSet, ['ورق', 'دفتر', 'كراسه', 'notebook', 'paper']) &&
        _intersects(tokenSet, ['غراء', 'glue'])) {
      boost += 5;
    }

    if (rule.key == 'hardware' &&
        _intersects(tokenSet, [
          'صيانة',
          'مفك',
          'مفكات',
          'عدة',
          'tools',
          'maintenance',
        ])) {
      boost += 5;
    }

    return boost;
  }

  static bool _shareProductSynonymGroup(Set<String> left, Set<String> right) {
    for (final group in _productSynonymGroups) {
      final normalizedGroup = group.map(normalize).toSet();
      if (left.intersection(normalizedGroup).isNotEmpty &&
          right.intersection(normalizedGroup).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  static bool _hasMeasurementWithNumber(String value) {
    final tokens = tokenize(value, removeSoftStopwords: false);
    for (var i = 0; i < tokens.length; i++) {
      if (!_isNumericToken(tokens[i])) continue;
      final previous = i > 0 ? tokens[i - 1] : null;
      final next = i < tokens.length - 1 ? tokens[i + 1] : null;
      if ((previous != null && _measurementStopwords.contains(previous)) ||
          (next != null && _measurementStopwords.contains(next))) {
        return true;
      }
    }
    return false;
  }

  static bool _hasAnyToken(String value, List<String> needles) {
    final tokens = tokenize(value, forCategory: true).toSet();
    return _intersects(tokens, needles.map(normalize).toList());
  }

  static bool _containsTokenPhrase(
    List<String> tokens,
    List<String> phraseTokens,
  ) {
    if (phraseTokens.isEmpty || tokens.length < phraseTokens.length) {
      return false;
    }
    for (var i = 0; i <= tokens.length - phraseTokens.length; i++) {
      var matches = true;
      for (var j = 0; j < phraseTokens.length; j++) {
        if (tokens[i + j] != phraseTokens[j]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  static bool _containsNormalizedPhrase(String text, String phrase) {
    if (text.isEmpty || phrase.isEmpty) return false;
    return ' $text '.contains(' $phrase ');
  }

  static bool _intersects(Set<String> tokens, Iterable<String> values) {
    final normalizedValues = values
        .map(normalize)
        .where((value) => value.isNotEmpty)
        .toSet();
    return tokens.intersection(normalizedValues).isNotEmpty;
  }

  static double _jaccard(Set<String> left, Set<String> right) {
    if (left.isEmpty || right.isEmpty) return 0;
    final intersection = left.intersection(right).length;
    final union = left.union(right).length;
    return union == 0 ? 0 : intersection / union;
  }

  static bool _isNumericToken(String token) => double.tryParse(token) != null;

  static T? _firstOrNull<T>(List<T> values) =>
      values.isEmpty ? null : values.first;

  static ItemTemplate? _templateById(String? id, List<ItemTemplate> templates) {
    if (id == null) return null;
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  static String? _categoryNameById(List<Category> categories, String? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category.name;
    }
    return null;
  }

  static String? _unitNameById(List<Unit> units, String? id) {
    if (id == null) return null;
    for (final unit in units) {
      if (unit.id == id) return unit.name;
    }
    return null;
  }

  static double _clamp(double value) => value.clamp(0, 1).toDouble();

  static double _roundConfidence(double value) =>
      (_clamp(value) * 100).round() / 100;

  static List<String> _dedupe(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      if (value.trim().isEmpty || seen.contains(value)) continue;
      seen.add(value);
      result.add(value);
    }
    return result;
  }

  // Category rules describe the semantic category first, then map that category
  // to whatever names the user created locally. Add new shopping domains here
  // instead of adding if/else checks in providers.
  static const List<CategoryRule> _categoryRules = [
    CategoryRule(
      key: 'meat_seafood',
      categoryAliases: [
        'لحوم',
        'لحم',
        'دجاج',
        'أسماك',
        'اسماك',
        'مأكولات بحرية',
        'مجمدات',
        'meat',
        'beef',
        'poultry',
        'seafood',
        'fish',
      ],
      keywords: [
        'لحم',
        'لحمة',
        'دجاج',
        'فراخ',
        'سمك',
        'تونة',
        'سالمون',
        'سردين',
        'جمبري',
        'روبيان',
        'مفروم',
        'كبدة',
        'نقانق',
        'سجق',
        'meat',
        'beef',
        'chicken',
        'fish',
        'tuna',
        'salmon',
        'shrimp',
        'sausage',
      ],
      strongPhrases: [
        'دجاج مفروم',
        'لحم مفروم',
        'سمك فيليه',
        'ground beef',
        'ground chicken',
      ],
      ambiguousKeywords: ['مفروم'],
    ),
    CategoryRule(
      key: 'produce',
      categoryAliases: [
        'خضار',
        'خضروات',
        'فواكه',
        'فاكهة',
        'فواكة',
        'produce',
        'vegetables',
        'vegetable',
        'fruit',
        'fruits',
      ],
      keywords: [
        'طماطم',
        'بندورة',
        'بطاطس',
        'بطاطا',
        'بصل',
        'ثوم',
        'خيار',
        'خس',
        'جزر',
        'فلفل',
        'ليمون',
        'تفاح',
        'موز',
        'برتقال',
        'عنب',
        'فراولة',
        'vegetable',
        'fruit',
        'tomato',
        'potato',
        'onion',
        'garlic',
        'apple',
        'banana',
        'orange',
      ],
      strongPhrases: ['فلفل رومي', 'bell pepper'],
      ambiguousKeywords: ['فلفل'],
    ),
    CategoryRule(
      key: 'dairy',
      categoryAliases: [
        'ألبان',
        'البان',
        'أجبان',
        'اجبان',
        'بيض',
        'dairy',
        'milk',
        'cheese',
        'eggs',
      ],
      keywords: [
        'حليب',
        'لبن',
        'زبادي',
        'روب',
        'جبن',
        'جبنة',
        'زبدة',
        'قشطة',
        'كريمة',
        'بيض',
        'milk',
        'yogurt',
        'cheese',
        'butter',
        'cream',
        'egg',
      ],
    ),
    CategoryRule(
      key: 'pantry',
      categoryAliases: [
        'بقالة',
        'بقاله',
        'مؤونة',
        'مونه',
        'بهارات',
        'توابل',
        'عطارة',
        'حبوب',
        'pantry',
        'grocery',
        'groceries',
        'spices',
        'staples',
      ],
      keywords: [
        'أرز',
        'ارز',
        'رز',
        'سكر',
        'ملح',
        'فلفل',
        'بهارات',
        'توابل',
        'كمون',
        'كركم',
        'قرفة',
        'دقيق',
        'طحين',
        'مكرونة',
        'معكرونة',
        'زيت',
        'خل',
        'شاي',
        'قهوة',
        'rice',
        'sugar',
        'salt',
        'spice',
        'flour',
        'pasta',
        'oil',
        'tea',
        'coffee',
      ],
      strongPhrases: ['فلفل أسود', 'black pepper', 'زيت زيتون', 'olive oil'],
      ambiguousKeywords: ['فلفل', 'زيت'],
    ),
    CategoryRule(
      key: 'cleaning',
      categoryAliases: [
        'منظفات',
        'نظافة',
        'عناية منزلية',
        'ادوات منزلية',
        'أدوات منزلية',
        'household',
        'cleaning',
        'home care',
        'homecare',
      ],
      keywords: [
        'صابون',
        'شامبو',
        'منظف',
        'مسحوق',
        'غسيل',
        'أطباق',
        'اطباق',
        'مواعين',
        'كلور',
        'معقم',
        'ممسحة',
        'مكنسة',
        'مناديل',
        'فاين',
        'مطهر',
        'إسفنجة',
        'اسفنجة',
        'soap',
        'shampoo',
        'cleaner',
        'detergent',
        'bleach',
        'sanitizer',
        'tissue',
        'sponge',
      ],
      strongPhrases: [
        'صابون غسيل أطباق',
        'صابون غسيل اطباق',
        'مناديل فاين',
        'dish soap',
        'dishwashing liquid',
      ],
      ambiguousKeywords: ['شامبو', 'مناديل'],
    ),
    CategoryRule(
      key: 'hardware',
      categoryAliases: [
        'خردوات',
        'صيانة',
        'عدة',
        'ادوات',
        'أدوات',
        'hardware',
        'tools',
        'maintenance',
      ],
      keywords: [
        'مسمار',
        'برغي',
        'مطرقة',
        'مفك',
        'مفكات',
        'زرادية',
        'كماشة',
        'شريط لاصق',
        'غراء',
        'قفل',
        'أقفال',
        'اقفال',
        'بطارية',
        'صيانة',
        'عدة',
        'أدوات',
        'ادوات',
        'nail',
        'screw',
        'hammer',
        'screwdriver',
        'pliers',
        'tape',
        'glue',
        'lock',
        'battery',
        'tools',
        'hardware',
      ],
      strongPhrases: ['طقم أدوات', 'طقم ادوات', 'شريط لاصق', 'tool set'],
      ambiguousKeywords: ['غراء', 'بطارية', 'ادوات'],
    ),
    CategoryRule(
      key: 'electronics',
      categoryAliases: [
        'إلكترونيات',
        'الكترونيات',
        'كهرباء',
        'أجهزة',
        'اجهزة',
        'electronics',
        'electrical',
        'tech',
      ],
      keywords: [
        'شاحن',
        'كابل',
        'سلك',
        'سماعة',
        'فيش',
        'مقبس',
        'لمبة',
        'مصباح',
        'بطارية',
        'باوربانك',
        'ماوس',
        'كيبورد',
        'وصلة',
        'charger',
        'cable',
        'wire',
        'headphone',
        'plug',
        'bulb',
        'lamp',
        'powerbank',
        'mouse',
        'keyboard',
      ],
      strongPhrases: ['تايب سي', 'type c', 'power bank', 'باور بانك'],
      ambiguousKeywords: ['بطارية', 'سلك'],
    ),
    CategoryRule(
      key: 'clothing',
      categoryAliases: [
        'ملابس',
        'أزياء',
        'ازياء',
        'أحذية',
        'احذية',
        'clothing',
        'apparel',
        'fashion',
        'shoes',
        'footwear',
      ],
      keywords: [
        'قميص',
        'بنطلون',
        'فستان',
        'حذاء',
        'جزمة',
        'شبشب',
        'جوارب',
        'جاكيت',
        'معطف',
        'تيشيرت',
        'عباية',
        'قبعة',
        'shirt',
        'pants',
        'dress',
        'shoes',
        'socks',
        'jacket',
        'coat',
        'hoodie',
      ],
      strongPhrases: ['حذاء رياضي', 'sports shoes', 'running shoes'],
    ),
    CategoryRule(
      key: 'sports',
      categoryAliases: [
        'رياضة',
        'رياضية',
        'ادوات رياضية',
        'أدوات رياضية',
        'sports',
        'fitness',
        'gym',
      ],
      keywords: [
        'دمبل',
        'أثقال',
        'اثقال',
        'كرة',
        'مضرب',
        'دراجة',
        'حبل مقاومة',
        'سجادة يوغا',
        'قفازات',
        'رياضة',
        'تمرين',
        'dumbbell',
        'weights',
        'ball',
        'racket',
        'bike',
        'yoga mat',
        'gloves',
        'fitness',
        'sport',
      ],
      strongPhrases: ['حبل مقاومة', 'سجادة يوغا', 'yoga mat'],
      ambiguousKeywords: ['كرة', 'قفازات'],
    ),
    CategoryRule(
      key: 'stationery',
      categoryAliases: [
        'مكتبية',
        'ادوات مكتبية',
        'أدوات مكتبية',
        'مدرسية',
        'قرطاسية',
        'stationery',
        'school',
        'office supplies',
      ],
      keywords: [
        'قلم',
        'دفتر',
        'كراسة',
        'ورق',
        'مسطرة',
        'غراء',
        'ممحاة',
        'براية',
        'حقيبة',
        'ملف',
        'دباسة',
        'حبر',
        'pen',
        'notebook',
        'paper',
        'ruler',
        'glue',
        'eraser',
        'bag',
        'folder',
        'stapler',
        'ink',
      ],
      strongPhrases: ['قلم رصاص', 'ورق طباعة', 'printer paper'],
      ambiguousKeywords: ['غراء', 'حقيبة'],
    ),
    CategoryRule(
      key: 'baby',
      categoryAliases: [
        'أطفال',
        'اطفال',
        'مستلزمات الأطفال',
        'مستلزمات اطفال',
        'baby',
        'baby care',
        'kids',
      ],
      keywords: [
        'حفاضات',
        'حفاظات',
        'رضاعة',
        'لهاية',
        'بودرة',
        'مناديل أطفال',
        'مناديل اطفال',
        'شامبو أطفال',
        'شامبو اطفال',
        'حليب أطفال',
        'حليب اطفال',
        'لعبة أطفال',
        'لعبة اطفال',
        'diapers',
        'baby bottle',
        'pacifier',
        'baby powder',
        'baby wipes',
        'baby shampoo',
        'formula',
      ],
      strongPhrases: [
        'حفاضات أطفال',
        'حفاضات اطفال',
        'مناديل أطفال',
        'baby wipes',
      ],
      ambiguousKeywords: ['شامبو', 'مناديل'],
    ),
  ];

  static final Map<String, CategoryRule> _categoryRulesByKey = {
    for (final rule in _categoryRules) rule.key: rule,
  };

  // Unit rules are canonical intents. They are resolved against the user's
  // actual unit table by aliases, symbols, and normalized names.
  static const List<UnitRule> _unitRules = [
    UnitRule(
      key: 'kg',
      type: UnitType.weight,
      aliases: [
        'كيلو',
        'كيلوغرام',
        'كيلو غرام',
        'كغ',
        'kg',
        'kilogram',
        'kilograms',
      ],
    ),
    UnitRule(
      key: 'g',
      type: UnitType.weight,
      aliases: ['جرام', 'غرام', 'جم', 'غ', 'g', 'gram', 'grams'],
    ),
    UnitRule(
      key: 'liter',
      type: UnitType.volume,
      aliases: ['لتر', 'لترين', 'ل', 'l', 'liter', 'litre', 'liters', 'litres'],
    ),
    UnitRule(
      key: 'ml',
      type: UnitType.volume,
      aliases: [
        'مل',
        'ملل',
        'ml',
        'milliliter',
        'millilitre',
        'milliliters',
        'millilitres',
      ],
    ),
    UnitRule(
      key: 'box',
      type: UnitType.count,
      aliases: [
        'علبة',
        'علبه',
        'عبوة',
        'عبوه',
        'كرتون',
        'باكيت',
        'box',
        'pack',
        'package',
      ],
    ),
    UnitRule(
      key: 'piece',
      type: UnitType.count,
      aliases: [
        'حبة',
        'حبه',
        'قطعة',
        'قطعه',
        'pcs',
        'pc',
        'piece',
        'pieces',
        'item',
      ],
    ),
    UnitRule(
      key: 'bottle',
      type: UnitType.count,
      aliases: ['زجاجة', 'زجاجه', 'قارورة', 'قاروره', 'bottle', 'bottles'],
    ),
    UnitRule(
      key: 'bag',
      type: UnitType.count,
      aliases: ['كيس', 'شنطة', 'شنطه', 'bag', 'sack'],
    ),
    UnitRule(
      key: 'bundle',
      type: UnitType.count,
      aliases: ['رزمة', 'رزمه', 'حزمة', 'حزمه', 'bundle', 'ream'],
    ),
    UnitRule(
      key: 'meter',
      type: UnitType.length,
      aliases: ['متر', 'م', 'meter', 'metre', 'meters', 'metres', 'm'],
    ),
  ];

  static final Map<String, UnitRule> _unitRulesByKey = {
    for (final rule in _unitRules) rule.key: rule,
  };

  static const Set<String> _softStopwords = {
    'طازج',
    'طازجة',
    'كبير',
    'كبيرة',
    'صغير',
    'صغيرة',
    'ممتاز',
    'ممتازة',
    'فاخر',
    'فاخرة',
    'جديد',
    'جديدة',
    'طبيعي',
    'طبيعية',
    'عضوي',
    'عضوية',
    'مقاس',
    'نوع',
    'ماركة',
    'fresh',
    'large',
    'small',
    'premium',
    'organic',
    'new',
    'natural',
    'size',
    'brand',
  };

  static final Set<String> _measurementStopwords = {
    for (final rule in _unitRules)
      for (final alias in rule.aliases) normalize(alias),
  };

  static const Set<String> _productSpecUnitKeys = {
    'kg',
    'g',
    'liter',
    'ml',
    'meter',
  };

  static const Set<String> _countPreferredCategoryKeys = {
    'hardware',
    'electronics',
    'clothing',
    'sports',
    'stationery',
  };

  static const List<List<String>> _productSynonymGroups = [
    ['طماطم', 'بندورة', 'tomato'],
    ['بطاطس', 'بطاطا', 'potato'],
    ['دجاج', 'فراخ', 'chicken'],
    ['لحم', 'لحمة', 'beef', 'meat'],
    ['سمك', 'fish'],
    ['زبادي', 'روب', 'yogurt'],
    ['جبن', 'جبنة', 'cheese'],
    ['حليب', 'milk'],
    ['رز', 'أرز', 'ارز', 'rice'],
    ['مكرونة', 'معكرونة', 'pasta'],
    ['مناديل', 'فاين', 'tissue'],
    ['حفاضات', 'حفاظات', 'diapers'],
    ['شاحن', 'charger'],
    ['كابل', 'سلك', 'cable', 'wire'],
    ['حذاء', 'جزمة', 'shoes', 'shoe'],
  ];
}

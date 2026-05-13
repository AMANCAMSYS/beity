import '../models/item_template_model.dart';

abstract class ItemTemplateRepository {
  Future<List<ItemTemplateModel>> getTemplates({
    required String homeId,
  });

  Future<ItemTemplateModel?> getTemplateById({
    required String templateId,
  });

  Future<ItemTemplateModel> createTemplate({
    required String homeId,
    required String name,
    double defaultQuantity = 1,
    String? defaultUnitId,
    String? defaultCategoryId,
  });

  Future<ItemTemplateModel> updateTemplate({
    required String templateId,
    String? name,
    double? defaultQuantity,
    String? defaultUnitId,
    String? defaultCategoryId,
  });

  Future<void> deleteTemplate({
    required String templateId,
  });

  Future<void> incrementUsage({
    required String templateId,
  });

  Future<List<ItemTemplateModel>> getTopTemplates({
    required String homeId,
    int limit = 10,
  });

  Stream<List<ItemTemplateModel>> watchTemplates({
    required String homeId,
  });

  /// Auto-create or update template when item is added (NOT on edit).
  /// If template exists by (home_id, name), increment usage_count.
  /// Otherwise create a new template.
  Future<void> syncTemplateOnAdd({
    required String homeId,
    required String name,
    double quantity = 1,
    String? unitId,
    String? categoryId,
  });
}

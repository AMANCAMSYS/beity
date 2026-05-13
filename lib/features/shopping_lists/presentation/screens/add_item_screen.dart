import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../widgets/item_suggestions_widget.dart';
import '../../domain/usecases/add_item_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final String listId;

  const AddItemScreen({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedUnitId;
  String? _selectedCategoryId;
  bool _isLoading = false;
  String _nameQuery = '';
  List<AutocompleteSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final query = _nameController.text;
    if (query != _nameQuery) {
      setState(() {
        _nameQuery = query;
      });
      _fetchSuggestions(query);
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    final listAsync = ref.read(shoppingListByIdProvider(widget.listId));
    final list = listAsync.valueOrNull;
    if (list == null) return;

    final repository = ref.read(shoppingItemRepositoryProvider);
    final results = await repository.getAutocompleteSuggestions(
      homeId: list.homeId,
      query: query,
    );

    if (mounted) {
      setState(() => _suggestions = results);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListByIdProvider(widget.listId));

    return listAsync.when(
      data: (list) {
        if (list == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('إضافة منتج')),
            body: const Center(child: Text('القائمة غير موجودة')),
          );
        }

        final homeId = list.homeId;
        final unitsAsync = ref.watch(unitsProvider('shopping'));
        final categoriesAsync = ref.watch(categoriesProvider(homeId));

        return _buildScreen(context, unitsAsync, categoriesAsync);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('إضافة منتج')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('إضافة منتج')),
        body: Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Widget _buildScreen(
    BuildContext context,
    AsyncValue<List<dynamic>> unitsAsync,
    AsyncValue<List<dynamic>> categoriesAsync,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _saveItem(skipDuplicateCheck: false),
            child: const Text('حفظ'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field with autocomplete
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج *',
                    hintText: 'مثال: حليب، خبز، تفاح',
                    prefixIcon: Icon(Icons.shopping_basket_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اسم المنتج مطلوب';
                    }
                    return null;
                  },
                ),
                ItemSuggestionsWidget(
                  suggestions: _suggestions,
                  query: _nameQuery,
                  onSuggestionTap: (suggestion) {
                    _nameController.text = suggestion.name;
                    _quantityController.text =
                        suggestion.quantity.toStringAsFixed(
                            suggestion.quantity == suggestion.quantity.roundToDouble()
                                ? 0
                                : 1);
                    setState(() {
                      _nameQuery = suggestion.name;
                      _suggestions = [];
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الكمية مطلوبة';
                      }
                      final quantity = double.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'الكمية غير صالحة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: unitsAsync.when(
                    data: (units) => DropdownButtonFormField<String>(
                      value: _selectedUnitId,
                      decoration: const InputDecoration(
                        labelText: 'الوحدة',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('بدون')),
                        ...units.map((unit) => DropdownMenuItem(
                              value: unit.id,
                              child: Text('${unit.name} (${unit.symbol})'),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUnitId = value;
                        });
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('خطأ في تحميل الوحدات'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'السعر (اختياري)',
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'ر.س',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'السعر غير صالح';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'التصنيف',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('بدون تصنيف')),
                  ...categories.map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('خطأ في تحميل التصنيفات'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                hintText: 'مثال: نوع معين، حجم كبير',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _saveItem(skipDuplicateCheck: false),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading ? 'جاري الإضافة...' : 'إضافة المنتج'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem({required bool skipDuplicateCheck}) async {
    if (!_formKey.currentState!.validate()) return;

    final listAsync = ref.read(shoppingListByIdProvider(widget.listId));
    final list = listAsync.valueOrNull;
    if (list == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(shoppingItemRepositoryProvider);
      final useCase = AddItemUseCase(repository);

      await useCase(
        listId: widget.listId,
        homeId: list.homeId,
        name: _nameController.text,
        quantity: double.parse(_quantityController.text),
        unitId: _selectedUnitId,
        categoryId: _selectedCategoryId,
        price: _priceController.text.isNotEmpty
            ? double.parse(_priceController.text)
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        skipDuplicateCheck: skipDuplicateCheck,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on DuplicateItemException catch (e) {
      if (mounted) {
        final shouldAdd = await _showDuplicateWarning(e.itemName);
        if (shouldAdd == true && mounted) {
          await _saveItem(skipDuplicateCheck: true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showDuplicateWarning(String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('منتج مكرر'),
        content: Text('"$itemName" موجود بالفعل في القائمة. هل تريد إضافته؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

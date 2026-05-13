import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_items_provider.dart';
import '../providers/shopping_lists_provider.dart';
import '../../domain/usecases/update_item_usecase.dart';
import '../../../categories/presentation/providers/units_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final String listId;
  final String itemId;

  const EditItemScreen({
    super.key,
    required this.listId,
    required this.itemId,
  });

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedUnitId;
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final repository = ref.read(shoppingItemRepositoryProvider);
    final item = await repository.getShoppingItemById(itemId: widget.itemId);
    
    if (item != null && mounted) {
      setState(() {
        _nameController.text = item.name;
        _quantityController.text = item.quantity.toString();
        _priceController.text = item.price?.toString() ?? '';
        _notesController.text = item.notes ?? '';
        _selectedUnitId = item.unitId;
        _selectedCategoryId = item.categoryId;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل المنتج')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Get shopping list to obtain homeId
    final listAsync = ref.watch(shoppingListByIdProvider(widget.listId));
    
    return listAsync.when(
      data: (list) {
        if (list == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تعديل المنتج')),
            body: const Center(child: Text('القائمة غير موجودة')),
          );
        }
        
        final homeId = list.homeId;
        final unitsAsync = ref.watch(unitsProvider(null));
        final categoriesAsync = ref.watch(categoriesProvider(homeId));
        
        return _buildScreen(context, unitsAsync, categoriesAsync);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('تعديل المنتج')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('تعديل المنتج')),
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
        title: const Text('تعديل المنتج'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveItem,
            child: const Text('حفظ'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج *',
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
                        const DropdownMenuItem(value: null, child: Text('بدون')),
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
                  const DropdownMenuItem(value: null, child: Text('بدون تصنيف')),
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
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveItem,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'جاري الحفظ...' : 'حفظ التعديلات'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(shoppingItemRepositoryProvider);
      final useCase = UpdateItemUseCase(repository);
      
      await useCase(
        itemId: widget.itemId,
        name: _nameController.text,
        quantity: double.parse(_quantityController.text),
        unitId: _selectedUnitId,
        categoryId: _selectedCategoryId,
        price: _priceController.text.isNotEmpty
            ? double.parse(_priceController.text)
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

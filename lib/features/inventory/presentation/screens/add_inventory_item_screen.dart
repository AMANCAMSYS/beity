import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import '../../domain/usecases/add_inventory_item_usecase.dart';
import '../../data/models/inventory_item_model.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../categories/presentation/providers/units_provider.dart';

class AddInventoryItemScreen extends ConsumerStatefulWidget {
  final String homeId;

  const AddInventoryItemScreen({super.key, required this.homeId});

  @override
  ConsumerState<AddInventoryItemScreen> createState() =>
      _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState
    extends ConsumerState<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _minQuantityController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedUnitId;
  String? _selectedCategoryId;
  List<InventoryItemModel> _suggestions = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onNameChanged(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    final repo = ref.read(inventoryRepositoryProvider);
    final results = await repo.searchInventoryItems(
      homeId: widget.homeId,
      query: query,
    );
    if (mounted) {
      setState(() => _suggestions = results);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final useCase = AddInventoryItemUseCase(
        ref.read(inventoryRepositoryProvider),
      );

      final name = _nameController.text.trim();
      final quantity = double.tryParse(_quantityController.text) ?? 1;
      final minQuantity = _minQuantityController.text.isNotEmpty
          ? double.tryParse(_minQuantityController.text)
          : null;
      final notes =
          _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null;

      await useCase(
        homeId: widget.homeId,
        name: name,
        quantity: quantity,
        unitId: _selectedUnitId,
        categoryId: _selectedCategoryId,
        minQuantity: minQuantity,
        notes: notes,
      );

      ref.invalidate(inventoryItemsProvider(widget.homeId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمت إضافة "$name" إلى المخزون')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(widget.homeId));
    final unitsAsync = ref.watch(unitsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field with suggestions
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج',
                hintText: 'مثال: أرز، حليب، زيت',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              onChanged: _onNameChanged,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال اسم المنتج';
                }
                return null;
              },
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(item.name),
                      subtitle: item.notes != null ? Text(item.notes!) : null,
                      onTap: () {
                        _nameController.text = item.name;
                        if (item.quantity > 0) {
                          _quantityController.text = item.quantity.toString();
                        }
                        setState(() => _suggestions = []);
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'الكمية',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'الرجاء إدخال الكمية';
                final q = double.tryParse(value);
                if (q == null || q <= 0) return 'الرجاء إدخال كمية صحيحة';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category dropdown
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ في تحميل التصنيفات: $e'),
              data: (categories) => DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'التصنيف (اختياري)',
                  prefixIcon: Icon(Icons.category),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('بدون تصنيف'),
                  ),
                  ...categories.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Unit dropdown
            unitsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ في تحميل الوحدات: $e'),
              data: (units) => DropdownButtonFormField<String>(
                initialValue: _selectedUnitId,
                decoration: const InputDecoration(
                  labelText: 'الوحدة (اختياري)',
                  prefixIcon: Icon(Icons.straighten),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('بدون وحدة'),
                  ),
                  ...units.map((unit) => DropdownMenuItem(
                        value: unit.id,
                        child: Text('${unit.name} (${unit.symbol})'),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedUnitId = value);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Min quantity threshold
            TextFormField(
              controller: _minQuantityController,
              decoration: const InputDecoration(
                labelText: 'الحد الأدنى (اختياري)',
                hintText: 'سيتم تنبيهك عند الوصول لهذا الحد',
                prefixIcon: Icon(Icons.warning_amber),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                hintText: 'مكان التخزين، نوع العلامة التجارية...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إضافة إلى المخزون'),
            ),
          ],
        ),
      ),
    );
  }
}

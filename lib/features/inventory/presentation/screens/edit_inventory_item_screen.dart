import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import '../widgets/quantity_adjuster_widget.dart';

class EditInventoryItemScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String homeId;

  const EditInventoryItemScreen({
    super.key,
    required this.itemId,
    required this.homeId,
  });

  @override
  ConsumerState<EditInventoryItemScreen> createState() =>
      _EditInventoryItemScreenState();
}

class _EditInventoryItemScreenState
    extends ConsumerState<EditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _notesController = TextEditingController();
  double _quantity = 0;
  double _originalQuantity = 0;
  String? _selectedUnitId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final repo = ref.read(inventoryRepositoryProvider);
    final item = await repo.getInventoryItemById(itemId: widget.itemId);
    if (item != null && mounted) {
      setState(() {
        _nameController.text = item.name;
        _quantity = item.quantity;
        _originalQuantity = item.quantity;
        _selectedUnitId = item.unitId;
        if (item.minQuantity != null) {
          _minQuantityController.text = item.minQuantity.toString();
        }
        if (item.notes != null) {
          _notesController.text = item.notes!;
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final minQuantity = _minQuantityController.text.isNotEmpty
          ? double.tryParse(_minQuantityController.text)
          : null;
      final notesText = _notesController.text.trim();
      final fieldsToNull = <String>[];
      if (notesText.isEmpty) fieldsToNull.add('notes');

      await repo.updateInventoryItem(
        itemId: widget.itemId,
        name: _nameController.text.trim(),
        quantity: _quantity,
        minQuantity: minQuantity,
        notes: notesText.isNotEmpty ? notesText : null,
        fieldsToNull: fieldsToNull,
      );

      // Only log transaction if quantity actually changed
      if (_quantity != _originalQuantity) {
        await repo.createTransaction(
          inventoryItemId: widget.itemId,
          homeId: widget.homeId,
          previousQuantity: _originalQuantity,
          newQuantity: _quantity,
          changeReason: 'manual_update',
        );
      }

      ref.invalidate(inventoryItemsProvider(widget.homeId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المنتج')),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل المنتج')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المنتج'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال اسم المنتج';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantity adjuster
            Center(
              child: Column(
                children: [
                  const Text('الكمية'),
                  const SizedBox(height: 8),
                  QuantityAdjusterWidget(
                    quantity: _quantity,
                    unitId: _selectedUnitId,
                    onChanged: (newQty) {
                      setState(() => _quantity = newQty);
                    },
                  ),
                ],
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
                  : const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}

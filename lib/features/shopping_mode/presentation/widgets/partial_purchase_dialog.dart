import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sawa/core/localization/app_localizations.dart';
import '../../../shopping_lists/data/models/shopping_item_model.dart';

class PartialPurchaseDialog extends StatefulWidget {
  final ShoppingItemModel item;
  final String? unitName;

  const PartialPurchaseDialog({super.key, required this.item, this.unitName});

  @override
  State<PartialPurchaseDialog> createState() => _PartialPurchaseDialogState();
}

class _PartialPurchaseDialogState extends State<PartialPurchaseDialog> {
  late TextEditingController _quantityController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity == widget.item.quantity.roundToDouble()
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final text = _quantityController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = context.translate('field_required');
      });
      return;
    }

    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      setState(() {
        _errorMessage = context.translate('invalid_quantity');
      });
      return;
    }

    if (value > widget.item.quantity) {
      setState(() {
        _errorMessage = context.translate('cannot_exceed_total_quantity');
      });
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = widget.unitName ?? context.translate('items');

    return AlertDialog(
      title: Text(context.translate('purchased_quantity')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.translate(
              'how_much_did_you_buy',
              arguments: {
                'item': widget.item.name,
                'total':
                    '${widget.item.quantity == widget.item.quantity.roundToDouble() ? widget.item.quantity.toInt() : widget.item.quantity} $unitLabel',
              },
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: context.translate('quantity'),
              suffixText: unitLabel,
              errorText: _errorMessage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => _validateAndSubmit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.translate('cancel')),
        ),
        FilledButton(
          onPressed: _validateAndSubmit,
          child: Text(context.translate('confirm')),
        ),
      ],
    );
  }
}

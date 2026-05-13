import 'package:flutter/material.dart';

class SplitSelector extends StatefulWidget {
  final int totalAmount;
  final List<String> memberIds;
  final String payerId;
  final List<String> memberNames;
  final void Function(List<({String memberId, int amount})> splits) onChanged;

  const SplitSelector({
    super.key,
    required this.totalAmount,
    required this.memberIds,
    required this.payerId,
    required this.memberNames,
    required this.onChanged,
  });

  @override
  State<SplitSelector> createState() => _SplitSelectorState();
}

class _SplitSelectorState extends State<SplitSelector> {
  bool _isEqualSplit = true;
  Map<String, int> _customAmounts = {};
  Set<String> _selectedMembers = {};

  @override
  void initState() {
    super.initState();
    _selectedMembers = Set.from(widget.memberIds);
    _updateSplits();
  }

  void _updateSplits() {
    List<({String memberId, int amount})> splits;

    if (_isEqualSplit) {
      splits = _calculateEqualSplits();
    } else {
      splits = _calculateCustomSplits();
    }

    widget.onChanged(splits);
  }

  List<({String memberId, int amount})> _calculateEqualSplits() {
    if (_selectedMembers.isEmpty) return [];

    final baseAmount = widget.totalAmount ~/ _selectedMembers.length;
    final remainder = widget.totalAmount % _selectedMembers.length;

    return _selectedMembers.map((memberId) {
      final amount =
          memberId == widget.payerId ? baseAmount + remainder : baseAmount;
      return (memberId: memberId, amount: amount);
    }).toList();
  }

  List<({String memberId, int amount})> _calculateCustomSplits() {
    return _selectedMembers.map((memberId) {
      final amount = _customAmounts[memberId] ?? 0;
      return (memberId: memberId, amount: amount);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('نوع التقسيم:'),
            const SizedBox(width: 16),
            ChoiceChip(
              label: const Text('بالتساوي'),
              selected: _isEqualSplit,
              onSelected: (selected) {
                setState(() {
                  _isEqualSplit = true;
                  _updateSplits();
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('مخصص'),
              selected: !_isEqualSplit,
              onSelected: (selected) {
                setState(() {
                  _isEqualSplit = false;
                  _updateSplits();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isEqualSplit) _buildEqualSplitView() else _buildCustomSplitView(),
      ],
    );
  }

  Widget _buildEqualSplitView() {
    return Column(
      children: [
        for (int i = 0; i < widget.memberIds.length; i++)
          CheckboxListTile(
            title: Text(widget.memberNames[i]),
            value: _selectedMembers.contains(widget.memberIds[i]),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedMembers.add(widget.memberIds[i]);
                } else {
                  _selectedMembers.remove(widget.memberIds[i]);
                }
                _updateSplits();
              });
            },
          ),
      ],
    );
  }

  Widget _buildCustomSplitView() {
    return Column(
      children: [
        for (int i = 0; i < widget.memberIds.length; i++)
          if (_selectedMembers.contains(widget.memberIds[i]))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.memberNames[i]),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final amount = (double.tryParse(value) ?? 0) * 100;
                        setState(() {
                          _customAmounts[widget.memberIds[i]] = amount.round();
                          _updateSplits();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

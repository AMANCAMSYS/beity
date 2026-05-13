import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final int maxRating;
  final double size;
  final bool enabled;

  const StarRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.maxRating = 5,
    this.size = 40.0,
    this.enabled = true,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starNumber = index + 1;
        final isFilled = starNumber <= _currentRating;
        return Semantics(
          button: true,
          label: '$starNumber star${starNumber > 1 ? 's' : ''}',
          selected: isFilled,
          child: GestureDetector(
            onTap: widget.enabled
                ? () {
                    setState(() {
                      _currentRating = starNumber;
                    });
                    widget.onRatingChanged(starNumber);
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                isFilled ? Icons.star : Icons.star_border,
                size: widget.size,
                color: isFilled
                    ? Colors.amber
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        );
      }),
    );
  }
}

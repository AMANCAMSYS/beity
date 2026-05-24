import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PendingSyncIndicator extends StatelessWidget {
  final double size;

  const PendingSyncIndicator({
    super.key,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.cloud_upload_outlined,
      size: size,
      color: AppColors.warning,
    );
  }
}

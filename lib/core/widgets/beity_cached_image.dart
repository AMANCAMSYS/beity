import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BeityCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool isAvatar;
  final Color? backgroundColor;

  const BeityCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.isAvatar = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildWrapper(_buildErrorWidget());
    }

    final imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );

    return _buildWrapper(imageWidget);
  }

  Widget _buildWrapper(Widget child) {
    if (isAvatar) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.grey.withValues(alpha: 0.1),
        ),
        child: ClipOval(child: child),
      );
    }
    return child;
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: backgroundColor ?? Colors.grey.withValues(alpha: 0.1),
          child: Icon(
            isAvatar ? Icons.person_rounded : Icons.image_not_supported_rounded,
            color: Colors.grey,
            size: (width != null && width! < 30) ? 16 : 24,
          ),
        );
  }
}

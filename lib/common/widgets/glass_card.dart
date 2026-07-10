import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final BorderSide? borderSide;
  final Color? fillCol;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BoxShape shape;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 15,
    this.borderSide,
    this.fillCol,
    this.padding,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: const Color(0x0F007AFF), // 6% opacity blue shadow
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape == BoxShape.circle 
            ? BorderRadius.zero 
            : BorderRadius.circular(borderRadius),
        clipBehavior: shape == BoxShape.circle ? Clip.none : Clip.antiAlias,
        child: shape == BoxShape.circle 
          ? ClipOval(child: _buildBlurContainer()) 
          : _buildBlurContainer(),
      ),
    );
  }

  Widget _buildBlurContainer() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
          border: Border.fromBorderSide(
            borderSide ?? const BorderSide(color: AppColors.glassBorder, width: 1.2),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              fillCol ?? AppColors.glassFill,
              Colors.white.withOpacity(0.7),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

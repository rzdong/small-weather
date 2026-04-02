import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/neu_theme.dart';

class NeuContainer extends StatelessWidget {
  final Widget? child;
  final double radius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isInner;
  final double distance;
  final double blur;
  final BoxShape shape;
  final Color? customBgColor;
  final double? intensity;

  const NeuContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.radius = 16.0,
    this.margin,
    this.isInner = false,
    this.distance = 6.0,
    this.blur = 12.0,
    this.shape = BoxShape.rectangle,
    this.customBgColor,
    this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    BoxDecoration decoration;
    Color bgColor = customBgColor ?? NeuTheme.getBg(provider.isDarkMode);

    double currentIntensity = intensity ?? provider.shadowIntensity;

    if (isInner) {
      decoration = BoxDecoration(
        color: bgColor,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
        boxShadow: NeuTheme.getInnerShadow(
          isDark: provider.isDarkMode,
          angle: provider.lightAngle,
          intensity: currentIntensity,
          distance: distance,
          blur: blur,
        ),
      );
    } else {
      decoration = BoxDecoration(
        color: bgColor,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
        boxShadow: NeuTheme.getOuterShadow(
          isDark: provider.isDarkMode,
          angle: provider.lightAngle,
          intensity: currentIntensity,
          distance: distance,
          blur: blur,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}

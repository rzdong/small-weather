import 'package:flutter/material.dart';
import 'dart:math';

class NeuTheme {
  // Light Mode Colors
  static const Color lightBg = Color(0xFFE0E6ED);
  static const Color lightTextPrime = Color(0xFF3F4A5E);
  static const Color lightTextSec = Color(0xFF76869F);
  static const Color lightHighlight = Color(0xFFFFFFFF);
  static const Color lightShadow = Color(0xFFA3B1C6);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF2E3A4B);
  static const Color darkTextPrime = Color(0xFFE0E6ED);
  static const Color darkTextSec = Color(0xFFA3B1C6);
  static const Color darkHighlight = Color(0xFF3A485A);
  static const Color darkShadow = Color(0xFF222C3C);

  static Color getBg(bool isDark) => isDark ? darkBg : lightBg;
  static Color getPrimaryText(bool isDark) => isDark ? darkTextPrime : lightTextPrime;
  static Color getSecondaryText(bool isDark) => isDark ? darkTextSec : lightTextSec;

  static List<BoxShadow> getOuterShadow({
    required bool isDark,
    required double angle,
    required double intensity,
    double distance = 6.0,
    double blur = 12.0,
  }) {
    double dxHighlight = cos(angle) * distance * intensity;
    double dyHighlight = sin(angle) * distance * intensity;
    
    double dxShadow = -dxHighlight;
    double dyShadow = -dyHighlight;

    return [
      BoxShadow(
        color: isDark ? darkHighlight : lightHighlight,
        offset: Offset(dxHighlight, dyHighlight),
        blurRadius: blur * intensity,
      ),
      BoxShadow(
        color: isDark ? darkShadow : lightShadow,
        offset: Offset(dxShadow, dyShadow),
        blurRadius: blur * intensity,
      ),
    ];
  }

  // Without inset package, we simulate it by swapping highlight/shadow colors and offsets
  static List<BoxShadow> getInnerShadow({
    required bool isDark,
    required double angle,
    required double intensity,
    double distance = 4.0,
    double blur = 8.0,
  }) {
    // Determine the offset for highlight (Sun direction)
    double dxHighlight = cos(angle) * distance * intensity;
    double dyHighlight = sin(angle) * distance * intensity;
    
    // For a simulated inset: 
    // The top-left (light source side) should have a SHADOW color to look recessed
    // The bottom-right (away from light) should have a HIGHLIGHT color
    return [
      BoxShadow(
        color: isDark ? darkShadow : lightShadow,
        offset: Offset(dxHighlight, dyHighlight),
        blurRadius: blur * intensity,
      ),
      BoxShadow(
        color: isDark ? darkHighlight : lightHighlight,
        offset: Offset(-dxHighlight, -dyHighlight),
        blurRadius: blur * intensity,
      ),
    ];
  }
}

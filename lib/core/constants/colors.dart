import 'package:flutter/material.dart';

class AppColors {
  // Base light background
  static const Color background = Color(0xFFFFFBDE); // Soft cream

  // Primary & secondary
  static const Color primary = Color(0xFF129990); // Teal green
  static const Color secondary = Color(0xFF90D1CA); // Light teal accent

  // Darker contrast tone
  static const Color contrast = Color(0xFF096B68); // Deep teal

  // Text colors
  static const Color textPrimary = Color(0xFF000000); // Black
  static const Color textSecondary = Color(0xFF333333); // Dark grey

  // Status colors
  static const Color success = Color(0xFF00A86B); // Green
  static const Color error = Color(0xFFD32F2F); // Red
  static const Color warning = Color(0xFFFFA000); // Orange

  // Button gradient (Optional)
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF90D1CA), Color(0xFF129990)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

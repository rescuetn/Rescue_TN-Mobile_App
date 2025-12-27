import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// This file contains all the static and constant values used throughout the application.
/// Centralizing these values makes it easy to maintain a consistent design system
/// and allows for quick theme updates.
///
/// For responsive sizing, use the responsive getters (e.g., AppPadding.smallR)
/// which scale based on screen size. The static values are kept for backward
/// compatibility and for cases where fixed sizing is needed.

// ==========================================================================
// App Colors
// ==========================================================================

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Main Palette
  static const Color primary = Color(0xFF1E88E5); // A strong, trustworthy blue
  static const Color onPrimary = Colors.white;

  static const Color accent = Color(0xFFFFC107); // A warm, attention-grabbing amber
  static const Color onAccent = Colors.black;

  static const Color background = Color(0xFFF5F5F5); // A light grey for the background
  static const Color surface = Colors.white; // For cards and surfaces

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // For headlines and primary text
  static const Color textSecondary = Color(0xFF757575); // For subheadings and secondary text

  // Other Colors
  static const Color error = Color(0xFFD32F2F); // A standard error red
}


// ==========================================================================
// App Padding and Spacing
// ==========================================================================

class AppPadding {
  // Prevent instantiation
  AppPadding._();

  // Static values (for backward compatibility)
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xLarge = 32.0;

  // Responsive values (use these for adaptive layouts)
  static double get smallR => 8.w;
  static double get mediumR => 16.w;
  static double get largeR => 24.w;
  static double get xLargeR => 32.w;
}


// ==========================================================================
// App Border Radius
// ==========================================================================

class AppBorderRadius {
  // Prevent instantiation
  AppBorderRadius._();

  // Static values (for backward compatibility)
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 16.0;
  static const double circle = 50.0;

  // Responsive values (use these for adaptive layouts)
  static double get smallR => 4.r;
  static double get mediumR => 8.r;
  static double get largeR => 16.r;
  static double get circleR => 50.r;
}


// ==========================================================================
// App Font Sizes (Responsive)
// ==========================================================================

class AppFontSize {
  // Prevent instantiation
  AppFontSize._();

  // Static values
  static const double xs = 10.0;
  static const double small = 12.0;
  static const double body = 14.0;
  static const double medium = 16.0;
  static const double large = 18.0;
  static const double title = 20.0;
  static const double headline = 24.0;
  static const double display = 32.0;

  // Responsive values
  static double get xsR => 10.sp;
  static double get smallR => 12.sp;
  static double get bodyR => 14.sp;
  static double get mediumR => 16.sp;
  static double get largeR => 18.sp;
  static double get titleR => 20.sp;
  static double get headlineR => 24.sp;
  static double get displayR => 32.sp;
}


// ==========================================================================
// App Icon Sizes (Responsive)
// ==========================================================================

class AppIconSize {
  // Prevent instantiation
  AppIconSize._();

  // Static values
  static const double small = 16.0;
  static const double medium = 24.0;
  static const double large = 32.0;
  static const double xLarge = 48.0;

  // Responsive values
  static double get smallR => 16.r;
  static double get mediumR => 24.r;
  static double get largeR => 32.r;
  static double get xLargeR => 48.r;
}

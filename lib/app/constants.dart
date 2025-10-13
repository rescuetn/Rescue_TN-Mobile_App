import 'package:flutter/material.dart';

/// This file contains all the static and constant values used throughout the application.
/// Centralizing these values makes it easy to maintain a consistent design system
/// and allows for quick theme updates.

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

  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xLarge = 32.0;
}


// ==========================================================================
// App Border Radius
// ==========================================================================

class AppBorderRadius {
  // Prevent instantiation
  AppBorderRadius._();

  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 16.0;
  static const double circle = 50.0;
}


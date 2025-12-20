import 'package:flutter/material.dart';
import 'package:rescuetn/app/constants.dart';

/// This file defines the master theme for the entire application.
/// By setting up ThemeData here, we ensure that all widgets, buttons, app bars,
/// and text fields have a consistent and polished appearance.

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter', // A clean, modern font. Add it to pubspec.yaml and assets.

      // Define the color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accent,
        onSecondary: AppColors.onAccent,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),

      // Define AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 4,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.onPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Define ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.large,
            vertical: AppPadding.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Define Card theme
      // cardTheme: CardTheme(
      //   elevation: 2,
      //   margin: const EdgeInsets.all(AppPadding.small),
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      //   ),
      // ),

      // Define InputDecoration theme for text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppPadding.medium, vertical: AppPadding.medium),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),

      // Define text themes
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.textPrimary),
      ),
    );
  }
}


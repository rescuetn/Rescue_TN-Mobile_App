import 'package:flutter/material.dart';
import 'package:rescuetn/app/constants.dart';

/// A reusable, styled button for social media sign-in options.
///
/// This widget provides a consistent look and feel for different social logins
/// (e.g., Google, Facebook, Apple) and can be easily customized with different
/// icons, text, and colors.
class SocialLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Widget icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const SocialLoginButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
    this.backgroundColor = AppColors.surface,
    this.foregroundColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: icon,
      label: Text(text),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size(double.infinity, 54), // Make button taller
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          // Add a subtle border for definition
          side: BorderSide(color: Colors.grey.shade300),
        ),
        elevation: 1, // Add a slight shadow for depth
        shadowColor: Colors.black.withOpacity(0.1),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

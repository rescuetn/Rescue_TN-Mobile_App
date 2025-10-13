import 'package:flutter/material.dart';

/// A reusable custom button widget to ensure a consistent style across the app.
/// It can display a loading indicator, which is useful for asynchronous operations.

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed, // Disable button when loading
      child: isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Colors.white,
        ),
      )
          : Text(text),
    );
  }
}

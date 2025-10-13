import 'package:flutter/material.dart';

enum AlertLevel { info, warning, severe }

class Alert {
  final String id;
  final String title;
  final String message;
  final AlertLevel level;
  final DateTime timestamp;

  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.level,
    required this.timestamp,
  });
}

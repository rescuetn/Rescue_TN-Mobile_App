import 'package:cloud_firestore/cloud_firestore.dart';
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

  // A factory constructor to create an Alert from a Firestore document.
  factory Alert.fromMap(Map<String, dynamic> map, String id) {
    return Alert(
      id: id,
      title: map['title'] ?? 'No Title',
      message: map['message'] ?? 'No message provided.',
      level: AlertLevel.values.firstWhere(
            (e) => e.name == map['level'],
        orElse: () => AlertLevel.info,
      ),
      timestamp: (map['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rescuetn/models/user_model.dart';

enum AlertLevel { info, warning, severe }

class Alert {
  final String id;
  final String title;
  final String message;
  final AlertLevel level;
  final DateTime timestamp;
  final List<String>? targetRoles; // null = all users, or specific roles
  final String? imageUrl;
  final bool isRead;
  final String? actionUrl;

  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.level,
    required this.timestamp,
    this.targetRoles,
    this.imageUrl,
    this.isRead = false,
    this.actionUrl,
  });

  /// Check if this alert is for the given user role
  bool isForRole(UserRole userRole) {
    if (targetRoles == null || targetRoles!.isEmpty) {
      return true; // All roles receive it
    }
    return targetRoles!.contains(userRole.name);
  }

  /// Create a copy with updated fields
  Alert copyWith({
    String? id,
    String? title,
    String? message,
    AlertLevel? level,
    DateTime? timestamp,
    List<String>? targetRoles,
    String? imageUrl,
    bool? isRead,
    String? actionUrl,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      targetRoles: targetRoles ?? this.targetRoles,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'level': level.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'targetRoles': targetRoles,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'actionUrl': actionUrl,
    };
  }

  // A factory constructor to create an Alert from a Firestore document.
  factory Alert.fromMap(Map<String, dynamic> map, String id) {
    // Handle both 'timestamp' and 'createdAt' fields with proper null handling
    DateTime timestamp;
    final createdAtValue = map['createdAt'];
    final timestampValue = map['timestamp'];
    
    if (createdAtValue is Timestamp) {
      timestamp = createdAtValue.toDate();
    } else if (timestampValue is Timestamp) {
      timestamp = timestampValue.toDate();
    } else {
      timestamp = DateTime.now();
    }

    return Alert(
      id: id,
      title: map['title'] ?? 'No Title',
      message: map['message'] ?? 'No message provided.',
      level: AlertLevel.values.firstWhere(
        (e) => e.name == map['level'],
        orElse: () => map['level'] == 'critical'
            ? AlertLevel.severe
            : AlertLevel.info,
      ),
      timestamp: timestamp,
      targetRoles: map['targetRoles'] != null
          ? List<String>.from(map['targetRoles'])
          : null,
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
      actionUrl: map['actionUrl'],
    );
  }

  /// Create Alert from FCM notification payload
  factory Alert.fromFCM(Map<String, dynamic> data,
      {String? title, String? body}) {
    return Alert(
      id: data['alertId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? data['title'] ?? 'Alert',
      message: body ?? data['message'] ?? data['body'] ?? 'New notification',
      level: AlertLevel.values.firstWhere(
        (e) => e.name == data['level'],
        orElse: () => AlertLevel.info,
      ),
      timestamp: DateTime.now(),
      targetRoles: data['targetRoles'] != null
          ? List<String>.from(data['targetRoles'].toString().split(','))
          : null,
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
    );
  }
}

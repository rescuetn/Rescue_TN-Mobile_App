import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rescuetn/models/incident_model.dart';

enum TaskStatus { pending, accepted, inProgress, completed }

class Task {
  final String id;
  final String title;
  final String incidentId;
  final String description;
  final Severity severity;
  final TaskStatus status;
  final String? assignedTo; // local alias for volunteerId
  
  // New fields from backend schema
  final String? location;
  final DateTime? assignedAt;
  final String? assignedBy;
  final String? assignedByName;
  final String? volunteerName;
  final DateTime? completedAt;
  final DateTime? updatedAt;
  final String? completionImageUrl; // Proof of completion

  const Task({
    required this.id,
    required this.title,
    required this.incidentId,
    required this.description,
    required this.severity,
    required this.status,
    this.assignedTo,
    this.location,
    this.assignedAt,
    this.assignedBy,
    this.assignedByName,
    this.volunteerName,
    this.completedAt,
    this.updatedAt,
    this.completionImageUrl,
  });

  Task copyWith({
    TaskStatus? status,
    String? assignedTo,
    String? completionImageUrl,
    // Add other fields if needed for copyWith, but these are primarily for status updates
  }) {
    return Task(
      id: id,
      title: title,
      incidentId: incidentId,
      description: description,
      severity: severity,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      location: location,
      assignedAt: assignedAt,
      assignedBy: assignedBy,
      assignedByName: assignedByName,
      volunteerName: volunteerName,
      completedAt: completedAt,
      updatedAt: updatedAt,
      completionImageUrl: completionImageUrl ?? this.completionImageUrl,
    );
  }

  // --- Factory constructor to create a Task from a Firestore map ---
  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      // Map 'taskTitle' to 'title', fallback to 'title' for backward compatibility
      title: map['taskTitle'] ?? map['title'] ?? 'Untitled Task',
      incidentId: map['incidentId'] ?? '',
      // Map 'taskDescription' to 'description', fallback to 'description'
      description: map['taskDescription'] ?? map['description'] ?? '',
      // Map 'priority' to 'severity'
      severity: _parseSeverity(map['priority'] ?? map['severity']),
      status: _parseStatus(map['status']),
      // Map 'volunteerId' to 'assignedTo'
      assignedTo: map['volunteerId'] ?? map['assignedTo'],
      
      // New fields
      location: map['location'],
      assignedAt: _parseTimestamp(map['assignedAt']),
      assignedBy: map['assignedBy'],
      assignedByName: map['assignedByName'],
      volunteerName: map['volunteerName'],
      completedAt: _parseTimestamp(map['completedAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      completionImageUrl: map['completionImageUrl'],
    );
  }

  // --- Method to convert a Task object into a map for Firestore ---
  Map<String, dynamic> toMap() {
    return {
      'taskTitle': title,
      'incidentId': incidentId,
      'taskDescription': description,
      'priority': severity.name,
      'status': status.name,
      'volunteerId': assignedTo,
      'location': location,
      'assignedAt': assignedAt, // Firestore handles DateTime conversion
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'volunteerName': volunteerName,
      'completedAt': completedAt,
      'updatedAt': updatedAt ?? DateTime.now(),
      'completionImageUrl': completionImageUrl,
    };
  }

  static Severity _parseSeverity(dynamic value) {
    if (value == null) return Severity.low;
    final stringValue = value.toString().toLowerCase();
    
    if (stringValue == 'high' || stringValue == 'critical') return Severity.high;
    if (stringValue == 'medium' || stringValue == 'moderate') return Severity.medium;
    return Severity.low;
  }

  static TaskStatus _parseStatus(dynamic value) {
    if (value == null) return TaskStatus.pending;
    final stringValue = value.toString().toLowerCase();
    
    if (stringValue == 'active') return TaskStatus.inProgress;
    
    return TaskStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == stringValue,
      orElse: () => TaskStatus.pending,
    );
  }
  
  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}


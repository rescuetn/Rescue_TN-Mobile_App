import 'package:rescuetn/models/incident_model.dart';

enum TaskStatus { pending, accepted, inProgress, completed }

class Task {
  final String id;
  final String title;
  final String incidentId;
  final String description;
  final Severity severity;
  final TaskStatus status;
  final String? assignedTo; // NEW: Field to store assigned volunteer ID

  const Task({
    required this.id,
    required this.title,
    required this.incidentId,
    required this.description,
    required this.severity,
    required this.status,
    this.assignedTo,
  });

  Task copyWith({
    TaskStatus? status,
    String? assignedTo,
  }) {
    return Task(
      id: id,
      title: title,
      incidentId: incidentId,
      description: description,
      severity: severity,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  // --- NEW: Factory constructor to create a Task from a Firestore map ---
  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      incidentId: map['incidentId'] ?? '',
      description: map['description'] ?? '',
      severity: Severity.values.firstWhere(
            (e) => e.name == map['severity'],
        orElse: () => Severity.low,
      ),
      status: TaskStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      assignedTo: map['assignedTo'],
    );
  }

  // --- NEW: Method to convert a Task object into a map for Firestore ---
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'incidentId': incidentId,
      'description': description,
      'severity': severity.name,
      'status': status.name,
      'assignedTo': assignedTo,
    };
  }
}


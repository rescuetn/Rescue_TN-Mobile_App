import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum PreparednessCategory { essentials, documents, actions, other } // Added 'other' for fallback

@immutable
class PreparednessItem {
  final String id;
  final String title;
  final String description;
  final PreparednessCategory category;
  final bool isCompleted;

  const PreparednessItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.isCompleted = false,
  });

  PreparednessItem copyWith({bool? isCompleted}) {
    return PreparednessItem(
      id: id,
      title: title,
      description: description,
      category: category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Converts this PreparednessItem object into a map that can be stored in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'isCompleted': isCompleted,
    };
  }

  /// A factory constructor to create a PreparednessItem object from a Firestore document map.
  factory PreparednessItem.fromMap(Map<String, dynamic> map, String id) {
    return PreparednessItem(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      // This safely handles cases where the category name might be missing or incorrect in the database.
      category: PreparednessCategory.values.firstWhere(
            (e) => e.name == map['category'],
        orElse: () => PreparednessCategory.other,
      ),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}


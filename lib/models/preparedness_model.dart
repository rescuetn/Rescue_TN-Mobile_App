import 'package:flutter/foundation.dart';

enum PreparednessCategory { essentials, documents, actions, other }

@immutable
class PreparednessItem {
  final String id;
  final String title;
  final String description;
  final PreparednessCategory category;
  final bool isCompleted;
  final int order;

  const PreparednessItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.isCompleted = false,
    this.order = 0,
  });

  PreparednessItem copyWith({bool? isCompleted}) {
    return PreparednessItem(
      id: id,
      title: title,
      description: description,
      category: category,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order,
    );
  }

  /// Converts this PreparednessItem object into a map that can be stored in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'isCompleted': isCompleted,
      'order': order,
    };
  }

  /// A factory constructor to create a PreparednessItem object from a Firestore document map.
  factory PreparednessItem.fromMap(Map<String, dynamic> map, String id) {
    return PreparednessItem(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: PreparednessCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => PreparednessCategory.other,
      ),
      isCompleted: map['isCompleted'] ?? false,
      order: map['order'] ?? 0,
    );
  }
}

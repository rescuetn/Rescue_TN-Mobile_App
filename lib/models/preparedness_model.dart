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

  static const List<PreparednessItem> defaultPlan = [
    PreparednessItem(
        id: 'p-01',
        title: 'Emergency Water Supply',
        description: 'Store at least 1 gallon of water per person per day.',
        category: PreparednessCategory.essentials,
        order: 1),
    PreparednessItem(
        id: 'p-02',
        title: 'Non-perishable Food',
        description: 'Stock a 3-day supply of non-perishable food.',
        category: PreparednessCategory.essentials,
        order: 2),
    PreparednessItem(
        id: 'p-03',
        title: 'First-Aid Kit',
        description: 'Ensure your first-aid kit is fully stocked.',
        category: PreparednessCategory.essentials,
        order: 3),
    PreparednessItem(
        id: 'p-04',
        title: 'Secure Important Documents',
        description:
            'Keep copies of passports, Aadhaar cards, etc., in a waterproof bag.',
        category: PreparednessCategory.documents,
        order: 4),
    PreparednessItem(
        id: 'p-05',
        title: 'Know Your Evacuation Route',
        description: 'Identify your local evacuation routes and have a plan.',
        category: PreparednessCategory.actions,
        order: 5),
  ];
}


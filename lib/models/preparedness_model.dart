import 'package:flutter/foundation.dart';

enum PreparednessCategory { essentials, documents, actions }

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
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rescuetn/models/preparedness_model.dart';

// A StateNotifier to manage the state of the preparedness checklist
class PreparednessPlanNotifier extends StateNotifier<List<PreparednessItem>> {
  PreparednessPlanNotifier() : super(_initialPlan);

  void toggleItemStatus(String itemId) {
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(isCompleted: !item.isCompleted)
        else
          item,
    ];
  }
}

final preparednessPlanProvider =
StateNotifierProvider<PreparednessPlanNotifier, List<PreparednessItem>>(
        (ref) {
      return PreparednessPlanNotifier();
    });

// A derived provider to calculate the completion percentage
final preparednessProgressProvider = Provider<double>((ref) {
  final items = ref.watch(preparednessPlanProvider);
  if (items.isEmpty) return 0;
  final completedItems = items.where((item) => item.isCompleted).length;
  return completedItems / items.length;
});


// Dummy data for the preparedness plan
const List<PreparednessItem> _initialPlan = [
  // Essentials
  PreparednessItem(
    id: 'p-01',
    title: 'Emergency Water Supply',
    description: 'Store at least 1 gallon of water per person per day for several days.',
    category: PreparednessCategory.essentials,
  ),
  PreparednessItem(
    id: 'p-02',
    title: 'Non-perishable Food',
    description: 'Stock a 3-day supply of non-perishable food items.',
    category: PreparednessCategory.essentials,
  ),
  PreparednessItem(
    id: 'p-03',
    title: 'First-Aid Kit',
    description: 'Ensure your first-aid kit is fully stocked and accessible.',
    category: PreparednessCategory.essentials,
  ),
  // Documents
  PreparednessItem(
    id: 'p-04',
    title: 'Secure Important Documents',
    description: 'Keep copies of passports, Aadhaar cards, and insurance policies in a waterproof bag.',
    category: PreparednessCategory.documents,
  ),
  // Actions
  PreparednessItem(
    id: 'p-05',
    title: 'Know Your Evacuation Route',
    description: 'Identify your local evacuation routes and have a plan.',
    category: PreparednessCategory.actions,
  ),
];


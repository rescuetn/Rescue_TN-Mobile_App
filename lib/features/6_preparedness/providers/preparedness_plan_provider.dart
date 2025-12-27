import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rescuetn/models/preparedness_model.dart';
import 'package:flutter/foundation.dart';

// Provider for the controller
final preparednessControllerProvider =
    StateNotifierProvider<PreparednessController, AsyncValue<List<PreparednessItem>>>((ref) {
  return PreparednessController();
});

// Alias for backward compatibility if needed, or simply use controller state directly in UI
final preparednessPlanProvider = Provider<AsyncValue<List<PreparednessItem>>>((ref) {
  return ref.watch(preparednessControllerProvider);
});

final preparednessProgressProvider = Provider<AsyncValue<double>>((ref) {
  final planAsync = ref.watch(preparednessControllerProvider);
  return planAsync.when(
    data: (items) {
      if (items.isEmpty) return const AsyncData(0.0);
      final completedItems = items.where((item) => item.isCompleted).length;
      return AsyncData(completedItems / items.length);
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

class PreparednessController extends StateNotifier<AsyncValue<List<PreparednessItem>>> {
  PreparednessController() : super(const AsyncLoading()) {
    _loadPlan();
  }

  static const String _storageKey = 'preparedness_plan_local';

  Future<void> _loadPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final items = jsonList
            .map((json) => PreparednessItem.fromMap(json, json['id'] ?? 'unknown'))
            .toList();
            
        // Sort by order
        items.sort((a, b) => a.order.compareTo(b.order));
        
        state = AsyncData(items);
      } else {
        // First run: Use default plan
        state = const AsyncData(PreparednessItem.defaultPlan);
        _savePlan(PreparednessItem.defaultPlan);
      }
    } catch (e, st) {
      debugPrint('Error loading preparedness plan: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> _savePlan(List<PreparednessItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(items.map((e) {
          // Add ID to map because toMap() might not include it if it was relying on doc ID
          var map = e.toMap();
          map['id'] = e.id; 
          return map;
      }).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving preparedness plan: $e');
    }
  }

  Future<void> toggleItemStatus(String itemId, bool currentStatus) async {
    state.whenData((items) {
      final updatedItems = items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isCompleted: !currentStatus);
        }
        return item;
      }).toList();

      state = AsyncData(updatedItems);
      _savePlan(updatedItems);
    });
  }
}

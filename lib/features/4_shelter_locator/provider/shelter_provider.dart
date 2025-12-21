import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/core/services/geocoding_service.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/shelter_model.dart';

/// An enum to represent the different filter states for the UI.
enum ShelterFilter { all, available, full, closed }

/// A StateProvider to hold the user's current filter selection.
final shelterFilterProvider = StateProvider.autoDispose<ShelterFilter>((ref) => ShelterFilter.all);

/// A StreamProvider that provides a real-time stream of all shelters from Firestore.
/// This also geocodes shelters that don't have coordinates but have a location name.
final shelterStreamProvider = StreamProvider.autoDispose<List<Shelter>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) {
    return Stream.value([]);
  }

  final databaseService = ref.watch(databaseServiceProvider);
  final geocodingService = ref.watch(geocodingServiceProvider);
  
  return databaseService.getSheltersStream().asyncMap((shelters) async {
    debugPrint('ShelterProvider: Received ${shelters.length} shelters from Firestore');
    
    // Process shelters to geocode those without coordinates
    final processedShelters = await Future.wait(
      shelters.map((shelter) async {
        debugPrint('ShelterProvider: Processing shelter "${shelter.name}"');
        debugPrint('  - hasValidCoordinates: ${shelter.hasValidCoordinates}');
        debugPrint('  - location: "${shelter.location}"');
        debugPrint('  - district: "${shelter.district}"');
        
        // If shelter already has valid coordinates, return as is
        if (shelter.hasValidCoordinates) {
          debugPrint('  - ✅ Already has coordinates: ${shelter.latitude}, ${shelter.longitude}');
          return shelter;
        }
        
        // Try to geocode using location name
        if (shelter.location.isNotEmpty) {
          debugPrint('  - Attempting geocode using location: "${shelter.location}"');
          final coords = await geocodingService.geocodeLocation(shelter.location);
          if (coords != null) {
            debugPrint('  - ✅ Geocoded successfully!');
            return Shelter(
              id: shelter.id,
              name: shelter.name,
              latitude: coords['latitude'],
              longitude: coords['longitude'],
              capacity: shelter.capacity,
              currentOccupancy: shelter.currentOccupancy,
              status: shelter.status,
              isGovernmentDesignated: shelter.isGovernmentDesignated,
              amenities: shelter.amenities,
              contactPerson: shelter.contactPerson,
              contactPhone: shelter.contactPhone,
              district: shelter.district,
              location: shelter.location,
              createdAt: shelter.createdAt,
              updatedAt: shelter.updatedAt,
            );
          }
        }
        
        // Try to geocode using shelter name + district
        if (shelter.district.isNotEmpty) {
          final searchQuery = '${shelter.name}, ${shelter.district}';
          debugPrint('  - Attempting geocode using name+district: "$searchQuery"');
          final coords = await geocodingService.geocodeLocation(searchQuery);
          if (coords != null) {
            debugPrint('  - ✅ Geocoded successfully with name+district!');
            return Shelter(
              id: shelter.id,
              name: shelter.name,
              latitude: coords['latitude'],
              longitude: coords['longitude'],
              capacity: shelter.capacity,
              currentOccupancy: shelter.currentOccupancy,
              status: shelter.status,
              isGovernmentDesignated: shelter.isGovernmentDesignated,
              amenities: shelter.amenities,
              contactPerson: shelter.contactPerson,
              contactPhone: shelter.contactPhone,
              district: shelter.district,
              location: shelter.location,
              createdAt: shelter.createdAt,
              updatedAt: shelter.updatedAt,
            );
          }
        }
        
        debugPrint('  - ❌ Could not geocode shelter');
        // Return shelter without coordinates if geocoding failed
        return shelter;
      }),
    );
    
    final geocodedCount = processedShelters.where((s) => s.hasValidCoordinates).length;
    debugPrint('ShelterProvider: Processing complete. $geocodedCount/${processedShelters.length} shelters have valid coordinates');
    
    return processedShelters;
  });
});

/// A derived Provider that returns a filtered list of shelters.
/// It watches both the main data stream and the filter provider.
final filteredShelterProvider = Provider.autoDispose<AsyncValue<List<Shelter>>>((ref) {
  final filter = ref.watch(shelterFilterProvider);
  final sheltersAsync = ref.watch(shelterStreamProvider);

  return sheltersAsync.when(
    data: (shelters) {
      if (filter == ShelterFilter.all) {
        return AsyncData(shelters);
      }
      final correspondingStatus = ShelterStatus.values.firstWhere((s) => s.name == filter.name);
      final filteredList = shelters.where((s) => s.status == correspondingStatus).toList();
      return AsyncData(filteredList);
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

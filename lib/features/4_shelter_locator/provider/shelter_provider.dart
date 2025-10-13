import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/models/shelter_model.dart';

/// A provider that supplies a list of dummy shelters for the demo app.
///
/// In a real application, this data would be fetched from a Firestore collection.
final shelterListProvider = Provider<List<Shelter>>((ref) {
  // Realistic dummy data for shelters in Chennai, Tamil Nadu.
  return const [
    Shelter(
      id: 'shelter_01',
      name: 'Govt. High School, Nungambakkam',
      latitude: 13.0625,
      longitude: 80.2450,
      capacity: 200,
      currentOccupancy: 150,
      status: ShelterStatus.available,
    ),
    Shelter(
      id: 'shelter_02',
      name: 'Community Hall, T. Nagar',
      latitude: 13.0400,
      longitude: 80.2350,
      capacity: 150,
      currentOccupancy: 150,
      status: ShelterStatus.full,
    ),
    Shelter(
      id: 'shelter_03',
      name: 'Corporation School, Saidapet',
      latitude: 13.0225,
      longitude: 80.2280,
      capacity: 100,
      currentOccupancy: 45,
      status: ShelterStatus.available,
    ),
    Shelter(
      id: 'shelter_04',
      name: 'Amma Arangam, Shenoy Nagar',
      latitude: 13.0800,
      longitude: 80.2150,
      capacity: 500,
      currentOccupancy: 120,
      status: ShelterStatus.available,
    ),
    Shelter(
      id: 'shelter_05',
      name: 'Relief Center, Velachery',
      latitude: 12.9785,
      longitude: 80.2190,
      capacity: 120,
      currentOccupancy: 120,
      status: ShelterStatus.closed,
    ),
  ];
});

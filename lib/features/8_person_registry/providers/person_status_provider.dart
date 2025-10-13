import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:rescuetn/models/person_status_model.dart';

// Using a StateNotifierProvider to allow adding new entries
class PersonStatusNotifier extends StateNotifier<List<PersonStatus>> {
  PersonStatusNotifier() : super(_initialData);

  void addPerson(PersonStatus person) {
    state = [...state, person];
  }
}

final personStatusProvider =
StateNotifierProvider<PersonStatusNotifier, List<PersonStatus>>((ref) {
  return PersonStatusNotifier();
});

// Dummy initial data
const List<PersonStatus> _initialData = [
  PersonStatus(
    id: 'ps-001',
    name: 'Kavitha S.',
    age: 45,
    status: PersonSafetyStatus.safe,
    lastKnownLocation: 'T. Nagar Relief Camp',
    submittedBy: 'public@test.com',
  ),
  PersonStatus(
    id: 'ps-002',
    name: 'Rajesh Kumar',
    age: 32,
    status: PersonSafetyStatus.missing,
    lastKnownLocation: 'Velachery',
    submittedBy: 'volunteer@test.com',
  ),
];

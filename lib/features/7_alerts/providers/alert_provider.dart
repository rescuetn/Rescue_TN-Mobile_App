import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/models/alert_model.dart';

final alertListProvider = Provider<List<Alert>>((ref) {
  // Dummy data for demonstration. In a real app, this would come from FCM or Firestore.
  return [
    Alert(
      id: 'alert-001',
      title: 'Severe Flood Warning',
      message: 'Heavy rainfall is expected in the next 24 hours. Residents in low-lying areas of Chennai are advised to evacuate to the nearest shelter.',
      level: AlertLevel.severe,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Alert(
      id: 'alert-002',
      title: 'High Wind Advisory',
      message: 'Strong winds are expected along the coastal areas. Fishermen are advised not to venture into the sea.',
      level: AlertLevel.warning,
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    Alert(
      id: 'alert-003',
      title: 'Relief Camp Information',
      message: 'A new relief camp has been set up at the Government Higher Secondary School in Adyar.',
      level: AlertLevel.info,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
});

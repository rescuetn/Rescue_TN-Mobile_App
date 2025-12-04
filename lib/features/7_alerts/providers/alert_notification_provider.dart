import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rescuetn/core/services/database_service.dart';
import 'package:rescuetn/core/services/notification_service.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/alert_model.dart';

/// Provider to get all alerts for the current user (role-based filtering)
final userAlertsProvider = StreamProvider<List<Alert>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final databaseService = ref.watch(databaseServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);

      // Get all alerts from database
      return databaseService.getAlertsStream().map((alerts) {
        // Filter alerts based on user's role
        return alerts.where((alert) => alert.isForRole(user.role)).toList();
      });
    },
    loading: () => Stream.value([]),
    error: (error, stack) => Stream.error(error),
  );
});

/// Provider to get unread alerts count
final unreadAlertsCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final databaseService = ref.watch(databaseServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(0);

      return databaseService.getAlertsStream().map((alerts) {
        final filtered =
            alerts.where((alert) => alert.isForRole(user.role)).toList();
        return filtered.where((alert) => !alert.isRead).length;
      });
    },
    loading: () => Stream.value(0),
    error: (error, stack) => Stream.error(error),
  );
});

/// Provider to get recent alerts (last 5)
final recentAlertsProvider = StreamProvider<List<Alert>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final databaseService = ref.watch(databaseServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);

      return databaseService.getAlertsStream().map((alerts) {
        final filtered =
            alerts.where((alert) => alert.isForRole(user.role)).toList();
        return filtered.take(5).toList();
      });
    },
    loading: () => Stream.value([]),
    error: (error, stack) => Stream.error(error),
  );
});

/// Notifier for managing alert interactions
class AlertNotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AlertNotificationNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      await databaseService.updateAlertStatus(alertId, true);
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Clear all unread alerts
  Future<void> clearUnreadAlerts() async {
    state = const AsyncValue.loading();
    try {
      final alerts = _ref.read(userAlertsProvider).value ?? [];
      final databaseService = _ref.read(databaseServiceProvider);

      for (final alert in alerts.where((a) => !a.isRead)) {
        await databaseService.updateAlertStatus(alert.id, true);
      }

      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

/// Provider for alert notification interactions
final alertNotificationProvider =
    StateNotifierProvider<AlertNotificationNotifier, AsyncValue<void>>((ref) {
  return AlertNotificationNotifier(ref);
});

/// Provider to get FCM token for the current user
final fcmTokenForUserProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.getFCMToken();
});

/// Provider to listen to FCM token changes
final fcmTokenStreamProvider = StreamProvider<String>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.fcmTokenStream;
});

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // The missing import that fixes the errors
import 'package:geolocator/geolocator.dart';
import 'package:rescuetn/features/1_auth/providers/auth_provider.dart';
import 'package:rescuetn/models/incident_model.dart';
import 'package:rescuetn/features/3_incident_reporting/repository/incident_repository.dart';

/// Represents the different states of the incident submission process.
class ReportIncidentState {
  final bool isLoading;
  final String uploadStatus;
  final double uploadProgress;
  final String? error;
  final bool isSuccess;

  const ReportIncidentState({
    this.isLoading = false,
    this.uploadStatus = '',
    this.uploadProgress = 0.0,
    this.error,
    this.isSuccess = false,
  });

  ReportIncidentState copyWith({
    bool? isLoading,
    String? uploadStatus,
    double? uploadProgress,
    String? error,
    bool? isSuccess,
  }) {
    return ReportIncidentState(
      isLoading: isLoading ?? this.isLoading,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// A StateNotifierProvider that creates and manages the state for the
/// incident reporting feature using the [ReportIncidentNotifier].
final reportIncidentProvider =
StateNotifierProvider.autoDispose<ReportIncidentNotifier, ReportIncidentState>(
      (ref) => ReportIncidentNotifier(
    repository: ref.read(incidentRepositoryProvider),
    ref: ref,
  ),
);

/// The Notifier that contains all the business logic for submitting an incident.
class ReportIncidentNotifier extends StateNotifier<ReportIncidentState> {
  final IncidentRepository repository;
  final Ref ref;

  ReportIncidentNotifier({
    required this.repository,
    required this.ref,
  }) : super(const ReportIncidentState());

  Future<void> submitIncident({
    required IncidentType type,
    required String description,
    required Severity severity,
    required Position position,
    String? district,
    required List<File> images,
    required List<String> audioPaths,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user == null) {
        throw Exception('User is not logged in. Cannot submit report.');
      }

      final incident = Incident(
        type: type,
        description: description,
        severity: severity,
        latitude: position.latitude,
        longitude: position.longitude,
        district: district,
        reportedBy: user.uid,
        timestamp: DateTime.now(),
      );

      await repository.submitIncident(
        incident: incident,
        images: images,
        audioPaths: audioPaths,
        onProgress: (status, progress) {
          // It's safe to update state here. Notifier is not a widget.
          state = state.copyWith(
            uploadStatus: status,
            uploadProgress: progress,
          );
        },
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Resets the state to its initial values after submission.
  void reset() {
    state = const ReportIncidentState();
  }
}


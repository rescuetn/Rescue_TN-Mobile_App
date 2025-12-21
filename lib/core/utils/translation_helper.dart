import 'package:flutter/material.dart';
import 'package:rescuetn/models/incident_model.dart';
import 'package:rescuetn/models/task_model.dart';
import 'package:rescuetn/core/providers/locale_provider.dart';

/// Helper class for translating enum values and backend data
class TranslationHelper {
  /// Translate incident type
  static String translateIncidentType(BuildContext context, IncidentType type) {
    final key = 'incidentTypes.${type.name}';
    return key.tr(context);
  }

  /// Translate severity
  static String translateSeverity(BuildContext context, Severity severity) {
    final key = 'severityLevels.${severity.name}';
    return key.tr(context);
  }

  /// Translate task status
  static String translateTaskStatus(BuildContext context, TaskStatus status) {
    final key = 'taskStatuses.${status.name}';
    return key.tr(context);
  }

  /// Translate shelter status
  static String translateShelterStatus(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'shelterStatuses.open'.tr(context);
      case 'full':
        return 'shelterStatuses.full'.tr(context);
      case 'closed':
        return 'shelterStatuses.closed'.tr(context);
      default:
        return status;
    }
  }

  /// Translate preparedness category
  static String translatePreparednessCategory(BuildContext context, String category) {
    switch (category.toLowerCase()) {
      case 'essentials':
        return 'preparedness.essentials'.tr(context);
      case 'documents':
        return 'preparedness.documents'.tr(context);
      case 'actions':
        return 'preparedness.actions'.tr(context);
      default:
        return 'preparedness.other'.tr(context);
    }
  }

  /// Translate volunteer status
  static String translateVolunteerStatus(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'volunteerStatus.available'.tr(context);
      case 'deployed':
        return 'volunteerStatus.deployed'.tr(context);
      case 'unavailable':
        return 'volunteerStatus.unavailable'.tr(context);
      default:
        return status;
    }
  }

  /// Translate alert level
  static String translateAlertLevel(BuildContext context, String level) {
    switch (level.toLowerCase()) {
      case 'severe':
        return 'alerts.tabSevere'.tr(context);
      case 'warning':
        return 'alerts.tabWarning'.tr(context);
      case 'info':
        return 'alerts.tabInfo'.tr(context);
      default:
        return level;
    }
  }

  /// Translate person safety status
  static String translatePersonStatus(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return 'personRegistry.markedSafe'.tr(context);
      case 'missing':
        return 'personRegistry.reportedMissing'.tr(context);
      case 'found':
        return 'personRegistry.personFound'.tr(context);
      default:
        return status;
    }
  }
}

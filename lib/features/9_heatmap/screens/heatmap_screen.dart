import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/3_incident_reporting/repository/incident_repository.dart';
import 'package:rescuetn/models/incident_model.dart';

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _showHeatmap = true;
  bool _showMarkers = false;
  Set<Marker> _markers = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Assigns a weight/intensity to each incident based on severity
  double _getWeightForSeverity(Severity severity) {
    switch (severity) {
      case Severity.critical:
        return 5.0; // Highest intensity
      case Severity.high:
        return 3.0;
      case Severity.medium:
        return 2.0;
      case Severity.low:
      default:
        return 1.0; // Lowest intensity
    }
  }

  /// Get color for severity
  Color _getColorForSeverity(Severity severity) {
    switch (severity) {
      case Severity.critical:
        return Colors.red.shade700;
      case Severity.high:
        return Colors.orange.shade700;
      case Severity.medium:
        return Colors.yellow.shade700;
      case Severity.low:
      default:
        return Colors.green.shade700;
    }
  }

  /// Get icon for incident type
  IconData _getIconForType(IncidentType type) {
    switch (type) {
      case IncidentType.flood:
        return Icons.water_damage_rounded;
      case IncidentType.fire:
        return Icons.local_fire_department_rounded;
      case IncidentType.earthquake:
        return Icons.crisis_alert_rounded;
      case IncidentType.accident:
        return Icons.car_crash_rounded;
      case IncidentType.medical:
        return Icons.medical_services_rounded;
      case IncidentType.other:
      default:
        return Icons.warning_rounded;
    }
  }

  /// Get formatted type label
  String _getTypeLabel(IncidentType type) {
    switch (type) {
      case IncidentType.flood:
        return 'Flood';
      case IncidentType.fire:
        return 'Fire';
      case IncidentType.earthquake:
        return 'Earthquake';
      case IncidentType.accident:
        return 'Accident';
      case IncidentType.medical:
        return 'Medical Emergency';
      case IncidentType.other:
      default:
        return 'Other';
    }
  }

  /// Create markers from incidents
  void _createMarkers(List<Incident> incidents) {
    _markers = incidents.map((incident) {
      return Marker(
        markerId: MarkerId(incident.id ?? DateTime.now().toString()),
        position: LatLng(incident.latitude, incident.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getHueForSeverity(incident.severity),
        ),
        infoWindow: InfoWindow(
          title: _getTypeLabel(incident.type),
          snippet: '${incident.severity.name.toUpperCase()} - ${incident.description.length > 30 ? '${incident.description.substring(0, 30)}...' : incident.description}',
        ),
        onTap: () => _showIncidentDetails(incident),
      );
    }).toSet();
  }

  /// Get marker hue based on severity
  double _getHueForSeverity(Severity severity) {
    switch (severity) {
      case Severity.critical:
        return BitmapDescriptor.hueRed;
      case Severity.high:
        return BitmapDescriptor.hueOrange;
      case Severity.medium:
        return BitmapDescriptor.hueYellow;
      case Severity.low:
      default:
        return BitmapDescriptor.hueGreen;
    }
  }

  /// Show incident details in bottom sheet
  void _showIncidentDetails(Incident incident) {
    final color = _getColorForSeverity(incident.severity);
    final icon = _getIconForType(incident.type);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTypeLabel(incident.type),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                incident.severity.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description_rounded, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                incident.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Coordinates',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${incident.latitude.toStringAsFixed(6)}, ${incident.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timestamp
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reported',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(incident.timestamp),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Media Section
                  if (incident.imageUrls.isNotEmpty || incident.audioUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attachment_rounded, color: color, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'Attachments',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (incident.imageUrls.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.image_rounded, color: color, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '${incident.imageUrls.length} ${incident.imageUrls.length == 1 ? 'Image' : 'Images'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          if (incident.imageUrls.isNotEmpty && incident.audioUrls.isNotEmpty)
                            const SizedBox(height: 8),
                          if (incident.audioUrls.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.audio_file_rounded, color: color, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '${incident.audioUrls.length} Audio ${incident.audioUrls.length == 1 ? 'File' : 'Files'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
      final period = timestamp.hour >= 12 ? 'PM' : 'AM';
      return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year} at ${hour == 0 ? 12 : hour}:${timestamp.minute.toString().padLeft(2, '0')} $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live stream of incidents from Firestore
    final incidentsAsync = ref.watch(incidentStreamProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepOrange.shade700,
              Colors.deepOrange.shade600,
              Colors.deepOrange.shade500,
              AppColors.background,
            ],
            stops: const [0.0, 0.15, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.heat_pump_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disaster Heatmap',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live incident visualization',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Map Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: incidentsAsync.when(
                        loading: () => const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading incident data...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    size: 64,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Unable to Load Map Data',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  err.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ref.invalidate(incidentStreamProvider);
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (incidents) {
                          if (incidents.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade50,
                                            Colors.blue.shade100.withOpacity(0.5),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        size: 80,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    const Text(
                                      'No Recent Incidents',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Great news! There are no disaster incidents to display on the map.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Create markers if marker view is enabled
                          if (_showMarkers) {
                            _createMarkers(incidents);
                          }

                          // Convert incidents to heatmap points
                          final heatmapPoints = incidents.map((incident) {
                            return WeightedLatLng(
                              LatLng(incident.latitude, incident.longitude),
                              weight: _getWeightForSeverity(incident.severity),
                            );
                          }).toSet();

                          // Create circles for visual representation (fallback if heatmap not supported)
                          final circles = incidents.map((incident) {
                            final color = _getColorForSeverity(incident.severity);
                            return Circle(
                              circleId: CircleId(incident.id ?? DateTime.now().toString()),
                              center: LatLng(incident.latitude, incident.longitude),
                              radius: _getWeightForSeverity(incident.severity) * 500,
                              fillColor: color.withOpacity(0.3),
                              strokeColor: color.withOpacity(0.8),
                              strokeWidth: 2,
                            );
                          }).toSet();

                          // Calculate stats
                          final criticalCount = incidents.where((i) => i.severity == Severity.critical).length;
                          final highCount = incidents.where((i) => i.severity == Severity.high).length;
                          final mediumCount = incidents.where((i) => i.severity == Severity.medium).length;

                          return Stack(
                            children: [
                              // Google Map
                              GoogleMap(
                                initialCameraPosition: const CameraPosition(
                                  target: LatLng(13.0827, 80.2707),
                                  zoom: 10.5,
                                ),
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                },
                                markers: _showMarkers ? _markers : {},
                                circles: _showHeatmap ? circles : {},
                                myLocationButtonEnabled: true,
                                myLocationEnabled: true,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                              ),

                              // Stats Card
                              Positioned(
                                top: 16,
                                left: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatItem(
                                        'Total',
                                        incidents.length.toString(),
                                        Colors.blue.shade600,
                                      ),
                                      _buildStatItem(
                                        'Critical',
                                        criticalCount.toString(),
                                        Colors.red.shade600,
                                      ),
                                      _buildStatItem(
                                        'High',
                                        highCount.toString(),
                                        Colors.orange.shade600,
                                      ),
                                      _buildStatItem(
                                        'Medium',
                                        mediumCount.toString(),
                                        Colors.yellow.shade700,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // View Toggle Buttons
                              Positioned(
                                bottom: 24,
                                left: 16,
                                right: 16,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildToggleButton(
                                        'Heatmap',
                                        Icons.heat_pump_rounded,
                                        _showHeatmap,
                                            () {
                                          setState(() {
                                            _showHeatmap = !_showHeatmap;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildToggleButton(
                                        'Markers',
                                        Icons.location_on_rounded,
                                        _showMarkers,
                                            () {
                                          setState(() {
                                            _showMarkers = !_showMarkers;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(
      String label,
      IconData icon,
      bool isActive,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          )
              : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
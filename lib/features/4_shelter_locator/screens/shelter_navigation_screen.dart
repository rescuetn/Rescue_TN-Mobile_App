import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/models/shelter_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ShelterNavigationScreen extends StatefulWidget {
  final Shelter shelter;

  const ShelterNavigationScreen({super.key, required this.shelter});

  @override
  State<ShelterNavigationScreen> createState() => _ShelterNavigationScreenState();
}

class _ShelterNavigationScreenState extends State<ShelterNavigationScreen> {
  // Google Maps API Key (same as in AndroidManifest.xml)
  static const String _googleApiKey = 'AIzaSyCLQ3cyXTMIDqcztRDR7v_Awrs-pLmJYoM';
  
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Route data
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  List<LatLng> _routePoints = [];
  
  // Distance and duration
  double? _distanceInMeters;
  String _distanceText = '--';
  String _durationText = '--';
  
  // Polyline points package
  final PolylinePoints _polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    await _getCurrentLocation();
    if (_currentPosition != null && widget.shelter.hasValidCoordinates) {
      await _getRoutePolyline();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled. Please enable them.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permission denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are permanently denied.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not get your location: $e';
      });
    }
  }

  Future<void> _getRoutePolyline() async {
    if (_currentPosition == null || !widget.shelter.hasValidCoordinates) {
      setState(() => _isLoading = false);
      return;
    }

    final startLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final endLatLng = LatLng(widget.shelter.latitude!, widget.shelter.longitude!);

    debugPrint('🗺️ Getting route from $startLatLng to $endLatLng');

    try {
      // Get route using flutter_polyline_points
      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(startLatLng.latitude, startLatLng.longitude),
          destination: PointLatLng(endLatLng.latitude, endLatLng.longitude),
          mode: TravelMode.driving,
        ),
      );

      debugPrint('🗺️ API Status: ${result.status}');
      debugPrint('🗺️ Error Message: ${result.errorMessage}');
      debugPrint('🗺️ Points count: ${result.points.length}');

      if (result.points.isNotEmpty) {
        // Convert points to LatLng list
        _routePoints = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        debugPrint('🗺️ ✅ Got ${_routePoints.length} route points!');
      } else {
        debugPrint('🗺️ ⚠️ No route points received, using straight line fallback');
        debugPrint('🗺️ Status: ${result.status}');
        debugPrint('🗺️ Error: ${result.errorMessage}');
        
        // Fallback to straight line
        _routePoints = [startLatLng, endLatLng];
      }
    } catch (e) {
      debugPrint('🗺️ ❌ Exception getting route: $e');
      // Fallback to straight line
      _routePoints = [startLatLng, endLatLng];
    }

    // Calculate distance (straight line for now, or use route distance)
    _distanceInMeters = Geolocator.distanceBetween(
      startLatLng.latitude,
      startLatLng.longitude,
      endLatLng.latitude,
      endLatLng.longitude,
    );

    // Calculate approximate route distance if we have route points
    if (_routePoints.length > 2) {
      double routeDistance = 0;
      for (int i = 0; i < _routePoints.length - 1; i++) {
        routeDistance += Geolocator.distanceBetween(
          _routePoints[i].latitude,
          _routePoints[i].longitude,
          _routePoints[i + 1].latitude,
          _routePoints[i + 1].longitude,
        );
      }
      _distanceInMeters = routeDistance;
    }

    // Format distance and duration
    _distanceText = _formatDistance(_distanceInMeters!);
    // Estimate duration (40 km/h average for driving)
    final durationMinutes = (_distanceInMeters! / 1000) / 40 * 60;
    _durationText = _formatDuration(durationMinutes);

    // Setup markers and polyline
    _setupMapElements(startLatLng, endLatLng);
  }

  void _setupMapElements(LatLng startLatLng, LatLng endLatLng) {
    setState(() {
      // Create markers
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: startLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
        Marker(
          markerId: const MarkerId('shelter'),
          position: endLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: widget.shelter.name,
            snippet: widget.shelter.location,
          ),
        ),
      };

      // Create polyline
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: AppColors.primary,
          width: 5,
          patterns: _routePoints.length <= 2 
              ? [PatternItem.dash(20), PatternItem.gap(10)] // Dashed for straight line
              : [], // Solid for actual route
        ),
      };

      _isLoading = false;
    });

    // Fit map to show the route
    _fitMapToRoute();
  }

  void _fitMapToRoute() {
    if (_mapController == null || _routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add some padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(double minutes) {
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(0)} min';
    } else {
      final hours = (minutes / 60).floor();
      final mins = (minutes % 60).toStringAsFixed(0);
      return '$hours h $mins min';
    }
  }

  Future<void> _openExternalMaps() async {
    if (!widget.shelter.hasValidCoordinates) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.shelter.latitude},${widget.shelter.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall() async {
    if (widget.shelter.contactPhone.isEmpty) return;

    final phoneNumber = widget.shelter.contactPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Color _getStatusColor(ShelterStatus status) {
    switch (status) {
      case ShelterStatus.available:
        return Colors.green.shade600;
      case ShelterStatus.full:
        return Colors.orange.shade600;
      case ShelterStatus.closed:
        return Colors.red.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.shelter.hasValidCoordinates
                  ? LatLng(widget.shelter.latitude!, widget.shelter.longitude!)
                  : const LatLng(13.0827, 80.2707),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_isLoading && _routePoints.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  _fitMapToRoute();
                });
              }
            },
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Getting directions...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Error overlay
          if (_errorMessage != null)
            Container(
              color: Colors.black38,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                              _isLoading = true;
                            });
                            _initializeNavigation();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _routePoints.length > 2 ? Icons.check_circle : Icons.info_outline,
                                size: 14,
                                color: _routePoints.length > 2 ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _routePoints.length > 2 ? 'Route found' : 'Navigating to',
                                style: textTheme.bodySmall?.copyWith(
                                  color: _routePoints.length > 2 ? Colors.green : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            widget.shelter.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Distance and duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoChip(
                            icon: Icons.straighten_rounded,
                            label: 'Distance',
                            value: _distanceText,
                            color: Colors.blue,
                          ),
                          _buildInfoChip(
                            icon: Icons.access_time_rounded,
                            label: 'Est. Time',
                            value: _durationText,
                            color: Colors.orange,
                          ),
                          _buildInfoChip(
                            icon: Icons.people_rounded,
                            label: 'Capacity',
                            value: '${widget.shelter.capacity}',
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Shelter info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(widget.shelter.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.home_rounded,
                                    color: _getStatusColor(widget.shelter.status),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.shelter.name,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (widget.shelter.location.isNotEmpty)
                                        Text(
                                          widget.shelter.location,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(widget.shelter.status).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.shelter.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(widget.shelter.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.shelter.district.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_city_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'District: ${widget.shelter.district}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade500,
                                    Colors.blue.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _openExternalMaps,
                                icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                                label: const Text(
                                  'Start Navigation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (widget.shelter.contactPhone.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: IconButton(
                                onPressed: _makePhoneCall,
                                icon: Icon(
                                  Icons.phone_rounded,
                                  color: Colors.green.shade700,
                                ),
                                iconSize: 24,
                                padding: const EdgeInsets.all(14),
                                tooltip: 'Call ${widget.shelter.contactPerson}',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

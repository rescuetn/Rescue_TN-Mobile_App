import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rescuetn/app/constants.dart';
import 'package:rescuetn/features/4_shelter_locator/provider/shelter_provider.dart';
import 'package:rescuetn/features/4_shelter_locator/widgets/shelter_details_bottom_sheet.dart';
import 'package:rescuetn/models/shelter_model.dart';

class ShelterMapScreen extends ConsumerStatefulWidget {
  const ShelterMapScreen({super.key});

  @override
  ConsumerState<ShelterMapScreen> createState() => _ShelterMapScreenState();
}

class _ShelterMapScreenState extends ConsumerState<ShelterMapScreen>
    with SingleTickerProviderStateMixin {
  // Initial camera position centered on Chennai
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(13.0827, 80.2707),
    zoom: 11.5,
  );

  GoogleMapController? _mapController;
  ShelterStatus? _filterStatus;
  bool _showLegend = true;
  bool _isLoadingLocation = true;
  Position? _currentPosition;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        _showLocationServiceDialog();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoadingLocation = false);
          }
          _showPermissionDeniedSnackBar();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        _showPermissionDeniedForeverDialog();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });

        // Move camera to current location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        _showErrorSnackBar('Could not get location: $e');
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location permission denied. Using default location.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Helper to get a colored marker based on shelter status
  BitmapDescriptor _getMarkerIcon(ShelterStatus status) {
    switch (status) {
      case ShelterStatus.available:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case ShelterStatus.full:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case ShelterStatus.closed:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _applyFilter(ShelterStatus? status) {
    // The build method will automatically handle filtering when this state changes
    if (mounted) setState(() => _filterStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live stream provider for real-time shelter updates
    final sheltersAsync = ref.watch(shelterStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: sheltersAsync.when(
        // Handle Loading State
        loading: () => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              markers: const {},
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
              zoomControlsEnabled: false,
            ),
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading shelters...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Handle Error State
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load shelters',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Handle Data State
        data: (shelters) {
          // Filter the live data based on the current UI state
          final filteredShelters = _filterStatus == null
              ? shelters
              : shelters.where((s) => s.status == _filterStatus).toList();

          // Create markers from the filtered live data
          final markers = filteredShelters.map((shelter) {
            return Marker(
              markerId: MarkerId(shelter.id),
              position: LatLng(shelter.latitude, shelter.longitude),
              infoWindow: InfoWindow(
                title: shelter.name,
                snippet: 'Tap for details',
              ),
              icon: _getMarkerIcon(shelter.status),
              onTap: () {
                if (!mounted) return;
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => ShelterDetailsBottomSheet(shelter: shelter),
                );
              },
            );
          }).toSet();

          return Stack(
            children: [
              // Google Map with live markers
              GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                markers: markers,
                myLocationButtonEnabled: false,
                myLocationEnabled: true,
                onMapCreated: (controller) => _mapController = controller,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),

              // Loading Overlay for location
              if (_isLoadingLocation)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Getting your location...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Custom UI Overlays
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar with live shelter count
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.all(AppPadding.medium),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppPadding.large),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(AppPadding.medium),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.medium,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: AppColors.primary,
                                      ),
                                      onPressed: () => context.go('/home'),
                                    ),
                                  ),
                                  const SizedBox(width: AppPadding.medium),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nearby Shelters',
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${shelters.length} total shelters found',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.medium,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        _showLegend
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.accent,
                                      ),
                                      onPressed: () {
                                        if (mounted) {
                                          setState(() {
                                            _showLegend = !_showLegend;
                                          });
                                        }
                                      },
                                      tooltip: 'Toggle Legend',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Filter Chips with live counts
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppPadding.medium,
                                0,
                                AppPadding.medium,
                                AppPadding.medium,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                      label: 'All',
                                      count: shelters.length,
                                      isSelected: _filterStatus == null,
                                      color: AppColors.primary,
                                      onTap: () => _applyFilter(null),
                                    ),
                                    const SizedBox(width: AppPadding.small),
                                    _buildFilterChip(
                                      label: 'Available',
                                      count: shelters.where((s) => s.status == ShelterStatus.available).length,
                                      isSelected: _filterStatus == ShelterStatus.available,
                                      color: Colors.green,
                                      onTap: () => _applyFilter(ShelterStatus.available),
                                    ),
                                    const SizedBox(width: AppPadding.small),
                                    _buildFilterChip(
                                      label: 'Full',
                                      count: shelters.where((s) => s.status == ShelterStatus.full).length,
                                      isSelected: _filterStatus == ShelterStatus.full,
                                      color: Colors.orange,
                                      onTap: () => _applyFilter(ShelterStatus.full),
                                    ),
                                    const SizedBox(width: AppPadding.small),
                                    _buildFilterChip(
                                      label: 'Closed',
                                      count: shelters.where((s) => s.status == ShelterStatus.closed).length,
                                      isSelected: _filterStatus == ShelterStatus.closed,
                                      color: Colors.red,
                                      onTap: () => _applyFilter(ShelterStatus.closed),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Bottom Controls
                    Padding(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // My Location Button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                color: AppColors.primary,
                              ),
                              iconSize: 28,
                              padding: const EdgeInsets.all(AppPadding.medium),
                              onPressed: () async {
                                if (_currentPosition != null && mounted) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLng(
                                      LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      ),
                                    ),
                                  );
                                } else {
                                  _getCurrentLocation();
                                }
                              },
                              tooltip: 'My Location',
                            ),
                          ),

                          // Legend Card with live counts
                          if (_showLegend) ...[
                            const SizedBox(height: AppPadding.medium),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(AppPadding.medium + AppPadding.small),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppPadding.large),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.textPrimary.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: AppPadding.small),
                                        Text(
                                          'Legend',
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppPadding.medium),
                                    _buildLegendItem(
                                      color: Colors.green,
                                      label: 'Available',
                                      count: shelters.where((s) => s.status == ShelterStatus.available).length,
                                    ),
                                    const SizedBox(height: AppPadding.small),
                                    _buildLegendItem(
                                      color: Colors.orange,
                                      label: 'Full',
                                      count: shelters.where((s) => s.status == ShelterStatus.full).length,
                                    ),
                                    const SizedBox(height: AppPadding.small),
                                    _buildLegendItem(
                                      color: Colors.red,
                                      label: 'Closed',
                                      count: shelters.where((s) => s.status == ShelterStatus.closed).length,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.medium,
          vertical: AppPadding.small + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.background,
          borderRadius: BorderRadius.circular(AppBorderRadius.circle),
          border: Border.all(
            color: isSelected ? color : AppColors.textSecondary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.onPrimary : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppPadding.small),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.onPrimary.withOpacity(0.2)
                    : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.onPrimary : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.small,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppBorderRadius.small),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
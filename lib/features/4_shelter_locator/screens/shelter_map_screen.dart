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
  GoogleMapController? _mapController;
  bool _showLegend = true;
  bool _isLoadingLocation = true;
  Position? _currentPosition;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Dynamic initial camera position that will update based on data
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(13.0827, 80.2707), // Default Chennai
    zoom: 11.5,
  );

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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        _showLocationServiceDialog();
        return;
      }

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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
          // Dynamically update initial position based on user location
          _initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 13.0,
          );
        });

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
    if (!mounted) return;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location permission denied. Using default location.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    if (!mounted) return;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Dynamic marker icon based on shelter status and government designation
  BitmapDescriptor _getMarkerIcon(Shelter shelter) {
    if (shelter.isGovernmentDesignated) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    switch (shelter.status) {
      case ShelterStatus.available:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case ShelterStatus.full:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case ShelterStatus.closed:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  // Dynamic color for filter based on current filter state
  Color _getFilterColor(ShelterFilter filter) {
    switch (filter) {
      case ShelterFilter.all:
        return AppColors.primary;
      case ShelterFilter.available:
        return Colors.green;
      case ShelterFilter.full:
        return Colors.orange;
      case ShelterFilter.closed:
        return Colors.red;
    }
  }

  // Dynamic icon for filter
  IconData _getFilterIcon(ShelterFilter filter) {
    switch (filter) {
      case ShelterFilter.all:
        return Icons.location_on;
      case ShelterFilter.available:
        return Icons.check_circle;
      case ShelterFilter.full:
        return Icons.people;
      case ShelterFilter.closed:
        return Icons.cancel;
    }
  }

  // Dynamically center map to show all shelters
  void _fitMapToBounds(List<Shelter> shelters) {
    if (shelters.isEmpty || _mapController == null) return;

    double minLat = shelters.first.latitude;
    double maxLat = shelters.first.latitude;
    double minLng = shelters.first.longitude;
    double maxLng = shelters.first.longitude;

    for (var shelter in shelters) {
      if (shelter.latitude < minLat) minLat = shelter.latitude;
      if (shelter.latitude > maxLat) maxLat = shelter.latitude;
      if (shelter.longitude < minLng) minLng = shelter.longitude;
      if (shelter.longitude > maxLng) maxLng = shelter.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch live providers for real-time updates
    final allSheltersAsync = ref.watch(shelterStreamProvider);
    final filteredSheltersAsync = ref.watch(filteredShelterProvider);
    final currentFilter = ref.watch(shelterFilterProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Google Map with live filtered markers
          filteredSheltersAsync.when(
            loading: () => GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              markers: const {},
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error.withValues(alpha: 0.5),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      err.toString(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Refresh the provider
                      ref.invalidate(shelterStreamProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (filteredShelters) {
              // Dynamically create markers from live filtered data
              final markers = filteredShelters.map((shelter) {
                return Marker(
                  markerId: MarkerId(shelter.id),
                  position: LatLng(shelter.latitude, shelter.longitude),
                  infoWindow: InfoWindow(
                    title: shelter.name,
                    snippet: '${shelter.status.name.toUpperCase()} • Tap for details',
                  ),
                  icon: _getMarkerIcon(shelter),
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

              // Auto-fit map to show all filtered shelters when filter changes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (filteredShelters.isNotEmpty && mounted) {
                  _fitMapToBounds(filteredShelters);
                }
              });

              return GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                markers: markers,
                myLocationButtonEnabled: false,
                myLocationEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Fit bounds on initial load
                  if (filteredShelters.isNotEmpty) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) _fitMapToBounds(filteredShelters);
                    });
                  }
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              );
            },
          ),

          // Dynamic loading overlay
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

          // Dynamic UI Overlays
          SafeArea(
            child: Column(
              children: [
                // Dynamic Top Bar with live counts
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppPadding.large),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                                  color: AppColors.primary.withValues(alpha: 0.1),
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
                                child: allSheltersAsync.when(
                                  data: (shelters) {
                                    // Dynamically calculate available shelters
                                    final availableCount = shelters
                                        .where((s) => s.status == ShelterStatus.available)
                                        .length;
                                    return Column(
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
                                          '${shelters.length} total • $availableCount available',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () => Column(
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
                                        'Loading...',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  error: (e, s) => Column(
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
                                        'Error loading',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
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

                        // Dynamic Filter Chips with live counts and icons
                        allSheltersAsync.when(
                          data: (allShelters) => Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppPadding.medium,
                              0,
                              AppPadding.medium,
                              AppPadding.medium,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ShelterFilter.values.map((filter) {
                                  final isSelected = currentFilter == filter;
                                  // Dynamically calculate count for each filter
                                  final count = filter == ShelterFilter.all
                                      ? allShelters.length
                                      : allShelters
                                      .where((s) => s.status.name == filter.name)
                                      .length;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: AppPadding.small),
                                    child: _buildFilterChip(
                                      label: filter.name[0].toUpperCase() +
                                          filter.name.substring(1),
                                      count: count,
                                      isSelected: isSelected,
                                      color: _getFilterColor(filter),
                                      icon: _getFilterIcon(filter),
                                      onTap: () {
                                        // Dynamically update filter
                                        ref.read(shelterFilterProvider.notifier).state =
                                            filter;
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.all(AppPadding.medium),
                            child: Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Dynamic Bottom Controls
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
                              color: AppColors.textPrimary.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _currentPosition != null
                                ? Icons.my_location
                                : Icons.location_searching,
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

                      // Dynamic Legend with live counts
                      if (_showLegend) ...[
                        const SizedBox(height: AppPadding.medium),
                        allSheltersAsync.when(
                          data: (allShelters) => FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildLegendCard(context, textTheme, allShelters),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required IconData icon,
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
            color: isSelected ? color : AppColors.textSecondary.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.onPrimary : color,
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
                    ? AppColors.onPrimary.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.2),
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

  Widget _buildLegendCard(
      BuildContext context,
      TextTheme textTheme,
      List<Shelter> allShelters,
      ) {
    // Dynamically calculate percentages
    final total = allShelters.length;
    final availableCount =
        allShelters.where((s) => s.status == ShelterStatus.available).length;
    final fullCount =
        allShelters.where((s) => s.status == ShelterStatus.full).length;
    final closedCount =
        allShelters.where((s) => s.status == ShelterStatus.closed).length;

    return Container(
      padding: const EdgeInsets.all(AppPadding.medium + AppPadding.small),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppPadding.large),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
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
              const Spacer(),
              Text(
                'Total: $total',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.medium),
          _buildLegendItem(
            color: Colors.green,
            label: 'Available',
            count: availableCount,
            percentage: total > 0 ? (availableCount / total * 100).toInt() : 0,
          ),
          const SizedBox(height: AppPadding.small),
          _buildLegendItem(
            color: Colors.orange,
            label: 'Full',
            count: fullCount,
            percentage: total > 0 ? (fullCount / total * 100).toInt() : 0,
          ),
          const SizedBox(height: AppPadding.small),
          _buildLegendItem(
            color: Colors.red,
            label: 'Closed',
            count: closedCount,
            percentage: total > 0 ? (closedCount / total * 100).toInt() : 0,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
    required int percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
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
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppBorderRadius.small),
          ),
          child: Text(
            '$count ($percentage%)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
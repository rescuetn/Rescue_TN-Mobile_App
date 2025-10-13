import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  ShelterStatus? _filterStatus;
  bool _showLegend = true;
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

    // We use a post-frame callback to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createMarkers();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Helper function to create map markers from our shelter data
  void _createMarkers() {
    final shelters = ref.read(shelterListProvider);
    final filteredShelters = _filterStatus == null
        ? shelters
        : shelters.where((s) => s.status == _filterStatus).toList();

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
          // Show a bottom sheet with shelter details when a marker is tapped
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => ShelterDetailsBottomSheet(shelter: shelter),
          );
        },
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _applyFilter(ShelterStatus? status) {
    setState(() {
      _filterStatus = status;
    });
    _createMarkers();
  }

  Color _getStatusColor(ShelterStatus status) {
    switch (status) {
      case ShelterStatus.available:
        return Colors.green;
      case ShelterStatus.full:
        return Colors.orange;
      case ShelterStatus.closed:
        return Colors.red;
    }
  }

  String _getStatusText(ShelterStatus status) {
    switch (status) {
      case ShelterStatus.available:
        return 'Available';
      case ShelterStatus.full:
        return 'Full';
      case ShelterStatus.closed:
        return 'Closed';
    }
  }

  int _getShelterCount(ShelterStatus status) {
    final shelters = ref.read(shelterListProvider);
    return shelters.where((s) => s.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shelters = ref.watch(shelterListProvider);
    final totalShelters = shelters.length;

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            onMapCreated: _onMapCreated,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // Custom UI Overlays
          SafeArea(
            child: Column(
              children: [
                // Top Bar
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
                                  onPressed: () => Navigator.of(context).pop(),
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
                                      '$totalShelters shelters found',
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
                                    setState(() {
                                      _showLegend = !_showLegend;
                                    });
                                  },
                                  tooltip: 'Toggle Legend',
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Filter Chips
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
                                  count: totalShelters,
                                  isSelected: _filterStatus == null,
                                  color: AppColors.primary,
                                  onTap: () => _applyFilter(null),
                                ),
                                const SizedBox(width: AppPadding.small),
                                _buildFilterChip(
                                  label: 'Available',
                                  count: _getShelterCount(ShelterStatus.available),
                                  isSelected:
                                  _filterStatus == ShelterStatus.available,
                                  color: Colors.green,
                                  onTap: () =>
                                      _applyFilter(ShelterStatus.available),
                                ),
                                const SizedBox(width: AppPadding.small),
                                _buildFilterChip(
                                  label: 'Full',
                                  count: _getShelterCount(ShelterStatus.full),
                                  isSelected: _filterStatus == ShelterStatus.full,
                                  color: Colors.orange,
                                  onTap: () => _applyFilter(ShelterStatus.full),
                                ),
                                const SizedBox(width: AppPadding.small),
                                _buildFilterChip(
                                  label: 'Closed',
                                  count: _getShelterCount(ShelterStatus.closed),
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
                            if (_mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  _initialCameraPosition,
                                ),
                              );
                            }
                          },
                          tooltip: 'My Location',
                        ),
                      ),

                      if (_showLegend) ...[
                        const SizedBox(height: AppPadding.medium),
                        // Legend Card
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
                                    Icon(
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
                                  count: _getShelterCount(ShelterStatus.available),
                                ),
                                const SizedBox(height: AppPadding.small),
                                _buildLegendItem(
                                  color: Colors.orange,
                                  label: 'Full',
                                  count: _getShelterCount(ShelterStatus.full),
                                ),
                                const SizedBox(height: AppPadding.small),
                                _buildLegendItem(
                                  color: Colors.red,
                                  label: 'Closed',
                                  count: _getShelterCount(ShelterStatus.closed),
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
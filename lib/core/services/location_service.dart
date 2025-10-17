import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// An abstract class defining the contract for location services.
/// This allows us to abstract the implementation details of the geolocator package.
abstract class LocationService {
  /// Fetches the current geographical position of the device.
  ///
  /// This method handles the entire flow of:
  /// 1. Checking if location services are enabled on the device.
  /// 2. Checking for and requesting location permissions from the user.
  /// 3. Fetching the current position.
  ///
  /// Throws a [Exception] with a user-friendly message if any step fails.
  Future<Position> getCurrentPosition();
}

/// A provider to make our LocationService available throughout the app.
final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorService();
});

/// The concrete implementation of [LocationService] using the geolocator package.
class GeolocatorService implements LocationService {
  @override
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them in your device settings.');
    }

    // 2. Check for location permissions.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    // 3. When we reach here, permissions are granted, and we can
    //    access the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}

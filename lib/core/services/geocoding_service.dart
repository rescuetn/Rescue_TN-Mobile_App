import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for converting place names to coordinates using geocoding
class GeocodingService {
  // Cache for geocoded locations to avoid repeated API calls
  final Map<String, Map<String, double>> _memoryCache = {};
  
  /// Geocode a location string to get latitude and longitude
  /// Returns null if geocoding fails
  /// Adds ", Tamil Nadu, India" suffix for better accuracy
  Future<Map<String, double>?> geocodeLocation(String locationName) async {
    if (locationName.isEmpty) {
      debugPrint('GeocodingService: Empty location name provided');
      return null;
    }
    
    // Check memory cache first
    final cacheKey = locationName.toLowerCase().trim();
    if (_memoryCache.containsKey(cacheKey)) {
      debugPrint('GeocodingService: Cache hit for "$locationName"');
      return _memoryCache[cacheKey];
    }
    
    // Check persistent cache
    final cachedResult = await _getFromCache(cacheKey);
    if (cachedResult != null) {
      debugPrint('GeocodingService: Persistent cache hit for "$locationName"');
      _memoryCache[cacheKey] = cachedResult;
      return cachedResult;
    }
    
    try {
      // Add Tamil Nadu, India suffix for better geocoding accuracy
      final searchQuery = '$locationName, Tamil Nadu, India';
      debugPrint('GeocodingService: Attempting geocode for "$searchQuery"');
      
      final locations = await locationFromAddress(searchQuery);
      
      if (locations.isNotEmpty) {
        final result = {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
        
        debugPrint('GeocodingService: ✅ Success! Found coordinates: ${result['latitude']}, ${result['longitude']}');
        
        // Save to caches
        _memoryCache[cacheKey] = result;
        await _saveToCache(cacheKey, result);
        
        return result;
      } else {
        debugPrint('GeocodingService: No locations found for "$searchQuery"');
      }
    } catch (e) {
      debugPrint('GeocodingService: First attempt failed with error: $e');
      // Try without the suffix if the first attempt fails
      try {
        debugPrint('GeocodingService: Retrying without suffix for "$locationName"');
        final locations = await locationFromAddress(locationName);
        
        if (locations.isNotEmpty) {
          final result = {
            'latitude': locations.first.latitude,
            'longitude': locations.first.longitude,
          };
          
          debugPrint('GeocodingService: ✅ Success on retry! Found coordinates: ${result['latitude']}, ${result['longitude']}');
          
          _memoryCache[cacheKey] = result;
          await _saveToCache(cacheKey, result);
          
          return result;
        }
      } catch (e2) {
        debugPrint('GeocodingService: ❌ Both attempts failed. Error: $e2');
      }
    }
    
    debugPrint('GeocodingService: ❌ Failed to geocode "$locationName"');
    return null;
  }
  
  /// Get cached geocoding result from persistent storage
  Future<Map<String, double>?> _getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('geocode_$key');
      if (cached != null) {
        final Map<String, dynamic> decoded = jsonDecode(cached);
        return {
          'latitude': decoded['latitude'] as double,
          'longitude': decoded['longitude'] as double,
        };
      }
    } catch (_) {}
    return null;
  }
  
  /// Save geocoding result to persistent storage
  Future<void> _saveToCache(String key, Map<String, double> coords) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('geocode_$key', jsonEncode(coords));
    } catch (_) {}
  }
  
  /// Clear all cached geocoding results
  Future<void> clearCache() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('geocode_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}

/// Provider for the geocoding service
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Service for getting real road directions from Google Directions API
class DirectionsService {
  // Google Maps API Key (same as used for Google Maps Flutter)
  static const String _apiKey = 'AIzaSyCLQ3cyXTMIDqcztRDR7v_Awrs-pLmJYoM';
  
  /// Get directions between two points
  /// Returns a DirectionsResult containing polyline points, distance, and duration
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=$mode'
      '&key=$_apiKey'
    );
    
    try {
      debugPrint('DirectionsService: Fetching directions...');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Decode polyline points
          final polyline = route['overview_polyline']['points'];
          final points = _decodePolyline(polyline);
          
          // Get distance and duration
          final distanceText = leg['distance']['text'];
          final distanceValue = leg['distance']['value']; // in meters
          final durationText = leg['duration']['text'];
          final durationValue = leg['duration']['value']; // in seconds
          
          // Get step-by-step instructions
          final List<DirectionStep> steps = [];
          for (final step in leg['steps']) {
            steps.add(DirectionStep(
              instruction: _stripHtmlTags(step['html_instructions']),
              distanceText: step['distance']['text'],
              durationText: step['duration']['text'],
              maneuver: step['maneuver'] ?? '',
            ));
          }
          
          debugPrint('DirectionsService: ✅ Got route with ${points.length} points');
          
          return DirectionsResult(
            polylinePoints: points,
            distanceText: distanceText,
            distanceMeters: distanceValue.toDouble(),
            durationText: durationText,
            durationSeconds: durationValue,
            steps: steps,
            startAddress: leg['start_address'],
            endAddress: leg['end_address'],
          );
        } else {
          debugPrint('DirectionsService: API returned status: ${data['status']}');
          debugPrint('DirectionsService: Error message: ${data['error_message'] ?? 'None'}');
        }
      } else {
        debugPrint('DirectionsService: HTTP error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DirectionsService: ❌ Error: $e');
    }
    
    return null;
  }
  
  /// Decode Google's encoded polyline format into a list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;
    
    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      
      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    
    return points;
  }
  
  /// Remove HTML tags from instruction text
  String _stripHtmlTags(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
  }
}

/// Result from directions API
class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String distanceText;
  final double distanceMeters;
  final String durationText;
  final int durationSeconds;
  final List<DirectionStep> steps;
  final String startAddress;
  final String endAddress;
  
  DirectionsResult({
    required this.polylinePoints,
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.durationSeconds,
    required this.steps,
    required this.startAddress,
    required this.endAddress,
  });
}

/// A single step in the directions
class DirectionStep {
  final String instruction;
  final String distanceText;
  final String durationText;
  final String maneuver;
  
  DirectionStep({
    required this.instruction,
    required this.distanceText,
    required this.durationText,
    required this.maneuver,
  });
  
  /// Get an icon for the maneuver type
  String get maneuverIcon {
    switch (maneuver) {
      case 'turn-left':
        return '↰';
      case 'turn-right':
        return '↱';
      case 'turn-slight-left':
        return '↖';
      case 'turn-slight-right':
        return '↗';
      case 'turn-sharp-left':
        return '↰';
      case 'turn-sharp-right':
        return '↱';
      case 'uturn-left':
      case 'uturn-right':
        return '↺';
      case 'straight':
        return '↑';
      case 'roundabout-left':
      case 'roundabout-right':
        return '↻';
      case 'merge':
        return '⤴';
      case 'ramp-left':
        return '↙';
      case 'ramp-right':
        return '↘';
      case 'fork-left':
        return '↖';
      case 'fork-right':
        return '↗';
      default:
        return '→';
    }
  }
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// OSRM (Open Source Routing Machine) Service
/// Self-hosted routing for free
class OSRMService {
  // Замените на ваш сервер OSRM
  static const String _baseUrl = 'http://your-server:5000';
  
  // Для тестирования можно использовать публичный OSRM
  // НО: не для production! Используйте свой сервер
  static const String _demoUrl = 'https://router.project-osrm.org';

  /// Get route between points
  /// 
  /// Example:
  /// ```dart
  /// final route = await OSRMService.getRoute([
  ///   LatLng(41.2995, 69.2401), // Tashkent
  ///   LatLng(41.3111, 69.2797), // Next point
  /// ]);
  /// ```
  static Future<RouteResult> getRoute(
    List<LatLng> waypoints, {
    bool alternatives = false,
    String profile = 'driving', // driving, walking, cycling
  }) async {
    if (waypoints.length < 2) {
      throw ArgumentError('Need at least 2 waypoints');
    }

    // Format coordinates for OSRM
    final coords = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = Uri.parse(
      '$_demoUrl/route/v1/$profile/$coords'
      '?overview=full'
      '&geometries=geojson'
      '&steps=true'
      '&annotations=true'
      '&alternatives=$alternatives'
    );

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode != 200) {
        throw Exception('OSRM error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      
      if (data['code'] != 'Ok') {
        throw Exception('Route not found: ${data['message']}');
      }

      final route = data['routes'][0];
      
      return RouteResult(
        distance: route['distance'] as double, // meters
        duration: route['duration'] as double, // seconds
        geometry: _decodeGeoJSON(route['geometry']),
        legs: (route['legs'] as List).map((leg) => RouteLeg(
          distance: leg['distance'] as double,
          duration: leg['duration'] as double,
          steps: (leg['steps'] as List).map((step) => RouteStep(
            instruction: step['name'] as String? ?? 'Продолжайте движение',
            distance: step['distance'] as double,
            duration: step['duration'] as double,
            maneuver: step['maneuver']['type'] as String,
            location: LatLng(
              step['maneuver']['location'][1] as double,
              step['maneuver']['location'][0] as double,
            ),
          )).toList(),
        )).toList(),
      );
    } catch (e) {
      throw Exception('Failed to get route: $e');
    }
  }

  /// Get optimized route (TSP solver)
  /// Returns waypoints in optimal order
  static Future<List<LatLng>> optimizeWaypoints(
    List<LatLng> waypoints, {
    String profile = 'driving',
  }) async {
    // OSRM trip service finds optimal route visiting all points
    final coords = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = Uri.parse(
      '$_demoUrl/trip/v1/$profile/$coords'
      '?source=first'
      '&destination=last'
      '&roundtrip=false'
    );

    final response = await http.get(url);
    
    if (response.statusCode != 200) {
      throw Exception('Optimization failed');
    }

    final data = json.decode(response.body);
    
    if (data['code'] != 'Ok') {
      return waypoints; // Fallback to original order
    }

    // Extract optimized order
    final waypointsData = data['waypoints'] as List;
    final sorted = List<LatLng>.filled(waypoints.length, waypoints[0]);
    
    for (final wp in waypointsData) {
      final index = wp['waypoint_index'] as int;
      final location = wp['location'] as List;
      sorted[index] = LatLng(location[1], location[0]);
    }

    return sorted;
  }

  /// Decode GeoJSON LineString to list of LatLng
  static List<LatLng> _decodeGeoJSON(Map<String, dynamic> geometry) {
    final coords = geometry['coordinates'] as List;
    return coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} м';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} км';
    }
  }

  /// Format duration for display
  static String formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours ч ${minutes} мин';
    } else {
      return '$minutes мин';
    }
  }

  /// Calculate bounds for map camera
  static LatLngBounds calculateBounds(List<LatLng> points) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }
}

/// Route result from OSRM
class RouteResult {
  final double distance; // meters
  final double duration; // seconds
  final List<LatLng> geometry; // Points for drawing polyline
  final List<RouteLeg> legs;

  RouteResult({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.legs,
  });

  String get formattedDistance => OSRMService.formatDistance(distance);
  String get formattedDuration => OSRMService.formatDuration(duration);
}

class RouteLeg {
  final double distance;
  final double duration;
  final List<RouteStep> steps;

  RouteLeg({
    required this.distance,
    required this.duration,
    required this.steps,
  });
}

class RouteStep {
  final String instruction;
  final double distance;
  final double duration;
  final String maneuver;
  final LatLng location;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    required this.location,
  });
}

class LatLngBounds {
  final LatLng southWest;
  final LatLng northEast;

  LatLngBounds(this.southWest, this.northEast);

  LatLng get center => LatLng(
        (southWest.latitude + northEast.latitude) / 2,
        (southWest.longitude + northEast.longitude) / 2,
      );
}

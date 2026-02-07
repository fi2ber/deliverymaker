import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/ios_theme.dart';
import '../bloc/route_bloc.dart';

/// iOS 18 styled map with route
class RouteMap extends StatefulWidget {
  final List<LatLng> routePoints;
  final List<DeliveryStop> stops;
  final LatLng? currentLocation;
  final Function(DeliveryStop)? onStopTap;
  final bool needsRecenter;

  const RouteMap({
    super.key,
    required this.routePoints,
    required this.stops,
    this.currentLocation,
    this.onStopTap,
    this.needsRecenter = false,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> with TickerProviderStateMixin {
  late final _animatedMapController = AnimatedMapController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );

  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.needsRecenter && !oldWidget.needsRecenter) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (widget.routePoints.isEmpty) return;
    
    final bounds = LatLngBounds.fromPoints(widget.routePoints);
    _animatedMapController.animatedFitBounds(
      bounds,
      options: const FitBoundsOptions(
        padding: EdgeInsets.all(80),
        maxZoom: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _animatedMapController.mapController,
        options: MapOptions(
          initialCenter: widget.currentLocation ?? const LatLng(41.2995, 69.2401),
          initialZoom: 13,
          minZoom: 5,
          maxZoom: 18,
        ),
        children: [
          // OpenStreetMap tiles
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.deliverymaker.app',
            tileBuilder: (context, child, tile) {
              // iOS-style tile rendering
              return Container(
                decoration: BoxDecoration(
                  color: IOSTheme.bgTertiary,
                ),
                child: child,
              );
            },
          ),
          
          // Route polyline
          if (widget.routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.routePoints,
                  color: IOSTheme.systemBlue,
                  strokeWidth: 5,
                  borderColor: Colors.white,
                  borderStrokeWidth: 2,
                  gradientColors: [
                    IOSTheme.systemBlue,
                    IOSTheme.systemIndigo,
                  ],
                ),
              ],
            ),
          
          // Stop markers
          MarkerLayer(
            markers: [
              // Current location marker
              if (widget.currentLocation != null)
                Marker(
                  point: widget.currentLocation!,
                  width: 40,
                  height: 40,
                  child: _CurrentLocationMarker(),
                ),
              
              // Stop markers
              ...widget.stops.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                return Marker(
                  point: stop.location,
                  width: 50,
                  height: 60,
                  alignment: Alignment.topCenter,
                  child: _StopMarker(
                    number: index + 1,
                    status: stop.status,
                    onTap: () => widget.onStopTap?.call(stop),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recenter button
          _MapButton(
            icon: Icons.my_location,
            onPressed: () {
              IOSTheme.lightImpact();
              if (widget.currentLocation != null) {
                _animatedMapController.animateTo(
                  dest: widget.currentLocation!,
                  zoom: 16,
                );
              } else {
                _fitBounds();
              }
            },
          ),
          const SizedBox(height: 8),
          
          // Zoom in
          _MapButton(
            icon: Icons.add,
            onPressed: () {
              IOSTheme.lightImpact();
              _animatedMapController.animatedZoomIn();
            },
          ),
          const SizedBox(height: 8),
          
          // Zoom out
          _MapButton(
            icon: Icons.remove,
            onPressed: () {
              IOSTheme.lightImpact();
              _animatedMapController.animatedZoomOut();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }
}

/// Current location marker with pulse animation
class _CurrentLocationMarker extends StatefulWidget {
  @override
  State<_CurrentLocationMarker> createState() => _CurrentLocationMarkerState();
}

class _CurrentLocationMarkerState extends State<_CurrentLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: IOSTheme.systemBlue.withOpacity(
                  0.3 * (1 - _controller.value),
                ),
              ),
            ),
            // Inner dot
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: IOSTheme.systemBlue,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: IOSTheme.shadowSm,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Stop number marker
class _StopMarker extends StatelessWidget {
  final int number;
  final StopStatus status;
  final VoidCallback? onTap;

  const _StopMarker({
    required this.number,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor = Colors.white;
    IconData? icon;

    switch (status) {
      case StopStatus.completed:
        bgColor = IOSTheme.systemGreen;
        icon = Icons.check;
        break;
      case StopStatus.inProgress:
        bgColor = IOSTheme.systemOrange;
        break;
      case StopStatus.failed:
        bgColor = IOSTheme.systemRed;
        icon = Icons.close;
        break;
      case StopStatus.pending:
        bgColor = IOSTheme.systemBlue;
        break;
    }

    return GestureDetector(
      onTap: () {
        IOSTheme.lightImpact();
        onTap?.call();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker bubble
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: IOSTheme.shadowMd,
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: textColor, size: 18)
                  : Text(
                      number.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          // Pointer
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Map control button
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(10),
      borderRadius: IOSTheme.radiusMd,
      child: IconButton(
        icon: Icon(icon, color: IOSTheme.labelPrimary, size: 22),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

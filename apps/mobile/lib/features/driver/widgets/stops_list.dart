import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/ios_theme.dart';
import '../bloc/route_bloc.dart';

/// Bottom sheet with list of delivery stops
/// iOS 18 style with spring animations
class StopsList extends StatelessWidget {
  final List<DeliveryStop> stops;
  final int completedCount;
  final RouteResult? routeInfo;
  final Function(DeliveryStop) onStopTap;
  final VoidCallback onOpenInNavigator;
  final DeliveryStop? currentStop;

  const StopsList({
    super.key,
    required this.stops,
    required this.completedCount,
    this.routeInfo,
    required this.onStopTap,
    required this.onOpenInNavigator,
    this.currentStop,
  });

  @override
  Widget build(BuildContext context) {
    final pendingStops = stops.where((s) => s.status == StopStatus.pending).toList();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.15, 0.35, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: IOSTheme.bgSecondary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(IOSTheme.radius2Xl),
            ),
            boxShadow: IOSTheme.shadowLg,
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: IOSTheme.fill,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              
              // Header with progress
              _buildHeader(),
              
              const Divider(height: 1),
              
              // Stats
              if (routeInfo != null)
                _buildStats(),
              
              const Divider(height: 1),
              
              // Stops list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: pendingStops.length,
                  itemBuilder: (context, index) {
                    final stop = pendingStops[index];
                    final isNext = index == 0;
                    
                    return _StopCard(
                      stop: stop,
                      sequenceNumber: stops.indexOf(stop) + 1,
                      isNext: isNext,
                      onTap: () => onStopTap(stop),
                      onNavigate: () {
                        IOSTheme.mediumImpact();
                        onOpenInNavigator();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final progress = stops.isEmpty ? 0.0 : completedCount / stops.length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Маршрут доставки',
                style: IOSTheme.title3,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: IOSTheme.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(IOSTheme.radiusFull),
                ),
                child: Text(
                  '$completedCount/${stops.length}',
                  style: IOSTheme.footnote.copyWith(
                    color: IOSTheme.systemBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: IOSTheme.fill,
              valueColor: const AlwaysStoppedAnimation(IOSTheme.systemBlue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.route,
            value: routeInfo!.formattedDistance,
            label: 'Расстояние',
          ),
          const SizedBox(width: 24),
          _StatItem(
            icon: Icons.schedule,
            value: routeInfo!.formattedDuration,
            label: 'Время',
          ),
          const SizedBox(width: 24),
          _StatItem(
            icon: Icons.local_shipping,
            value: '${stops.length - completedCount}',
            label: 'Осталось',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: IOSTheme.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
            ),
            child: Icon(
              icon,
              size: 20,
              color: IOSTheme.systemBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: IOSTheme.headline,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: IOSTheme.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final DeliveryStop stop;
  final int sequenceNumber;
  final bool isNext;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

  const _StopCard({
    required this.stop,
    required this.sequenceNumber,
    required this.isNext,
    required this.onTap,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.springCurve,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: IOSCard(
        onTap: onTap,
        backgroundColor: isNext 
            ? IOSTheme.systemBlue.withOpacity(0.05)
            : IOSTheme.bgSecondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isNext ? IOSTheme.systemBlue : IOSTheme.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      sequenceNumber.toString(),
                      style: TextStyle(
                        color: isNext ? Colors.white : IOSTheme.labelSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stop.customerName,
                              style: IOSTheme.headline,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isNext)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: IOSTheme.systemOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Следующая',
                                style: IOSTheme.footnote.copyWith(
                                  color: IOSTheme.systemOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stop.address,
                        style: IOSTheme.bodyMedium.copyWith(
                          color: IOSTheme.labelSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stop.comment != null && stop.comment!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: IOSTheme.systemYellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 14,
                                color: IOSTheme.systemOrange,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  stop.comment!,
                                  style: IOSTheme.footnote.copyWith(
                                    color: IOSTheme.labelPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Позвонить',
                    onTap: () {
                      IOSTheme.lightImpact();
                      // Launch phone dialer
                    },
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.navigation_outlined,
                    label: 'Маршрут',
                    color: IOSTheme.systemBlue,
                    onTap: onNavigate,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Доставлено',
                    color: IOSTheme.systemGreen,
                    onTap: () {
                      IOSTheme.success();
                      onTap();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IOSTheme.labelSecondary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: IOSTheme.footnote.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

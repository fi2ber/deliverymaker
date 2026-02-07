import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/ios_theme.dart';
import '../bloc/route_bloc.dart';
import '../widgets/route_map.dart';
import '../widgets/stops_list.dart';
import '../widgets/delivery_completion_sheet.dart';

/// Main route screen for drivers
/// Shows map with route and list of delivery stops
class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RouteBloc()
        ..add(LoadRoute(_mockStops)), // TODO: Load from API/Isar
      child: const _RouteScreenContent(),
    );
  }
}

class _RouteScreenContent extends StatelessWidget {
  const _RouteScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: BlocConsumer<RouteBloc, RouteState>(
        listener: (context, state) {
          if (state.error != null) {
            _showError(context, state.error!);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Map layer
              RouteMap(
                routePoints: state.routeGeometry,
                stops: state.stops,
                currentLocation: state.currentLocation,
                needsRecenter: state.needsRecenter,
                onStopTap: (stop) => _onStopTap(context, stop),
              ),
              
              // Loading overlay
              if (state.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(IOSTheme.systemBlue),
                    ),
                  ),
                ),
              
              // Stops list sheet
              if (state.stops.isNotEmpty)
                StopsList(
                  stops: state.stops,
                  completedCount: state.completedStops,
                  routeInfo: state.routeInfo,
                  currentStop: state.nextStop,
                  onStopTap: (stop) => _onStopTap(context, stop),
                  onOpenInNavigator: () => _openNavigator(state.nextStop),
                ),
              
              // Top bar with back button and title
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(8),
                        borderRadius: IOSTheme.radiusMd,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: IOSTheme.labelPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 20,
                                color: IOSTheme.labelSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Маршрут доставки',
                                style: IOSTheme.headline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onStopTap(BuildContext context, DeliveryStop stop) {
    IOSTheme.mediumImpact();
    
    if (stop.status == StopStatus.pending) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DeliveryCompletionSheet(
          stop: stop,
          onComplete: (proof) {
            context.read<RouteBloc>().add(MarkStopCompleted(stop.id, proof));
          },
        ),
      );
    }
  }

  void _openNavigator(DeliveryStop? stop) {
    if (stop == null) return;
    
    // TODO: Launch external navigator
    // For now just show snackbar
    IOSTheme.lightImpact();
    debugPrint('Opening navigator to: ${stop.address}');
  }

  void _showError(BuildContext context, String error) {
    IOSTheme.error();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: IOSTheme.systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
        ),
      ),
    );
  }
}

// Mock data for testing
final List<DeliveryStop> _mockStops = [
  const DeliveryStop(
    id: '1',
    orderCode: 'SUB-240215-A3F7-D1',
    customerName: 'Анвар Рахимов',
    phone: '+998901234567',
    address: 'ул. Амира Темура, 45, кв. 12',
    location: LatLng(41.2995, 69.2401),
    comment: 'Домофон не работает, позвоните',
  ),
  const DeliveryStop(
    id: '2',
    orderCode: 'SUB-240215-B2K9-D1',
    customerName: 'Гулноза Каримова',
    phone: '+998907654321',
    address: 'ул. Навои, 128, подъезд 3',
    location: LatLng(41.3111, 69.2797),
  ),
  const DeliveryStop(
    id: '3',
    orderCode: 'SUB-240215-C4M2-D1',
    customerName: 'Баходир Усманов',
    phone: '+998905556677',
    address: 'проспект Мустакиллик, 88',
    location: LatLng(41.2850, 69.2150),
    comment: 'Офис на 3 этаже',
  ),
  const DeliveryStop(
    id: '4',
    orderCode: 'SUB-240215-D8N5-D1',
    customerName: 'Нодира Ахмедова',
    phone: '+998909998877',
    address: 'ул. Фергана, 15',
    location: LatLng(41.3250, 69.2650),
  ),
];

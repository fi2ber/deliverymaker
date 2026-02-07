import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/ios_theme.dart';
import 'delivery_completion_screen.dart';

/// Route Screen - Main screen for delivery driver
/// Shows list of orders for the day with optimized route
class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  int _currentOrderIndex = 0;
  bool _isOffline = false;

  // Mock data - replace with API
  final List<DeliveryOrder> _orders = [
    DeliveryOrder(
      id: 'ORD-001',
      customerName: 'ООО "Магнит"',
      address: 'ул. Ленина, 45, Ташкент',
      phone: '+998 90 123 45 67',
      totalAmount: 125000,
      items: 12,
      status: OrderStatus.current,
      notes: 'Вход с торца, позвонить за 10 мин',
      latitude: 41.2995,
      longitude: 69.2401,
    ),
    DeliveryOrder(
      id: 'ORD-002',
      customerName: 'ИП Иванов А.А.',
      address: 'ул. Навои, 78, Ташкент',
      phone: '+998 90 234 56 78',
      totalAmount: 89000,
      items: 8,
      status: OrderStatus.pending,
      notes: '',
      latitude: 41.3050,
      longitude: 69.2450,
    ),
    DeliveryOrder(
      id: 'ORD-003',
      customerName: 'Супермаркет "Насия"',
      address: 'проспект Мустакиллик, 120, Ташкент',
      phone: '+998 90 345 67 89',
      totalAmount: 234000,
      items: 25,
      status: OrderStatus.pending,
      notes: 'Погрузка с заднего входа',
      latitude: 41.3100,
      longitude: 69.2500,
    ),
    DeliveryOrder(
      id: 'ORD-004',
      customerName: 'Магазин "У дома"',
      address: 'ул. Амира Темура, 15, Ташкент',
      phone: '+998 90 456 78 90',
      totalAmount: 67000,
      items: 5,
      status: OrderStatus.pending,
      notes: '',
      latitude: 41.2950,
      longitude: 69.2350,
    ),
    DeliveryOrder(
      id: 'ORD-005',
      customerName: 'ООО "Азия Фуд"',
      address: 'ул. Фурката, 92, Ташкент',
      phone: '+998 90 567 89 01',
      totalAmount: 156000,
      items: 18,
      status: OrderStatus.pending,
      notes: 'Доставка до 14:00',
      latitude: 41.3150,
      longitude: 69.2550,
    ),
  ];

  List<DeliveryOrder> get _sortedOrders {
    final sorted = List<DeliveryOrder>.from(_orders);
    sorted.sort((a, b) {
      if (a.status == OrderStatus.current) return -1;
      if (b.status == OrderStatus.current) return 1;
      if (a.status == OrderStatus.pending && b.status != OrderStatus.pending) return -1;
      if (b.status == OrderStatus.pending && a.status != OrderStatus.pending) return 1;
      return 0;
    });
    return sorted;
  }

  int get _completedCount => _orders.where((o) => o.status == OrderStatus.completed).length;
  int get _pendingCount => _orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.current).length;

  void _openNavigation(DeliveryOrder order) {
    IOSTheme.mediumImpact();
    // Open maps app
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _NavigationSheet(order: order),
    );
  }

  void _callCustomer(String phone) {
    IOSTheme.lightImpact();
    // Launch dialer
  }

  void _startDelivery(DeliveryOrder order) {
    IOSTheme.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryCompletionScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completedCount / _orders.length;

    return Scaffold(
      backgroundColor: IOSTheme.bgSecondary,
      body: CustomScrollView(
        slivers: [
          // Header with progress
          SliverToBoxAdapter(
            child: _buildHeader(progress),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: _buildStats(),
          ),

          // Section Title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'Маршрут',
                    style: IOSTheme.title2.copyWith(
                      color: IOSTheme.label,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isOffline ? IOSTheme.iosOrange.withOpacity(0.15) : IOSTheme.iosGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isOffline ? Icons.cloud_off : Icons.cloud_done,
                          size: 16,
                          color: _isOffline ? IOSTheme.iosOrange : IOSTheme.iosGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isOffline ? 'Офлайн' : 'Онлайн',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isOffline ? IOSTheme.iosOrange : IOSTheme.iosGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Orders List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final order = _sortedOrders[index];
                  final isCurrent = order.status == OrderStatus.current;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderCard(
                      order: order,
                      isCurrent: isCurrent,
                      onNavigate: () => _openNavigation(order),
                      onCall: () => _callCustomer(order.phone),
                      onStart: () => _startDelivery(order),
                    ),
                  );
                },
                childCount: _sortedOrders.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),

      // Floating Action Button for current order
      floatingActionButton: _buildQuickActionFAB(),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        color: IOSTheme.iosBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: IOSTheme.iosBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Сегодня',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Маршрут доставки',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_completedCount}/${_orders.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.schedule,
              value: '$_pendingCount',
              label: 'Осталось',
              color: IOSTheme.iosOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle,
              value: '$_completedCount',
              label: 'Выполнено',
              color: IOSTheme.iosGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.payments,
              value: '${(_orders.fold<int>(0, (sum, o) => sum + o.totalAmount) / 1000).toStringAsFixed(0)}k',
              label: 'Сумма',
              color: IOSTheme.iosPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildQuickActionFAB() {
    final currentOrder = _orders.firstWhere(
      (o) => o.status == OrderStatus.current,
      orElse: () => _orders.firstWhere(
        (o) => o.status == OrderStatus.pending,
        orElse: () => _orders.first,
      ),
    );

    if (currentOrder.status == OrderStatus.completed) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        onPressed: () => _startDelivery(currentOrder),
        backgroundColor: IOSTheme.iosBlue,
        elevation: 4,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Доставлено'),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final bool isCurrent;
  final VoidCallback onNavigate;
  final VoidCallback onCall;
  final VoidCallback onStart;

  const _OrderCard({
    required this.order,
    required this.isCurrent,
    required this.onNavigate,
    required this.onCall,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? IOSTheme.iosBlue.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCurrent
            ? Border.all(color: IOSTheme.iosBlue.withOpacity(0.3), width: 2)
            : null,
        boxShadow: IOSTheme.shadowSm,
      ),
      child: Column(
        children: [
          // Header with status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrent ? IOSTheme.iosBlue : IOSTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${order.items}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : IOSTheme.label,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.id,
                        style: TextStyle(
                          color: IOSTheme.labelSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  text: _getStatusText(order.status),
                  type: _getStatusType(order.status),
                ),
              ],
            ),
          ),

          // Address
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: IOSTheme.iosBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.address,
                    style: const TextStyle(
                      fontSize: 15,
                      color: IOSTheme.label,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: IOSTheme.iosGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} сум',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: IOSTheme.iosGreen,
                  ),
                ),
                const Spacer(),
                // Action buttons
                _ActionButton(
                  icon: Icons.navigation,
                  color: IOSTheme.iosBlue,
                  onTap: onNavigate,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.phone,
                  color: IOSTheme.iosGreen,
                  onTap: onCall,
                ),
              ],
            ),
          ),

          // Start Delivery Button (only for current/pending)
          if (order.status != OrderStatus.completed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? IOSTheme.iosBlue : IOSTheme.bgSecondary,
                    foregroundColor: isCurrent ? Colors.white : IOSTheme.label,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isCurrent ? 'Начать доставку' : 'Пропустить',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.current:
        return 'Сейчас';
      case OrderStatus.pending:
        return 'В очереди';
      case OrderStatus.completed:
        return 'Готово';
    }
  }

  StatusBadgeType _getStatusType(OrderStatus status) {
    switch (status) {
      case OrderStatus.current:
        return StatusBadgeType.info;
      case OrderStatus.pending:
        return StatusBadgeType.pending;
      case OrderStatus.completed:
        return StatusBadgeType.success;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: IOSTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: IOSTheme.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationSheet extends StatelessWidget {
  final DeliveryOrder order;

  const _NavigationSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            order.customerName,
            style: IOSTheme.title2,
          ),
          const SizedBox(height: 8),
          Text(
            order.address,
            style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _NavigationOption(
                  icon: Icons.navigation,
                  label: 'Google Maps',
                  color: IOSTheme.iosGreen,
                  onTap: () {
                    // Launch Google Maps
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavigationOption(
                  icon: Icons.map,
                  label: 'Yandex Maps',
                  color: IOSTheme.iosYellow,
                  onTap: () {
                    // Launch Yandex Maps
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavigationOption(
                  icon: Icons.content_copy,
                  label: 'Копировать',
                  color: IOSTheme.iosBlue,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: order.address));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Адрес скопирован')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavigationOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavigationOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Models
class DeliveryOrder {
  final String id;
  final String customerName;
  final String address;
  final String phone;
  final int totalAmount;
  final int items;
  OrderStatus status;
  final String notes;
  final double latitude;
  final double longitude;

  DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.totalAmount,
    required this.items,
    required this.status,
    required this.notes,
    required this.latitude,
    required this.longitude,
  });
}

enum OrderStatus {
  current,
  pending,
  completed,
}

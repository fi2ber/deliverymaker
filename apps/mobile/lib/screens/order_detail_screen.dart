import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../db/schemas/order.dart';
import '../db/schemas/order_item.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  
  // Temporary state for edits
  Map<String, double> _quantities = {};

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final isar = getIt<DatabaseService>().isar;
    final order = await isar.orders.get(widget.orderId);
    
    if (order != null) {
      setState(() {
        _order = order;
        _loading = false;
        // Initialize quantities
        _quantities = {
          for (var item in order.items) item.productId: item.quantity
        };
      });
    }
  }

  void _updateQuantity(String productId, double change) {
    if (_order == null) return;
    
    final current = _quantities[productId] ?? 0;
    final newQty = current + change;
    
    // Find original max quantity to prevent over-delivery (unless allowed?)
    // Usually logistics = deliver what was ordered or less.
    final originalItem = _order!.items.firstWhere((i) => i.productId == productId);
    
    if (newQty < 0) return;
    if (newQty > originalItem.quantity) return; // Cannot deliver more than ordered

    setState(() {
      _quantities[productId] = newQty;
    });
  }
  
  double get _currentTotal {
    if (_order == null) return 0.0;
    double total = 0.0;
    for (var item in _order!.items) {
      final qty = _quantities[item.productId] ?? 0;
      total += qty * item.price;
    }
    return total;
  }

  Future<void> _confirmDelivery() async {
    if (_order == null) return;
    
    final syncService = getIt<SyncService>();
    
    // 1. Update Local Order
    final isar = getIt<DatabaseService>().isar;
    await isar.writeTxn(() async {
      // Update items with Delivered vs Rejected
      final updatedItems = _order!.items.map((item) {
        final delivered = _quantities[item.productId] ?? 0;
        item.deliveredQuantity = delivered;
        item.rejectedQuantity = item.quantity - delivered;
        return item;
      }).toList();
      
      _order!.items = updatedItems;
      _order!.status = 'delivered';
      _order!.totalAmount = _currentTotal; 
      _order!.isSynced = false; // Need sync
      
      await isar.orders.put(_order!);
      
      // 2. Queue Sync Action
      // We need to implement this in SyncService
       await syncService.queueDelivery(_order!);
    });
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order Delivered!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_order == null) return const Scaffold(body: Center(child: Text('Order not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_order!.clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_order!.address),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Chip(label: Text(_order!.paymentInfo)),
                  ],
                )
              ],
            ),
          ),
          
          // Items
          Expanded(
            child: ListView.builder(
              itemCount: _order!.items.length,
              itemBuilder: (context, index) {
                final item = _order!.items[index];
                final currentQty = _quantities[item.productId] ?? 0;
                
                return ListTile(
                  title: Text(item.productName),
                  subtitle: Text('${item.price} x ${item.quantity} (Orig)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _updateQuantity(item.productId, -1),
                        color: Colors.red,
                      ),
                      Text('$currentQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _updateQuantity(item.productId, 1),
                        color: Colors.green,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Footer
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!))
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${_currentTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _confirmDelivery,
                      icon: const Icon(Icons.check),
                      label: const Text('CONFIRM DELIVERY'),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

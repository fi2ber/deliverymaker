import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart';
import '../db/schemas/stock.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';

class TruckStockScreen extends StatefulWidget {
  const TruckStockScreen({super.key});

  @override
  State<TruckStockScreen> createState() => _TruckStockScreenState();
}

class _TruckStockScreenState extends State<TruckStockScreen> {
  bool _loading = false;
  
  @override
  void initState() {
    super.initState();
    _syncStock();
  }
  
  Future<void> _syncStock() async {
      setState(() => _loading = true);
      await getIt<SyncService>().pullTruckStock();
      setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Van Stock'),
        actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _syncStock)
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<Stock>>(
            stream: getIt<DatabaseService>().isar.stocks.where().watch(fireImmediately: true),
            builder: (context, snapshot) {
                final stocks = snapshot.data ?? [];
                if (stocks.isEmpty) {
                    return const Center(child: Text('Truck is empty'));
                }
                
                return ListView.builder(
                    itemCount: stocks.length,
                    itemBuilder: (context, index) {
                        final item = stocks[index];
                        return ListTile(
                            leading: CircleAvatar(child: Text(item.productName[0])),
                            title: Text(item.productName),
                            subtitle: Text('Batch: ${item.batchCode ?? "N/A"}'),
                            trailing: Text(
                                item.quantity.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                        );
                    },
                );
            },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.shopping_cart),
        label: const Text('SELL'),
        onPressed: () {
            // Navigate to Van Sale Creation
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Van Sale Coming Soon')));
        },
      ),
    );
  }
}

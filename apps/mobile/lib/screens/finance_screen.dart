import 'package:flutter/material.dart';
import '../main.dart';
import '../services/finance_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  double _balance = 0.0;
  bool _loading = true;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => _loading = true);
    final balance = await getIt<FinanceService>().getBalance();
    setState(() {
      _balance = balance;
      _loading = false;
    });
  }

  Future<void> _handover() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Amount')),
      );
      return;
    }

    if (amount > _balance) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient funds')),
      );
      return; 
    }

    setState(() => _loading = true);
    try {
      await getIt<FinanceService>().requestHandover(amount);
      _amountController.clear();
      await _loadBalance(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Handover Requested! Ask Admin to confirm.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Current Cash Balance', style: TextStyle(fontSize: 16)),
                Text(
                  _balance.toStringAsFixed(2), 
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green)
                ),
                const SizedBox(height: 48),
                const Text('Handover Cash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _handover,
                    icon: const Icon(Icons.payments),
                    label: const Text('REQUEST HANDOVER'),
                  ),
                )
              ],
            ),
          ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/entities/customer_entity.dart';
import 'customer_registration_screen.dart';
import 'quick_order_screen.dart';

/// Search customers or create new
class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final _searchController = TextEditingController();
  final _repository = CustomerRepository();
  List<CustomerEntity> _results = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _repository.searchCustomers(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Поиск клиента...',
            hintStyle: IOSTheme.body.copyWith(color: IOSTheme.labelTertiary),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _results = []);
                    },
                  )
                : null,
          ),
          onChanged: _search,
        ),
      ),
      body: Column(
        children: [
          // Add new customer button
          Padding(
            padding: const EdgeInsets.all(16),
            child: IOSCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerRegistrationScreen(
                      salesRepId: 'sales_rep_001', // TODO: Get from auth
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: IOSTheme.systemGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: IOSTheme.systemGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Новый клиент',
                          style: IOSTheme.headline,
                        ),
                        Text(
                          'Зарегистрировать клиента с подтверждением',
                          style: IOSTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),

          const Divider(),

          // Search results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty && _searchController.text.length >= 2
                    ? const Center(child: Text('Клиенты не найдены'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final customer = _results[index];
                          return _CustomerListItem(
                            customer: customer,
                            onTap: () {
                              // Navigate to quick order for this customer
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuickOrderScreen(
                                    customer: customer,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CustomerListItem extends StatelessWidget {
  final CustomerEntity customer;
  final VoidCallback onTap;

  const _CustomerListItem({
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: IOSTheme.systemBlue.withOpacity(0.1),
        child: Text(
          customer.firstName[0].toUpperCase(),
          style: const TextStyle(
            color: IOSTheme.systemBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(customer.fullName, style: IOSTheme.headline),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customer.phone, style: IOSTheme.caption),
          if (customer.isPhoneVerified)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: IOSTheme.systemGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '✓ Подтвержден',
                style: IOSTheme.footnote.copyWith(
                  color: IOSTheme.systemGreen,
                ),
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

/// Quick order screen (placeholder)
class QuickOrderScreen extends StatelessWidget {
  final CustomerEntity customer;

  const QuickOrderScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заказ для ${customer.firstName}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Клиент: ${customer.fullName}'),
            Text('Телефон: ${customer.phone}'),
            const SizedBox(height: 20),
            const Text('Выберите товары из каталога'),
          ],
        ),
      ),
    );
  }
}

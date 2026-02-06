import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/van_sale/van_sale_bloc.dart';
import '../main.dart';

class VanSaleScreen extends StatelessWidget {
  const VanSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VanSaleBloc(getIt(), getIt())..add(VanSaleLoadStock()),
      child: const _VanSaleView(),
    );
  }
}

class _VanSaleView extends StatefulWidget {
  const _VanSaleView();

  @override
  State<_VanSaleView> createState() => _VanSaleViewState();
}

class _VanSaleViewState extends State<_VanSaleView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddToCartDialog(BuildContext context, VanSaleLoaded state, int index) {
    final stock = state.filteredStock[index];
    final cartItem = state.cart[stock.productId];
    final currentQty = cartItem?.quantity ?? 0;
    final availableQty = stock.quantity - currentQty;

    if (availableQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stock available')),
      );
      return;
    }

    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: stock.price.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.productName,
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available: ${availableQty.toStringAsFixed(2)}',
                style: TextStyle(
                  color: availableQty > 10 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (stock.batchCode != null)
                Text(
                  'Batch: ${stock.batchCode}',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              const SizedBox(height: 24),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: 'units',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price per unit',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final qty = double.tryParse(quantityController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;

                    if (qty <= 0 || qty > availableQty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Invalid quantity. Available: ${availableQty.toStringAsFixed(2)}'),
                        ),
                      );
                      return;
                    }

                    context.read<VanSaleBloc>().add(VanSaleAddToCart(
                      productId: stock.productId,
                      productName: stock.productName,
                      quantity: qty,
                      price: price,
                    ));

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${stock.productName} to cart'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Add to Cart', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCartBottomSheet(BuildContext context, VanSaleLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shopping Cart',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${state.cart.length} items',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cart Items
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: state.cart.length,
                    itemBuilder: (context, index) {
                      final item = state.cart.values.elementAt(index);
                      return ListTile(
                        title: Text(item.productName),
                        subtitle: Text('\$${item.price.toStringAsFixed(2)} × ${item.quantity.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                context.read<VanSaleBloc>().add(
                                  VanSaleRemoveFromCart(item.productId),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Footer with Total and Checkout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${state.cartTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showCheckoutDialog(context, state);
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Proceed to Checkout',
                              style: TextStyle(fontSize: 16),
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
        );
      },
    );
  }

  void _showCheckoutDialog(BuildContext context, VanSaleLoaded state) {
    // For demo, using a simple client selection. In production, this should fetch from local DB or API
    final paymentMethods = [
      {'value': 'CASH', 'label': 'Cash', 'icon': Icons.money},
      {'value': 'CREDIT', 'label': 'Credit', 'icon': Icons.credit_card},
      {'value': 'CARD', 'label': 'Card', 'icon': Icons.payment},
    ];

    String selectedPayment = 'CASH';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Complete Sale'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '\$${state.cartTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Payment Method:'),
                  const SizedBox(height: 8),
                  ...paymentMethods.map((method) {
                    return RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(method['icon'] as IconData),
                          const SizedBox(width: 8),
                          Text(method['label'] as String),
                        ],
                      ),
                      value: method['value'] as String,
                      groupValue: selectedPayment,
                      onChanged: (value) {
                        setState(() {
                          selectedPayment = value!;
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    // For demo, using a placeholder client ID
                    // In production, this should come from a client selection dialog
                    context.read<VanSaleBloc>().add(
                      const VanSaleClientSelected('demo-client', 'Demo Client'),
                    );
                    context.read<VanSaleBloc>().add(
                      VanSaleSubmit(selectedPayment),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Complete Sale'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Van Sale'),
        actions: [
          BlocBuilder<VanSaleBloc, VanSaleState>(
            builder: (context, state) {
              if (state is VanSaleLoaded && state.cart.isNotEmpty) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () => _showCartBottomSheet(context, state),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${state.cart.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: null,
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<VanSaleBloc, VanSaleState>(
        listener: (context, state) {
          if (state is VanSaleSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sale completed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<VanSaleBloc>().add(VanSaleClearCart());
          } else if (state is VanSaleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VanSaleInitial || state is VanSaleLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VanSaleError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<VanSaleBloc>().add(VanSaleLoadStock());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is VanSaleSubmitting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing sale...'),
                ],
              ),
            );
          }

          if (state is VanSaleLoaded) {
            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      context.read<VanSaleBloc>().add(VanSaleSearchChanged(value));
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<VanSaleBloc>().add(const VanSaleSearchChanged(''));
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${state.filteredStock.length} products',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (state.searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(filtered)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Product List
                Expanded(
                  child: state.filteredStock.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                state.searchQuery.isEmpty
                                    ? 'No stock available'
                                    : 'No products found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.filteredStock.length,
                          itemBuilder: (context, index) {
                            final stock = state.filteredStock[index];
                            final cartItem = state.cart[stock.productId];
                            final inCart = cartItem?.quantity ?? 0;
                            final available = stock.quantity - inCart;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  stock.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Available: ${available.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: available > 10 ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (stock.batchCode != null)
                                      Text(
                                        'Batch: ${stock.batchCode}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    if (inCart > 0)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${inCart.toStringAsFixed(2)} in cart',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${stock.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (available > 0)
                                      FilledButton.tonal(
                                        onPressed: () => _showAddToCartDialog(context, state, index),
                                        child: const Text('Add'),
                                      )
                                    else
                                      const Text(
                                        'Out of stock',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: available > 0
                                    ? () => _showAddToCartDialog(context, state, index)
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}

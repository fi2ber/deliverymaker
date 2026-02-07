import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/ios_theme.dart';
import '../bloc/catalog_bloc.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_summary.dart';
import '../widgets/category_tabs.dart';
import 'customer_search_screen.dart';

/// Sales catalog screen with products and cart
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CatalogBloc()..add(const LoadCatalog()),
      child: const _CatalogScreenContent(),
    );
  }
}

class _CatalogScreenContent extends StatelessWidget {
  const _CatalogScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar with search
            SliverToBoxAdapter(
              child: _buildAppBar(context),
            ),

            // Category tabs
            SliverToBoxAdapter(
              child: CategoryTabs(
                onCategorySelected: (categoryId) {
                  context.read<CatalogBloc>().add(LoadCatalog(categoryId: categoryId));
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Products grid
            BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state.error != null) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        state.error!,
                        style: IOSTheme.body,
                      ),
                    ),
                  );
                }

                if (state.filteredProducts.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('Нет товаров'),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = state.filteredProducts[index];
                        final quantity = state.getCartQuantity(
                          product.serverId ?? product.id.toString(),
                        );

                        return ProductCard(
                          product: product,
                          quantity: quantity,
                          onAdd: () => context.read<CatalogBloc>().add(
                            AddToCart(product),
                          ),
                          onRemove: () => context.read<CatalogBloc>().add(
                            RemoveFromCart(
                              product.serverId ?? product.id.toString(),
                            ),
                          ),
                          onUpdateQuantity: (qty) => context.read<CatalogBloc>().add(
                            UpdateCartQuantity(
                              product.serverId ?? product.id.toString(),
                              qty,
                            ),
                          ),
                        );
                      },
                      childCount: state.filteredProducts.length,
                    ),
                  ),
                );
              },
            ),

            // Bottom padding for cart summary
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // Floating cart summary
      bottomSheet: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          if (state.cart.isEmpty) return const SizedBox.shrink();

          return CartSummary(
            itemCount: state.cartItemCount,
            total: state.cartTotal,
            onCheckout: () {
              // Navigate to customer selection / order creation
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerSearchScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Каталог',
                style: IOSTheme.title1,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Show search
                  _showSearch(context);
                },
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Search bar
          GestureDetector(
            onTap: () => _showSearch(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: IOSTheme.bgSecondary,
                borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
                border: Border.all(color: IOSTheme.fill),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: IOSTheme.labelSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Поиск товаров...',
                    style: IOSTheme.bodyMedium.copyWith(
                      color: IOSTheme.labelTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CatalogBloc>(),
        child: const _ProductSearchSheet(),
      ),
    );
  }
}

class _ProductSearchSheet extends StatefulWidget {
  const _ProductSearchSheet();

  @override
  State<_ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<_ProductSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(IOSTheme.radius2Xl),
        ),
      ),
      child: Column(
        children: [
          // Handle
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

          // Search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Введите название или артикул',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          context.read<CatalogBloc>().add(const SearchProducts(''));
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: IOSTheme.bgTertiary,
              ),
              onChanged: (value) {
                context.read<CatalogBloc>().add(SearchProducts(value));
              },
            ),
          ),

          // Results
          Expanded(
            child: BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, state) {
                if (state.filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('Ничего не найдено'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = state.filteredProducts[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('${product.currentPrice.toStringAsFixed(0)} сум'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: IOSTheme.systemBlue),
                        onPressed: () {
                          context.read<CatalogBloc>().add(AddToCart(product));
                        },
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

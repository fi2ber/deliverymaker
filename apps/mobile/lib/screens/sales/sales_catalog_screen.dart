import 'package:flutter/material.dart';
import '../../theme/ios_theme.dart';
import 'client_registration_screen.dart';
import 'order_confirmation_screen.dart';

class SalesCatalogScreen extends StatefulWidget {
  final Client? client;
  const SalesCatalogScreen({super.key, this.client});

  @override
  State<SalesCatalogScreen> createState() => _SalesCatalogScreenState();
}

class _SalesCatalogScreenState extends State<SalesCatalogScreen> {
  String _selectedCategory = 'all';
  final Map<String, CartItem> _cart = {};
  bool _isGridView = true;

  final List<Category> _categories = [
    Category(id: 'all', name: 'Все', icon: Icons.apps),
    Category(id: 'drinks', name: 'Напитки', icon: Icons.local_drink),
    Category(id: 'snacks', name: 'Снеки', icon: Icons.fastfood),
  ];

  final List<Product> _products = [
    Product(id: '1', name: 'Coca-Cola 1.5L', price: 12000, category: 'drinks', imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400', stock: 150, discount: 0),
    Product(id: '2', name: 'Fanta Orange 1L', price: 10500, category: 'drinks', imageUrl: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400', stock: 89, discount: 10),
    Product(id: '3', name: 'Lays Classic', price: 8000, category: 'snacks', imageUrl: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400', stock: 120, discount: 15),
    Product(id: '4', name: 'Pringles Original', price: 15000, category: 'snacks', imageUrl: 'https://images.unsplash.com/photo-1561758033-d8f2311da1e5?w=400', stock: 45, discount: 0),
  ];

  double get _cartTotal => _cart.values.fold(0, (sum, item) => sum + (item.product.price * item.quantity * (1 - item.product.discount / 100)));
  int get _cartItemsCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(Product product) {
    IOSTheme.lightImpact();
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity++;
      } else {
        _cart[product.id] = CartItem(product: product, quantity: 1);
      }
    });
  }

  void _proceedToCheckout() {
    if (_cart.isEmpty) return;
    IOSTheme.mediumImpact();

    if (widget.client == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ClientRegistrationScreen(cartItems: _cart.values.toList())));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OrderConfirmationScreen(client: widget.client!, cartItems: _cart.values.toList())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _selectedCategory == 'all' ? _products : _products.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: IOSTheme.bgSecondary,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildCategories()),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _isGridView
                ? SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = filteredProducts[index];
                      return _ProductCard(product: product, cartQuantity: _cart[product.id]?.quantity ?? 0, onAddToCart: () => _addToCart(product));
                    }, childCount: filteredProducts.length),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = filteredProducts[index];
                      return _ProductListItem(product: product, cartQuantity: _cart[product.id]?.quantity ?? 0, onAddToCart: () => _addToCart(product));
                    }, childCount: filteredProducts.length),
                  ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      bottomNavigationBar: _cart.isNotEmpty ? _buildCartBar() : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      decoration: const BoxDecoration(color: IOSTheme.iosBlue, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.shopping_bag, color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Каталог', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
            IconButton(onPressed: () => setState(() => _isGridView = !_isGridView), icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white)),
          ]),
          const SizedBox(height: 16),
          Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: TextField(decoration: InputDecoration(hintText: 'Поиск товаров...', hintStyle: TextStyle(color: IOSTheme.labelTertiary, fontSize: 17), prefixIcon: const Icon(Icons.search, color: IOSTheme.labelSecondary), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category.id;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () { IOSTheme.lightImpact(); setState(() => _selectedCategory = category.id); },
              child: Container(
                width: 80,
                decoration: BoxDecoration(color: isSelected ? IOSTheme.iosBlue : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: IOSTheme.shadowSm),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(category.icon, color: isSelected ? Colors.white : IOSTheme.iosBlue, size: 28), const SizedBox(height: 8), Text(category.name, style: TextStyle(color: isSelected ? Colors.white : IOSTheme.label, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: IOSTheme.iosBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.shopping_cart, color: IOSTheme.iosBlue), const SizedBox(width: 8), Text('$_cartItemsCount', style: const TextStyle(color: IOSTheme.iosBlue, fontWeight: FontWeight.bold, fontSize: 16))])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [const Text('Итого:', style: TextStyle(color: IOSTheme.labelSecondary, fontSize: 13)), Text('${_cartTotal.toStringAsFixed(0)} сум', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
          ElevatedButton(onPressed: _proceedToCheckout, style: ElevatedButton.styleFrom(backgroundColor: IOSTheme.iosBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Оформить', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final VoidCallback onAddToCart;
  const _ProductCard({required this.product, required this.cartQuantity, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final discountedPrice = product.price * (1 - product.discount / 100);
    return GestureDetector(
      onTap: onAddToCart,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: IOSTheme.shadowSm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: Stack(children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Container(color: IOSTheme.bgSecondary, child: Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity))),
            if (product.discount > 0) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: IOSTheme.iosRed, borderRadius: BorderRadius.circular(8)), child: Text('-${product.discount}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
            if (cartQuantity > 0) Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: IOSTheme.iosBlue, shape: BoxShape.circle, boxShadow: IOSTheme.shadowMd), child: Text('$cartQuantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
          ])),
          Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(children: [
              Expanded(child: Text('${discountedPrice.toStringAsFixed(0)} сум', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: IOSTheme.iosGreen))),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: IOSTheme.iosBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add, color: IOSTheme.iosBlue, size: 20)),
            ])),
          ]))),
        ]),
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final VoidCallback onAddToCart;
  const _ProductListItem({required this.product, required this.cartQuantity, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final discountedPrice = product.price * (1 - product.discount / 100);
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: IOSTheme.shadowSm),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(product.imageUrl, width: 80, height: 80, fit: BoxFit.cover)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${discountedPrice.toStringAsFixed(0)} сум', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: IOSTheme.iosGreen)),
        ])),
        Column(children: [
          if (cartQuantity > 0) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: IOSTheme.iosBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('$cartQuantity', style: const TextStyle(color: IOSTheme.iosBlue, fontWeight: FontWeight.bold))),
          GestureDetector(onTap: onAddToCart, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: IOSTheme.iosBlue, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add, color: Colors.white, size: 24))),
        ]),
      ]),
    );
  }
}

class Category { final String id; final String name; final IconData icon; Category({required this.id, required this.name, required this.icon}); }
class Product { final String id; final String name; final double price; final String category; final String imageUrl; final int stock; final double discount; Product({required this.id, required this.name, required this.price, required this.category, required this.imageUrl, required this.stock, required this.discount}); }
class CartItem { final Product product; int quantity; CartItem({required this.product, this.quantity = 1}); }
class Client { final String id; final String name; final String phone; final String address; Client({required this.id, required this.name, required this.phone, required this.address}); }

import 'package:flutter/material.dart';
import '../../theme/ios_theme.dart';

/// Order Confirmation Screen - Final step of order creation
/// Client is already verified, just confirm order details
class OrderConfirmationScreen extends StatefulWidget {
  final Client client;
  final List<CartItem> cartItems;
  final bool isNewClient;

  const OrderConfirmationScreen({
    super.key,
    required this.client,
    required this.cartItems,
    this.isNewClient = false,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  String _paymentMethod = 'cash';
  bool _isProcessing = false;

  double get _cartTotal => widget.cartItems.fold(
        0,
        (sum, item) => sum + (item.product.price * item.quantity * (1 - item.product.discount / 100)),
      );

  void _completeOrder() async {
    IOSTheme.success();
    setState(() => _isProcessing = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() => _isProcessing = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: IOSTheme.iosGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: IOSTheme.iosGreen, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Заказ создан!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              widget.isNewClient
                  ? 'Клиент зарегистрирован и получит ссылку на Telegram бота'
                  : 'Заказ успешно оформлен',
              textAlign: TextAlign.center,
              style: const TextStyle(color: IOSTheme.labelSecondary),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: IOSTheme.iosBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('К следующему клиенту'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Подтверждение'),
        backgroundColor: IOSTheme.bgSecondary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Progress
          Row(
            children: [
              _buildStepIndicator(1, 'Каталог', true),
              Expanded(child: Container(height: 2, color: IOSTheme.iosBlue)),
              _buildStepIndicator(2, 'Клиент', true),
              Expanded(child: Container(height: 2, color: IOSTheme.iosBlue)),
              _buildStepIndicator(3, 'Готово', true),
            ],
          ),
          const SizedBox(height: 32),

          // Client Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: IOSTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.client.isVerified 
                            ? IOSTheme.iosGreen.withOpacity(0.1)
                            : IOSTheme.iosBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.client.isVerified ? Icons.verified_user : Icons.person,
                        color: widget.client.isVerified ? IOSTheme.iosGreen : IOSTheme.iosBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.client.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(widget.client.phone, style: const TextStyle(color: IOSTheme.labelSecondary)),
                              if (widget.client.isVerified) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle, color: IOSTheme.iosGreen, size: 16),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.isNewClient)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: IOSTheme.iosGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Новый',
                          style: TextStyle(color: IOSTheme.iosGreen, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                if (widget.client.isVerified) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: IOSTheme.iosGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: IOSTheme.iosGreen, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Телефон подтверждён',
                          style: TextStyle(color: IOSTheme.iosGreen, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: IOSTheme.labelSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(widget.client.address, style: const TextStyle(color: IOSTheme.labelSecondary))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Order Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: IOSTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Заказ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...widget.cartItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(item.product.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text('${item.quantity} шт. × ${item.product.price.toStringAsFixed(0)} сум', style: const TextStyle(color: IOSTheme.labelSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                      Text('${(item.product.price * item.quantity).toStringAsFixed(0)} сум', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Итого:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('${_cartTotal.toStringAsFixed(0)} сум', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: IOSTheme.iosGreen)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment Method
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: IOSTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Способ оплаты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _PaymentOption(
                  icon: Icons.money,
                  title: 'Наличные',
                  isSelected: _paymentMethod == 'cash',
                  onTap: () => setState(() => _paymentMethod = 'cash'),
                ),
                const SizedBox(height: 12),
                _PaymentOption(
                  icon: Icons.credit_card,
                  title: 'Карта',
                  isSelected: _paymentMethod == 'card',
                  onTap: () => setState(() => _paymentMethod = 'card'),
                ),
                const SizedBox(height: 12),
                _PaymentOption(
                  icon: Icons.account_balance_wallet,
                  title: 'В долг',
                  isSelected: _paymentMethod == 'credit',
                  onTap: () => setState(() => _paymentMethod = 'credit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Telegram Info (only for new clients)
          if (widget.isNewClient)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0088CC).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.telegram, color: Color(0xFF0088CC), size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Telegram интеграция', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          'Клиент получит ссылку на личный кабинет в Telegram боте',
                          style: TextStyle(color: IOSTheme.labelSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      // Complete Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _completeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: IOSTheme.iosGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: IOSTheme.fill,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isProcessing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Завершить заказ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: isActive ? IOSTheme.iosBlue : IOSTheme.fill, shape: BoxShape.circle),
          child: Center(
            child: Text('$step', style: TextStyle(color: isActive ? Colors.white : IOSTheme.labelTertiary, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isActive ? IOSTheme.iosBlue : IOSTheme.labelTertiary, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({required this.icon, required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? IOSTheme.iosBlue.withOpacity(0.1) : IOSTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? IOSTheme.iosBlue : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? IOSTheme.iosBlue : IOSTheme.labelSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? IOSTheme.iosBlue : IOSTheme.label))),
            if (isSelected) const Icon(Icons.check_circle, color: IOSTheme.iosBlue),
          ],
        ),
      ),
    );
  }
}

class Client {
  final String id;
  final String name;
  final String phone;
  final String address;
  final bool isVerified;
  Client({required this.id, required this.name, required this.phone, required this.address, this.isVerified = false});
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final double discount;
  Product({required this.id, required this.name, required this.price, required this.imageUrl, required this.discount});
}

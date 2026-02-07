import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';

/// Bottom cart summary bar
class CartSummary extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onCheckout;

  const CartSummary({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(IOSTheme.radius2Xl),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cart icon with badge
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: IOSTheme.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: IOSTheme.systemBlue,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: IOSTheme.systemRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Total
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Итого:',
                    style: IOSTheme.caption,
                  ),
                  Text(
                    '${total.toStringAsFixed(0)} сум',
                    style: IOSTheme.title2.copyWith(color: IOSTheme.systemBlue),
                  ),
                ],
              ),
            ),

            // Checkout button
            IOSButton(
              text: 'Оформить',
              onPressed: onCheckout,
            ),
          ],
        ),
      ),
    );
  }
}

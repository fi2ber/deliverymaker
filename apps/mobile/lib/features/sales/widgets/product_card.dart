import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../data/entities/product_entity.dart';

/// iOS-style product card for catalog
class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final double quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final Function(double) onUpdateQuantity;

  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscount;

    return GestureDetector(
      onTap: () => _showQuantitySheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: IOSTheme.bgSecondary,
          borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
          boxShadow: IOSTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: IOSTheme.bgTertiary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(IOSTheme.radiusXl),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(IOSTheme.radiusXl),
                  ),
                  child: product.mainImage != null
                      ? Image.network(
                          product.mainImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      product.name,
                      style: IOSTheme.headline.copyWith(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Price
                    Row(
                      children: [
                        Text(
                          '${product.currentPrice.toStringAsFixed(0)} сум',
                          style: IOSTheme.headline.copyWith(
                            color: hasDiscount ? IOSTheme.systemRed : IOSTheme.labelPrimary,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${product.price.toStringAsFixed(0)} сум',
                            style: IOSTheme.footnote.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: IOSTheme.labelTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Quantity selector or Add button
                    if (quantity > 0)
                      _buildQuantitySelector()
                    else
                      _buildAddButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: IOSTheme.labelQuaternary,
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: IOSButton(
        text: 'Добавить',
        onPressed: onAdd,
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: IOSTheme.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.remove,
                size: 18,
                color: IOSTheme.systemBlue,
              ),
            ),
          ),
          Text(
            '${quantity.toStringAsFixed(0)} ${product.unit}',
            style: IOSTheme.headline.copyWith(
              color: IOSTheme.systemBlue,
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.add,
                size: 18,
                color: IOSTheme.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuantitySheet(
        product: product,
        currentQuantity: quantity,
        onQuantityChanged: onUpdateQuantity,
      ),
    );
  }
}

class _QuantitySheet extends StatefulWidget {
  final ProductEntity product;
  final double currentQuantity;
  final Function(double) onQuantityChanged;

  const _QuantitySheet({
    required this.product,
    required this.currentQuantity,
    required this.onQuantityChanged,
  });

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.currentQuantity > 0 ? widget.currentQuantity : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IOSTheme.bgSecondary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(IOSTheme.radius2Xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: IOSTheme.fill,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Product name
          Text(
            widget.product.name,
            style: IOSTheme.title3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.product.currentPrice.toStringAsFixed(0)} сум / ${widget.product.unit}',
            style: IOSTheme.bodyMedium.copyWith(
              color: IOSTheme.labelSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Quantity control
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuantityButton(
                icon: Icons.remove,
                onTap: () {
                  if (_quantity > 0.5) {
                    setState(() => _quantity -= 0.5);
                  }
                },
              ),
              const SizedBox(width: 24),
              Text(
                '${_quantity.toStringAsFixed(1)} ${widget.product.unit}',
                style: IOSTheme.title2,
              ),
              const SizedBox(width: 24),
              _QuantityButton(
                icon: Icons.add,
                onTap: () => setState(() => _quantity += 0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: IOSTheme.bgTertiary,
              borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Итого:', style: IOSTheme.body),
                Text(
                  '${(widget.product.currentPrice * _quantity).toStringAsFixed(0)} сум',
                  style: IOSTheme.title3.copyWith(color: IOSTheme.systemBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Add button
          SizedBox(
            width: double.infinity,
            child: IOSButton(
              text: 'Добавить в заказ',
              onPressed: () {
                widget.onQuantityChanged(_quantity);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: IOSTheme.systemBlue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: IOSTheme.systemBlue, size: 24),
      ),
    );
  }
}

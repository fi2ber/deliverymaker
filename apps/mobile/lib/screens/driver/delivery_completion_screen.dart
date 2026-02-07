import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/ios_theme.dart';
import 'route_screen.dart';

/// Delivery Completion Screen
/// Step-by-step flow: Photo -> Signature/Scan -> Confirm
class DeliveryCompletionScreen extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryCompletionScreen({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryCompletionScreen> createState() => _DeliveryCompletionScreenState();
}

class _DeliveryCompletionScreenState extends State<DeliveryCompletionScreen> {
  int _currentStep = 0;
  bool _hasPhoto = false;
  bool _hasSignature = false;
  String? _paymentMethod;
  int _receivedAmount = 0;

  final List<String> _steps = [
    'Фото доставки',
    'Подтверждение',
    'Оплата',
  ];

  void _nextStep() {
    IOSTheme.mediumImpact();
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _completeDelivery();
    }
  }

  void _completeDelivery() {
    IOSTheme.success();
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
              child: const Icon(
                Icons.check_circle,
                color: IOSTheme.iosGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Доставлено!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Заказ ${widget.order.id} успешно доставлен',
              style: TextStyle(
                color: IOSTheme.labelSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: IOSTheme.iosBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'К следующему заказу',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
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
        title: Text('Заказ ${widget.order.id}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress Steps
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: _steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? IOSTheme.iosGreen
                                    : isActive
                                        ? IOSTheme.iosBlue
                                        : IOSTheme.bgSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isActive ? Colors.white : IOSTheme.labelSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                color: isActive ? IOSTheme.label : IOSTheme.labelSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (index < _steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isCompleted ? IOSTheme.iosGreen : IOSTheme.bgSecondary,
                            margin: const EdgeInsets.only(bottom: 20),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Step Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IOSTheme.iosBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: IOSTheme.bgSecondary,
                    disabledForegroundColor: IOSTheme.labelTertiary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentStep == _steps.length - 1 ? 'Завершить' : 'Далее',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _hasPhoto;
      case 1:
        return _hasSignature;
      case 2:
        return _paymentMethod != null;
      default:
        return true;
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _PhotoStep(
          hasPhoto: _hasPhoto,
          onPhotoTaken: () => setState(() => _hasPhoto = true),
          order: widget.order,
        );
      case 1:
        return _ConfirmationStep(
          hasSignature: _hasSignature,
          onSignatureDone: () => setState(() => _hasSignature = true),
        );
      case 2:
        return _PaymentStep(
          order: widget.order,
          selectedMethod: _paymentMethod,
          onMethodSelected: (method) => setState(() => _paymentMethod = method),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// Step 1: Photo
class _PhotoStep extends StatelessWidget {
  final bool hasPhoto;
  final VoidCallback onPhotoTaken;
  final DeliveryOrder order;

  const _PhotoStep({
    required this.hasPhoto,
    required this.onPhotoTaken,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Card
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
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: IOSTheme.iosBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.address,
                        style: TextStyle(
                          color: IOSTheme.labelSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 18, color: IOSTheme.iosGreen),
                    const SizedBox(width: 8),
                    Text(
                      '${order.items} товаров',
                      style: TextStyle(
                        color: IOSTheme.labelSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${order.totalAmount.toStringAsFixed(0)} сум',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: IOSTheme.iosGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Photo Section
          const Text(
            'Сделайте фото доставки',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Фото подтверждает передачу товара клиенту',
            style: TextStyle(
              color: IOSTheme.labelSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),

          // Photo Options
          Row(
            children: [
              Expanded(
                child: _PhotoOption(
                  icon: Icons.camera_alt,
                  label: 'Камера',
                  onTap: () {
                    IOSTheme.mediumImpact();
                    onPhotoTaken();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PhotoOption(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: () {
                    IOSTheme.mediumImpact();
                    onPhotoTaken();
                  },
                ),
              ),
            ],
          ),

          if (hasPhoto) ...[
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: IOSTheme.iosGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: IOSTheme.iosGreen, width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: IOSTheme.iosGreen,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Фото добавлено',
                      style: TextStyle(
                        color: IOSTheme.iosGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Переснять'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: IOSTheme.shadowSm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: IOSTheme.iosBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: IOSTheme.iosBlue, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 2: Confirmation
class _ConfirmationStep extends StatelessWidget {
  final bool hasSignature;
  final VoidCallback onSignatureDone;

  const _ConfirmationStep({
    required this.hasSignature,
    required this.onSignatureDone,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Подтверждение получения',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите способ подтверждения',
            style: TextStyle(
              color: IOSTheme.labelSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // QR Scan Option
          _ConfirmationOption(
            icon: Icons.qr_code_scanner,
            title: 'Сканировать QR клиента',
            subtitle: 'Клиент показывает QR в приложении',
            color: IOSTheme.iosBlue,
            onTap: () {
              IOSTheme.mediumImpact();
              onSignatureDone();
            },
          ),

          const SizedBox(height: 16),

          // Signature Option
          _ConfirmationOption(
            icon: Icons.draw,
            title: 'Подпись клиента',
            subtitle: 'Клиент подписывает на экране',
            color: IOSTheme.iosPurple,
            onTap: () {
              IOSTheme.mediumImpact();
              _showSignaturePad(context);
            },
          ),

          const SizedBox(height: 16),

          // Photo of ID Option
          _ConfirmationOption(
            icon: Icons.badge,
            title: 'Фото документа',
            subtitle: 'Сфотографировать паспорт/ID',
            color: IOSTheme.iosOrange,
            onTap: () {
              IOSTheme.mediumImpact();
              onSignatureDone();
            },
          ),

          if (hasSignature) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IOSTheme.iosGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: IOSTheme.iosGreen),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: IOSTheme.iosGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Подтверждение получено',
                      style: TextStyle(
                        color: IOSTheme.iosGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSignaturePad(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Подпись клиента',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    'Область для подписи\n(Signature Pad)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Очистить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        onSignatureDone();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IOSTheme.iosBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ConfirmationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: IOSTheme.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: IOSTheme.labelSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: IOSTheme.labelTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// Step 3: Payment
class _PaymentStep extends StatelessWidget {
  final DeliveryOrder order;
  final String? selectedMethod;
  final Function(String) onMethodSelected;

  const _PaymentStep({
    required this.order,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Amount Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [IOSTheme.iosBlue, IOSTheme.iosIndigo],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: IOSTheme.iosBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Сумма к оплате',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} сум',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Способ оплаты',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Payment Methods
          _PaymentMethodTile(
            icon: Icons.money,
            title: 'Наличные',
            subtitle: 'Клиент платит наличными',
            isSelected: selectedMethod == 'cash',
            onTap: () => onMethodSelected('cash'),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            icon: Icons.credit_card,
            title: 'Карта',
            subtitle: 'Оплата картой при получении',
            isSelected: selectedMethod == 'card',
            onTap: () => onMethodSelected('card'),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            icon: Icons.account_balance_wallet,
            title: 'В долг',
            subtitle: 'Оплата позже, добавить в долг',
            isSelected: selectedMethod == 'credit',
            onTap: () => onMethodSelected('credit'),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        IOSTheme.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? IOSTheme.iosBlue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? IOSTheme.iosBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? null : IOSTheme.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? IOSTheme.iosBlue.withOpacity(0.2)
                    : IOSTheme.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? IOSTheme.iosBlue : IOSTheme.labelSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: isSelected ? IOSTheme.iosBlue : IOSTheme.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: IOSTheme.labelSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: IOSTheme.iosBlue,
              ),
          ],
        ),
      ),
    );
  }
}

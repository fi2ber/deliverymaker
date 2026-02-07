import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/ios_theme.dart';
import 'order_confirmation_screen.dart';

/// Client Registration Screen with Phone Verification
/// Steps: 1. Form → 2. Phone Verification → 3. Success → Order
class ClientRegistrationScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const ClientRegistrationScreen({super.key, required this.cartItems});

  @override
  State<ClientRegistrationScreen> createState() => _ClientRegistrationScreenState();
}

class _ClientRegistrationScreenState extends State<ClientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyController = TextEditingController();
  final _codeController = TextEditingController();

  int _currentStep = 1; // 1: Form, 2: Verification, 3: Success
  String _clientType = 'business';
  String? _verificationCode;
  bool _isCodeSent = false;
  bool _isVerified = false;
  bool _isLoading = false;
  int _resendTimer = 0;
  Timer? _timer;

  double get _cartTotal => widget.cartItems.fold(
        0,
        (sum, item) => sum + (item.product.price * item.quantity * (1 - item.product.discount / 100)),
      );

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _sendVerificationCode() {
    if (_formKey.currentState?.validate() ?? false) {
      IOSTheme.mediumImpact();
      setState(() => _isLoading = true);

      // Simulate API call to send Telegram code
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
          _verificationCode = (Random().nextInt(9000) + 1000).toString();
          _isCodeSent = true;
          _currentStep = 2;
        });
        _startResendTimer();
        _showCodeSentDialog();
      });
    }
  }

  void _showCodeSentDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0088CC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Color(0xFF0088CC), size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Код отправлен!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Код подтверждения отправлен в Telegram на номер',
              textAlign: TextAlign.center,
              style: TextStyle(color: IOSTheme.labelSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _phoneController.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: IOSTheme.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Код: $_verificationCode',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(в продакшене код видит только клиент)',
              style: TextStyle(color: IOSTheme.labelTertiary, fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Ввести код', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyCode() {
    if (_codeController.text == _verificationCode) {
      IOSTheme.success();
      setState(() {
        _isVerified = true;
        _currentStep = 3;
      });
      
      // Auto proceed after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _proceedToOrder();
      });
    } else {
      HapticFeedback.vibrate();
      _showErrorDialog('Неверный код', 'Проверьте код из Telegram и попробуйте снова');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _proceedToOrder() {
    // Create verified client
    final newClient = Client(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      name: _clientType == 'business' ? _companyController.text : _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      isVerified: true,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          client: newClient,
          cartItems: widget.cartItems,
          isNewClient: true,
        ),
      ),
    );
  }

  void _changePhone() {
    setState(() {
      _currentStep = 1;
      _isCodeSent = false;
      _verificationCode = null;
      _codeController.clear();
      _timer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Регистрация клиента'),
        backgroundColor: IOSTheme.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress Steps
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                _buildStepIndicator(1, 'Данные', _currentStep >= 1),
                Expanded(child: Container(height: 2, color: _currentStep >= 2 ? IOSTheme.iosBlue : IOSTheme.fill)),
                _buildStepIndicator(2, 'Код', _currentStep >= 2),
                Expanded(child: Container(height: 2, color: _currentStep >= 3 ? IOSTheme.iosBlue : IOSTheme.fill)),
                _buildStepIndicator(3, 'Готово', _currentStep >= 3),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _currentStep == 1 
                ? _buildFormStep()
                : _currentStep == 2
                    ? _buildVerificationStep()
                    : _buildSuccessStep(),
          ),
        ],
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
          decoration: BoxDecoration(
            color: isActive ? IOSTheme.iosBlue : IOSTheme.fill,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _currentStep > step
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : IOSTheme.labelTertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? IOSTheme.iosBlue : IOSTheme.labelTertiary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildFormStep() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Client Type Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: IOSTheme.fill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _clientType = 'business'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _clientType == 'business' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _clientType == 'business' ? IOSTheme.shadowSm : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business,
                            size: 18,
                            color: _clientType == 'business' ? IOSTheme.iosBlue : IOSTheme.labelSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Юр. лицо',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _clientType == 'business' ? IOSTheme.iosBlue : IOSTheme.labelSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _clientType = 'individual'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _clientType == 'individual' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _clientType == 'individual' ? IOSTheme.shadowSm : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 18,
                            color: _clientType == 'individual' ? IOSTheme.iosBlue : IOSTheme.labelSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Физ. лицо',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _clientType == 'individual' ? IOSTheme.iosBlue : IOSTheme.labelSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form Fields
          if (_clientType == 'business') ...[
            _buildTextField(
              controller: _companyController,
              label: 'Название компании *',
              hint: 'ООО "Пример"',
              icon: Icons.business,
              validator: (v) => v?.isEmpty ?? true ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 16),
          ],

          if (_clientType == 'individual')
            _buildTextField(
              controller: _nameController,
              label: 'ФИО *',
              hint: 'Иванов Иван Иванович',
              icon: Icons.person,
              validator: (v) => v?.isEmpty ?? true ? 'Обязательное поле' : null,
            ),

          if (_clientType == 'individual') const SizedBox(height: 16),

          _buildTextField(
            controller: _phoneController,
            label: 'Телефон *',
            hint: '+998 90 123 45 67',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Обязательное поле';
              if (v!.length < 9) return 'Минимум 9 цифр';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _addressController,
            label: 'Адрес доставки *',
            hint: 'ул. Ленина, 45, офис 301',
            icon: Icons.location_on,
            maxLines: 2,
            validator: (v) => v?.isEmpty ?? true ? 'Обязательное поле' : null,
          ),
          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0088CC).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088CC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.telegram, color: Color(0xFF0088CC), size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Подтверждение через Telegram',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'На указанный номер будет отправлен код подтверждения',
                        style: TextStyle(color: IOSTheme.labelSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Send Code Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
                foregroundColor: Colors.white,
                disabledBackgroundColor: IOSTheme.fill,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 12),
                        Text('Отправить код в Telegram', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Phone Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF0088CC).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_iphone, color: Color(0xFF0088CC), size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Подтвердите телефон',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Введите 4-значный код, отправленный в Telegram на номер',
            textAlign: TextAlign.center,
            style: TextStyle(color: IOSTheme.labelSecondary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: IOSTheme.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _phoneController.text,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _changePhone,
                  child: const Icon(Icons.edit, color: IOSTheme.iosBlue, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Code Input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: '0000',
                    hintStyle: TextStyle(
                      fontSize: 36,
                      color: IOSTheme.labelTertiary,
                      letterSpacing: 16,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onChanged: (value) {
                    if (value.length == 4) {
                      _verifyCode();
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Resend Timer
          if (_resendTimer > 0)
            Text(
              'Отправить код повторно через ${_resendTimer}с',
              style: TextStyle(color: IOSTheme.labelTertiary),
            )
          else
            TextButton.icon(
              onPressed: () {
                _sendVerificationCode();
                _codeController.clear();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Отправить код повторно'),
            ),
          
          const Spacer(),
          
          // Verify Button (fallback if auto-submit doesn't work)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _codeController.text.length == 4 ? _verifyCode : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: IOSTheme.iosBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: IOSTheme.fill,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Подтвердить', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: IOSTheme.iosGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: IOSTheme.iosGreen, size: 64),
          ),
          const SizedBox(height: 24),
          const Text(
            'Телефон подтверждён!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Перенаправляем к оформлению заказа...',
            style: TextStyle(color: IOSTheme.labelSecondary, fontSize: 16),
          ),
          const SizedBox(height: 40),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: IOSTheme.shadowSm,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: IOSTheme.labelTertiary),
              prefixIcon: Icon(icon, color: IOSTheme.labelSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

// Data Classes
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
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.discount,
  });
}

class Client {
  final String id;
  final String name;
  final String phone;
  final String address;
  final bool isVerified;
  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.isVerified = false,
  });
}

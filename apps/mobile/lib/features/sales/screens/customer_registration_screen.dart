import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/ios_theme.dart';
import '../bloc/customer_registration_bloc.dart';

/// Customer registration screen with OTP verification
class CustomerRegistrationScreen extends StatelessWidget {
  final String salesRepId;

  const CustomerRegistrationScreen({
    super.key,
    required this.salesRepId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomerRegistrationBloc(),
      child: _CustomerRegistrationContent(salesRepId: salesRepId),
    );
  }
}

class _CustomerRegistrationContent extends StatelessWidget {
  final String salesRepId;

  const _CustomerRegistrationContent({required this.salesRepId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: IOSTheme.labelPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Новый клиент', style: IOSTheme.title2),
      ),
      body: BlocConsumer<CustomerRegistrationBloc, CustomerRegistrationState>(
        listener: (context, state) {
          if (state.isSuccess) {
            _showSuccessDialog(context, state.registeredCustomer!);
          }
          if (state.error != null) {
            _showError(context, state.error!);
          }
        },
        builder: (context, state) {
          return Stepper(
            currentStep: state.currentStep,
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: [
              Step(
                title: Text('Личные данные', style: IOSTheme.headline),
                content: _PersonalInfoStep(salesRepId: salesRepId),
                isActive: state.currentStep == 0,
                state: state.currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: Text('Подтверждение', style: IOSTheme.headline),
                content: const _VerificationStep(),
                isActive: state.currentStep == 1,
                state: state.currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: Text('Завершение', style: IOSTheme.headline),
                content: const _CompletionStep(),
                isActive: state.currentStep == 2,
                state: state.currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, dynamic customer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: IOSTheme.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IOSTheme.systemGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: IOSTheme.systemGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Клиент зарегистрирован!',
              style: IOSTheme.title2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Реферальный код: ${customer.referralCode}',
              style: IOSTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          IOSButton(
            text: 'Готово',
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: IOSTheme.systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
        ),
      ),
    );
  }
}

class _PersonalInfoStep extends StatelessWidget {
  final String salesRepId;

  const _PersonalInfoStep({required this.salesRepId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerRegistrationBloc, CustomerRegistrationState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First name
            _buildTextField(
              label: 'Имя *',
              hint: 'Введите имя клиента',
              value: state.firstName,
              error: state.firstNameError,
              onChanged: (value) => context.read<CustomerRegistrationBloc>().add(
                UpdatePersonalInfo(firstName: value),
              ),
            ),
            const SizedBox(height: 16),

            // Last name
            _buildTextField(
              label: 'Фамилия',
              hint: 'Введите фамилию',
              value: state.lastName,
              onChanged: (value) => context.read<CustomerRegistrationBloc>().add(
                UpdatePersonalInfo(lastName: value),
              ),
            ),
            const SizedBox(height: 16),

            // Phone
            _buildTextField(
              label: 'Телефон *',
              hint: '+998 XX XXX XX XX',
              value: state.phone,
              error: state.phoneError,
              keyboardType: TextInputType.phone,
              prefixText: '+998 ',
              onChanged: (value) {
                // Format phone number
                final clean = value.replaceAll(RegExp(r'\D'), '');
                if (clean.length <= 9) {
                  context.read<CustomerRegistrationBloc>().add(
                    UpdatePersonalInfo(phone: '+998$clean'),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // Address
            _buildTextField(
              label: 'Адрес доставки',
              hint: 'Улица, дом, квартира',
              value: state.address,
              maxLines: 2,
              onChanged: (value) => context.read<CustomerRegistrationBloc>().add(
                UpdatePersonalInfo(address: value),
              ),
            ),
            const SizedBox(height: 24),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: IOSButton(
                text: 'Продолжить',
                onPressed: state.isPersonalInfoValid && !state.isPhoneTaken
                    ? () => context.read<CustomerRegistrationBloc>().add(
                          SendOtp(state.phone, ''), // TODO: Get Telegram ID
                        )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String value,
    String? error,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: IOSTheme.headline),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            errorText: error,
            prefixText: prefixText,
            filled: true,
            fillColor: IOSTheme.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
              borderSide: const BorderSide(color: IOSTheme.systemBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
              borderSide: const BorderSide(color: IOSTheme.systemRed),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerRegistrationBloc, CustomerRegistrationState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Введите код из Telegram',
              style: IOSTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.phone,
              style: IOSTheme.headline.copyWith(color: IOSTheme.systemBlue),
            ),
            const SizedBox(height: 24),

            // OTP input
            _OtpInput(
              onCompleted: (code) {
                context.read<CustomerRegistrationBloc>().add(
                  VerifyOtp(state.phone, code),
                );
              },
            ),
            const SizedBox(height: 16),

            // Timer / Resend
            if (state.otpExpirySeconds > 0)
              Text(
                'Код действителен еще ${state.otpExpirySeconds} сек',
                style: IOSTheme.caption,
              )
            else
              TextButton(
                onPressed: state.canResendOtp
                    ? () => context.read<CustomerRegistrationBloc>().add(
                          ResendOtp(state.phone, ''),
                        )
                    : null,
                child: const Text('Отправить код повторно'),
              ),

            const SizedBox(height: 24),

            if (state.isVerifyingOtp)
              const CircularProgressIndicator()
            else if (state.otpAttempts > 0)
              Text(
                'Неверный код. Попыток: ${state.otpAttempts}/3',
                style: IOSTheme.caption.copyWith(color: IOSTheme.systemRed),
              ),
          ],
        );
      },
    );
  }
}

class _OtpInput extends StatefulWidget {
  final Function(String) onCompleted;

  const _OtpInput({required this.onCompleted});

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  final List<String> _digits = ['', '', '', ''];
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 56,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: IOSTheme.title1,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: IOSTheme.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
                borderSide: const BorderSide(color: IOSTheme.systemBlue, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                _digits[index] = value;
                if (index < 3) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  // Completed
                  widget.onCompleted(_digits.join());
                }
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}

class _CompletionStep extends StatelessWidget {
  const _CompletionStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerRegistrationBloc, CustomerRegistrationState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Проверьте данные клиента:',
              style: IOSTheme.headline,
            ),
            const SizedBox(height: 16),

            _buildInfoRow('Имя:', state.fullName),
            _buildInfoRow('Телефон:', state.phone),
            if (state.address.isNotEmpty)
              _buildInfoRow('Адрес:', state.address),
            _buildInfoRow('Статус:', '✓ Номер подтвержден'),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: IOSButton(
                text: 'Зарегистрировать клиента',
                isLoading: state.isRegistering,
                onPressed: () => context.read<CustomerRegistrationBloc>().add(
                  RegisterCustomer('sales_rep_id'), // TODO: Pass actual ID
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: IOSTheme.bodyMedium.copyWith(
                color: IOSTheme.labelSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: IOSTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/entities/customer_entity.dart';
import '../../../data/repositories/customer_repository.dart';

// Events
abstract class CustomerRegistrationEvent extends Equatable {
  const CustomerRegistrationEvent();
  @override
  List<Object?> get props => [];
}

class UpdatePersonalInfo extends CustomerRegistrationEvent {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  
  const UpdatePersonalInfo({
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
  });
  
  @override
  List<Object?> get props => [firstName, lastName, phone, address];
}

class SendOtp extends CustomerRegistrationEvent {
  final String phone;
  final String telegramId;
  const SendOtp(this.phone, this.telegramId);
  @override
  List<Object?> get props => [phone, telegramId];
}

class VerifyOtp extends CustomerRegistrationEvent {
  final String phone;
  final String code;
  const VerifyOtp(this.phone, this.code);
  @override
  List<Object?> get props => [phone, code];
}

class ResendOtp extends CustomerRegistrationEvent {
  final String phone;
  final String telegramId;
  const ResendOtp(this.phone, this.telegramId);
  @override
  List<Object?> get props => [phone, telegramId];
}

class RegisterCustomer extends CustomerRegistrationEvent {
  final String salesRepId;
  const RegisterCustomer(this.salesRepId);
  @override
  List<Object?> get props => [salesRepId];
}

class ResetForm extends CustomerRegistrationEvent {
  const ResetForm();
}

class CheckPhoneExists extends CustomerRegistrationEvent {
  final String phone;
  const CheckPhoneExists(this.phone);
  @override
  List<Object?> get props => [phone];
}

// State
class CustomerRegistrationState extends Equatable {
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String? telegramId;
  final String? telegramUsername;
  
  final bool isPhoneValid;
  final bool isPhoneVerified;
  final bool isPhoneTaken;
  final String? otpCode;
  final int otpExpirySeconds;
  final int otpAttempts;
  final bool canResendOtp;
  final bool isSendingOtp;
  final bool isVerifyingOtp;
  
  final bool isRegistering;
  final bool isSuccess;
  final CustomerEntity? registeredCustomer;
  final String? error;
  final int currentStep;

  const CustomerRegistrationState({
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.address = '',
    this.telegramId,
    this.telegramUsername,
    this.isPhoneValid = false,
    this.isPhoneVerified = false,
    this.isPhoneTaken = false,
    this.otpCode,
    this.otpExpirySeconds = 300,
    this.otpAttempts = 0,
    this.canResendOtp = false,
    this.isSendingOtp = false,
    this.isVerifyingOtp = false,
    this.isRegistering = false,
    this.isSuccess = false,
    this.registeredCustomer,
    this.error,
    this.currentStep = 0,
  });

  CustomerRegistrationState copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? telegramId,
    String? telegramUsername,
    bool? isPhoneValid,
    bool? isPhoneVerified,
    bool? isPhoneTaken,
    String? otpCode,
    int? otpExpirySeconds,
    int? otpAttempts,
    bool? canResendOtp,
    bool? isSendingOtp,
    bool? isVerifyingOtp,
    bool? isRegistering,
    bool? isSuccess,
    CustomerEntity? registeredCustomer,
    String? error,
    int? currentStep,
  }) {
    return CustomerRegistrationState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      telegramId: telegramId ?? this.telegramId,
      telegramUsername: telegramUsername ?? this.telegramUsername,
      isPhoneValid: isPhoneValid ?? this.isPhoneValid,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isPhoneTaken: isPhoneTaken ?? this.isPhoneTaken,
      otpCode: otpCode ?? this.otpCode,
      otpExpirySeconds: otpExpirySeconds ?? this.otpExpirySeconds,
      otpAttempts: otpAttempts ?? this.otpAttempts,
      canResendOtp: canResendOtp ?? this.canResendOtp,
      isSendingOtp: isSendingOtp ?? this.isSendingOtp,
      isVerifyingOtp: isVerifyingOtp ?? this.isVerifyingOtp,
      isRegistering: isRegistering ?? this.isRegistering,
      isSuccess: isSuccess ?? this.isSuccess,
      registeredCustomer: registeredCustomer ?? this.registeredCustomer,
      error: error,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        phone,
        address,
        telegramId,
        telegramUsername,
        isPhoneValid,
        isPhoneVerified,
        isPhoneTaken,
        otpCode,
        otpExpirySeconds,
        otpAttempts,
        canResendOtp,
        isSendingOtp,
        isVerifyingOtp,
        isRegistering,
        isSuccess,
        registeredCustomer,
        error,
        currentStep,
      ];

  // Validation helpers
  bool get isPersonalInfoValid =>
      firstName.isNotEmpty && phone.isNotEmpty && isPhoneValid;

  bool get canRegister =>
      isPersonalInfoValid && isPhoneVerified && !isPhoneTaken;

  String? get firstNameError =>
      firstName.isEmpty ? 'Введите имя' : null;

  String? get phoneError {
    if (phone.isEmpty) return 'Введите номер телефона';
    if (!isPhoneValid) return 'Неверный формат номера';
    if (isPhoneTaken) return 'Этот номер уже зарегистрирован';
    return null;
  }
}

// BLoC
class CustomerRegistrationBloc
    extends Bloc<CustomerRegistrationEvent, CustomerRegistrationState> {
  final CustomerRepository _customerRepository = CustomerRepository();
  Timer? _otpTimer;

  CustomerRegistrationBloc() : super(const CustomerRegistrationState()) {
    on<UpdatePersonalInfo>(_onUpdatePersonalInfo);
    on<SendOtp>(_onSendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<ResendOtp>(_onResendOtp);
    on<RegisterCustomer>(_onRegisterCustomer);
    on<ResetForm>(_onResetForm);
    on<CheckPhoneExists>(_onCheckPhoneExists);
  }

  void _onUpdatePersonalInfo(
    UpdatePersonalInfo event,
    Emitter<CustomerRegistrationState> emit,
  ) {
    String? phone = event.phone;
    bool isPhoneValid = state.isPhoneValid;

    if (phone != null) {
      // Basic phone validation for Uzbekistan
      // Format: +998 XX XXX XX XX
      phone = phone.replaceAll(RegExp(r'\s+'), '');
      isPhoneValid = RegExp(r'^\+998\d{9}$').hasMatch(phone);
    }

    emit(state.copyWith(
      firstName: event.firstName,
      lastName: event.lastName,
      phone: phone,
      address: event.address,
      isPhoneValid: isPhoneValid,
      // Reset verification if phone changed
      isPhoneVerified: phone != state.phone ? false : state.isPhoneVerified,
    ));

    // Check if phone exists
    if (phone != null && phone != state.phone && isPhoneValid) {
      add(CheckPhoneExists(phone));
    }
  }

  Future<void> _onCheckPhoneExists(
    CheckPhoneExists event,
    Emitter<CustomerRegistrationState> emit,
  ) async {
    try {
      final existing = await _customerRepository.getCustomerByPhone(event.phone);
      emit(state.copyWith(isPhoneTaken: existing != null));
    } catch (e) {
      // Ignore errors, will check again on submit
    }
  }

  Future<void> _onSendOtp(
    SendOtp event,
    Emitter<CustomerRegistrationState> emit,
  ) async {
    emit(state.copyWith(isSendingOtp: true, error: null));

    try {
      final verification = await _customerRepository.sendTelegramOtp(
        event.phone,
        event.telegramId,
      );

      _startOtpTimer(emit);

      emit(state.copyWith(
        isSendingOtp: false,
        otpCode: verification.code, // For demo, in production don't expose this
        otpExpirySeconds: verification.secondsRemaining,
        otpAttempts: 0,
        canResendOtp: false,
        currentStep: 1, // Move to OTP verification step
      ));
    } catch (e) {
      emit(state.copyWith(
        isSendingOtp: false,
        error: 'Не удалось отправить код: $e',
      ));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtp event,
    Emitter<CustomerRegistrationState> emit,
  ) async {
    emit(state.copyWith(isVerifyingOtp: true, error: null));

    try {
      final success = await _customerRepository.verifyOtp(
        event.phone,
        event.code,
      );

      if (success) {
        _otpTimer?.cancel();
        emit(state.copyWith(
          isVerifyingOtp: false,
          isPhoneVerified: true,
          otpAttempts: 0,
          currentStep: 2, // Move to final step
        ));
      } else {
        emit(state.copyWith(
          isVerifyingOtp: false,
          otpAttempts: state.otpAttempts + 1,
          error: 'Неверный код, попробуйте еще раз',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isVerifyingOtp: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onResendOtp(
    ResendOtp event,
    Emitter<CustomerRegistrationState> emit,
  ) async {
    // Same as send but with reset
    add(SendOtp(event.phone, event.telegramId));
  }

  Future<void> _onRegisterCustomer(
    RegisterCustomer event,
    Emitter<CustomerRegistrationState> emit,
  ) async {
    if (!state.canRegister) {
      emit(state.copyWith(error: 'Заполните все обязательные поля'));
      return;
    }

    emit(state.copyWith(isRegistering: true, error: null));

    try {
      final customer = await _customerRepository.registerCustomer(
        firstName: state.firstName,
        lastName: state.lastName.isNotEmpty ? state.lastName : null,
        phone: state.phone,
        address: state.address.isNotEmpty ? state.address : null,
        telegramId: state.telegramId,
        telegramUsername: state.telegramUsername,
        salesRepId: event.salesRepId,
      );

      emit(state.copyWith(
        isRegistering: false,
        isSuccess: true,
        registeredCustomer: customer,
        currentStep: 3, // Success step
      ));
    } catch (e) {
      emit(state.copyWith(
        isRegistering: false,
        error: 'Ошибка регистрации: $e',
      ));
    }
  }

  void _onResetForm(ResetForm event, Emitter<CustomerRegistrationState> emit) {
    _otpTimer?.cancel();
    emit(const CustomerRegistrationState());
  }

  void _startOtpTimer(Emitter<CustomerRegistrationState> emit) {
    _otpTimer?.cancel();
    
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.otpExpirySeconds <= 0) {
        timer.cancel();
        emit(state.copyWith(canResendOtp: true));
      } else {
        emit(state.copyWith(otpExpirySeconds: state.otpExpirySeconds - 1));
      }
    });
  }

  @override
  Future<void> close() {
    _otpTimer?.cancel();
    return super.close();
  }
}

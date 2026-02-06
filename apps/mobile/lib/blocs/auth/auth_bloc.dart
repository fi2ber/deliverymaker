import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/auth_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String tenantId;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    required this.tenantId,
  });

  @override
  List<Object?> get props => [email, password, tenantId];
}

class AuthLogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;
  final String role;

  const AuthAuthenticated({
    required this.userId,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [userId, email, role];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(
          userId: user.userId,
          email: user.email,
          role: user.role,
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.login(
        email: event.email,
        password: event.password,
        tenantId: event.tenantId,
      );
      emit(AuthAuthenticated(
        userId: user.userId,
        email: user.email,
        role: user.role,
      ));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authService.logout();
    emit(AuthUnauthenticated());
  }
}

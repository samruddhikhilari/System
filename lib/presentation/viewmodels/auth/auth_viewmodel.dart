import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/usecases/auth/login_usecase.dart';

class AuthState {
  const AuthState({
    this.email = '',
    this.password = '',
    this.organizationId = '',
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.rememberMe = false,
    this.error,
    this.authResponse,
    this.organizations = const <OrganizationModel>[],
  });

  final String email;
  final String password;
  final String organizationId;
  final bool isPasswordVisible;
  final bool isLoading;
  final bool rememberMe;
  final String? error;
  final AuthResponse? authResponse;
  final List<OrganizationModel> organizations;

  AuthState copyWith({
    String? email,
    String? password,
    String? organizationId,
    bool? isPasswordVisible,
    bool? isLoading,
    bool? rememberMe,
    String? error,
    bool clearError = false,
    AuthResponse? authResponse,
    bool clearAuthResponse = false,
    List<OrganizationModel>? organizations,
  }) {
    return AuthState(
      email: email ?? this.email,
      password: password ?? this.password,
      organizationId: organizationId ?? this.organizationId,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      rememberMe: rememberMe ?? this.rememberMe,
      error: clearError ? null : (error ?? this.error),
      authResponse: clearAuthResponse ? null : (authResponse ?? this.authResponse),
      organizations: organizations ?? this.organizations,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel(this._loginUseCase, this._authRepository) : super(const AuthState());

  final LoginUseCase _loginUseCase;
  final AuthRepository _authRepository;

  void setEmail(String email) {
    state = state.copyWith(email: email, clearError: true);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, clearError: true);
  }

  void setOrganization(String organizationId) {
    state = state.copyWith(organizationId: organizationId, clearError: true);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  Future<void> loadOrganizations() async {
    try {
      final organizations = await _authRepository.getOrganizations();
      final defaultOrg = organizations.isNotEmpty ? organizations.first.id : state.organizationId;
      state = state.copyWith(
        organizations: organizations,
        organizationId: state.organizationId.isEmpty ? defaultOrg : state.organizationId,
      );
    } on AppException catch (_) {
      // Organizations can be optional for first login attempt.
    }
  }

  Future<void> login() async {
    state = state.copyWith(isLoading: true, clearError: true, clearAuthResponse: true);

    try {
      final result = await _loginUseCase(
        LoginParams(
          email: state.email,
          password: state.password,
          organizationId: state.organizationId,
        ),
      );
      state = state.copyWith(authResponse: result, isLoading: false);
    } on ValidationException catch (error) {
      state = state.copyWith(error: error.message, isLoading: false);
    } on AppException catch (error) {
      state = state.copyWith(error: error.message, isLoading: false);
    }
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthViewModel(loginUseCase, authRepository);
});

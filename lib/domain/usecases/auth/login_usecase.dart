import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginParams {
  const LoginParams({
    required this.email,
    required this.password,
    required this.organizationId,
  });

  final String email;
  final String password;
  final String organizationId;
}

class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthResponse> call(LoginParams params) async {
    final email = params.email.trim();

    if (!_isValidEmail(email)) {
      throw ValidationException.emailInvalid();
    }
    if (params.password.length < 8) {
      throw ValidationException.passwordWeak();
    }
    if (params.organizationId.trim().isEmpty) {
      throw const ValidationException(
        message: 'Please select an organization.',
        code: 'ORG_REQUIRED',
      );
    }

    return _repository.login(email, params.password, params.organizationId);
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }
}

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

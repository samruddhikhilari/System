/// Utility class for form validation
class Validators {
  Validators._();

  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid work email address';
    }

    return null;
  }

  /// Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  /// Required field validation
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Numeric validation
  static String? numeric(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a number';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  /// Minimum length validation
  static String? minLength(String? value, int min) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    if (value.length < min) {
      return 'Must be at least $min characters';
    }

    return null;
  }

  /// Maximum length validation
  static String? maxLength(String? value, int max) {
    if (value != null && value.length > max) {
      return 'Must be at most $max characters';
    }
    return null;
  }
}

class ValidationUtils {
  /// Validates if a string is not empty (after trimming)
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty';
    }

    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    return null;
  }

  /// Validates squad name
  static String? validateSquadName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Squad name cannot be empty';
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Squad name must be at least 2 characters long';
    }

    if (trimmed.length > 50) {
      return 'Squad name must be less than 50 characters';
    }

    return null;
  }

  /// Validates squad ID
  static String? validateSquadId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Squad ID cannot be empty';
    }

    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Squad ID must be at least 3 characters long';
    }

    return null;
  }

  /// Trims whitespace from a string
  static String trimString(String? value) {
    return value?.trim() ?? '';
  }
}

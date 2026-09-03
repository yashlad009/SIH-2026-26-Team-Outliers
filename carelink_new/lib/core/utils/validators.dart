/// Form validators for CareLink.
/// All validators return null on success, or an error string on failure.
class Validators {
  Validators._();

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\-.]+@[\w\-]+\.[a-z]{2,}$', caseSensitive: false);
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 0 || n > 120) return 'Enter a valid age (0–120)';
    return null;
  }

  static String? temperature(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid temperature';
    if (n < 30 || n > 45) return 'Temperature must be between 30–45 °C';
    return null;
  }

  static String? bpSystolic(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 50 || n > 250) return 'Systolic BP must be 50–250 mmHg';
    return null;
  }

  static String? bpDiastolic(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 30 || n > 150) return 'Diastolic BP must be 30–150 mmHg';
    return null;
  }

  static String? spO2(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 50 || n > 100) return 'SpO₂ must be 50–100%';
    return null;
  }

  static String? heartRate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 20 || n > 300) return 'Heart rate must be 20–300 bpm';
    return null;
  }

  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid weight';
    if (n < 0.5 || n > 500) return 'Weight must be 0.5–500 kg';
    return null;
  }

  static String? height(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid height';
    if (n < 30 || n > 250) return 'Height must be 30–250 cm';
    return null;
  }

  static String? minLength(String? value, int min, [String field = 'This field']) {
    if (value == null || value.trim().length < min) {
      return '$field must be at least $min characters';
    }
    return null;
  }
}

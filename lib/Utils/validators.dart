import 'package:flutter/material.dart';

class Validators {
  static String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static FormFieldValidator<String> requiredField(String label) {
    return (value) => _required(value, label);
  }

  static FormFieldValidator<String> requiredMinLength(String label, int minLength) {
    return (value) {
      final req = _required(value, label);
      if (req != null) return req;
      if (value!.trim().length < minLength) {
        return '$label must be at least $minLength characters';
      }
      return null;
    };
  }

  static FormFieldValidator<String> requiredExactLengthDigits(String label, int length) {
    return (value) {
      final req = _required(value, label);
      if (req != null) return req;
      final v = value!.trim();
      if (v.length != length) {
        return '$label must be exactly $length digits';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
        return '$label must contain only numbers';
      }
      return null;
    };
  }

  static String? email(String? value, {String label = 'Email'}) {
    final req = _required(value, label);
    if (req != null) return req;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static FormFieldValidator<String> fullName() => requiredMinLength('Full name', 2);

  static FormFieldValidator<String> memberNumber() => requiredMinLength('Member number', 3);

  static FormFieldValidator<String> idNumber() => requiredMinLength('Identification number', 5);

  static FormFieldValidator<String> requiredDropdown(String label) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Please select $label';
      }
      return null;
    };
  }

  static FormFieldValidator<String> mobileNumberBasic({
    String label = 'Mobile number',
    int minDigits = 10,
    int maxDigits = 15,
  }) {
    return (value) {
      final req = _required(value, label);
      if (req != null) return req;
      final digitsOnly = value!.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length < minDigits || digitsOnly.length > maxDigits) {
        return 'Enter a valid mobile number ($minDigits-$maxDigits digits)';
      }
      return null;
    };
  }

  static FormFieldValidator<String> phoneLocal({String label = 'Phone number'}) {
    return (value) {
      final req = _required(value, label);
      if (req != null) return req;
      final cleaned = value!.replaceAll(RegExp(r'[^0-9]'), '');
      final isValid = cleaned.length == 10 && cleaned.startsWith('07');
      if (!isValid) {
        return 'Please enter a valid phone number (format: 07XXXXXXXX)';
      }
      return null;
    };
  }

  static FormFieldValidator<String> amount({
    required String currencyCode,
    double min = 0.0,
    double? max,
    double? availableBalance,
  }) {
    return (value) {
      final req = _required(value, 'Amount');
      if (req != null) return req;
      final amount = double.tryParse(value!.trim());
      if (amount == null || amount <= 0) {
        return 'Please enter a valid amount';
      }
      if (amount < min) {
        return 'Minimum amount is $currencyCode ${min.toStringAsFixed(0)}';
      }
      if (max != null && amount > max) {
        final maxStr = max % 1 == 0 ? max.toStringAsFixed(0) : max.toString();
        return 'Maximum amount is $currencyCode $maxStr';
      }
      if (availableBalance != null && amount > availableBalance) {
        return 'Insufficient balance';
      }
      return null;
    };
  }

  static FormFieldValidator<String> pin({
    String label = 'PIN',
    int minLength = 4,
    int maxLength = 6,
    String Function()? disallowEqualTo,
    String? disallowEqualMessage,
  }) {
    return (value) {
      final req = _required(value, label);
      if (req != null) return req;
      final v = value!.trim();
      if (v.length < minLength || v.length > maxLength) {
        if (minLength == maxLength) {
          return '$label must be exactly $minLength digits';
        }
        return '$label must be between $minLength-$maxLength digits';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
        return '$label must contain only numbers';
      }
      if (disallowEqualTo != null) {
        final other = disallowEqualTo();
        if (other.isNotEmpty && other == v) {
          return disallowEqualMessage ?? '$label must be different from previous';
        }
      }
      return null;
    };
  }

  static FormFieldValidator<String> confirmMatch({
    required String label,
    required String Function() otherValue,
    String mismatchMessage = 'Values do not match',
  }) {
    return (value) {
      final req = _required(value, label);
      if (req != null) return req;
      if (value!.trim() != otherValue().trim()) {
        return mismatchMessage;
      }
      return null;
    };
  }
}



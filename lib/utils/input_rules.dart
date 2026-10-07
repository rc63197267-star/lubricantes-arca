import 'package:flutter/services.dart';

class InputRules {
  InputRules._();

  static final List<TextInputFormatter> digits = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
  ];

  static final List<TextInputFormatter> personName = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ' .-]")),
  ];

  static final List<TextInputFormatter> money = <TextInputFormatter>[
    _MoneyInputFormatter(),
  ];

  static final List<TextInputFormatter> alphanumeric = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.-]')),
  ];

  static final List<TextInputFormatter> productText = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(
      RegExp(r"[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ' ./()+_-]"),
    ),
  ];
}

class _MoneyInputFormatter extends TextInputFormatter {
  final RegExp _pattern = RegExp(r'^\d{0,9}([\.,]\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty || _pattern.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

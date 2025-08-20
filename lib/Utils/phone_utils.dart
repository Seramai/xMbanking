class PhoneUtils {
  static bool isValidPhoneFormat(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length == 10 && cleaned.startsWith('07');
  }
  static String formatToLocal(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('254') && cleaned.length >= 12 && cleaned.substring(3, 4) == '7') {
      return '0${cleaned.substring(3)}'.substring(0, 10);
    }
    if (cleaned.startsWith('7') && cleaned.length == 9) {
      return '0$cleaned';
    }
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return cleaned;
    }
    return cleaned;
  }
}



import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CurrencyService {
  static const String _currencyKey = 'selected_currency';
  static const Map<String, Map<String, String>> availableCurrencies = {
    'KES': {'name': 'Kenyan Shilling', 'symbol': 'KES'},
    'UGX': {'name': 'Ugandan Shilling', 'symbol': 'UGX'},
    'TSH': {'name': 'Tanzanian Shilling', 'symbol': 'TSH'},
  };
  // Setting selected currency
  static Future<void> setCurrency(String currencyCode) async {
    if (!availableCurrencies.containsKey(currencyCode)) {
      throw ArgumentError('Currency $currencyCode is not supported');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencyCode);
  }
  static Future<String?> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey);
  }
  static Future<String> getCurrencySymbol() async {
    final currency = await getCurrency();
    if (currency == null) return '';
    return availableCurrencies[currency]?['symbol'] ?? '';
  }
  static Future<String> getCurrencyName() async {
    final currency = await getCurrency();
    if (currency == null) return '';
    return availableCurrencies[currency]?['name'] ?? '';
  }
  static Future<String> formatAmount(double amount) async {
    final symbol = await getCurrencySymbol();
    return '$symbol ${NumberFormat("#,##0.00").format(amount)}';
  }
  static Future<bool> isCurrencySelected() async {
    final currency = await getCurrency();
    return currency != null && currency.isNotEmpty;
  }
  static Future<void> clearCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currencyKey);
  }
  static List<String> getAllCurrencies() {
    return availableCurrencies.keys.toList();
  }
  static String getCurrencyDisplayText(String currencyCode) {
    final currencyInfo = availableCurrencies[currencyCode];
    if (currencyInfo == null) return currencyCode;
    return '${currencyInfo['symbol']} - ${currencyInfo['name']}';
  }
}
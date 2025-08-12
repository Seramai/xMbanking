import 'package:flutter/material.dart';
import '../services/currency_service.dart';

class CurrencySelectionDialog extends StatefulWidget {
  final Function(String selectedCurrency) onCurrencySelected;
  final String? currentCurrency;

  const CurrencySelectionDialog({
    super.key,
    required this.onCurrencySelected,
    this.currentCurrency,
  });

  @override
  _CurrencySelectionDialogState createState() => _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<CurrencySelectionDialog> {
  String? selectedCurrency;

  @override
  void initState() {
    super.initState();
    selectedCurrency = widget.currentCurrency;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Select Currency',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose your preferred currency:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ...CurrencyService.getAllCurrencies().map((currency) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        selectedCurrency = currency;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedCurrency == currency
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          width: selectedCurrency == currency ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: selectedCurrency == currency
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedCurrency == currency
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                currency,
                                style: TextStyle(
                                  color: selectedCurrency == currency
                                      ? Colors.white
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CurrencyService.availableCurrencies[currency]!['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  currency,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selectedCurrency == currency)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: selectedCurrency == null
                      ? null
                      : () {
                          widget.onCurrencySelected(selectedCurrency!);
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
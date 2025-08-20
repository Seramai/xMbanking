import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatelessWidget {
  final List<dynamic> transactions;
  final String currencyCode;

  const TransactionsScreen({
    super.key,
    required this.transactions,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final txn = transactions[index] as Map<String, dynamic>;
            final description = txn['Description']?.toString() ?? 'Transaction';
            final amount = (txn['Amount'] is num)
                ? (txn['Amount'] as num).toDouble()
                : double.tryParse(txn['Amount']?.toString() ?? '0') ?? 0.0;
            DateTime date = DateTime.now();
            try {
              if (txn['TrxDate'] != null) {
                final dateString = txn['TrxDate'].toString();
                final parts = dateString.split(' ');
                if (parts.length == 2) {
                  final dateParts = parts[0].split('/');
                  final timePart = parts[1];
                  if (dateParts.length == 3) {
                    final iso = '${dateParts[2]}-${dateParts[0].padLeft(2, '0')}-${dateParts[1].padLeft(2, '0')}T$timePart';
                    date = DateTime.parse(iso);
                  }
                }
              }
            } catch (_) {}
            final isCredit = description.toLowerCase().contains('deposit') || amount >= 0;
            final color = isCredit ? Colors.green : Colors.red;
            final icon = isCredit ? Icons.trending_up : Icons.trending_down;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                trailing: Text(
                  '${isCredit ? '+' : '-'}$currencyCode ${NumberFormat('#,##0.00').format(amount.abs())}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}



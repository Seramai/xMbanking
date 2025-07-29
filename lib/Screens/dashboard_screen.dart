import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';
import 'dart:io';
import 'dart:typed_data';

class DashboardScreen extends StatefulWidget {
  final String username;
  final String email;
  final File? profileImageFile;
  final Uint8List? profileImageBytes;
  
  const DashboardScreen({
    super.key,
    this.username = "Winnie",
    this.email = "winnie@example.com",
    this.profileImageFile,
    this.profileImageBytes,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceVisible = true;
  final double _accountBalance = 12500.00;
  final int _numberOfAccounts = 2;
  final int _notificationCount = 3;

  final List<Transaction> _miniStatement = [
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 1)),
      description: "MPESA Deposit",
      amount: 2500.00,
      type: TransactionType.credit,
      icon: Icons.phone_android,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 2)),
      description: "ATM Withdrawal",
      amount: -1000.00,
      type: TransactionType.debit,
      icon: Icons.atm,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: "Bank Transfer",
      amount: -500.00,
      type: TransactionType.debit,
      icon: Icons.swap_horiz,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 4)),
      description: "Salary Deposit",
      amount: 15000.00,
      type: TransactionType.credit,
      icon: Icons.account_balance,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 5)),
      description: "Utility Payment",
      amount: -3200.00,
      type: TransactionType.debit,
      icon: Icons.receipt_long,
    ),
  ];

  String get _lastLoginTime {
    final now = DateTime.now();
    final lastLogin = now.subtract(const Duration(hours: 2, minutes: 18));
    return DateFormat('dd MMMM yyyy, HH:mm').format(lastLogin);
  }

  void _toggleBalance() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          username: widget.username,
          email: widget.email,
          profileImageBytes: widget.profileImageBytes,
          profileImageFile: widget.profileImageFile,
        ),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void _handleDeposit() {}
  void _handleWithdraw() {}
  void _viewFullStatement() {}

  Widget _buildProfileImage() {
    if (widget.profileImageBytes != null) {
      return Image.memory(
        widget.profileImageBytes!,
        fit: BoxFit.cover,
      );
    } else if (widget.profileImageFile != null) {
      return Image.file(
        widget.profileImageFile!,
        fit: BoxFit.cover,
      );
    } else {
      return Icon(
        Icons.person,
        color: Colors.white,
        size: 28,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.8),
                    Theme.of(context).primaryColor.withOpacity(0.6),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Top Row with Profile and Notification Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile Icon
                      GestureDetector(
                        onTap: _navigateToProfile,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: _buildProfileImage(),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Welcome, ${widget.username}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Notification Icon
                      GestureDetector(
                        onTap: _navigateToNotifications,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            if (_notificationCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '$_notificationCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Account Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Account Balance',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleBalance,
                              child: Icon(
                                _isBalanceVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isBalanceVisible
                              ? 'KES ${NumberFormat("#,##0.00").format(_accountBalance)}'
                              : 'KES ••••••',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_numberOfAccounts linked accounts',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleDeposit,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Deposit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleWithdraw,
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('Withdraw'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Last Login',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _lastLoginTime,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: _viewFullStatement,
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _miniStatement.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final transaction = _miniStatement[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: transaction.type == TransactionType.credit
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                transaction.icon,
                                color: transaction.type == TransactionType.credit
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              transaction.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy').format(transaction.date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              '${transaction.amount >= 0 ? '+' : ''}KES ${NumberFormat("#,##0.00").format(transaction.amount.abs())}',
                              style: TextStyle(
                                color: transaction.type == TransactionType.credit
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionItem(
                                  icon: Icons.phone_android,
                                  title: 'Mobile Money',
                                  color: Colors.green,
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildQuickActionItem(
                                  icon: Icons.history,
                                  title: 'History',
                                  color: Colors.purple,
                                  onTap: _viewFullStatement,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum TransactionType { credit, debit }

class Transaction {
  final DateTime date;
  final String description;
  final double amount;
  final TransactionType type;
  final IconData icon;

  Transaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.icon,
  });
}
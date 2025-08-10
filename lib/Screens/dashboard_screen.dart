import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'deposit_dialog.dart';
import 'withdraw_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; 


class DashboardScreen extends StatefulWidget {
  final String username;
  final String email;
  final File? profileImageFile;
  final Uint8List? profileImageBytes;
  
  const DashboardScreen({
    super.key,
    this.username = "",
    this.email = "",
    this.profileImageFile,
    this.profileImageBytes,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceVisible = true;
  double _accountBalance = 0.0;
  String? _apiUsername;
  final int _numberOfAccounts = 2;
  final int _notificationCount = 3;
  // they are varibales that will store the api responses
  Map<String, dynamic>? _loginData;
  List<dynamic> _apiTransactions = [];
  List<Transaction> _miniStatement = [];
    @override
  void initState() {
    super.initState();
    _initializeData();
  }
  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null) {
        if (args['loginData'] != null) {
          setState(() {
            _loginData = args['loginData'];
            if (args['useStoredData'] == true || 
            _loginData?['needsRefresh'] == true ||
            _loginData?['data']?['balance'] == null) {
          _refreshDashboardOnInit(args['authToken'] ?? _loginData?['data']?['Token'] ?? '');
        } else {
          _loadApiData();
        }
      });
        }
        else if (args['authToken'] != null) {
          _refreshDashboardOnInit(args['authToken']);
        }
      } else {
        _loadStoredData();
      }
    });
  }
  Future<void> _refreshDashboardOnInit(String authToken) async {
    try {
      final response = await ApiService.refreshDashboard(token: authToken);
      
      if (response['success']) {
        setState(() {
          _loginData = {
            ...response,
            'needsRefresh': false
          };
          _loadApiData();
        });
      } else {
        await _loadStoredData();
      }
    } catch (e) {
      await _loadStoredData();
    }
  }

  void _loadApiData() {
    
    if (_loginData == null) {
      return;
    }
    
    // getting the actual data
    Map<String, dynamic> actualData;
    
    if (_loginData!['data'] != null) {
      actualData = _loginData!['data'] as Map<String, dynamic>;
    } else {
      actualData = _loginData!;
    }
    final balance = actualData['balance'];
    
    if (balance != null && balance['Balance'] != null) {
      final newBalance = balance['Balance'].toDouble();
      setState(() {
        _accountBalance = newBalance;
      });
    } else {
    }
    final statements = actualData['statement'] as List<dynamic>?;
    
    if (statements != null) {
      setState(() {
        _apiTransactions = statements;
        _updateMiniStatement();
      });
    } else {
    }
    if (actualData['Name'] != null) {
      setState(() {
        _apiUsername = actualData['Name'];
      });
    } else {
      print("No name found in data");
    }
  }

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedLoginData = prefs.getString('loginData');
      
      if (storedLoginData != null) {
        setState(() {
          _loginData = jsonDecode(storedLoginData);
          _loadApiData();
        });
      }
    } catch (e) {
      print('Error loading stored data: $e');
    }
  }
      // handles pull to refresh functionality
  Future<void> _refreshDashboard() async {
    try {
      // Extract auth token
      String? authToken;
      if (_loginData != null && _loginData!['data'] != null) {
        final actualData = _loginData!['data'] as Map<String, dynamic>;
        authToken = actualData['Token'];
      }
      
      if (authToken == null || authToken.isEmpty) {
        return;
      }
      // Call the refresh API
      final response = await ApiService.refreshDashboard(token: authToken);
      
      if (response['success']) {
        setState(() {
          if (_loginData!['data'] != null) {
            _loginData!['data'] = response['data'];
          } else {
            _loginData = response['data'];
          }
          _loadApiData();
        });
        
      } else {
        if (response['message'].toString().toLowerCase().contains('unauthorized') || 
          response['message'].toString().toLowerCase().contains('token') ||
          response['message'].toString().toLowerCase().contains('expired')) {
        _handleSessionExpired();
      }
      }
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _handleSessionExpired();
      }
    }
  }
  void _handleSessionExpired() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Your session has expired. Please login again.'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
    ),
  );
  Future.delayed(const Duration(seconds: 1), () {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  });
}

  void _updateMiniStatement() {
    List<Transaction> apiTransactions = _apiTransactions.map((txn) {
      double amount = txn['Amount']?.toDouble() ?? 0.0;
      String description = txn['Description'] ?? 'Transaction';
      
      DateTime date = DateTime.now();
        try {
          if (txn['TrxDate'] != null) {
            String dateString = txn['TrxDate'].toString();
            List<String> parts = dateString.split(' ');
          if (parts.length == 2) {
            List<String> dateParts = parts[0].split('/');
            String timePart = parts[1];
            
            if (dateParts.length == 3) {
              // Converting MM/dd/yyyy to yyyy-MM-dd format
              String isoDate = '${dateParts[2]}-${dateParts[0].padLeft(2, '0')}-${dateParts[1].padLeft(2, '0')}T$timePart';
              date = DateTime.parse(isoDate);
            }
          }
        }
      } catch (e) {
        print('Date parsing error: $e');
      }
      
      TransactionType type = amount >= 0 ? TransactionType.credit : TransactionType.debit;
      IconData icon = Icons.account_balance;
      
      if (description.toLowerCase().contains('deposit')) {
        icon = Icons.add_circle_outline;
      } else if (description.toLowerCase().contains('interest')) {
        icon = Icons.trending_up;
      } else if (description.toLowerCase().contains('repayment')) {
        icon = Icons.payment;
      }
      
      return Transaction(
        date: date,
        description: description,
        amount: amount,
        type: type,
        icon: icon,
      );
    }).toList();
    
    apiTransactions.sort((a, b) => b.date.compareTo(a.date));
    _miniStatement = apiTransactions.take(5).toList();
  }
  String get _lastLoginTime {
    if (_loginData != null) {
      Map<String, dynamic>? actualData;
      if (_loginData!['data'] != null) {
        actualData = _loginData!['data'] as Map<String, dynamic>;
      } else {
        actualData = _loginData!;
      }
      
      if (actualData['LoginInfo'] != null) {
        final loginInfo = actualData['LoginInfo'];
        final lastDate = loginInfo['LastLoginDate'];
        final lastTime = loginInfo['LastLoginTime'];
        
        if (lastDate != null && lastTime != null) {
          try {
            final dateTime = DateTime.parse('$lastDate $lastTime');
            return DateFormat('dd MMMM yyyy, HH:mm').format(dateTime);
          } catch (e) {
            print('Date parsing error: $e');
          }
        }
      }
    }
    
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
    String? authToken;
    Map<String, dynamic>? loginData;
    
    if (_loginData != null) {
      if (_loginData!['data'] != null) {
        final actualData = _loginData!['data'] as Map<String, dynamic>;
        authToken = actualData['Token'] ?? actualData['token'] ?? actualData['accessToken'];
        loginData = _loginData;
      } else {
        authToken = _loginData!['Token'] ?? _loginData!['token'] ?? _loginData!['accessToken'];
        loginData = _loginData;
      }
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          username: _apiUsername ?? widget.username,
          email: widget.email,
          profileImageBytes: widget.profileImageBytes,
          profileImageFile: widget.profileImageFile,
          authToken: authToken,
          loginData: loginData,
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

    void _handleDeposit() {
    String? authToken;
     if (_loginData != null && _loginData!['data'] != null) {
        final actualData = _loginData!['data'] as Map<String, dynamic>;
        authToken = actualData['Token']; 
      }
    if (authToken == null || authToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DepositDialog(
          authToken: authToken!,
          onDepositSuccess: (double amount, String phoneNumber) {
            setState(() {
              _accountBalance += amount;
              _miniStatement.insert(0, Transaction(
                date: DateTime.now(),
                description: "Mobile Deposit",
                amount: amount,
                type: TransactionType.credit,
                icon: Icons.phone_android,
              ));
              if (_miniStatement.length > 5) {
                _miniStatement.removeRange(5, _miniStatement.length);
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Successfully deposited KES ${amount.toStringAsFixed(2)}'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
      },
    );
  }
    void _handleWithdraw() {
    String? authToken;
    if (_loginData != null && _loginData!['data'] != null) {
      final actualData = _loginData!['data'] as Map<String, dynamic>;
      authToken = actualData['Token']; 
    }
    if (authToken == null || authToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WithdrawDialog(
          currentBalance: _accountBalance,
          authToken: authToken!,
          onWithdrawSuccess: (double amount, String phoneNumber) {
            setState(() {
              _accountBalance -= amount;
              
              // Add the new withdrawal transaction to the mini statement
              _miniStatement.insert(0, Transaction(
                date: DateTime.now(),
                description: "Mobile Withdrawal",
                 // Negative amount for withdrawal
                amount: -amount,
                type: TransactionType.debit,
                icon: Icons.phone_android,
              ));
              if (_miniStatement.length > 5) {
                _miniStatement.removeRange(5, _miniStatement.length);
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Successfully withdrew KES ${amount.toStringAsFixed(2)}'),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
      },
    );
  }
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
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0D1B4A),  
                      Color(0xFF1A237E), 
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                          'Welcome, ${_apiUsername ?? widget.username}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _miniStatement.length,
                        itemBuilder: (context, index) {
                          final transaction = _miniStatement[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
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
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('MMM dd, yyyy • HH:mm').format(transaction.date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${transaction.amount >= 0 ? '+' : ''}KES ${NumberFormat("#,##0.00").format(transaction.amount.abs())}',
                                      style: TextStyle(
                                        color: transaction.type == TransactionType.credit
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: transaction.type == TransactionType.credit
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        transaction.type == TransactionType.credit ? 'Credit' : 'Debit',
                                        style: TextStyle(
                                          color: transaction.type == TransactionType.credit
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
                                    color: Color(0xFF1A237E).withOpacity(0.8),
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildQuickActionItem(
                                    icon: Icons.history,
                                    title: 'History',
                                    color: Color(0xFF1A237E).withOpacity(0.8),
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
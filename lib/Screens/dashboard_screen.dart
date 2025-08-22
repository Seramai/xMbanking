import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'user_profile_screen.dart';
import 'notifications_screen.dart';
import '../services/api_service.dart';
import '../Widgets/custom_dialogs.dart';
import 'dart:io';
import 'dart:typed_data';
import 'deposit_dialog.dart';
import 'withdraw_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/token_manager.dart';
import 'dart:convert';
import '../Utils/phone_utils.dart';
import 'menu_drawer_screen.dart';
import '../Utils/status_messages.dart';

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
  String _currentCurrencyCode = '';
  String _currentCurrencySymbol = '';
  String? _userMobileNumber;
  final int _numberOfAccounts = 2;
  final int _notificationCount = 3;
  Map<String, dynamic>? _loginData;
  List<dynamic> _apiTransactions = [];
  List<Transaction> _miniStatement = [];
  Uint8List? _cachedImageBytes;
  File? _cachedImageFile;
  String? _cachedEmail;
  bool _isRefreshing = false;
// this triggers the data initialization process
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadRegistrationDataFromCache();
      
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null) {
        if (args['loginData'] != null) {
          setState(() {
            _loginData = args['loginData'];
            // token extracted here
            String? extractedPhoneFromToken;
            try {
              if (args['loginData']?['data']?['Token'] != null) {
                String token = args['loginData']['data']['Token'];
                List<String> parts = token.split('.');
                if (parts.length == 3) {
                  String payload = parts[1];
                  while (payload.length % 4 != 0) {
                    payload += '=';
                  }
                  String decoded = utf8.decode(base64.decode(payload));
                  Map<String, dynamic> tokenData = json.decode(decoded);
                  extractedPhoneFromToken = tokenData['UserName']; 
                }
              }
            } catch (e) {}
            _userMobileNumber = extractedPhoneFromToken ?? 
                              args['mobileNumber'] ?? 
                              args['phoneNumber'] ?? 
                              widget.username;
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
          _userMobileNumber = args['mobileNumber'];
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
  void _loadCurrencyFromLoginData() {
    if (_loginData != null) {
      Map<String, dynamic> actualData;
      
      if (_loginData!['data'] != null) {
        actualData = _loginData!['data'] as Map<String, dynamic>;
      } else {
        actualData = _loginData!;
      }
      
      final dynamic rawCurrency = actualData['CurrencyCode'];
      final String codeFromData = (rawCurrency is String ? rawCurrency : rawCurrency?.toString() ?? '').trim();
      final String resolvedCode = codeFromData.isNotEmpty ? codeFromData : _currentCurrencyCode;
      final String currencySymbol = resolvedCode;
      
      if (resolvedCode.isNotEmpty) {
        setState(() {
          _currentCurrencyCode = resolvedCode;
          _currentCurrencySymbol = currencySymbol;
        });
      }
    }
  }
  // prevents processing data that is null
  void _loadApiData() {
    if (_loginData == null) {
      return;
    }
    Map<String, dynamic> actualData;
    
    if (_loginData!['data'] != null) {
      actualData = _loginData!['data'] as Map<String, dynamic>;
    } else {
      actualData = _loginData!;
    }
    try {
      final dynamic tokenCandidate = actualData['Token'] ?? actualData['token'] ?? actualData['accessToken'];
      final String latestToken = (tokenCandidate is String ? tokenCandidate : tokenCandidate?.toString() ?? '').trim();
      if (latestToken.isNotEmpty) {
        TokenManager.setToken(latestToken);
      }
    } catch (_) {}
    final balance = actualData['balance'];
    if (balance != null && balance['Balance'] != null) {
      final newBalance = balance['Balance'].toDouble();
      setState(() {
        _accountBalance = newBalance;
      });
    }
    final statements = actualData['statement'] as List<dynamic>?;
    if (statements != null) {
      setState(() {
        _apiTransactions = statements;
        _updateMiniStatement();
      });
    }
    if (actualData['Name'] != null) {
      setState(() {
        _apiUsername = actualData['Name'];
      });
    }
    
    _loadCurrencyFromLoginData();
  }
  Future<void> _loadRegistrationDataFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? phoneKey;
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['mobileNumber'] != null) {
        phoneKey = PhoneUtils.canonicalPhoneKey(args['mobileNumber']);
      } else if (_userMobileNumber != null) {
        phoneKey = PhoneUtils.canonicalPhoneKey(_userMobileNumber!);
      }
      
      String? cachedEmail;
      String? cachedImageBytes;
      String? cachedImagePath;
      String? cachedUsername;
      if (phoneKey != null) {
        cachedEmail = prefs.getString('user_${phoneKey}_email');
        cachedImageBytes = prefs.getString('user_${phoneKey}_profileImage_bytes');
        cachedImagePath = prefs.getString('user_${phoneKey}_profileImage_path');
        cachedUsername = prefs.getString('user_${phoneKey}_fullName');
      }
      if (cachedEmail == null) {
        cachedEmail = prefs.getString('registration_email');
        cachedImageBytes = prefs.getString('registration_profileImage_bytes');
        cachedImagePath = prefs.getString('registration_profileImage_path');
        cachedUsername = prefs.getString('registration_fullName');
      }
      
      setState(() {
        _cachedEmail = cachedEmail;
        _apiUsername = cachedUsername ?? _apiUsername;
        if (cachedImageBytes != null) {
          try {
            _cachedImageBytes = base64Decode(cachedImageBytes);
          } catch (e) {}
        }
        if (cachedImagePath != null && !kIsWeb) {
          _cachedImageFile = File(cachedImagePath);
        }
      });
    } catch (e) {}
  }
  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedDashboardData = prefs.getString('dashboardData');
      if (storedDashboardData != null) {
        setState(() {
          _loginData = jsonDecode(storedDashboardData);
          _loadApiData();
        });
        _userMobileNumber = prefs.getString('userMobile') ?? 
                           prefs.getString('userPhoneNumber') ?? 
                           widget.username;
        final storedCurrencyCode = prefs.getString('userCurrencyCode');
        if (storedCurrencyCode != null && storedCurrencyCode.isNotEmpty) {
          setState(() {
            _currentCurrencyCode = storedCurrencyCode;
            _currentCurrencySymbol = storedCurrencyCode;
          });
          print('[DASHBOARD] Loaded currency code from stored data: $storedCurrencyCode');
        } else {
          print('[DASHBOARD] No currency code found in stored data');
        }
        return;
      }
      final storedLoginData = prefs.getString('loginData');
      if (storedLoginData != null) {
        setState(() {
          _loginData = jsonDecode(storedLoginData);
          _loadApiData();
        });
      }
      _userMobileNumber = prefs.getString('userMobile') ?? 
                         prefs.getString('userPhoneNumber') ?? 
                         widget.username;
      final storedCurrencyCode = prefs.getString('userCurrencyCode');
      if (storedCurrencyCode != null && storedCurrencyCode.isNotEmpty) {
        setState(() {
          _currentCurrencyCode = storedCurrencyCode;
          _currentCurrencySymbol = storedCurrencyCode;
        });
        print('[DASHBOARD] Loaded currency code from SharedPreferences: $storedCurrencyCode');
      } else {
        print('[DASHBOARD] No currency code found in SharedPreferences');
      }
    } catch (e) {}
  }
  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      String? authToken;
      if (_loginData != null && _loginData!['data'] != null) {
        final actualData = _loginData!['data'] as Map<String, dynamic>;
        authToken = actualData['Token'] ?? actualData['token'] ?? actualData['accessToken'];
      }
      if (authToken == null || authToken.isEmpty) {
        authToken = await TokenManager.getToken();
      }
      
      if (authToken.isEmpty) {
        return;
      }
      
      Map<String, dynamic> response = await ApiService.refreshDashboard(token: authToken);
      if (response['tokenValid'] == false) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final stored = prefs.getString('authToken');
          if (stored != null && stored.isNotEmpty && stored != authToken) {
            response = await ApiService.refreshDashboard(token: stored);
          }
        } catch (_) {}
      }
      
      if (response['success']) {
        // Get currency code before setState to avoid await in setState
        String? storedCurrencyCode;
        if (_currentCurrencyCode.isEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            storedCurrencyCode = prefs.getString('userCurrencyCode');
          } catch (e) {
            print('[DASHBOARD] Error getting currency code: $e');
          }
        }
        
        setState(() {
          if (_loginData!['data'] != null) {
            _loginData!['data'] = response['data'];
          } else {
            _loginData = response['data'];
          }
          _loadApiData();
          
          // Ensure currency code is preserved if not in response
          if (_currentCurrencyCode.isEmpty && storedCurrencyCode != null && storedCurrencyCode.isNotEmpty) {
            _currentCurrencyCode = storedCurrencyCode;
            _currentCurrencySymbol = storedCurrencyCode;
            print('[DASHBOARD] Restored currency code from SharedPreferences: $storedCurrencyCode');
          }
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
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
  void _handleSessionExpired() {
    if (mounted && context.mounted) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Session Expired',
        message: 'Your session has expired. You will be redirected to the login screen.',
        onPressed: () {
          Navigator.of(context).pop(); 
        },
      );
    }
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
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
              String isoDate = '${dateParts[2]}-${dateParts[0].padLeft(2, '0')}-${dateParts[1].padLeft(2, '0')}T$timePart';
              date = DateTime.parse(isoDate);
            }
          }
        }
      } catch (e) {}
      TransactionType type;
      if (description.toLowerCase().contains('deposit')) {
        type = TransactionType.credit;
      } else if (description.toLowerCase().contains('withdrawal') || description.toLowerCase().contains('withdraw')) {
        type = TransactionType.debit; 
      } else {
        type = amount >= 0 ? TransactionType.credit : TransactionType.debit;
      }
      IconData icon = Icons.account_balance;
      if (description.toLowerCase().contains('deposit')) {
        icon = Icons.add_circle_outline;
      } else if (description.toLowerCase().contains('interest')) {
        icon = Icons.trending_up;
      } else if (description.toLowerCase().contains('repayment')) {
        icon = Icons.payment;
      } else if (description.toLowerCase().contains('withdrawal') || description.toLowerCase().contains('withdraw')) {
        icon = Icons.remove_circle_outline;
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
          } catch (e) {}
        }
      }
    }
    final now = DateTime.now();
    final lastLogin = now.subtract(const Duration(hours: 2, minutes: 18));
    return DateFormat('dd MMMM yyyy, HH:mm').format(lastLogin);
  }
  bool get _isAccountBadStatus {
    try {
      final data = _loginData?['data'] ?? _loginData;
      if (data is Map<String, dynamic>) {
        final status = (data['Status'] ?? data['status'] ?? '').toString().toLowerCase();
        return status.isNotEmpty && status != 'active' && status != 'ok';
      }
    } catch (_) {}
    return false;
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
          email: _cachedEmail ?? widget.email,
          profileImageBytes: _cachedImageBytes ?? widget.profileImageBytes,
          profileImageFile: _cachedImageFile ?? widget.profileImageFile,
          authToken: authToken,
          loginData: loginData,
          mobileNumber: _userMobileNumber,
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

  Future<void> _handleSendToSacco() async {
    String? authToken;
    if (_loginData != null && _loginData!['data'] != null) {
      final actualData = _loginData!['data'] as Map<String, dynamic>;
      authToken = actualData['Token'] ?? actualData['token'] ?? actualData['accessToken']; 
    }
    if (authToken == null || authToken.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        authToken = prefs.getString('authToken');
      } catch (_) {}
    }
    if (authToken == null || authToken.isEmpty) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Authentication Error',
        message: 'Please login again to perform this transaction.',
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DepositDialog(
          authToken: authToken!,
          lockedPhoneNumber: _userMobileNumber ?? widget.username,
          currencyCode: _currentCurrencyCode,
          onDepositSuccess: (double amount, String phoneNumber) async {
            await _refreshDashboard();
            if (mounted && context.mounted) {
              StatusMessages.success(
                context,
                message: 'Successfully sent $_currentCurrencyCode ${amount.toStringAsFixed(2)} to SACCO',
              );
            }
          },
        );
      },
    );
  }
  Future<void> _handleSendToMTN() async {
    String? authToken;
    if (_loginData != null && _loginData!['data'] != null) {
      final actualData = _loginData!['data'] as Map<String, dynamic>;
      authToken = actualData['Token'] ?? actualData['token'] ?? actualData['accessToken']; 
    }
    if (authToken == null || authToken.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        authToken = prefs.getString('authToken');
      } catch (_) {}
    }
    if (authToken == null || authToken.isEmpty) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Authentication Error',
        message: 'Please login again to perform this transaction.',
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WithdrawDialog(
          currentBalance: _accountBalance,
          authToken: authToken!,
          lockedPhoneNumber: _userMobileNumber ?? widget.username,
          currencyCode: _currentCurrencyCode,
          onWithdrawSuccess: (double amount, String phoneNumber) async {
            await _refreshDashboard();
            if (mounted && context.mounted) {
              StatusMessages.info(
                context,
                message: 'Successfully sent $_currentCurrencyCode ${amount.toStringAsFixed(2)} to MTN',
              );
            }
          },
        );
      },
    );
  }

  void _handlePayBills() {
    StatusMessages.info(context, message: 'Pay Bills feature coming soon!', duration: const Duration(seconds: 2));
  }

  void _viewFullStatement() {
  }
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
    } else if (_cachedImageBytes != null) {
      return Image.memory(
        _cachedImageBytes!,
        fit: BoxFit.cover,
      );
    } else if (_cachedImageFile != null && !kIsWeb) {
      return Image.file(
        _cachedImageFile!,
        fit: BoxFit.cover,
      );
    } else {
      return const Icon(
        Icons.person,
        color: Colors.white,
        size: 28,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const MenuDrawerScreen(),
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
                      const Color(0xFF0D1B4A),  
                      const Color(0xFF1A237E), 
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
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  _greeting,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _apiUsername ?? widget.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_isAccountBadStatus) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.white, size: 14),
                                        SizedBox(width: 6),
                                        Text('Account status: Attention required', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
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
                            const SizedBox(width: 8),
                            Builder(
                              builder: (context) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.menu,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    Scaffold.of(context).openEndDrawer();
                                  },
                                  tooltip: 'Open menu',
                                ),
                              ),
                            ),
                          ],
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
                                ? '$_currentCurrencyCode ${NumberFormat("#,##0.00").format(_accountBalance)}'
                                : '$_currentCurrencyCode ••••••',
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
                              onPressed: _isRefreshing ? null : _handleSendToSacco,
                              icon: const Icon(Icons.business_outlined),
                              label: const Text('Send to SACCO'),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isRefreshing ? null : _handleSendToMTN,
                              icon: const Icon(Icons.phone_android_outlined),
                              label: const Text('Send to MTN'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA726),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 12),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        child: ElevatedButton.icon(
                          onPressed: _isRefreshing ? null : _handlePayBills,
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Pay Bills'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
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
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/transactions',
                                arguments: {
                                  'transactions': _apiTransactions,
                                  'currencyCode': _currentCurrencyCode,
                                },
                              );
                            },
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
                                      '${transaction.type == TransactionType.credit ? '+' : '-'}$_currentCurrencyCode ${NumberFormat("#,##0.00").format(transaction.amount.abs())}',
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
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickActionItem(
                                    icon: Icons.phone_android,
                                    title: 'Mobile Money',
                                    color: const Color(0xFF1A237E).withOpacity(0.8),
                                    onTap: () {
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildQuickActionItem(
                                    icon: Icons.history,
                                    title: 'History',
                                    color: const Color(0xFF1A237E).withOpacity(0.8),
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
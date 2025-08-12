import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/currency_service.dart';

class WithdrawDialog extends StatefulWidget {
  final Function(double amount, String phoneNumber) onWithdrawSuccess;
  final double currentBalance;
  final String? authToken;

  const WithdrawDialog({
    super.key,
    required this.onWithdrawSuccess,
    required this.currentBalance,
    this.authToken,
  });

  @override
  _WithdrawDialogState createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isProcessing = false;
  String? _cachedToken;
  String _currentCurrency = '';
  String _currentCurrencySymbol = '';

  @override
  void initState() {
    super.initState();
    _loadCachedToken();
    _loadCurrency();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.getCurrency() ?? '';
    final currencySymbol = await CurrencyService.getCurrencySymbol();
    
    if (mounted) {
      setState(() {
        _currentCurrency = currency;
        _currentCurrencySymbol = currencySymbol;
      });
    }
}

  Future<void> _loadCachedToken() async {
    try {
      if (widget.authToken != null && widget.authToken!.isNotEmpty) {
        _cachedToken = widget.authToken;
      } else {
        final prefs = await SharedPreferences.getInstance();
        _cachedToken = prefs.getString('authToken') ?? '';
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error loading cached token: $e");
      _cachedToken = '';
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    if (amount < 10) {
      return 'Minimum withdrawal amount is $_currentCurrencySymbol 10';
    }
    if (amount > 7000000) {
      return 'Maximum withdrawal amount is $_currentCurrencySymbol 7000,000';
    }
    if (amount > widget.currentBalance) {
      return 'Insufficient balance';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }
    String cleanedPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanedPhone.startsWith('254') && cleanedPhone.length == 12) {
      return null;
    } else if (cleanedPhone.startsWith('0') && cleanedPhone.length == 10) {
      return null;
    } else if (cleanedPhone.startsWith('7') && cleanedPhone.length == 9) {
      return null;
    }
    return 'Please enter a valid phone number';
  }

  String _formatPhoneNumber(String phone) {
    String cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanedPhone.startsWith('0')) {
      return '254${cleanedPhone.substring(1)}';
    } else if (cleanedPhone.startsWith('7')) {
      return '254$cleanedPhone';
    } else if (cleanedPhone.startsWith('254')) {
      return cleanedPhone;
    }
    return cleanedPhone;
  }

  void _processWithdraw() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Ensuring we have the latest token
        if (_cachedToken == null || _cachedToken!.isEmpty) {
          await _loadCachedToken();
        }

        String? authToken = _cachedToken;

        if (authToken == null || authToken.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          return;
        }

        final result = await ApiService.processWithdraw(
          token: authToken,
          phoneNumber: _formatPhoneNumber(_phoneController.text),
          amount: double.parse(_amountController.text),
          remarks: "Withdrawal from wallet",
        );

        if (result['success'] == true) {
          _showStkPushDialog(); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Withdrawal request failed'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      } catch (e) {
        if (e.toString().contains('401') || e.toString().contains('Unauthorized') || 
            e.toString().contains('Invalid/Expired token')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('authToken');
          await prefs.setBool('isLoggedIn', false);
          
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Withdrawal failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showStkPushDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WithdrawStkPushDialog(
          amount: double.parse(_amountController.text),
          phoneNumber: _formatPhoneNumber(_phoneController.text),
          onSuccess: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            widget.onWithdrawSuccess(
              double.parse(_amountController.text),
              _formatPhoneNumber(_phoneController.text),
            );
          },
          onCancel: () {
            Navigator.of(context).pop(); 
            setState(() {
              _isProcessing = false;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Withdraw Money',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Balance: $_currentCurrencySymbol ${NumberFormat("#,##0.00").format(widget.currentBalance)}', 
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Amount ($_currentCurrencySymbol)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          prefixText: '$_currentCurrencySymbol ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: _validateAmount,
                        enabled: !_isProcessing,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: InputDecoration(
                          hintText: '0712345678 or 254...',
                          prefixIcon: const Icon(Icons.phone_android),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: _validatePhone,
                        enabled: !_isProcessing,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _processWithdraw,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isProcessing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Processing...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Process Withdrawal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You will receive a notification to confirm the withdrawal. Money will be sent to the phone number above.',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WithdrawStkPushDialog extends StatefulWidget {
  final double amount;
  final String phoneNumber;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const WithdrawStkPushDialog({
    super.key,
    required this.amount,
    required this.phoneNumber,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  _WithdrawStkPushDialogState createState() => _WithdrawStkPushDialogState();
}

class _WithdrawStkPushDialogState extends State<WithdrawStkPushDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int _countdown = 60;
  late AnimationController _countdownController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _countdownController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    _animationController.repeat(reverse: true);
    _startCountdown();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _showSuccessMessage();
      }
    });
  }

  void _startCountdown() {
    _countdownController.forward();
    _countdownController.addListener(() {
      if (mounted) {
        setState(() {
          _countdown = (60 * (1 - _countdownController.value)).round();
        });
      }
    });
    
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        widget.onCancel();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _showSuccessMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Withdrawal Successful!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: CurrencyService.getCurrencySymbol(),
                  builder: (context, snapshot) {
                    final symbol = snapshot.data ?? '';
                    return Text(
                      '$symbol ${widget.amount.toStringAsFixed(2)} has been sent to ${widget.phoneNumber}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'The amount has been deducted from your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onSuccess();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android,
                      color: Colors.orange.shade600,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Notification Sent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your phone for M-Pesa prompt to confirm withdrawal',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Withdrawal: KES ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'To: ${widget.phoneNumber}',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Expires in: ${_countdown}s',
              style: TextStyle(
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
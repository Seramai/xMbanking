import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DepositDialog extends StatefulWidget {
  final Function(double amount, String phoneNumber) onDepositSuccess;
  final String authToken;
  final String? lockedPhoneNumber;
  final String currencyCode;

  const DepositDialog({
    super.key,
    required this.onDepositSuccess,
    required this.authToken,
    this.lockedPhoneNumber,
    required this.currencyCode,
  });

  @override
  _DepositDialogState createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _isProcessing = false;
  String _currentCurrencyCode = '';

  @override
  void initState() {
    super.initState();
    _currentCurrencyCode = widget.currencyCode;
    
    if (widget.lockedPhoneNumber != null && widget.lockedPhoneNumber!.isNotEmpty) {
      String phoneNumber = widget.lockedPhoneNumber!;
      if (_isValidPhoneFormat(phoneNumber)) {
        _phoneController.text = phoneNumber;
      }
    }
  }

  bool _isValidPhoneFormat(String phone) {
    String cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return (cleanedPhone.startsWith('254') && cleanedPhone.length == 12) ||
          (cleanedPhone.startsWith('0') && cleanedPhone.length == 10) ||
          (cleanedPhone.startsWith('7') && cleanedPhone.length == 9);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _remarksController.dispose();
    super.dispose();
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
      return 'Minimum deposit amount is $_currentCurrencyCode 10';
    }
    if (amount > 15000000) {
      return 'Maximum deposit amount is $_currentCurrencyCode 15,000,000';
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

  void _processDeposit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        String? authToken = widget.authToken;

        if (authToken.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          authToken = prefs.getString('authToken') ?? '';
          
          if (authToken.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication error. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isProcessing = false;
            });
            return;
          }
        }
        final result = await ApiService.processDeposit(
          token: authToken,
          phoneNumber: _formatPhoneNumber(_phoneController.text),
          amount: double.parse(_amountController.text),
          remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        );

        if (result['success'] == true) {
          _showStkPushDialog(); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Deposit request failed'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deposit failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        return StkPushDialog(
          amount: double.parse(_amountController.text),
          phoneNumber: _formatPhoneNumber(_phoneController.text),
          currencyCode: _currentCurrencyCode,
          onSuccess: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            widget.onDepositSuccess(
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
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 400,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Deposit Money',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Amount ($_currentCurrencyCode)',
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
                    prefixText: '$_currentCurrencyCode ',
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
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
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
                    hintText: widget.lockedPhoneNumber == null 
                        ? '0712345678 or 254712345678'
                        : null,
                    prefixIcon: Icon(
                      Icons.phone_android,
                      color: widget.lockedPhoneNumber != null 
                          ? Colors.grey.shade500 
                          : null,
                    ),
                    suffixIcon: widget.lockedPhoneNumber != null 
                        ? Icon(Icons.lock, color: Colors.grey.shade500) 
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.lockedPhoneNumber != null 
                            ? Colors.grey.shade400 
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.lockedPhoneNumber != null 
                            ? Colors.grey.shade400 
                            : Colors.grey.shade300,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    filled: true,
                    fillColor: widget.lockedPhoneNumber != null 
                        ? Colors.grey.shade200
                        : Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    color: widget.lockedPhoneNumber != null 
                        ? Colors.grey.shade700
                        : Colors.black,
                    fontWeight: widget.lockedPhoneNumber != null 
                        ? FontWeight.w500 
                        : FontWeight.normal,
                  ),
                  validator: _validatePhone,
                  enabled: (widget.lockedPhoneNumber == null || 
                            widget.lockedPhoneNumber!.isEmpty || 
                            !_isValidPhoneFormat(widget.lockedPhoneNumber!)) && !_isProcessing,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Remarks (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _remarksController,
                  decoration: InputDecoration(
                    hintText: 'Enter remarks for this deposit',
                    prefixIcon: const Icon(Icons.note),
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
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  enabled: !_isProcessing,
                  maxLines: 2,
                  maxLength: 100,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processDeposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Processing...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Process Deposit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will receive an notification on your phone to complete the transaction.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
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
    );
  }
}

class StkPushDialog extends StatefulWidget {
  final double amount;
  final String phoneNumber;
  final String currencyCode;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const StkPushDialog({
    super.key,
    required this.amount,
    required this.phoneNumber,
    required this.currencyCode,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  _StkPushDialogState createState() => _StkPushDialogState();
}

class _StkPushDialogState extends State<StkPushDialog>
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
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
                  'Deposit Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.currencyCode} ${widget.amount.toStringAsFixed(2)} has been deposited to your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
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
      child: Padding(
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android,
                      color: Colors.green.shade600,
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your phone for a pin prompt',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount: ${widget.currencyCode} ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Phone: ${widget.phoneNumber}',
                    style: TextStyle(color: Colors.grey.shade600),
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
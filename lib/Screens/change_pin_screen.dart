import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Services/api_service.dart';
import '../Utils/validators.dart';
import '../Widgets/custom_dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePinScreen extends StatefulWidget {
  final String authToken;
  // helps determine if its a fisrt time user or an existing one
  final bool isFirstTime;
  final String? username;
  final String? email;
  final Map<String, dynamic>? loginData; 

  const ChangePinScreen({
    super.key,
    required this.authToken,
    this.isFirstTime = false,
    this.username,
    this.email,
    this.loginData, 
  });

  @override
  _ChangePinScreenState createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  bool _isCurrentPinVisible = false;
  bool _isNewPinVisible = false;
  bool _isConfirmPinVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

  String authToken = widget.authToken;
  if (authToken.isEmpty) {
    // getting token from cache
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('authToken') ?? '';
    
    if (authToken.isEmpty) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Authentication Error',
        message: 'Authentication error. Please login again.',
      );
      return;
    }
  }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result = await ApiService.changePin(
        token: authToken,
        currentPin: _currentPinController.text.trim(),
        newPin: _newPinController.text.trim(),
        confirmNewPin: _confirmPinController.text.trim(),
      );
      if (result['tokenValid'] == false) {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('authToken') ?? '';
        if (stored.isNotEmpty && stored != authToken) {
          result = await ApiService.changePin(
            token: stored,
            currentPin: _currentPinController.text.trim(),
            newPin: _newPinController.text.trim(),
            confirmNewPin: _confirmPinController.text.trim(),
          );
        }
      }

      if (result['success'] == true) {
        CustomDialogs.showSuccessDialog(
          context: context,
          title: 'PIN Changed Successfully',
          message: result['message'] ?? 'PIN changed successfully!',
          buttonText: 'OK',
          onPressed: () {
            Navigator.of(context).pop();
            if (widget.isFirstTime) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/dashboard',
                (route) => false,
                arguments: {
                  'loginData': widget.loginData ?? {
                    'data': {
                      'Name': widget.username,
                      'Email': widget.email,
                      'Token': widget.authToken,
                      'isFirstTimeUser': false,
                    },
                    'success': true,
                    'message': 'PIN setup successful',
                  },
                  'authToken': widget.authToken,
                  'username': widget.username ?? 'User',
                  'email': widget.email ?? '',
                  'profileImageBytes': widget.loginData?['profileImageBytes'],
                  'profileImageFile': widget.loginData?['profileImageFile'],
                  'useStoredData': false,
                },
              );
            } else {
              Navigator.pop(context);
            }
          },
        );
      } else {
        CustomDialogs.showErrorDialog(
          context: context,
          title: 'PIN Change Failed',
          message: result['message'] ?? 'PIN change failed. Please try again.',
        );
      }
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'PIN Change Error',
        message: 'PIN change error: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back navigation for first-time users (mandatory PIN change)
      onWillPop: () async => !widget.isFirstTime,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isFirstTime ? 'Set Your PIN' : 'Change PIN'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !widget.isFirstTime,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8F9FA).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    widget.isFirstTime ? 'Set Your New PIN' : 'Change Your PIN',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    widget.isFirstTime 
                        ? 'Please set a secure 6-digit PIN to protect your account'
                        : 'Enter your current PIN and set a new 6-digit PIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _currentPinController,
                              validator: Validators.requiredExactLengthDigits('Current PIN', 6),
                              keyboardType: TextInputType.number,
                              obscureText: !_isCurrentPinVisible,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Current PIN',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                ),
                                counterText: '',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isCurrentPinVisible 
                                        ? Icons.visibility_off 
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isCurrentPinVisible = !_isCurrentPinVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _newPinController,
                              validator: Validators.pin(
                                minLength: 6,
                                maxLength: 6,
                                disallowEqualTo: () => _currentPinController.text,
                                disallowEqualMessage: 'New PIN must be different from current PIN',
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: !_isNewPinVisible,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'New PIN',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                ),
                                counterText: '',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isNewPinVisible 
                                        ? Icons.visibility_off 
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isNewPinVisible = !_isNewPinVisible;
                                    });
                                  },
                                ),
                              ),
                              onChanged: (value) {
                                // Triggering validation of confirm PIN when new PIN changes
                                if (_confirmPinController.text.isNotEmpty) {
                                  _formKey.currentState?.validate();
                                }
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _confirmPinController,
                              validator: Validators.confirmMatch(
                                label: 'Confirm PIN',
                                otherValue: () => _newPinController.text,
                                mismatchMessage: 'Confirm PIN does not match New PIN',
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: !_isConfirmPinVisible,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Confirm New PIN',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_clock),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                ),
                                counterText: '',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPinVisible 
                                        ? Icons.visibility_off 
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPinVisible = !_isConfirmPinVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _changePin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Changing PIN...'),
                                        ],
                                      )
                                    : Text(
                                        widget.isFirstTime ? 'Set PIN' : 'Change PIN',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                            // Cancel Button (only for non-first-time users)
                            if (!widget.isFirstTime) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Security Tips:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Use a unique 6-digit PIN\n'
                          '• Don\'t use obvious patterns (123456, 000000)\n'
                          '• Keep your PIN confidential\n'
                          '• Change your PIN regularly',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
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
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Services/api_service.dart';

class ChangePinScreen extends StatefulWidget {
  final String authToken;
  // helps determine if its a fisrt time user or an existing one
  final bool isFirstTime;
  final String? username;
  final String? email;

  const ChangePinScreen({
    super.key,
    required this.authToken,
    this.isFirstTime = false,
    this.username,
    this.email,
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

  String? _validateCurrentPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current PIN is required';
    }
    if (value.length != 6) {
      return 'PIN must be exactly 6 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    return null;
  }

  String? _validateNewPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'New PIN is required';
    }
    if (value.length != 6) {
      return 'PIN must be exactly 6 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    if (value == _currentPinController.text) {
      return 'New PIN must be different from current PIN';
    }
    return null;
  }

  String? _validateConfirmPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm PIN is required';
    }
    if (value.length != 6) {
      return 'PIN must be exactly 6 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    if (value != _newPinController.text) {
      return 'Confirm PIN does not match New PIN';
    }
    return null;
  }

  Future<void> _changePin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.authToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.changePin(
        token: widget.authToken,
        currentPin: _currentPinController.text.trim(),
        newPin: _newPinController.text.trim(),
        confirmNewPin: _confirmPinController.text.trim(),
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(result['message'] ?? 'PIN changed successfully!'),
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

        // Navigate based on whether it's first time or not
        if (widget.isFirstTime) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
            arguments: {
              'username': widget.username ?? 'User',
              'email': widget.email ?? '',
            },
          );
        } else {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(result['message'] ?? 'PIN change failed. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('PIN change error: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 4),
        ),
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
          // Hide back button for first-time users
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
                              validator: _validateCurrentPin,
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
                              validator: _validateNewPin,
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
                              validator: _validateConfirmPin,
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Widgets/custom_dialogs.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  _ForgotPinScreenState createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  // masking of the pin numbers
  bool _isNewPinVisible = false;
  bool _isConfirmPinVisible = false;
  bool _isLoading = false;
  // 0: verification, 1: new PIN setup
  int _currentStep = 0; 
// they are disposed in the dispose method to prevent memory leak
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateNewPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'New PIN is required';
    }
    if (value.length < 4 || value.length > 6) {
      return 'PIN must be between 4-6 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    return null;
  }

  String? _validateConfirmPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your PIN';
    }
    if (value != _newPinController.text) {
      return 'PINs do not match';
    }
    return null;
  }

  Future<void> _verifyUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
// loading of the UI and preventing duplicate submissions
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call for user verification
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _currentStep = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User verified! Please set your new PIN.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Verification Failed',
        message: 'Verification failed: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call for PIN update
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'PIN Update Failed',
        message: 'PIN update failed: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildVerificationStep() {
    return Column(
      children: [
        const Text(
          'Verify Your Identity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please enter your username and email to verify your identity',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _usernameController,
          validator: _validateUsername,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      Text('Verifying...'),
                    ],
                  )
                : const Text('Verify Identity'),
          ),
        ),
      ],
    );
  }
  Widget _buildNewPinStep() {
    return Column(
      children: [
        const Text(
          'Set New PIN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please enter your new PIN (4-6 digits)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _newPinController,
          validator: _validateNewPin,
          obscureText: !_isNewPinVisible,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            labelText: 'New PIN',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
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
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPinController,
          validator: _validateConfirmPin,
          obscureText: !_isConfirmPinVisible,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            labelText: 'Confirm PIN',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updatePin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      Text('Updating PIN...'),
                    ],
                  )
                : const Text('Update PIN'),
          ),
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _currentStep = 0;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Back to Verification'),
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot PIN'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
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
                // Progress indicator
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: _currentStep >= 0 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: _currentStep >= 1 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
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
                      child: _currentStep == 0 
                        ? _buildVerificationStep() 
                        : _buildNewPinStep(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Remember your PIN? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
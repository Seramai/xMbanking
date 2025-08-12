import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../Services/api_service.dart';
import '../widgets/currency_selection_dialog.dart';
import '../Services/currency_service.dart';
import 'menu_drawer_screen.dart';
import 'dart:io';
import 'dart:typed_data';

class LoginScreen extends StatefulWidget {
  final Uint8List? profileImageBytes;
  final File? profileImageFile;
  
  const LoginScreen({
    super.key,
    this.profileImageBytes,
    this.profileImageFile,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPinVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mobileNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (value.length < 10) {
      return 'Mobile number must be at least 10 digits';
    }
    if (!RegExp(r'^[0-9+]+$').hasMatch(value)) {
      return 'Please enter a valid mobile number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 4) {
      return 'Password must be at least 4 characters';
    }
    return null;
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.loginUser(
        mobileNumber: _mobileNumberController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result['success'] == true) {
        final isCurrencySelected = await CurrencyService.isCurrencySelected();
        
        if (!isCurrencySelected) {
          _showCurrencySelectionDialog(result['data']);
        } else {
          _navigateToOtpScreen(result['data']);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _showCurrencySelectionDialog(Map<String, dynamic>? loginData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CurrencySelectionDialog(
          onCurrencySelected: (selectedCurrency) async {
            await CurrencyService.setCurrency(selectedCurrency);
            _navigateToOtpScreen(loginData);
          },
        );
      },
    );
  }
  void _navigateToOtpScreen(Map<String, dynamic>? loginData) async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    String? userId = loginData?['UserId'] ?? loginData?['userId'];
    if (userId == null && loginData != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login error: User ID not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.pushNamed(
      context,
      '/otp-verification',
      arguments: {
        'mobileNumber': _mobileNumberController.text,
        'email': loginData?['Email'] ?? loginData?['EmailAddress'] ?? '',
        'userId': userId,
        'loginData': loginData,
        'profileImageBytes': widget.profileImageBytes,
        'profileImageFile': widget.profileImageFile,
        'fromRegistration': args?['fromRegistration'] ?? false,
      },
    );
  }

  void _handleForgotPin() {
    Navigator.pushNamed(context, '/forgot-pin');
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    drawer: const MenuDrawerScreen(),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
             Color(0xFF0D1B4A),  
             Color(0xFF1A237E), 
             Colors.white.withOpacity(0.1),  
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      tooltip: 'Open menu',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to our online banking platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    const Text(
                      'Login to Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _mobileNumberController,
                                validator: _validateMobileNumber,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.phone),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey.shade400),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              TextFormField(
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                  obscureText: !_isPinVisible,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.lock),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade400),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPinVisible 
                                          ? Icons.visibility_off 
                                          : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPinVisible = !_isPinVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: Theme.of(context).primaryColor,
                                      ),
                                      const Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: _handleForgotPin,
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _performLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                                            Text('Signing In...'),
                                          ],
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
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
            ),
          ],
        ),
      ),
    ),
  );
}
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Text editing controllers for form fields
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  
  // State variables for user interactions and authentication
  bool _isPinVisible = false; // Controls PIN visibility toggle
  bool _isLoading = false; // Shows loading state during authentication
  bool _isBiometricAvailable = false; // Checks if biometric auth is available
  bool _rememberMe = false; // Remember user preference
  
  // Biometric authentication instance
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Animation controllers 
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers for smooth transitions
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Create fade animation for elements
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    
    // Create slide animation for form elements
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    
    // Start animations and check biometric availability
    _initializeScreen();
  }

  @override
  void dispose() {
    // Clean up controllers and animations to prevent memory leaks
    _usernameController.dispose();
    _pinController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Initializing screen with animations and biometric check
  Future<void> _initializeScreen() async {
    // Start animations
    _fadeController.forward();
    await Future.delayed(Duration(milliseconds: 300));
    _slideController.forward();
    
    // Check biometric availability
    await _checkBiometricAvailability();
  }

  //Check if biometric authentication is available on device
  Future<void> _checkBiometricAvailability() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _isBiometricAvailable = isAvailable && availableBiometrics.isNotEmpty;
      });
    } catch (e) {
      // Handle biometric check errors 
      print('Error checking biometric availability: $e');
      setState(() {
        _isBiometricAvailable = false;
      });
    }
  }
  // validations
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, dots, and underscores';
    }
    return null;
  }
  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    if (value.length < 4 || value.length > 6) {
      return 'PIN must be between 4-6 digits';
    }
    // Ensure only digits are allowed
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
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
      // Simulate API authentication call
      await Future.delayed(Duration(seconds: 2));
      await _handleSuccessfulLogin();
      
    } catch (e) {
      // Handle login errors 
      _showErrorSnackBar('Login failed: ${e.toString()}');
    } finally {
      // Hide loading state
      setState(() {
        _isLoading = false;
      });
    }
  }
  //Biometric authentication process
  Future<void> _performBiometricLogin() async {
    try {
      setState(() {
        _isLoading = true;
      });
      // Perform biometric authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        await _handleSuccessfulLogin();
      } else {
        _showErrorSnackBar('Biometric authentication failed or was cancelled');
      }
    } catch (e) {
      _showErrorSnackBar('Biometric authentication error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _handleSuccessfulLogin() async {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Login successful! Welcome back.'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
    // Wait for snackbar animation
    await Future.delayed(Duration(seconds: 1));
    _showSuccessDialog();
  }
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Login Successful'),
            ],
          ),
          content: Text(
            'You have successfully logged in to your account. You will now be redirected to the dashboard.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                //Navigate to dashboard
                // Navigator.pushReplacementNamed(context, '/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Continue to Dashboard'),
            ),
          ],
        );
      },
    );
  }
  void _handleForgotPin() {
    //  Navigate to forgot PIN screen
    // Navigator.pushNamed(context, '/forgot-pin');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange),
              SizedBox(width: 12),
              Text('Forgot PIN?'),
            ],
          ),
          content: Text(
            'You will be redirected to the PIN recovery process. This typically involves:\n\n'
            '• Verifying your identity\n'
            '• Answering security questions\n'
            '• Receiving a reset code via SMS/Email\n'
            '• Setting a new PIN',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        obscureText: isPassword && !_isPinVisible,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPinVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isPinVisible = !_isPinVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      ),
    );
  }

  //biometric authentication button
  Widget _buildBiometricButton() {
    if (!_isBiometricAvailable) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 16),
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _performBiometricLogin,
        icon: Icon(Icons.fingerprint, size: 24),
        label: Text(
          'Use Biometric Login',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor.withOpacity(0.4),
              Colors.white,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          // App logo/icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              size: 50,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Welcome text
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sign in to access your account',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Form title
                              Text(
                                'Login to Your Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 32),

                              // Username input field
                              _buildInputField(
                                controller: _usernameController,
                                label: 'Username',
                                hint: 'Enter your username',
                                icon: Icons.person,
                                validator: _validateUsername,
                                keyboardType: TextInputType.text,
                              ),
                              _buildInputField(
                                controller: _pinController,
                                label: 'PIN',
                                hint: 'Enter your 4-6 digit PIN',
                                icon: Icons.lock,
                                validator: _validatePin,
                                isPassword: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
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
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Spacer(),
                                  GestureDetector(
                                    onTap: _handleForgotPin,
                                    child: Text(
                                      'Forgot PIN?',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _performLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isLoading
                                    ? Row(
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
                                          Text(
                                            'Signing In...',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                              ),

                              // Biometric authentication button
                              _buildBiometricButton(),

                              SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                ],
                              ),

                              SizedBox(height: 24),
                              // Register redirect for new users
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 15,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // Navigate to registration screen
                                      Navigator.pushNamed(context, '/registration');
                                    },
                                    child: Text(
                                      'Register Here',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
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

                    SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Secure Banking at Your Fingertips',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.security, color: Colors.white.withOpacity(0.7), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Protected by 256-bit SSL encryption',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
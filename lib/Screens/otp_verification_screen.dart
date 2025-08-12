import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/api_service.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String mobileNumber;
  final Uint8List? profileImageBytes;
  final File? profileImageFile;
  final Map<String, dynamic>? loginData;
  final Map<String, dynamic>? arguments;
  final String userId;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.mobileNumber,
    this.profileImageBytes,
    this.profileImageFile,
    this.loginData,
    required this.userId,
    this.arguments,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  String _getOTPCode() =>
      _otpControllers.map((controller) => controller.text).join();

  bool _isOTPComplete() => _getOTPCode().length == 6;

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_isOTPComplete()) {
      _verifyOTP();
    }
  }

  Future<void> _verifyOTP() async {
    if (!_isOTPComplete()) {
      _showSnackBar('Please enter complete OTP', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otpCode = _getOTPCode();
      final result = await ApiService.verifyOTP(
        userId: widget.userId,
        otpCode: otpCode,
      );

      print("=== OTP VERIFICATION RESPONSE ===");
      print("Full result: $result");
      print("Result data: ${result['data']}");
      print("==================================");

      if (result['success'] == true) {
        final authToken = result['data']?['Token'] ??
            result['data']?['token'] ??
            result['data']?['accessToken'] ??
            result['token'] ??
            result['accessToken'];

        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        final cameFromRegistration = args?['fromRegistration'] == true;
        final isFirstTimeUser = (result['data']?['isFirstTimeUser'] ??
                result['data']?['IsFirstTimeUser'] ??
                result['data']?['firstTimeUser'] ??
                false) ||
            cameFromRegistration;

        // For existing users, we need to structure the data properly for the dashboard
        Map<String, dynamic> completeLoginData;
        
        if (isFirstTimeUser) {
          // For first-time users, we'll navigate to change PIN
          completeLoginData = {
            'data': result['data'] ?? result,
            'success': true,
            'message': result['message'] ?? 'OTP verified successfully',
          };
        } else {
          // For existing users, structure the data to match what dashboard expects
          completeLoginData = {
            'data': result['data'] ?? result,
            'success': true,
            'message': result['message'] ?? 'Login successful',
            'needsRefresh': false,
          };
          
          print("=== STRUCTURED LOGIN DATA FOR DASHBOARD ===");
          print("Complete login data: $completeLoginData");
          print("Data portion: ${completeLoginData['data']}");
          print("==========================================");
        }

        // Storing data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loginData', jsonEncode(completeLoginData));
        await prefs.setString('authToken', authToken ?? '');
        await prefs.setString('userId', widget.userId);
        await prefs.setString('userEmail', widget.email);
        await prefs.setString('userMobile', widget.mobileNumber);
        await prefs.setBool('isLoggedIn', true);

        _showSnackBar('OTP verified successfully!', Colors.green);
        if (isFirstTimeUser) {
          _navigateTo(
            '/change-pin',
            {
              'authToken': authToken ?? '',
              'isFirstTime': true,
              'username':
                  result['data']?['Name'] ?? args?['fullName'] ?? 'User',
              'email': widget.email,
              'profileImageBytes': widget.profileImageBytes,
              'profileImageFile': widget.profileImageFile,
              'loginData': completeLoginData,
              'useStoredData': true,
            },
          );
        } else {
          // For existing users, pass the complete data to dashboard
          _navigateTo(
            '/dashboard',
            {
              'loginData': completeLoginData, // This contains all the fresh data from OTP verification
              'authToken': authToken,
              'username': result['data']?['Name'] ?? args?['fullName'] ?? 'User',
              'mobileNumber': widget.mobileNumber,
              'email': widget.email,
              'profileImageBytes': widget.profileImageBytes,
              'profileImageFile': widget.profileImageFile,
              'useStoredData': false,
            },
          );
        }
      } else {
        _showSnackBar(
          result['message'] ?? 'Invalid OTP. Please try again.',
          Colors.red,
        );
        _clearOTP();
      }
    } catch (e) {
      print("OTP verification error: $e");
      _showSnackBar('Verification failed: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearOTP() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    setState(() => _isResending = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      _showSnackBar('OTP resent to ${widget.email}', Colors.green);
      _startResendTimer();
    } catch (e) {
      _showSnackBar('Failed to resend OTP: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _navigateTo(String route, Map<String, dynamic> arguments) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
      arguments: arguments,
    );
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Login OTP'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  height - MediaQuery.of(context).padding.top - kToolbarHeight - 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: height * 0.03),
                const Icon(Icons.mark_email_read, size: 80, color: Colors.blue),
                SizedBox(height: height * 0.025),
                const Text(
                  'Enter Verification Code',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'We sent a 6-digit code to\n${widget.mobileNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: height * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 55,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onOTPChanged(value, index),
                      ),
                    );
                  }),
                ),
                SizedBox(height: height * 0.04),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
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
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Verifying...'),
                            ],
                          )
                        : const Text('Verify Account',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Didn't receive the code? "),
                    GestureDetector(
                      onTap:
                          _resendTimer == 0 && !_isResending ? _resendOTP : null,
                      child: Text(
                        _resendTimer > 0
                            ? 'Resend in ${_resendTimer}s'
                            : _isResending
                                ? 'Sending...'
                                : 'Resend OTP',
                        style: TextStyle(
                          color: _resendTimer == 0 && !_isResending
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                          decoration: _resendTimer == 0 && !_isResending
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _clearOTP,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
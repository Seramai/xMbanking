import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String mobileNumber;
  final String? fullName;
  final Uint8List? profileImageBytes;
  final File? profileImageFile;
  
  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.mobileNumber,
    this.fullName,
    this.profileImageBytes,
    this.profileImageFile,
  });
  
  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
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
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool _isOTPComplete() {
    return _getOTPCode().length == 6;
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      String otpCode = _getOTPCode();
      // otp verification 
      if (otpCode == "123456") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/login', 
          (route) => false,
          arguments: {
            'email': widget.email,
            'mobileNumber': widget.mobileNumber,
            'fullName': widget.fullName,
            'profileImageBytes': widget.profileImageBytes,
            'profileImageFile': widget.profileImageFile,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        _clearOTP();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      // Simulate API call to resend OTP
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP resent to ${widget.email}'),
          backgroundColor: Colors.green,
        ),
      );
      _startResendTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Account'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Header
            const Icon(
              Icons.mark_email_read,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a 6-digit code to\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
            const SizedBox(height: 40),
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Verifying...'),
                        ],
                      )
                    : const Text(
                        'Verify Account',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive the code? "),
                GestureDetector(
                  onTap: _resendTimer == 0 && !_isResending ? _resendOTP : null,
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
            
            // Clear button
            TextButton(
              onPressed: _clearOTP,
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}
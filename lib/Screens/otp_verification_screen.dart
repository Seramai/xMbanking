import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/api_service.dart';
import '../Widgets/custom_dialogs.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:otp_autofill/otp_autofill.dart';
import '../Services/token_manager.dart';
import '../Services/device_fingerprint_service.dart';

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

class _OTPVerificationScreenState extends State<OTPVerificationScreen> with CodeAutoFill {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;
  String _autoFillCode = '';
  late OTPTextEditController _otpConsentController;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _initSmsAutofill();
    _initUserConsent();
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    try {
      SmsAutoFill().unregisterListener();
    } catch (_) {}
    try {
      cancel();
    } catch (_) {}
    try {
      _otpConsentController.stopListen();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initSmsAutofill() async {
    try {
      listenForCode();
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint('App signature for OTP SMS: $signature');
    } catch (e) {
      debugPrint('Failed to initialize SMS autofill: $e');
    }
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

  void _initUserConsent() {
    try {
      _otpConsentController = OTPTextEditController(
        codeLength: 6,
        onCodeReceive: (receivedMessage) {
          final match = RegExp(r'\d{4,6}').firstMatch(receivedMessage ?? '');
          final digits = match?.group(0) ?? '';
          if (digits.isEmpty) return;
          if (!mounted) return;
          setState(() {
            _autoFillCode = digits;
          });
          for (int i = 0; i < 6 && i < digits.length; i++) {
            _otpControllers[i].text = digits[i];
          }
          if (digits.length == 6) {
            _verifyOTP();
          }
        },
      )
        ..startListenUserConsent(
          (message) {
            final match = RegExp(r'\d{4,6}').firstMatch(message ?? '');
            return match?.group(0) ?? '';
          },
        );
    } catch (e) {
      debugPrint('Failed to initialize SMS User Consent: $e');
    }
  }

  String _getOTPCode() {
    if (_autoFillCode.isNotEmpty) return _autoFillCode;
    return _otpControllers.map((c) => c.text).join();
  }

  bool _isOTPComplete() => _getOTPCode().replaceAll(RegExp(r'\D'), '').length == 6;

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
      CustomDialogs.showWarningDialog(
        context: context, 
        title: 'Incomplete OTP', 
        message: 'Please enter the complete 6-digit verification code.',
        );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otpCode = _getOTPCode();
      final result = await ApiService.verifyOTP(
        userId: widget.userId,
        otpCode: otpCode,
      );

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
        }

        // Storing data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loginData', jsonEncode(completeLoginData));
        await prefs.setString('dashboardData', jsonEncode(completeLoginData));
        await prefs.setString('authToken', authToken ?? '');
        await prefs.setString('userToken', authToken ?? '');
        await TokenManager.setToken(authToken ?? '');
        await prefs.setString('userId', widget.userId);
        await prefs.setString('userEmail', widget.email);
        await prefs.setString('userMobile', widget.mobileNumber);
        await prefs.setString('userName', result['data']?['Name'] ?? '');
        await prefs.setBool('isLoggedIn', true);
        if (result['data']?['CurrencyCode'] != null) {
          await prefs.setString('userCurrencyCode', result['data']['CurrencyCode']);
        } else {
        }
        if (authToken != null && authToken.isNotEmpty) {
          await _promptAndTrustDeviceMandatory(authToken);
        }

        CustomDialogs.showSuccessDialog(
          context: context, 
          title: 'Verification Successful', 
          message: 'Your Account has been verified successfully',
          onPressed: (){
            Navigator.of(context).pop();
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
            }
            );
      } else {
        CustomDialogs.showErrorDialog(
          context: context,
          title: 'Verification Failed',
          message: result['message'] ?? 'The verification code you entered is incorrect. Please check and try again.',
        );
        _clearOTP();
      }
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context: context, 
        title: 'Verification Error', 
        message: 'Unable to verify your code. Please check your internet connection and try again. ',
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _trustCurrentDevice(String authToken) async {
    try {
      final trustResult = await DeviceFingerprintService.trustDevice(
        authToken: authToken,
      );
      if (trustResult['success'] == true) {
        print('[OTP_VERIFICATION] Device trusted successfully');
      } else {
        print('[OTP_VERIFICATION] Failed to trust device: ${trustResult['message']}');
      }
    } catch (e) {
      print('[OTP_VERIFICATION] Error trusting device: $e');
    }
  }

  Future<void> _promptAndTrustDeviceMandatory(String authToken) async {
    try {
      final completer = Completer<void>();

      CustomDialogs.showConfirmationDialog(
        context: context,
        title: 'Trust this device',
        message:
            'To continue, you must trust this device for future sign-ins. Only trust devices you own.',
        yesButtonText: 'Trust Device',
        noButtonText: 'Cancel',
        onYesPressed: () async {
          Navigator.of(context).pop();
          await _trustCurrentDevice(authToken);
          if (!completer.isCompleted) completer.complete();
        },
        onNoPressed: () {
          CustomDialogs.showWarningDialog(
            context: context,
            title: 'Action required',
            message: 'You must trust this device to proceed.',
          );
        },
      );

      await completer.future;
    } catch (e) {
      print('[OTP_VERIFICATION] Unable to prompt mandatory trust: $e');
    }
  }

  void _clearOTP() {
    setState(() {
      _autoFillCode = '';
    });
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  @override
  void codeUpdated() {
    final received = code ?? '';
    if (received.isEmpty) return;
    final digits = received.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _autoFillCode = digits;
    });
    for (int i = 0; i < 6 && i < digits.length; i++) {
      _otpControllers[i].text = digits[i];
    }
    if (digits.length == 6) {
      _verifyOTP();
    }
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    setState(() => _isResending = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      CustomDialogs.showInfoDialog(
        context: context,
        title: 'Code Resent',
        message: 'A new verification code has been sent to ${widget.mobileNumber}',
      );
      _startResendTimer();
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context: context,
        title: 'Resend Failed',
        message: 'Unable to resend verification code. Please try again.',
      );
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
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
// http functionality
import 'package:http/http.dart' as http;
// Handles files
import 'package:http_parser/http_parser.dart';
import '../Config/api_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 

class ApiService {
  // Validating registration details
  static Future<Map<String, dynamic>> validateRegistration({
    required String fullName,
    required String clientId,
    required String mobileNumber,
    required String identificationType,
    required String identificationNumber,
    required String emailAddress,
  }) async {
    try {
      // converting normal id to api code
      String idTypeCode = _convertIdTypeToCode(identificationType);
      final requestBody = {
        "FullName": fullName,
        "ClientId": clientId,
        "MobileNumber": mobileNumber,
        "IdentificationType": idTypeCode,
        "IdentificationNumber": identificationNumber,
        "EmailAddress": emailAddress,
      };
      
      print("Validating registration for $emailAddress");
      print("Request body: ${jsonEncode(requestBody)}");
      
      final response = await http.post(
        Uri.parse(ApiConfig.validateRegistrationUrl),
        headers: ApiConfig.headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Validation successful',
          'data': responseData,
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Validation failed',
          'errors': errorData,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection - please check your network',
      };
    } catch (e) {
      print("Validation error: $e");
      if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'message': 'Request timeout - please check your internet connection',
        };
      }
      return {
        'success': false,
        'message': 'Validation failed: ${e.toString()}',
      };
    }
  }
  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String clientId,
    required String mobileNumber,
    required String identificationType,
    required String identificationNumber,
    required String emailAddress,
    required String gender,
    File? profileImageFile,
    Uint8List? profileImageBytes,
    File? signatureFile,
    Uint8List? signatureBytes,
    String? signatureFileName,
  }) async {
    try {
      print("Starting registration for: $emailAddress");
      
      // Convert images to base64(first checks if the image bytes and image file is provided and then converts and then adds the prefix data:image/jpeg;base64 )
      String? selfieBase64;
      String? signatureBase64;
      if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
        selfieBase64 = 'data:image/jpeg;base64,${base64Encode(profileImageBytes)}';
        print("Added profile image (${profileImageBytes.length} bytes)");
      } else if (profileImageFile != null) {
        final bytes = await profileImageFile.readAsBytes();
        selfieBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        print("Added profile image from file");
      }
      if (signatureBytes != null && signatureBytes.isNotEmpty) {
        signatureBase64 = 'data:image/jpeg;base64,${base64Encode(signatureBytes)}';
        print("Added signature image (${signatureBytes.length} bytes)");
      } else if (signatureFile != null) {
        final bytes = await signatureFile.readAsBytes();
        signatureBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        print("Added signature image from file");
      }
      final requestBody = {
        "ClientId": clientId,
        "Names": fullName,
        "Gender": gender,
        "NationalId": identificationNumber,
        "MobileNumber": mobileNumber,
        "IdentificationType": _convertIdTypeToCode(identificationType),
        "Email": emailAddress,
        "Selfie": selfieBase64,
        "Signature": signatureBase64,
      };

      print("Sending registration request");
      print("Request body keys: ${requestBody.keys.toList()}");
      final response = await http.post(
        Uri.parse(ApiConfig.registrationUrl),
        headers: ApiConfig.headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout - please check your internet connection');
        },
      );
      
      print("Registration response status: ${response.statusCode}");
      print("Registration response body: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Registration successful',
          'data': responseData,
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['title'] ?? 'Registration failed',
          'errors': errorData,
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection - please check your network',
      };
    } catch (e) {
      print("Registration error: $e");
      if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'message': 'Upload timeout - please check your internet connection',
        };
      }
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }
  // login user
  static Future<Map<String, dynamic>> loginUser({
    required String mobileNumber,
    required String password,
  }) async {
    try {
      // getting the device details
      final deviceDetails = await _getDeviceDetails();
      final requestBody = {
        "MobileNumber": mobileNumber,
        "Password": password,
        "DeviceDetails": deviceDetails,
      };
      
      print("Attempting login for: $mobileNumber");
      print("Request body: ${jsonEncode(requestBody)}");
      
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: ApiConfig.headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Login timeout - please check your internet connection');
        },
      );
      
      print("Login response status: ${response.statusCode}");
      print("Login response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Login successful',
          'data': responseData,
        };
      } else if (response.statusCode == 401) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Invalid mobile number or password',
          'errors': errorData,
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['title'] ?? 'Login failed',
          'errors': errorData,
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection - please check your network',
      };
    } catch (e) {
      print("Login error: $e");
      if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'message': 'Login timeout - please check your internet connection',
        };
      }
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }
  // handles otp verification
  static Future<Map<String, dynamic>> verifyOTP({
    required String userId,
    required String otpCode,
  }) async {
    try {
      final requestBody = {
        "UserId": userId,
        "Otp": otpCode,
      };
      
      print("Verifying OTP for UserId: $userId");
      print("Request body: ${jsonEncode(requestBody)}");
      
      final response = await http.post(
        Uri.parse(ApiConfig.otpUrl),
        headers: ApiConfig.headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('OTP verification timeout - please check your internet connection');
        },
      );
      
      print("OTP verification response status: ${response.statusCode}");
      print("OTP verification response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'OTP verification successful',
          'data': responseData,
        };
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Invalid OTP',
          'errors': errorData,
        };
      } else {
        return {
          'success': false,
          'message': 'OTP verification failed: ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection - please check your network',
      };
    } catch (e) {
      print("OTP verification error: $e");
      if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'message': 'OTP verification timeout - please check your internet connection',
        };
      }
      return {
        'success': false,
        'message': 'OTP verification failed: ${e.toString()}',
      };
    }
  }
  // handles the deposit functionality
  static Future<Map<String, dynamic>> processDeposit({
    required String token,
    required String phoneNumber,
    required double amount,
    String? remarks,
  }) async {
    try {
      // Clean up remarks 
      String cleanedRemarks = remarks?.trim().replaceAll('\n', ' ') ?? "Deposit to wallet";
      
      final requestBody = {
        "Msisdn": phoneNumber,
        "Amount": amount,
        "Remarks": cleanedRemarks,
      };
      
      print("Processing deposit for: $phoneNumber");
      print("Deposit URL: ${ApiConfig.depositUrl}");
      print("Request headers: ${ApiConfig.getTransactionHeaders(token)}"); 
      print("Request body: ${jsonEncode(requestBody)}");
      
      // Add connection check
      try {
        final connectivity = await Connectivity().checkConnectivity();
        print("Network connectivity: $connectivity");
        if (connectivity == ConnectivityResult.none) {
          return {
            'success': false,
            'message': 'No internet connection - please check your network',
          };
        }
      } catch (e) {
        print("Connectivity check failed: $e");
      }

      final response = await http.post(
        Uri.parse(ApiConfig.depositUrl),
        headers: ApiConfig.getTransactionHeaders(token),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Deposit request timeout - please check your internet connection');
        },
      );
      
      print("Deposit response status: ${response.statusCode}");
      print("Deposit response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Deposit request successful',
          'data': responseData,
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Deposit request failed',
          'errors': errorData,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized - please login again',
        };
      } else {
        return {
          'success': false,
          'message': 'Deposit failed: ${response.statusCode}',
        };
      }
    } on SocketException catch (e) {
      print("Socket Exception: $e");
      return {
        'success': false,
        'message': 'Network error - please check your internet connection',
      };
    } on http.ClientException catch (e) {
      print("HTTP Client Exception: $e");
      return {
        'success': false,
        'message': 'Connection failed - please try again',
      };
    } on FormatException catch (e) {
      print("Format Exception: $e");
      return {
        'success': false,
        'message': 'Invalid server response format',
      };
    } catch (e) {
      print("Deposit error: $e");
      if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'message': 'Deposit request timeout - please check your internet connection',
        };
      } else if (e.toString().contains('Invalid status code 0')) {
        return {
          'success': false,
          'message': 'Connection failed - please check your network and try again',
        };
      }
      return {
        'success': false,
        'message': 'Deposit failed: ${e.toString()}',
      };
    }
  }
    // handles the withdraw functionality
  static Future<Map<String, dynamic>> processWithdraw({
    required String token,
    required String phoneNumber,
    required double amount,
    String? remarks,
  }) async {
    try {
      String cleanedRemarks = remarks?.trim().replaceAll('\n', ' ') ?? "Withdrawal from wallet";
      
      final requestBody = {
        "Msisdn": phoneNumber,
        "Amount": amount,
        "Remarks": cleanedRemarks,
      };
      
      print("Processing withdrawal for: $phoneNumber");
      print("Withdraw URL: ${ApiConfig.withdrawUrl}");
      print("Request headers: ${ApiConfig.getTransactionHeaders(token)}"); 
      print("Request body: ${jsonEncode(requestBody)}");
      try {
        final connectivity = await Connectivity().checkConnectivity();
        print("Network connectivity: $connectivity");
        if (connectivity == ConnectivityResult.none) {
          return {
            'success': false,
            'message': 'No internet connection - please check your network',
          };
        }
      } catch (e) {
        print("Connectivity check failed: $e");
      }

      final response = await http.post(
        Uri.parse(ApiConfig.withdrawUrl),
        headers: ApiConfig.getTransactionHeaders(token),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Withdrawal request timeout - please check your internet connection');
        },
      );
      
      print("Withdraw response status: ${response.statusCode}");
      print("Withdraw response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Withdrawal request successful',
          'data': responseData,
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Withdrawal request failed',
          'errors': errorData,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized - please login again',
        };
      } else {
        return {
          'success': false,
          'message': 'Withdrawal failed: ${response.statusCode}',
        };
      }
    } on SocketException catch (e) {
      print("Socket Exception: $e");
      return {
        'success': false,
        'message': 'Network error - please check your internet connection',
      };
    } on http.ClientException catch (e) {
      print("HTTP Client Exception: $e");
      return {
        'success': false,
        'message': 'Connection failed - please try again',
      };
    } on FormatException catch (e) {
      print("Format Exception: $e");
      return {
        'success': false,
        'message': 'Invalid server response format',
      };
    } catch (e) {
      print("Withdrawal error: $e");
      if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'message': 'Withdrawal request timeout - please check your internet connection',
        };
      } else if (e.toString().contains('Invalid status code 0')) {
        return {
          'success': false,
          'message': 'Connection failed - please check your network and try again',
        };
      }
      return {
        'success': false,
        'message': 'Withdrawal failed: ${e.toString()}',
      };
    }
  }
  // Convert ID type to API code
  static String _convertIdTypeToCode(String identificationType) {
    switch (identificationType) {
      case 'National ID':
        return 'NIN';
      case 'Passport No':
        return 'PASSPORT';
      case 'Military No':
        return 'MILITARY_ID';
      case 'Driver\'s License No':
        return 'DRIVING_LICENSE';
      case 'Birth Certificate No':
        return 'BIRTH_CERTIFICATE';
      default:
        return 'NIN';
    }
  }
  // helper method that gathers device information
  static Future<Map<String, dynamic>> _getDeviceDetails() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
      final ui.FlutterView view = ui.PlatformDispatcher.instance.views.first;
      final Size screenSize = view.physicalSize;
      final double pixelRatio = view.devicePixelRatio;
      final Locale locale = ui.PlatformDispatcher.instance.locale;
      
      Map<String, dynamic> deviceDetails = {};
      
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceDetails = {
          "DeviceId": androidInfo.id, 
          "Model": androidInfo.model,
          "Brand": androidInfo.brand,
          "OsVersion": androidInfo.version.release,
          "SdkVersion": androidInfo.version.sdkInt.toString(),
          "AppVersion": packageInfo.version,
          "BuildNumber": packageInfo.buildNumber,
          "ScreenResolution": "${screenSize.width.toInt()}x${screenSize.height.toInt()}",
          "PixelDensity": pixelRatio,
          "NetworkType": connectivityResult.toString(),
          "Language": locale.languageCode,
          "Country": locale.countryCode ?? "Unknown",
          "TimeZone": DateTime.now().timeZoneName,
        };
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceDetails = {
          "DeviceId": iosInfo.identifierForVendor ?? "Unknown", 
          "Model": iosInfo.model,
          "Brand": "Apple",
          "OsVersion": iosInfo.systemVersion,
          "SdkVersion": iosInfo.systemVersion,
          "AppVersion": packageInfo.version,
          "BuildNumber": packageInfo.buildNumber,
          "ScreenResolution": "${screenSize.width.toInt()}x${screenSize.height.toInt()}",
          "PixelDensity": pixelRatio,
          "NetworkType": connectivityResult.toString(),
          "Language": locale.languageCode,
          "Country": locale.countryCode ?? "Unknown",
          "TimeZone": DateTime.now().timeZoneName,
        };
      } else {
        deviceDetails = {
          "DeviceId": "web_device_${DateTime.now().millisecondsSinceEpoch}",
          "Model": "Unknown",
          "Brand": "Unknown",
          "OsVersion": "Unknown",
          "SdkVersion": "Unknown",
          "AppVersion": packageInfo.version,
          "BuildNumber": packageInfo.buildNumber,
          "ScreenResolution": "${screenSize.width.toInt()}x${screenSize.height.toInt()}",
          "PixelDensity": pixelRatio,
          "NetworkType": connectivityResult.toString(),
          "Language": locale.languageCode,
          "Country": locale.countryCode ?? "Unknown",
          "TimeZone": DateTime.now().timeZoneName,
        };
      }
      
      return deviceDetails;
    } catch (e) {
      print("Error getting device details: $e");
      return {
        "DeviceId": "unknown_device_${DateTime.now().millisecondsSinceEpoch}",
        "Model": "Unknown",
        "Brand": "Unknown",
        "OsVersion": "Unknown",
        "SdkVersion": "Unknown",
        "AppVersion": "1.0.0",
        "BuildNumber": "1",
        "ScreenResolution": "Unknown",
        "PixelDensity": 1.0,
        "NetworkType": "Unknown",
        "Language": "en",
        "Country": "Unknown",
        "TimeZone": "Unknown",
      };
    }
  }
}
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../Config/api_config.dart';

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
      
      // Convert images to base64
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
}
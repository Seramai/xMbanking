import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../Config/api_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DeviceFingerprintService {
  static const String _fingerprintKey = 'device_fingerprint';
  static const String _trustedDeviceKey = 'trusted_device';
  
  // Generating a unique device fingerprint
  static Future<String> generateDeviceFingerprint() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
      final ui.FlutterView view = ui.PlatformDispatcher.instance.views.first;
      final Size screenSize = view.physicalSize;
      final double pixelRatio = view.devicePixelRatio;
      final Locale locale = ui.PlatformDispatcher.instance.locale;
      
      Map<String, dynamic> deviceData = {};
      
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceData = {
          "deviceId": androidInfo.id,
          "model": androidInfo.model,
          "brand": androidInfo.brand,
          "manufacturer": androidInfo.manufacturer,
          "osVersion": androidInfo.version.release,
          "sdkVersion": androidInfo.version.sdkInt.toString(),
          "hardware": androidInfo.hardware,
          "fingerprint": androidInfo.fingerprint,
          "serialNumber": androidInfo.serialNumber,
          "appVersion": packageInfo.version,
          "buildNumber": packageInfo.buildNumber,
          "screenResolution": "${screenSize.width.toInt()}x${screenSize.height.toInt()}",
          "pixelDensity": pixelRatio,
          "networkType": connectivityResult.toString(),
          "language": locale.languageCode,
          "country": locale.countryCode ?? "Unknown",
          "timeZone": DateTime.now().timeZoneName,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        };
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceData = {
          "deviceId": iosInfo.identifierForVendor ?? "Unknown",
          "model": iosInfo.model,
          "brand": "Apple",
          "osVersion": iosInfo.systemVersion,
          "sdkVersion": iosInfo.systemVersion,
          "hardware": iosInfo.utsname.machine,
          "appVersion": packageInfo.version,
          "buildNumber": packageInfo.buildNumber,
          "screenResolution": "${screenSize.width.toInt()}x${screenSize.height.toInt()}",
          "pixelDensity": pixelRatio,
          "networkType": connectivityResult.toString(),
          "language": locale.languageCode,
          "country": locale.countryCode ?? "Unknown",
          "timeZone": DateTime.now().timeZoneName,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        deviceData = {
          "deviceId": "web_device_${DateTime.now().millisecondsSinceEpoch}",
          "model": "Web Browser",
          "brand": "Unknown",
          "osVersion": "Web",
          "sdkVersion": "Web",
          "appVersion": packageInfo.version,
          "buildNumber": packageInfo.buildNumber,
          "screenResolution": "${screenSize.width.toInt()}x${screenSize.height.toInt()}",
          "pixelDensity": pixelRatio,
          "networkType": connectivityResult.toString(),
          "language": locale.languageCode,
          "country": locale.countryCode ?? "Unknown",
          "timeZone": DateTime.now().timeZoneName,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        };
      }
       final sortedKeys = deviceData.keys.toList()..sort();
       final deviceString = sortedKeys.map((key) => '$key:${deviceData[key]}').join('|');
       // Generating hash for device data
       final bytes = utf8.encode(deviceString);
       final digest = sha256.convert(bytes);
       final random = Random();
       final randomSuffix = random.nextInt(10000).toString().padLeft(4, '0');
       final fingerprint = '${digest.toString().substring(0, 32)}_$randomSuffix';
       return fingerprint;
         } catch (e) {
       final random = Random();
       final timestamp = DateTime.now().millisecondsSinceEpoch;
       final fallbackString = 'fallback_${timestamp}_${random.nextInt(1000000)}';
       final bytes = utf8.encode(fallbackString);
       final digest = sha256.convert(bytes);
       final fallbackFingerprint = digest.toString().substring(0, 32);
       return fallbackFingerprint;
     }
  }
  static Future<String> getDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    String? fingerprint = prefs.getString(_fingerprintKey);
    
    if (fingerprint == null || fingerprint.isEmpty) {
      fingerprint = await generateDeviceFingerprint();
      await prefs.setString(_fingerprintKey, fingerprint);
    } else {
    }
    
    return fingerprint;
  }
  static Future<bool> isDeviceTrusted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trustedDeviceKey) ?? false;
  }
  static Future<void> markDeviceAsTrusted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trustedDeviceKey, true);
  }
  static Future<Map<String, dynamic>> trustDevice({
    required String authToken,
  }) async {
    try {
      final fingerprint = await getDeviceFingerprint();
      final response = await http.post(
        Uri.parse(ApiConfig.trustDeviceUrl),
        headers: {
          ...ApiConfig.headers,
          'X-Device-Fingerprint': fingerprint,
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'deviceFingerprint': fingerprint,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Trust device request timeout');
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData = {};
        if (response.body.isNotEmpty) {
          try {
            responseData = jsonDecode(response.body);
          } catch (e) {
            
          }
        }
        
        await markDeviceAsTrusted();
        print('[TRUST_DEVICE] Device trusted successfully on server');
        return {
          'success': true,
          'message': 'Device trusted successfully',
          'data': responseData,
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to trust device',
          'errors': errorData,
        };
      } else if (response.statusCode == 401) {
        print('[TRUST_DEVICE] Unauthorized error');
        return {
          'success': false,
          'message': 'Unauthorized - please login again',
        };
      } else {
        print('[TRUST_DEVICE] Unexpected status code: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to trust device: ${response.statusCode}',
        };
      }
    } on SocketException {
      print('[TRUST_DEVICE] SocketException: No internet connection');
      return {
        'success': false,
        'message': 'No internet connection - please check your network',
      };
    } catch (e) {
      print('[TRUST_DEVICE] Exception: $e');
      return {
        'success': false,
        'message': 'Failed to trust device: ${e.toString()}',
      };
    }
  }
  static Future<Map<String, dynamic>> getDeviceDetails() async {
    try {
      print('[DEVICE_DETAILS] Getting device details for API...');
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
      final ui.FlutterView view = ui.PlatformDispatcher.instance.views.first;
      final Size screenSize = view.physicalSize;
      final double pixelRatio = view.devicePixelRatio;
      final Locale locale = ui.PlatformDispatcher.instance.locale;
      final fingerprint = await getDeviceFingerprint();
      
      Map<String, dynamic> deviceDetails = {};
      
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceDetails = {
          "DeviceId": fingerprint, 
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
          "DeviceId": fingerprint, 
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
          "DeviceId": fingerprint, 
          "Model": "Web Browser",
          "Brand": "Unknown",
          "OsVersion": "Web",
          "SdkVersion": "Web",
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
       
               print('[DEVICE_DETAILS] Device details: $deviceDetails');
        print('[DEVICE_DETAILS] Device details JSON: ${jsonEncode(deviceDetails)}');
        return deviceDetails;
         } catch (e) {
       final fingerprint = await getDeviceFingerprint();
       final fallbackDetails = {
         "DeviceId": fingerprint,
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
       return fallbackDetails;
     }
  }
  static Future<void> clearDeviceTrust() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_trustedDeviceKey);
  }
  
  static Future<String> getStoredFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    final fingerprint = prefs.getString(_fingerprintKey) ?? 'No fingerprint stored';
    return fingerprint;
  }
}

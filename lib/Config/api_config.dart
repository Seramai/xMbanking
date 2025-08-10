import 'package:flutter_dotenv/flutter_dotenv.dart';
// this loads and manages environment variables
class ApiConfig{
  // the .env file is loaded and read
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      // Verify all required variables exist
      if (dotenv.env['API_BASE_URL'] == null ||
          dotenv.env['API_KEY'] == null ||
          dotenv.env['VALIDATE_REGISTRATION_URL'] == null ||
          dotenv.env['REGISTRATION_URL'] == null) {
        throw Exception("Missing required environment variables");
      }
      
      print("Environment variables loaded successfully");
    } catch (e) {
      print("Error loading .env: $e");
      throw Exception("Failed to load environment configuration: $e");
    }
  }
  // this function retrieves the base url from the .env file
  static String get baseUrl{
    final url = dotenv.env['API_BASE_URL'];
    if(url == null || url.isEmpty){
      throw Exception("API_BASE_URL not found in the env file");
    }
    return url;
  }
  // getting the api key from the env file
  static String get apiKey{
    final key = dotenv.env['API_KEY'];
    if(key == null || key.isEmpty){
      throw Exception("API_KEY not found in the env file");
    }
    return key;
  }
  // getting the validation url
  static String get validateRegistrationUrl{
    final endpoint = dotenv.env['VALIDATE_REGISTRATION_URL'];
    if(endpoint == null || endpoint.isEmpty){
      throw Exception("VALIDATE REGISTATION URL not found in the env file");
    }
    return baseUrl + endpoint;
  }
  // getting the registration url
  static String get registrationUrl{
    final endpoint = dotenv.env['REGISTRATION_URL'];
    if(endpoint == null || endpoint.isEmpty){
      throw Exception("REGISTRATION URL not found in the env file");
    }
    return baseUrl + endpoint;
  }
  // getting the login url
  static String get loginUrl{
    final endpoint = dotenv.env['LOGIN_URL'];
    if(endpoint == null || endpoint.isEmpty){
      throw Exception("LOGIN URL not found in the env file");
    }
    return baseUrl + endpoint;
  }
  // retrieves the otp url
  static String get otpUrl{
    final endpoint = dotenv.env['OTP_URL'];
    if(endpoint == null || endpoint.isEmpty){
      throw Exception("OTP URL not found in the env file");
    }
    return baseUrl + endpoint;
  }
  // retrieving the deposit url
  static String get depositUrl{
    final endpoint = dotenv.env['DEPOSIT_URL'];
    if(endpoint == null || endpoint.isEmpty){
      throw Exception("DEPOSIT URL not found in the env file");
    }
    return baseUrl + endpoint;
  }
  // retrieving the withdraw url
  static String get withdrawUrl{
    final endpoint = dotenv.env['WITHDRAW_URL'];
    if(endpoint == null || endpoint.isEmpty){
      throw Exception("WITHDRAW URL not found in the env file");
    }
    return baseUrl + endpoint;
  }
  // retrieves the chnage pin url
  static String get changePinUrl{
    final endpoint = dotenv.env['CHANGE_PIN_URL'];
    if(endpoint == null || endpoint.isEmpty){
      throw Exception("CHNAGE PIN URL not found in the env file");
    }
    return baseUrl + endpoint;
  }
  // Retrieves the refresh url
  static String get dashboardReloadUrl{
    final endpoint = dotenv.env['DASHBOARD_RELOAD_URL'];
    if(endpoint == null || endpoint.isEmpty){
      throw Exception("DASHBOARD_RELOAD_URL not found in the env file");
    }
    return baseUrl + endpoint;
  }

  // this is the deposit/withdraw header only
  static Map<String, String> getTransactionHeaders(String token){
    return{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }
  // getting the headers that will be used in the api
  static Map<String, String> get headers{
    return {
      'Content-Type': 'application/json',
      'ApiKey': apiKey,
      'Accept': 'application/json',
    };
  }
  // header used for the uploads
  static Map<String, String> get multipartHeaders{
    return {
      'ApiKey': apiKey,
      'Accept': 'application/json',
    };
  }
  static void printConfig(){
    print("API Configuration:");
    print("Base URL: $baseUrl");
    print("Validate URL: $validateRegistrationUrl");
    print("Register URL: $registrationUrl");
    print("Login URL: $loginUrl");
    print("API Key: ${apiKey.substring(0, 8)}...");
  }
}
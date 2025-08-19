import 'package:flutter/material.dart';
import 'Screens/registration_screen.dart';
import 'Screens/login_screen.dart';
import 'Screens/forgot_pin_screen.dart';
import 'Screens/otp_verification_screen.dart';
import 'Screens/dashboard_screen.dart';
import 'Screens/user_profile_screen.dart';
import 'Screens/notifications_screen.dart';
import 'Screens/change_pin_screen.dart';
import 'Screens/splash_screen.dart'; 
import 'Config/api_config.dart';
import 'Widgets/inactivity_logout.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();


void main() async{
  // initializing flutter
  WidgetsFlutterBinding.ensureInitialized();
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.addPostFrameCallback((_) async {
    await precacheImage(
      const AssetImage('assets/images/logo.jpg'), 
      binding.rootElement!,
    );
  });
  runApp(const MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
  try{
    await ApiConfig.initialize();
    print(" App initialized successfully");
  } catch(e){
    print("failed to initialize app $e");
  }
   runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InactivityLogout(
      timeout: const Duration(minutes: 3),
      onTimeout: () {
        appNavigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      },
      child: MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1A237E), 
          primary: Color(0xFF1A237E),
          secondary: Color(0xFF303F9F), 
        ),
        primaryColor: Color(0xFF1A237E),
      ),
      routes: {
        '/': (context) => const SplashScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return LoginScreen(
            profileImageBytes: args?['profileImageBytes'],
            profileImageFile: args?['profileImageFile'],
          );
        },
        '/forgot-pin': (context) => const ForgotPinScreen(),
        '/otp-verification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return OTPVerificationScreen(
            email: args?['email'] ?? '',
            mobileNumber: args?['mobileNumber'] ?? '',
            userId: args?['userId'] ?? '',
            loginData: args?['loginData'],
            profileImageBytes: args?['profileImageBytes'],
            profileImageFile: args?['profileImageFile'],
          );
        },
        '/dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return DashboardScreen(
            username: args?['username'] ?? 'User',
            email: args?['email'] ?? 'user@example.com',
            profileImageBytes: args?['profileImageBytes'],
            profileImageFile: args?['profileImageFile'],
          );
        },
        '/profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return UserProfileScreen(
            username: args?['username'] ?? 'User',
            email: args?['email'] ?? 'user@example.com',
            profileImageFile: args?['profileImageFile'],
            profileImageBytes: args?['profileImageBytes'],
          );
        },
        '/change-pin': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ChangePinScreen(
            authToken: args?['authToken'] ?? '',
            isFirstTime: args?['isFirstTime'] ?? false,
            username: args?['username'],
            email: args?['email'],
            loginData: args?['loginData'],
          );
        },
        '/notifications': (context) => const NotificationsScreen(),
      },
      initialRoute: '/',
    ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _navigateToRegistration() {
    Navigator.pushNamed(context, '/register');
  }
  
  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _navigateToRegistration,
            icon: const Icon(Icons.person_add),
            tooltip: 'Go to Registration',
          ),
          IconButton(
            onPressed: _navigateToLogin,
            icon: const Icon(Icons.login),
            tooltip: 'Go to Login',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToRegistration,
              child: const Text('Go to Registration'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _navigateToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
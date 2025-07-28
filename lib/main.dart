import 'package:flutter/material.dart';
import 'Screens/registration_screen.dart';
import 'Screens/login_screen.dart';
import 'Screens/forgot_pin_screen.dart';
import 'Screens/otp_verification_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        // '/': (context) => const MyHomePage(title: 'Flutter Demo Home Page'),
        '/': (context) =>  const RegistrationScreen(),
        '/login': (context) =>  LoginScreen(),
        '/forgot-pin': (context) => const ForgotPinScreen(),
        '/otp-verification': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
            return OTPVerificationScreen(
              email: args?['email'] ?? '',
              mobileNumber: args?['mobileNumber'] ?? '',
            );
},
      },
      initialRoute: '/',
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

  // Function to navigate to registration screen
  void _navigateToRegistration() {
    Navigator.pushNamed(context, '/');
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
        // button to navigate to registration
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
            // button to navigate to registration screen
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
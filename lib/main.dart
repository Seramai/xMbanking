import 'package:flutter/material.dart';
import 'Screens/registration_screen.dart';
import 'Screens/login_screen.dart';

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
      // routes for better navigation management
      routes: {
        '/': (context) => const MyHomePage(title: 'Flutter Demo Home Page'),
        '/registration': (context) => RegistrationScreen(),
        '/login': (context)=> LoginScreen(),
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
    Navigator.pushNamed(context, '/registration');
  }
  void _navigateToLogin(){
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        //button to navigate to registration
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
            //button to navigate to registration screen
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
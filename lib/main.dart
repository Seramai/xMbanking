import 'package:flutter/material.dart';
import 'Screens/registration_screen.dart';

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
      // 🔥 NEW: Added named routes for better navigation management
      routes: {
        '/': (context) => const MyHomePage(title: 'Flutter Demo Home Page'),
        '/registration': (context) => RegistrationScreen(),
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

  // 🔥 NEW: Function to navigate to registration screen
  void _navigateToRegistration() {
    Navigator.pushNamed(context, '/registration');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        //action button to navigate to registration
        actions: [
          IconButton(
            onPressed: _navigateToRegistration,
            icon: const Icon(Icons.person_add),
            tooltip: 'Go to Registration',
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
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Import your Firebase initialization file such as the API key and others.
import 'package:problemm9/screens/homepage.dart';
import 'package:problemm9/screens/login.dart';
import 'package:problemm9/screens/register.dart';
import 'package:problemm9/screens/reminder.dart';
import 'package:problemm9/logo/logo.dart';


void main() async { // the async keyword makes this function run independently without blocking the main flow (other blocks are executed and this takes its time fetching for data)
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase(); // waiting to initialize firebase services before before running my app
  runApp(MyApp());
}

// here i used maps and routes to open classes in the order i prefer for the best flow of this app
// and adding routes helps in navigation
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => Logo(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/reminder': (context) => ReminderScreen(),
        '/homepage': (context) => HomePage(),
      },
    );
  }
}

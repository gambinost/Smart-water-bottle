import 'package:flutter/material.dart';
import 'dart:async'; // allow using some libraries like Timer

class Logo extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<Logo> {
  @override
  // adding a 10 seconds loading time for the logo , before our login page appears

  void initState() {
    super.initState();
    Timer(Duration(seconds: 10), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; //  Retrieves the width of the device’s screen.
    // This is used to scale the image size relative to the screen width , so i can adjust my logo size accordingly.

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, //aligning out column content in the center of the main axis
          children: [
            Text(
              "Smart water bottle",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 62, 55, 62),
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.grey.withOpacity(0.5),
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Image.asset('assets/water_logo.jpg', width: screenWidth * 0.9),
            SizedBox(height: 20),
            CircularProgressIndicator(), // the loading indicator
          ],
        ),
      ),
    );
  }
}

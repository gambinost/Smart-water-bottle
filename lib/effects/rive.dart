import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class MyRiveAnimation extends StatelessWidget {
  const MyRiveAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: RiveAnimation.asset(
          'assets/rive/liquid_download.riv', // Path to your .riv file
          fit: BoxFit.cover,
          // You can use a RiveAnimationController here if needed
        ),
      ),
    );
  }
}

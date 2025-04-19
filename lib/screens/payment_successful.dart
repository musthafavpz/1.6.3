import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' show pi;  // Add this import for pi constant
import 'package:confetti/confetti.dart';
import '../constants.dart';
import 'my_courses.dart';

class PaymentSuccessfulScreen extends StatefulWidget {
  const PaymentSuccessfulScreen({Key? key}) : super(key: key);

  @override
  State<PaymentSuccessfulScreen> createState() => _PaymentSuccessfulScreenState();
}

class _PaymentSuccessfulScreenState extends State<PaymentSuccessfulScreen> {
  late ConfettiController _confettiController;
  late Timer _redirectTimer;
  int _secondsRemaining = 6;

  @override
  void initState() {
    super.initState();
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play();
    
    // Set up timer for auto-redirect
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _redirectTimer.cancel();
          _navigateToMyCourses();
        }
      });
    });
    
    // Ensure we navigate after 6 seconds even if timer fails
    Future.delayed(const Duration(seconds: 6), _navigateToMyCourses);
  }

  void _navigateToMyCourses() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyCoursesScreen()),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _redirectTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon with animation
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // Success message
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: const Text(
                    'Payment Successful!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Thank you message
                Text(
                  'Thank you for your purchase.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Redirect message
                Text(
                  'Redirecting to My Courses in $_secondsRemaining seconds...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Manual redirect button
                ElevatedButton(
                  onPressed: _navigateToMyCourses,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDefaultColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Go to My Courses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Top confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
          
          // Left side confetti
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 0,
              emissionFrequency: 0.05,
              numberOfParticles: 10,
              maxBlastForce: 4,
              minBlastForce: 2,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
          
          // Right side confetti
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi,
              emissionFrequency: 0.05,
              numberOfParticles: 10,
              maxBlastForce: 4,
              minBlastForce: 2,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

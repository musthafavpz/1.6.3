import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' show pi;
import 'package:confetti/confetti.dart';
import '../constants.dart';
import 'tab_screen.dart';

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
    
    // Initialize confetti controller with shorter duration
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
    
    // Ensure we navigate after 6 seconds
    Future.delayed(const Duration(seconds: 6), _navigateToMyCourses);
  }

  void _navigateToMyCourses() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TabsScreen(pageIndex: 2)),
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
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 80,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Success message
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Thank you message
                Text(
                  'Thank you for your purchase.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Redirect message
                Text(
                  'Redirecting to My Courses in $_secondsRemaining seconds...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 25),
                
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
          
          // Single confetti source from top
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 4,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 15,
              gravity: 0.2,
              colors: const [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFF10B981),
                Color(0xFFFFA000),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

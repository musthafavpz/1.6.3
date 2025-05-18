import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:academy_lms_app/screens/notifications_screen.dart'; // Add this import
import 'package:academy_lms_app/screens/ai_assistant.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants.dart';

class AppBarOne extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;
  final dynamic title;
  final dynamic logo;
  final String? currentScreen;
  final String? screenDetails;
  
  const AppBarOne({
    super.key, 
    this.title, 
    this.logo,
    this.currentScreen,
    this.screenDetails,
  }) : preferredSize = const Size.fromHeight(70.0);
    
  @override
  State<AppBarOne> createState() => _AppBarOneState();
}

class _AppBarOneState extends State<AppBarOne> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Get current route name for screen context
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final screenName = widget.currentScreen ?? currentRoute ?? 'Home';
    final screenDetails = widget.screenDetails ?? 'This is the ${widget.title ?? screenName} screen.';
    
    return AppBar(
      backgroundColor: kBackGroundColor,
      toolbarHeight: 70,
      leadingWidth: 160,
      centerTitle: false,
      // Logo on the left
      leading: widget.logo != null
          ? Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Image.asset(
                'assets/images/${widget.logo}',
                height: 35.0,
                width: 140.0,
                fit: BoxFit.contain,
              ),
            )
          : null,
      // Title in the center if no logo
      title: widget.title != null
          ? Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      // Actions on the right side
      actions: [
        // AI Chat icon
        GestureDetector(
          onTap: () {
            // Navigate to AI Assistant screen with current screen context
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIAssistantScreen(
                  currentScreen: screenName,
                  screenDetails: screenDetails,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 18, bottom: 18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // AI Assistant icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
                // Animation dot
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Notification icon
        GestureDetector(
          onTap: () {
            // Navigate to Notifications screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 18, bottom: 18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Notification bell icon
                Icon(
                  Icons.notifications_outlined,
                  size: 26,
                  color: const Color(0xFF6366F1),
                ),
                // Message badge
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

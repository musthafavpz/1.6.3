import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:academy_lms_app/screens/notifications_screen.dart'; // Add this import
import 'package:academy_lms_app/screens/ai_assistant.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import 'package:academy_lms_app/providers/theme_provider.dart';

class AppBarOne extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;
  final dynamic title;
  final dynamic logo;
  final bool useWhiteLogoFilter;
  final String? currentScreen;
  final String? screenDetails;
  
  const AppBarOne({
    super.key, 
    this.title, 
    this.logo,
    this.useWhiteLogoFilter = false,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      toolbarHeight: 70,
      leadingWidth: 80,
      centerTitle: false,
      // Back button
      leading: widget.logo == null ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
        child: GestureDetector(
          child: Card(
            color: Theme.of(context).colorScheme.surface,
            elevation: 0,
            borderOnForeground: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.onSurface,
                size: 18,
              ),
            ),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ) : null,
      // Logo on the left if provided
      title: widget.logo != null
          ? Padding(
              padding: const EdgeInsets.only(left: 0.0),
              child: widget.useWhiteLogoFilter
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      child: Image.asset(
                        'assets/images/${widget.logo}',
                        height: 35.0,
                        width: 140.0,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      'assets/images/${widget.logo}',
                      height: 35.0,
                      width: 140.0,
                      fit: BoxFit.contain,
                    ),
            )
          : widget.title != null
              ? Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                )
              : null,
      // Actions on the right side
      actions: [
        // Dark mode/light mode switch
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: themeProvider.isDarkMode ? const Color(0xFFFFA000) : const Color(0xFF8B5CF6),
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
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

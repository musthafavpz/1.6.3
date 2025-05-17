import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:academy_lms_app/screens/cart.dart'; // Add this import
import 'package:academy_lms_app/screens/notifications_screen.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants.dart';

class AppBarOne extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;
  final dynamic title;
  final dynamic logo;
  const AppBarOne({super.key, this.title, this.logo})
      : preferredSize = const Size.fromHeight(70.0);
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
            padding: const EdgeInsets.only(right: 16.0, top: 18, bottom: 18),
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
        // Cart icon
        GestureDetector(
          onTap: () {
            // Navigate to Cart screen
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ));
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 18, bottom: 18),
            child: Stack(
              fit: StackFit.loose,
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  'assets/icons/shopping-cart 1.svg',
                ),
                // Cart badge code commented out
              ],
            ),
          ),
        )
      ],
    );
  }
}

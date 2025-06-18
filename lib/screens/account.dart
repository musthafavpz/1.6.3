// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../providers/auth.dart';
import '../widgets/custom_text.dart';
import 'account_remove_screen.dart';
import 'certificates_screen.dart';
import 'edit_profile.dart';
import 'notifications_screen.dart';
import 'privacy_policy_screen.dart';
import 'refund_policy_screen.dart';
import 'support_screen.dart';
import 'about_us_screen.dart';
import 'update_password.dart';
import 'faq_screen.dart';
import 'ai_assistant.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _dataUpdated = false;
  SharedPreferences? sharedPreferences;
  Map<String, dynamic>? user;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    getData();
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    setState(() {
      _isLoading = true;
    });

    sharedPreferences = await SharedPreferences.getInstance();
    var userDetails = sharedPreferences!.getString("user");

    if (userDetails != null) {
      try {
        setState(() {
          user = jsonDecode(userDetails);
        });
      } catch (e) {
        print('Error decoding user details: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dataUpdated) {
      getData();
      _dataUpdated = false;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : user == null
              ? const Center(child: Text('No user data available'))
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Profile header with gradient background
                      Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                            ],
                          ),
                            borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Profile Image
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                            Container(
                                padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: CircleAvatar(
                                    radius: 40,
                                backgroundImage: user?['photo'] != null
                                    ? NetworkImage(user!['photo'])
                                    : null,
                                backgroundColor: Colors.white,
                                child: user?['photo'] == null
                                    ? SvgPicture.asset(
                                        'assets/icons/profile_vector.svg',
                                          height: 40,
                                          width: 40,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.grey,
                                          BlendMode.srcIn,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            // Edit Profile Button
                              GestureDetector(
                                onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditPrfileScreen(),
                                  ),
                                );
                                if (result == true) {
                                  setState(() {
                                    _dataUpdated = true;
                                  });
                                }
                              },
                                child: Container(
                                    padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                    shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                      color: Color(0xFF6366F1),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                          user?['name'] ?? 'No Name',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.email_outlined,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          user?['email'] ?? "No email available",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Quick Action Buttons
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                title: "AI Assistant",
                                icon: Icons.smart_toy_rounded,
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  iconColor: const Color(0xFF6366F1),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AIAssistantScreen(
                                        currentScreen: 'Account',
                                        screenDetails: 'This is the Account screen where you can manage your profile and app settings.',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                              const SizedBox(width: 16),
                            Expanded(
                              child: _buildQuickActionButton(
                                title: "Certificates",
                                icon: Icons.verified_user_outlined,
                                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                  iconColor: const Color(0xFF8B5CF6),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CertificatesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Account Settings Section
                        _buildSectionHeader("ACCOUNT SETTINGS"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                          ),
                            color: Colors.white,
                          child: Column(
                            children: [
                              _buildProfileOption(
                                title: 'Edit Profile',
                                icon: Icons.person_outline,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditPrfileScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    setState(() {
                                      _dataUpdated = true;
                                    });
                                  }
                                },
                                  iconColor: const Color(0xFF6366F1),
                              ),
                              _divider(),
                              _buildProfileOption(
                                title: 'Change Password',
                                icon: Icons.lock_outline,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UpdatePassword(),
                                    ),
                                  );
                                },
                                  iconColor: const Color(0xFF8B5CF6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Support Section
                      _buildSectionHeader("SUPPORT"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          child: Column(
                            children: [
                              _buildProfileOption(
                                title: 'Help & Support',
                                icon: Icons.support_agent_outlined,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SupportScreen(),
                                    ),
                                  );
                                },
                                iconColor: const Color(0xFF6366F1),
                              ),
                              _divider(),
                              _buildProfileOption(
                                title: 'FAQ',
                                icon: Icons.help_outline,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FAQScreen(),
                                    ),
                                  );
                                },
                                iconColor: const Color(0xFF8B5CF6),
                              ),
                              _divider(),
                              _buildProfileOption(
                                title: 'Refund Policy',
                                icon: Icons.monetization_on_outlined,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RefundPolicyScreen(),
                                    ),
                                  );
                                },
                                iconColor: const Color(0xFF8B5CF6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // App Settings Section
                        _buildSectionHeader("ABOUT US"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                          ),
                            color: Colors.white,
                          child: Column(
                            children: [
                              _buildProfileOption(
                                title: 'About Us',
                                icon: Icons.info_outline,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AboutUsScreen(),
                                    ),
                                  );
                                },
                                iconColor: const Color(0xFF6366F1),
                                showSubtitle: true,
                                subtitle: "Version 1.3.0",
                              ),
                              _divider(),
                              _buildProfileOption(
                                title: 'Privacy Policy',
                                icon: Icons.privacy_tip_outlined,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PrivacyPolicyScreen(),
                                    ),
                                  );
                                },
                                iconColor: const Color(0xFF8B5CF6),
                              ),
                            ],
                          ),
                        ),
                      ),
 
                      // Account Management Section
                        _buildSectionHeader("ACCOUNT MANAGEMENT"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                          ),
                            color: Colors.white,
                          child: Column(
                            children: [
                              _buildProfileOption(
                                title: 'Delete Account',
                                icon: Icons.delete_outline,
                                onTap: () {
                                  Navigator.of(context).pushNamed(AccountRemoveScreen.routeName);
                                },
                                iconColor: Colors.grey,
                                textColor: Colors.red,
                              ),
                              _divider(),
                              _buildProfileOption(
                                title: 'Log Out',
                                icon: Icons.logout_rounded,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => _buildLogoutDialog(context),
                                  );
                                },
                                iconColor: Colors.red,
                                textColor: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Add bottom padding to avoid overlap with navigation bar
                      const SizedBox(height: 80),
                    ],
                  ),
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              thickness: 0.5,
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
        ],
                ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
              icon,
                size: 28,
              color: iconColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.blue,
    Color textColor = const Color(0xFF374151),
    bool showSubtitle = false,
    String subtitle = "",
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (showSubtitle)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        thickness: 0.5,
        height: 0.5,
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  Widget _buildLogoutDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Log Out?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Are you sure you want to logout?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<Auth>(context, listen: false).logout().then(
                            (_) => Navigator.pushNamedAndRemoveUntil(
                                context, '/home', (r) => false));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

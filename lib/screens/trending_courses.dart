import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../providers/courses.dart';
import '../widgets/appbar_one.dart';
import '../widgets/common_functions.dart';
import 'course_detail.dart';
import 'payment_webview.dart';
import 'tab_screen.dart';

class TrendingCoursesScreen extends StatefulWidget {
  final List courses;
  final String title;
  
  const TrendingCoursesScreen({
    Key? key,
    required this.courses,
    required this.title,
  }) : super(key: key);

  @override
  State<TrendingCoursesScreen> createState() => _TrendingCoursesScreenState();
}

class _TrendingCoursesScreenState extends State<TrendingCoursesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor = isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF8F9FA);
    Color cardColor = isDarkMode ? const Color(0xFF374151) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);
    Color secondaryTextColor = isDarkMode ? Colors.grey[300]! : const Color(0xFF6B7280);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarOne(title: widget.title),
      body: SafeArea(
        child: _isLoading
          ? _buildLoadingShimmer()
          : _buildContent(isDarkMode, cardColor, textColor, secondaryTextColor),
      ),
    );
  }
  
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent(bool isDarkMode, Color cardColor, Color textColor, Color secondaryTextColor) {
    return AnimationLimiter(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: widget.courses.length,
        itemBuilder: (ctx, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildCourseCard(widget.courses[index], isDarkMode, cardColor, textColor, secondaryTextColor),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCourseCard(dynamic course, bool isDarkMode, Color cardColor, Color textColor, Color secondaryTextColor) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          CourseDetailScreen.routeName,
          arguments: course.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                course.title.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: 'Inter',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            
            // Thumbnail Section
            CachedNetworkImage(
              imageUrl: course.thumbnail.toString(),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            ),
            
            // Course Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructor Row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF6366F1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Instructor",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6366F1),
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              course.instructor ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                                fontFamily: 'Inter',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Stats Row
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.average_rating?.toString() ?? '0.0',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              ' (${course.total_reviews ?? 0})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Students
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.numberOfEnrollment ?? 0} students',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Buttons Row
                  Row(
                    children: [
                      // Explore Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              CourseDetailScreen.routeName,
                              arguments: course.id,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF374151) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF6366F1),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Explore',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6366F1),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Buy Now/Enroll Now Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final authToken = (prefs.getString('access_token') ?? '');
                            
                            if (authToken.isNotEmpty) {
                              if (course.isPaid == 1) {
                                final emailPre = prefs.getString('email');
                                final passwordPre = prefs.getString('password');
                                var email = emailPre;
                                var password = passwordPre;
                                DateTime currentDateTime = DateTime.now();
                                int currentTimestamp = (currentDateTime.millisecondsSinceEpoch / 1000).floor();
                                
                                String authToken = 'Basic ${base64Encode(utf8.encode('$email:$password:$currentTimestamp'))}';
                                final url = '$baseUrl/payment/web_redirect_to_pay_fee?auth=$authToken&unique_id=academylaravelbycreativeitem';
                                
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentWebView(url: url),
                                  ),
                                );
                                
                                CommonFunctions.showSuccessToast('Processing payment...');
                                if (!course.is_cart!) {
                                  Provider.of<Courses>(context, listen: false)
                                      .toggleCart(course.id!, false);
                                }
                              } else {
                                // Free course enrollment
                                String url = "$baseUrl/api/free_course_enroll/${course.id}";
                                var response = await http.get(Uri.parse(url), headers: {
                                  'Content-Type': 'application/json',
                                  'Accept': 'application/json',
                                  'Authorization': 'Bearer $authToken',
                                });
                                
                                if (response.statusCode == 200) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const TabsScreen(pageIndex: 1),
                                    ),
                                  );
                                  CommonFunctions.showSuccessToast('Course Successfully Enrolled');
                                } else {
                                  final data = jsonDecode(response.body);
                                  CommonFunctions.showErrorDialog(data['message'], context);
                                }
                              }
                            } else {
                              CommonFunctions.showWarningToast('Please login first');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(isDarkMode ? 0.4 : 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                course.isPaid == 1
                                    ? 'Buy Now'
                                    : 'Enroll Now',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants.dart';
import '../providers/categories.dart';
import '../providers/courses.dart';
import '../widgets/appbar_one.dart';
import '../widgets/common_functions.dart';
import 'course_detail.dart';
import 'courses_screen.dart';
import 'sub_category.dart';
import 'payment_webview.dart';
import 'my_courses.dart';
import 'tab_screen.dart';

class CategoryDetailsScreen extends StatefulWidget {
  static const routeName = '/sub-cat';
  const CategoryDetailsScreen({super.key});

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
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
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final categoryId = routeArgs['category_id'] as int;
    final title = routeArgs['title'];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBarOne(title: title),
      body: SafeArea(
        child: FutureBuilder(
          future: Provider.of<Categories>(context, listen: false).fetchCategoryDetails(categoryId),
          builder: (ctx, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingShimmer();
            } else if (dataSnapshot.error != null) {
              return _buildErrorView();
            } else {
              return _buildContent(categoryId, title);
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 130,
                  height: 18,
                  color: Colors.white,
                ),
                Container(
                  width: 70,
                  height: 18,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100,
                  height: 18,
                  color: Colors.white,
                ),
                Container(
                  width: 80,
                  height: 18,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Retry', style: TextStyle(fontSize: 14)),
            style: TextButton.styleFrom(
              foregroundColor: kDefaultColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(int categoryId, String title) {
    return Consumer<Categories>(
      builder: (context, categoryDetails, child) {
        final loadedCategoryDetail = categoryDetails.getCategoryDetail;
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSectionHeader(
                'Sub Categories',
                'Show all',
                () {
                  Navigator.of(context).pushNamed(
                    SubCategoryScreen.routeName,
                    arguments: {
                      'category_id': categoryId,
                      'title': title,
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSubCategoriesList(loadedCategoryDetail),
              const SizedBox(height: 24),
              _buildSectionHeader(
                'Courses',
                'All courses',
                () {
                  Navigator.of(context).pushNamed(
                    CoursesScreen.routeName,
                    arguments: {
                      'category_id': null,
                      'seacrh_query': null,
                      'type': CoursesPageData.all,
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCoursesList(loadedCategoryDetail),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSectionHeader(String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6366F1),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Row(
            children: [
              Text(
                actionText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSubCategoriesList(dynamic loadedCategoryDetail) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: loadedCategoryDetail.mSubCategory!.length,
        itemBuilder: (ctx, index) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.1 * index, 0.1 * index + 0.5, curve: Curves.easeOut),
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.1 * index, 0.1 * index + 0.5, curve: Curves.easeOut),
                ),
              ),
              child: _buildSubCategoryCard(loadedCategoryDetail, index),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSubCategoryCard(dynamic loadedCategoryDetail, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          CoursesScreen.routeName,
          arguments: {
            'category_id': loadedCategoryDetail.mSubCategory![index].id,
            'search_query': null,
            'type': CoursesPageData.category,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: MediaQuery.of(context).size.width * 0.45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: loadedCategoryDetail.mSubCategory![index].thumbnail.toString(),
                  placeholder: (context, url) => Container(
                    height: 60,
                    width: 60,
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 60,
                    width: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey, size: 18),
                  ),
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loadedCategoryDetail.mSubCategory![index].title.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${loadedCategoryDetail.mSubCategory![index].numberOfCourses.toString()} Courses",
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCoursesList(dynamic loadedCategoryDetail) {
    return AnimationLimiter(
      child: ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loadedCategoryDetail.mCourse!.length,
      itemBuilder: (ctx, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
            child: _buildCourseCard(loadedCategoryDetail, index),
              ),
          ),
        );
      },
      ),
    );
  }
  
  Widget _buildCourseCard(dynamic loadedCategoryDetail, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          CourseDetailScreen.routeName,
          arguments: loadedCategoryDetail.mCourse![index].id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                loadedCategoryDetail.mCourse![index].title.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Inter',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            
            // Thumbnail Section
            CachedNetworkImage(
                imageUrl: loadedCategoryDetail.mCourse![index].thumbnail.toString(),
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
                        child: loadedCategoryDetail.mCourse![index].instructorImage != null &&
                              loadedCategoryDetail.mCourse![index].instructorImage!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CachedNetworkImage(
                                  imageUrl: loadedCategoryDetail.mCourse![index].instructorImage!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF6366F1),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.person,
                                    color: Color(0xFF6366F1),
                                    size: 24,
                                  ),
                                ),
                              )
                            : const Icon(
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
                              loadedCategoryDetail.mCourse![index].instructor.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B5563),
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
                        loadedCategoryDetail.mCourse![index].average_rating.toString(),
                        style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              ' (${loadedCategoryDetail.mCourse![index].total_reviews})',
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
                              '${loadedCategoryDetail.mCourse![index].numberOfEnrollment} students',
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
                              arguments: loadedCategoryDetail.mCourse![index].id,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                              if (loadedCategoryDetail.mCourse![index].isPaid == 1) {
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
                                if (!loadedCategoryDetail.mCourse![index].is_cart!) {
                                  Provider.of<Courses>(context, listen: false)
                                      .toggleCart(loadedCategoryDetail.mCourse![index].id!, false);
                                }
                              } else {
                                // Free course enrollment
                                String url = "$baseUrl/api/free_course_enroll/${loadedCategoryDetail.mCourse![index].id}";
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
                            ),
                            child: Center(
                              child: Text(
                                loadedCategoryDetail.mCourse![index].isPaid == 1
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
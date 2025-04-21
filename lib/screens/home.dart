import 'dart:convert';

import 'package:academy_lms_app/screens/course_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../providers/categories.dart';
import '../providers/courses.dart';
import '../providers/my_courses.dart';
import '../widgets/common_functions.dart';
import 'category_details.dart';
import 'courses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _isInit = true;
  var topCourses = [];
  final searchController = TextEditingController();
  String? userName;
  Map<String, dynamic>? user;
  bool _isLoading = false;
  
  // Single banner data
  final Map<String, dynamic> bannerData = {
    'title': 'Special Offer!',
    'description': 'Get 50% off on all premium courses. Limited time offer!',
    'buttonText': 'CLAIM NOW',
    'gradientColors': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  };

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var userDetails = sharedPreferences.getString("user");

    if (userDetails != null) {
      try {
        setState(() {
          user = jsonDecode(userDetails);
          userName = user?['name'];
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
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {});

      Provider.of<Courses>(context).fetchTopCourses().then((_) {
        setState(() {
          topCourses = Provider.of<Courses>(context, listen: false).topItems;
        });
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  Future<void> refreshList() async {
    try {
      setState(() {});
      await getUserData();
      await Provider.of<Courses>(context, listen: false).fetchTopCourses();
      await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();

      setState(() {
        topCourses = Provider.of<Courses>(context, listen: false).topItems;
      });
    } catch (error) {
      const errorMsg = 'Could not refresh!';
      // ignore: use_build_context_synchronously
      CommonFunctions.showErrorDialog(errorMsg, context);
    }

    return;
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search for courses...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: kDefaultColor),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, color: kDefaultColor),
            onPressed: () {
              // Show filter options
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: InputBorder.none,
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.of(context).pushNamed(
              CoursesScreen.routeName,
              arguments: {
                'category_id': null,
                'seacrh_query': value,
                'type': CoursesPageData.search,
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName != null ? 'Welcome back, ${userName?.split(' ')[0]}!' : 'Welcome back!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'What would you like to learn today?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bannerData['gradientColors'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: bannerData['gradientColors'][0].withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bannerData['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  bannerData['description'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              bannerData['buttonText'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: bannerData['gradientColors'][0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF6366F1),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            CourseDetailScreen.routeName,
            arguments: course.id,
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: MediaQuery.of(context).size.width * .65,
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/images/loading_animated.gif',
                      image: course.thumbnail.toString(),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            course.average_rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Text(
                        course.title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              color: kGreyLightColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.total_reviews} Enrolled',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: kGreyLightColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              color: Color(0xFF6366F1),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Start Learning',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildContinueLearningSection() {
    // If user is not logged in, don't show this section
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Continue Learning', () {
          // Navigate to My Courses screen
        }),
        
        Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: 15),
          child: FutureBuilder(
            future: Provider.of<MyCourses>(context, listen: false).fetchMyCourses(),
            builder: (ctx, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CupertinoActivityIndicator(
                    color: Color(0xFF6366F1),
                  ),
                );
              } else {
                if (dataSnapshot.error != null) {
                  return Center(
                    child: Text('An error occurred: ${dataSnapshot.error}'),
                  );
                } else {
                  return Consumer<MyCourses>(
                    builder: (ctx, myCourseData, _) {
                      // If no courses, don't show this section
                      if (myCourseData.items.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: myCourseData.items.length,
                        itemBuilder: (ctx, index) {
                          final course = myCourseData.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  CourseDetailScreen.routeName,
                                  arguments: course.id,
                                );
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                  color: kWhiteColor,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        course.title.toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 100,
                                              decoration: BoxDecoration(
                                                color: kDefaultColor,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: kDefaultColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Continue',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        50;
    return Container(
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFFF8F9FA), // Lighter background color
      child: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: refreshList,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder(
            future: Provider.of<Categories>(context, listen: false).fetchCategories(),
            builder: (ctx, dataSnapshot) {
              if (dataSnapshot.connectionState == ConnectionState.waiting || _isLoading) {
                return SizedBox(
                  height: height,
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      color: Color(0xFF6366F1),
                    ),
                  ),
                );
              } else {
                if (dataSnapshot.error != null) {
                  return Center(
                    child: Text(dataSnapshot.error.toString()),
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Welcome Message with User Name
                      _buildWelcomeSection(),
                      
                      // Search Bar
                      _buildSearchBar(),
                      
                      // Single Banner
                      _buildSingleBanner(),
                      const SizedBox(height: 10),
                      
                      // Continue Learning Section - Only show if user is logged in and has courses
                      _buildContinueLearningSection(),
                      
                      // Popular Courses Section
                      _buildSectionTitle('Popular Courses', () {
                        Navigator.of(context).pushNamed(
                          CoursesScreen.routeName,
                          arguments: {
                            'category_id': null,
                            'seacrh_query': null,
                            'type': CoursesPageData.all,
                          },
                        );
                      }),
                      
                      Container(
                        height: 255,
                        margin: const EdgeInsets.only(bottom: 15),
                        child: topCourses.isEmpty
                            ? const Center(child: Text('No popular courses available'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: topCourses.length,
                                itemBuilder: (ctx, index) {
                                  return _buildCourseCard(topCourses[index]);
                                },
                              ),
                      ),
                      
                      // Add proper bottom padding for menu tabs
                      const SizedBox(height: 80),
                    ],
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

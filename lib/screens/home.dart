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
  var recentCourses = [];
  var bundles = [];
  dynamic bundleStatus;
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

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var userDetails = sharedPreferences.getString("user");

      if (userDetails != null && userDetails.isNotEmpty) {
        try {
          final decoded = jsonDecode(userDetails);
          if (decoded != null && decoded is Map<String, dynamic>) {
            setState(() {
              user = decoded;
              userName = user?['name'];
            });
          }
        } catch (e) {
          print('Error decoding user details: $e');
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {});

      Provider.of<Courses>(context).fetchTopCourses().then((_) {
        setState(() {
          topCourses = Provider.of<Courses>(context, listen: false).topItems;
          recentCourses = List.from(topCourses.reversed);
        });
      }).catchError((error) {
        print('Error fetching top courses: $error');
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  Future<void> refreshList() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await getUserData();
      
      try {
        await Provider.of<Courses>(context, listen: false).fetchTopCourses();
        setState(() {
          topCourses = Provider.of<Courses>(context, listen: false).topItems;
          recentCourses = List.from(topCourses.reversed);
        });
      } catch (e) {
        print('Error refreshing courses: $e');
      }
      
      try {
        await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
      } catch (e) {
        print('Error refreshing my courses: $e');
      }
    } catch (error) {
      const errorMsg = 'Could not refresh!';
      CommonFunctions.showErrorDialog(errorMsg, context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName != null ? 'Welcome, ${userName?.split(' ')[0]}' : 'Welcome',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What would you like to learn today?',
            style: TextStyle(
              fontSize: 13,
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
              fontSize: 17,
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
          width: MediaQuery.of(context).size.width * .45,
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
                      image: course.thumbnail?.toString() ?? '',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
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
                            course.average_rating?.toString() ?? '0.0',
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
                        course.title?.toString() ?? 'Untitled Course',
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
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          color: kGreyLightColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.total_reviews ?? 0} Enrolled',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: kGreyLightColor,
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
      ),
    );
  }

  Widget _buildContinueLearningCard(dynamic course) {
    final double progressValue = course.progress is double ? course.progress : 0.0;
    
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
          width: MediaQuery.of(context).size.width * .85,
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
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/images/loading_animated.gif',
                  image: course.thumbnail?.toString() ?? '',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title?.toString() ?? 'Untitled Course',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_alt_outlined,
                            color: kGreyLightColor,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.total_reviews ?? 0} Enrolled',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: kGreyLightColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: kGreyLightColor.withOpacity(0.2),
                        color: kDefaultColor,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progressValue * 100).toInt()}% Completed',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kGreyLightColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                CourseDetailScreen.routeName,
                                arguments: course.id,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: kDefaultColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueLearningSection() {
    return Consumer<MyCourses>(
      builder: (context, myCourses, child) {
        // Add safe check for myCourses.items
        final courseItems = myCourses.items ?? [];
        
        if (courseItems.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: kDefaultColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '0 Courses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Continue your learning journey',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: kDefaultColor,
                  radius: 20,
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Continue Learning', () {
              // Navigate to my courses
            }),
            SizedBox(
              height: courseItems.isEmpty ? 0 : 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: courseItems.length,
                itemBuilder: (ctx, index) {
                  return _buildContinueLearningCard(courseItems[index]);
                },
              ),
            ),
            const SizedBox(height: 15),
          ],
        );
      },
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
            future: Future.wait([
              Provider.of<Categories>(context, listen: false).fetchCategories().catchError((e) {
                print('Error fetching categories: $e');
                return null;
              }),
              Provider.of<MyCourses>(context, listen: false).fetchMyCourses().catchError((e) {
                print('Error fetching my courses: $e');
                return null;
              }),
            ]),
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
                // Show specific error message if there's an error
                if (dataSnapshot.hasError) {
                  return SizedBox(
                    height: height,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Error: ${dataSnapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isInit = true;
                                didChangeDependencies();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Welcome Message with User Name - Updated font size and text
                      _buildWelcomeSection(),
                      
                      // Single Banner
                      _buildSingleBanner(),
                      const SizedBox(height: 10),
                      
                      // Continue Learning Section - Fixed to properly show enrolled courses
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
                      
                      Consumer<Courses>(
                        builder: (ctx, coursesData, _) {
                          final courses = coursesData.topItems;
                          return Container(
                            height: 235,
                            margin: const EdgeInsets.only(bottom: 15),
                            child: courses.isEmpty
                                ? const Center(child: Text('No popular courses available'))
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: courses.length,
                                    itemBuilder: (ctx, index) {
                                      return _buildCourseCard(courses[index]);
                                    },
                                  ),
                          );
                        },
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

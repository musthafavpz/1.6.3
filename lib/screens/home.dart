import 'dart:convert';

import 'package:academy_lms_app/screens/course_detail.dart';
import 'package:academy_lms_app/screens/my_course_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? userName;
  Map<String, dynamic>? user;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
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
    } catch (e) {
      print('Error getting user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {});

      try {
        Provider.of<Courses>(context, listen: false).fetchTopCourses().then((_) {
          if (mounted) {
            setState(() {
              topCourses = Provider.of<Courses>(context, listen: false).topItems;
            });
          }
        });
        
        // Fetch user's enrolled courses
        Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
      } catch (e) {
        print('Error in didChangeDependencies: $e');
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  Future<void> refreshList() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
      
      await getUserData();
      
      await Provider.of<Courses>(context, listen: false).fetchTopCourses();
      await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();

      if (mounted) {
        setState(() {
          topCourses = Provider.of<Courses>(context, listen: false).topItems;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error refreshing data: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        const errorMsg = 'Could not refresh!';
        CommonFunctions.showErrorDialog(errorMsg, context);
      }
    }

    return;
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                userName != null ? 'Welcome, $userName ' : 'Welcome ',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Text(
                '👋',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Learn bigger, achieve anything',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
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
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        enabled: false, // Make it non-interactive
        decoration: InputDecoration(
          hintText: 'Search for courses, instructors...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF6366F1),
            size: 22,
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.5), // Dimmed color to indicate non-functional
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCustomBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Banner Image
            Image.asset(
              'assets/images/code_the_ledger.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
            // Join Now Button (positioned bottom right)
            Positioned(
              bottom: 15,
              right: 15,
              child: InkWell(
                onTap: () async {
                  final Uri whatsappUrl = Uri.parse('https://chat.whatsapp.com/IEekUggTZaI77NHW6ruu10');
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not launch WhatsApp'),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Join Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildTrendingCourseCard(dynamic course) {
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
                            'TRENDING',
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

  Widget _buildContinueLearningCard(dynamic myCourse) {
    // Calculate progress percentage
    double progress = myCourse.courseCompletion.toDouble();
    
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          // Updated navigation to use MyCourseDetailScreen instead of CourseDetailScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                return MyCourseDetailScreen(
                  courseId: myCourse.id,
                  enableDripContent: myCourse.enableDripContent.toString(),
                );
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: MediaQuery.of(context).size.width * .75,
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
                      image: myCourse.thumbnail.toString(),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
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
                      height: 36,
                      child: Text(
                        myCourse.title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${progress.toInt()}% Complete',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'CONTINUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.book,
                          color: kGreyLightColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${myCourse.totalNumberOfCompletedLessons}/${myCourse.totalNumberOfLessons} Lessons',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: kGreyLightColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.person,
                          color: kGreyLightColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            myCourse.instructor,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: kGreyLightColor,
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
      ),
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
                  return SizedBox(
                    height: height,
                    child: Center(
                      child: Text('An error occurred: ${dataSnapshot.error}'),
                    ),
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Welcome Message with User Name and Hand Wave
                      _buildWelcomeSection(),
                      
                      // Search Bar - Now static
                      _buildSearchBar(),
                      
                      // Custom Banner with Join Now button
                      _buildCustomBanner(),
                      const SizedBox(height: 15),
                      
                      // Continue Learning Section
                      Consumer<MyCourses>(
                        builder: (ctx, myCourses, _) => myCourses.items.isNotEmpty
                          ? Column(
                              children: [
                                _buildSectionTitle('Continue Learning', () {
                                  // Navigate to all enrolled courses
                                }),
                                Container(
                                  height: 200,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: myCourses.items.length,
                                    itemBuilder: (ctx, index) {
                                      return _buildContinueLearningCard(myCourses.items[index]);
                                    },
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      ),
                      
                      // Trending Courses Section
                      _buildSectionTitle('Trending Courses', () {
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
                            ? const Center(child: Text('No trending courses available'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: topCourses.length,
                                itemBuilder: (ctx, index) {
                                  return _buildTrendingCourseCard(topCourses[index]);
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

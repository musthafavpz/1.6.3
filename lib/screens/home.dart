import 'dart:convert';

import 'package:academy_lms_app/screens/course_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../providers/categories.dart';
import '../providers/courses.dart';
import '../providers/my_courses.dart'; // <-- Import MyCourses provider
import '../widgets/common_functions.dart';
import 'category_details.dart';
import 'courses_screen.dart';
import 'my_courses_screen.dart'; // <-- Import MyCoursesScreen for navigation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _isInit = true;
  var topCourses = [];
  var recentCourses = [];
  // Store filtered in-progress courses
  var inProgressCourses = []; // <-- State variable for in-progress courses
  var bundles = [];
  dynamic bundleStatus;
  final searchController = TextEditingController();
  String? userName;
  Map<String, dynamic>? user;
  // Combined future for loading multiple data sources
  Future<void>? _loadDataFuture; // <-- Future for FutureBuilder

  // Sample data for trending instructors (Keep as is)
  final List<Map<String, dynamic>> trendingInstructors = [
    // ... (keep existing instructor data)
     {
      'name': 'Dr. Sarah Johnson',
      'expertise': 'Data Science',
      'image': 'https://randomuser.me/api/portraits/women/44.jpg',
      'rating': 4.9,
      'courses': 12
    },
    {
      'name': 'Prof. Michael Chen',
      'expertise': 'Web Development',
      'image': 'https://randomuser.me/api/portraits/men/32.jpg',
      'rating': 4.8,
      'courses': 8
    },
    {
      'name': 'Dr. Emily Williams',
      'expertise': 'UX Design',
      'image': 'https://randomuser.me/api/portraits/women/33.jpg',
      'rating': 4.7,
      'courses': 5
    },
    {
      'name': 'John Doe',
      'expertise': 'Mobile Development',
      'image': 'https://randomuser.me/api/portraits/men/44.jpg',
      'rating': 4.6,
      'courses': 10
    },
  ];

  // Single banner data (Keep as is)
  final Map<String, dynamic> bannerData = {
    // ... (keep existing banner data)
     'title': 'Special Offer!',
    'description': 'Get 50% off on all premium courses. Limited time offer!',
    'buttonText': 'CLAIM NOW',
    'gradientColors': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
  };


  @override
  void initState() {
    super.initState();
    // Don't fetch data here, wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      // Assign the combined future to the state variable
      _loadDataFuture = _fetchAllData();
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Centralized function to fetch all necessary data
  Future<void> _fetchAllData() async {
    // Fetch user data first (doesn't need Future.wait usually)
    await getUserData();

    // Use Future.wait for parallel fetching of other data
    await Future.wait([
      Provider.of<Categories>(context, listen: false).fetchCategories(),
      Provider.of<Courses>(context, listen: false).fetchTopCourses(),
      Provider.of<MyCourses>(context, listen: false).fetchMyCourses(), // <-- Fetch MyCourses
    ]);

    // Process data after all fetches are complete
    _processFetchedData();
  }

  // Process data and update state AFTER fetching
  void _processFetchedData() {
     final coursesProvider = Provider.of<Courses>(context, listen: false);
     final myCoursesProvider = Provider.of<MyCourses>(context, listen: false);

     // --- Filter In-Progress Courses ---
     // IMPORTANT: Adjust 'progress' to your actual property name
     // It could be 'completion_percentage / 100.0', '!is_completed', etc.
     final allMyCourses = myCoursesProvider.items;
     final filteredInProgress = allMyCourses.where((course) {
       // Assuming 'progress' is a double between 0.0 and 1.0
       // If you have percentage (0-100), use: course.progress < 100
       // If you have is_completed (bool), use: !course.isCompleted
       // Add a null check if progress can be null
       return course.progress != null && course.progress < 1.0;
     }).toList();
     // --- End Filter ---

    // Update state variables
    setState(() {
      topCourses = coursesProvider.topItems;
      // For demo purposes, use same data but filter differently
      // In production, fetch a different list
      recentCourses = List.from(topCourses.reversed);
      inProgressCourses = filteredInProgress; // <-- Store filtered courses
    });
  }

  Future<void> getUserData() async {
    // No need for _isLoading here if FutureBuilder handles it
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var userDetails = sharedPreferences.getString("user");

    if (userDetails != null) {
      try {
        // Don't call setState here directly, let _fetchAllData handle it
        user = jsonDecode(userDetails);
        userName = user?['name'];
      } catch (e) {
        print('Error decoding user details: $e');
        userName = null; // Reset username on error
        user = null;
      }
    } else {
       userName = null; // Reset if no user details found
       user = null;
    }
  }

  Future<void> refreshList() async {
    try {
      // Re-fetch all data and update the future for the builder
      setState(() {
         _loadDataFuture = _fetchAllData();
      });
      // Wait for the fetch to complete for the refresh indicator
      await _loadDataFuture;
    } catch (error) {
      const errorMsg = 'Could not refresh!';
      // ignore: use_build_context_synchronously
      if (mounted) { // Check if widget is still mounted before showing dialog
       CommonFunctions.showErrorDialog(errorMsg, context);
      }
    }
  }

  // --- Keep existing _buildSearchBar, _buildWelcomeSection, _buildSingleBanner ---
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
            // Use the state variable 'userName' fetched in getUserData
            userName != null ? 'Welcome back, ${userName?.split(' ')[0]}!' : 'Welcome back!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'What would you like to learn today?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666), // Slightly darker grey
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
          // Safely access colors with null check or default
          colors: bannerData['gradientColors'] as List<Color>? ?? [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            // Safely access color with null check or default
            color: (bannerData['gradientColors'] as List<Color>? ?? [Colors.blue])[0].withOpacity(0.2),
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
                  // Use ?? for null safety on banner data
                  bannerData['title'] as String? ?? 'Special Offer!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  bannerData['description'] as String? ?? 'Check out our latest deals.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9), // Slightly transparent
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15), // Add spacing
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              bannerData['buttonText'] as String? ?? 'CLAIM NOW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                 // Safely access color with null check or default
                color: (bannerData['gradientColors'] as List<Color>? ?? [Colors.blue])[0],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // --- Keep existing _buildSectionTitle ---
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


  // --- Keep existing _buildCourseCard, _buildTrendingCourseCard, _buildInstructorCard ---
 Widget _buildCourseCard(dynamic course) {
    // Null check for course data
    if (course == null) return const SizedBox.shrink();

    // Assuming course has properties like id, thumbnail, average_rating, title, total_reviews
    // Add null checks or default values for each property access
    final String thumbnailUrl = course.thumbnail?.toString() ?? 'assets/images/placeholder.png'; // Provide a placeholder path
    final String rating = course.average_rating?.toString() ?? 'N/A';
    final String courseTitle = course.title?.toString() ?? 'Untitled Course';
    final String enrolledCount = course.total_reviews?.toString() ?? '0'; // Assuming total_reviews maps to enrolled count

    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          if (course.id != null) {
            Navigator.of(context).pushNamed(
              CourseDetailScreen.routeName,
              arguments: course.id,
            );
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: MediaQuery.of(context).size.width * .45,
          decoration: BoxDecoration(
            color: kWhiteColor, // Assume kWhiteColor is defined
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
                      placeholder: 'assets/images/loading_animated.gif', // Ensure this asset exists
                      image: thumbnailUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) {
                        // Show placeholder if image fails to load
                        return Image.asset(
                          'assets/images/placeholder.png', // Fallback image asset
                           height: 120,
                           width: double.infinity,
                           fit: BoxFit.cover,
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
                            rating,
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
                      height: 40, // Fixed height might clip longer titles
                      child: Text(
                        courseTitle,
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
                          color: kGreyLightColor, // Assume kGreyLightColor is defined
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$enrolledCount Enrolled',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: kGreyLightColor, // Assume kGreyLightColor is defined
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

  Widget _buildTrendingCourseCard(dynamic course) {
     // Null check for course data
    if (course == null) return const SizedBox.shrink();

    // Add null checks or default values for property access
    final String thumbnailUrl = course.thumbnail?.toString() ?? 'assets/images/placeholder.png';
    final String rating = course.average_rating?.toString() ?? 'N/A';
    final String courseTitle = course.title?.toString() ?? 'Untitled Course';
    final String enrolledCount = course.total_reviews?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          if (course.id != null) {
            Navigator.of(context).pushNamed(
              CourseDetailScreen.routeName,
              arguments: course.id,
            );
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: MediaQuery.of(context).size.width * .65,
          decoration: BoxDecoration(
            color: kWhiteColor, // Assume kWhiteColor is defined
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
                      image: thumbnailUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                       imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/placeholder.png', // Fallback image asset
                           height: 140,
                           width: double.infinity,
                           fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  // TRENDING Tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800), // Use specific color for trending
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
                  // Rating Tag
                   Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1), // Use consistent rating color
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
                            rating,
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
                        courseTitle,
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
                        // Enrolled Count
                        Row(
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              color: kGreyLightColor, // Assume defined
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$enrolledCount Enrolled',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: kGreyLightColor, // Assume defined
                              ),
                            ),
                          ],
                        ),
                        // Start Learning Link (Optional)
                        const Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: Color(0xFF6366F1),
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
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

  Widget _buildInstructorCard(Map<String, dynamic> instructor) {
    // Use ?? for null safety
    final String imageUrl = instructor['image'] as String? ?? 'assets/images/placeholder_avatar.png'; // Provide a placeholder
    final String name = instructor['name'] as String? ?? 'Instructor Name';
    final String expertise = instructor['expertise'] as String? ?? 'Expertise';
    final String rating = (instructor['rating'] as num?)?.toString() ?? 'N/A';
    final String coursesCount = (instructor['courses'] as int?)?.toString() ?? '0';


    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          // Navigate to instructor profile (Implement this)
          print("Navigate to profile of $name");
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: MediaQuery.of(context).size.width * .65,
          decoration: BoxDecoration(
            color: kWhiteColor, // Assume defined
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
            // Ensure Column takes full height if needed, or adjust container height
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30), // Make it circular
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/loading_animated.gif',
                        image: imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/placeholder_avatar.png', // Fallback avatar
                             width: 60,
                             height: 60,
                             fit: BoxFit.cover,
                           );
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600, // Make name bolder
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expertise,
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: kGreyLightColor, // Assume defined
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFAB00), // Gold color for rating
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.book_outline, // Use outline icon
                                color: kGreyLightColor, // Assume defined
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$coursesCount Courses',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kGreyLightColor, // Assume defined
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
              // View Profile Button - ensure it's always at the bottom if Column expands
              // If the container height is fixed, this works. If not, use Spacer or Expanded
               const Spacer(), // Pushes button to bottom if Column expands
               InkWell(
                 onTap: (){
                    // Navigate to instructor profile (Implement this)
                     print("Navigate to profile of $name");
                 },
                 child: Container(
                   width: double.infinity,
                   padding: const EdgeInsets.symmetric(vertical: 10),
                   decoration: const BoxDecoration(
                     color: Color(0xFF6366F1),
                     borderRadius: BorderRadius.only(
                       bottomLeft: Radius.circular(15),
                       bottomRight: Radius.circular(15),
                     ),
                   ),
                   alignment: Alignment.center,
                   child: const Text(
                     'View Profile',
                     style: TextStyle(
                       color: Colors.white,
                       fontWeight: FontWeight.w500,
                       fontSize: 13,
                     ),
                   ),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
 // --- End Keep existing cards ---


  // --- NEW WIDGET: Card for "Continue Learning" ---
  Widget _buildContinueLearningCard(dynamic course) {
    // Add null checks and default values
    final String thumbnailUrl = course.thumbnail?.toString() ?? 'assets/images/placeholder.png';
    final String courseTitle = course.title?.toString() ?? 'Untitled Course';
    // Ensure progress is a double between 0.0 and 1.0
    final double progress = (course.progress as num?)?.toDouble() ?? 0.0;
    // Clamp progress value just in case
    final double clampedProgress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          if (course.id != null) {
            Navigator.of(context).pushNamed(
              CourseDetailScreen.routeName, // Or specific screen to resume course
              arguments: course.id,
            );
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: MediaQuery.of(context).size.width * .60, // Slightly wider? Adjust as needed
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
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/images/loading_animated.gif',
                  image: thumbnailUrl,
                  height: 120, // Adjust height as needed
                  width: double.infinity,
                  fit: BoxFit.cover,
                   imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/placeholder.png', // Fallback image asset
                           height: 120,
                           width: double.infinity,
                           fit: BoxFit.cover,
                        );
                      },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40, // Fixed height for title consistency
                      child: Text(
                        courseTitle,
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
                    // Progress Indicator
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                             borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: clampedProgress,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                              minHeight: 6, // Adjust thickness
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(clampedProgress * 100).toStringAsFixed(0)}%', // Display percentage
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5), // Optional extra spacing
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- End Continue Learning Card ---


  @override
  Widget build(BuildContext context) {
    // Calculate height once if needed, though maybe not necessary here
    // final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: const Color(0xFFF8F9FA), // Lighter background color
      child: RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: refreshList,
        child: FutureBuilder(
          // Use the state future variable
          future: _loadDataFuture,
          builder: (ctx, dataSnapshot) {
            // --- Loading State ---
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CupertinoActivityIndicator(
                  color: Color(0xFF6366F1),
                ),
              );
            }
            // --- Error State ---
            else if (dataSnapshot.error != null) {
              print('Error loading home screen data: ${dataSnapshot.error}'); // Log error
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.error_outline, color: Colors.red, size: 40),
                     const SizedBox(height: 10),
                     const Text(
                       'Failed to load data.',
                       style: TextStyle(fontSize: 16),
                       textAlign: TextAlign.center,
                       ),
                     const SizedBox(height: 10),
                     ElevatedButton(
                       style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF6366F1),
                           foregroundColor: Colors.white),
                       onPressed: () {
                         // Trigger refresh on error button press
                         setState(() {
                           _loadDataFuture = _fetchAllData();
                         });
                       },
                       child: const Text('Retry'),
                     )
                   ],
                 ),
               );
            }
            // --- Data Loaded State ---
            else {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Welcome Message with User Name
                    _buildWelcomeSection(),

                    // Search Bar
                    _buildSearchBar(),

                    // Single Banner instead of slider
                    _buildSingleBanner(),
                    const SizedBox(height: 10),

                    // --- NEW: Continue Learning Section (Conditional) ---
                    if (inProgressCourses.isNotEmpty) ...[
                      _buildSectionTitle('Continue Learning', () {
                        // Navigate to My Courses screen
                        Navigator.of(context).pushNamed(MyCoursesScreen.routeName);
                      }),
                      Container(
                        height: 215, // Adjust height based on card content
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          // Limit items or show all inProgressCourses
                          itemCount: inProgressCourses.length,
                          itemBuilder: (ctx, index) {
                            return _buildContinueLearningCard(inProgressCourses[index]);
                          },
                        ),
                      ),
                    ],
                    // --- End Continue Learning Section ---

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
                      height: 255, // Keep original heights or adjust
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

                    // Trending Instructors Section
                    _buildSectionTitle('Trending Instructors', () {
                      // Navigate to all instructors page (Implement this)
                       print("Navigate to all instructors");
                    }),
                    Container(
                      height: 190, // Adjusted height slightly for better button visibility
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: trendingInstructors.length,
                        itemBuilder: (ctx, index) {
                          return _buildInstructorCard(trendingInstructors[index]);
                        },
                      ),
                    ),

                    // Featured Courses Section
                    _buildSectionTitle('Featured Courses', () {
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
                      height: 235, // Keep original heights or adjust
                      margin: const EdgeInsets.only(bottom: 15),
                      child: topCourses.isEmpty
                          ? const Center(child: Text('No courses available'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: topCourses.length,
                              itemBuilder: (ctx, index) {
                                return _buildCourseCard(topCourses[index]);
                              },
                            ),
                    ),

                    // Recently Added Courses Section
                    _buildSectionTitle('Recently Added', () {
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
                      height: 235, // Keep original heights or adjust
                      margin: const EdgeInsets.only(bottom: 15),
                      child: recentCourses.isEmpty
                          ? const Center(child: Text('No recent courses available'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: recentCourses.length,
                              itemBuilder: (ctx, index) {
                                return _buildCourseCard(recentCourses[index]);
                              },
                            ),
                    ),

                    // Add proper bottom padding for menu tabs
                    const SizedBox(height: 80),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

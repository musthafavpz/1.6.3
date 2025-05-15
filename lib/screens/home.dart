import 'dart:convert';

import 'package:academy_lms_app/screens/course_detail.dart';
import 'package:academy_lms_app/screens/my_course_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  var _isInit = true;
  var topCourses = [];
  String? userName;
  Map<String, dynamic>? user;
  bool _isLoading = false;
  
  // Animation controllers
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    getUserData();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
    
    // Only forward the animation if the widget is still mounted
    if (mounted) {
      _animationController!.forward();
    }
    
    // Immediately refresh data when screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        refreshList();
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
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
              
              // Sort courses by enrollment count (descending order)
              topCourses.sort((a, b) {
                // Get enrollment count, handling different possible field names
                int aEnrollment = _parseEnrollmentCount(a);
                int bEnrollment = _parseEnrollmentCount(b);
                
                // Sort in descending order (higher enrollment first)
                return bEnrollment.compareTo(aEnrollment);
              });
            });
          }
        });
        
        // Fetch top instructors
        Provider.of<Courses>(context, listen: false).fetchTopInstructors();
        
        // Fetch user's enrolled courses
        Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
      } catch (e) {
        print('Error in didChangeDependencies: $e');
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // Helper method to safely parse enrollment count from various possible fields and types
  int _parseEnrollmentCount(dynamic course) {
    // Try numberOfEnrollment first
    if (course.numberOfEnrollment != null) {
      if (course.numberOfEnrollment is int) {
        return course.numberOfEnrollment;
      } else {
        try {
          return int.parse(course.numberOfEnrollment.toString());
        } catch (e) {
          // Could not parse, continue to next field
        }
      }
    }
    
    // Try totalEnrollment second
    if (course.totalEnrollment != null) {
      if (course.totalEnrollment is int) {
        return course.totalEnrollment;
      } else {
        try {
          return int.parse(course.totalEnrollment.toString());
        } catch (e) {
          // Could not parse, continue to next field
        }
      }
    }
    
    // Try total_reviews as fallback
    if (course.total_reviews != null) {
      if (course.total_reviews is int) {
        return course.total_reviews;
      } else {
        try {
          return int.parse(course.total_reviews.toString());
        } catch (e) {
          // Could not parse
          return 0;
        }
      }
    }
    
    return 0;
  }

  Future<void> refreshList() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
      
      await getUserData();
      
      await Provider.of<Courses>(context, listen: false).fetchTopCourses();
      await Provider.of<Courses>(context, listen: false).fetchTopInstructors();
      await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();

      if (mounted) {
        setState(() {
          topCourses = Provider.of<Courses>(context, listen: false).topItems;
          
          // Sort courses by enrollment count (descending order)
          topCourses.sort((a, b) {
            // Use the helper method to parse enrollment counts
            int aEnrollment = _parseEnrollmentCount(a);
            int bEnrollment = _parseEnrollmentCount(b);
            
            // Sort in descending order (higher enrollment first)
            return bEnrollment.compareTo(aEnrollment);
          });
          
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
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: Row(
        children: [
          // Avatar/Profile Circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName != null && userName!.isNotEmpty 
                    ? userName![0].toUpperCase() 
                    : "G",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Text content
          Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                      'Hello, ',
                style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Text(
                      userName != null ? '$userName!' : 'there!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              const Text(
                      ' 👋',
                style: TextStyle(
                        fontSize: 16,
                ),
              ),
            ],
          ),
                const SizedBox(height: 5),
          const Text(
                  'Ready to continue your learning journey?',
            style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          width: 2,
            color: const Color(0xFF6366F1),
          ),
            ),
      child: Container(
        decoration: BoxDecoration(
              color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            width: 1,
            color: const Color(0xFF8B5CF6),
          ),
        ),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Code the Ledger',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'From Journal Entries to Neural Networks',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Learning AI',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Enroll Now Button
                              InkWell(
                onTap: () async {
                                  final Uri enrollUrl = Uri.parse('https://chat.whatsapp.com/IEekUggTZaI77NHW6ruu10');
                                  if (await canLaunchUrl(enrollUrl)) {
                                    await launchUrl(enrollUrl, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                                          content: Text('Could not open enrollment link'),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.3),
                                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                                    'Enroll Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Preview Button
                              InkWell(
                                onTap: () {
                                  _showVideoPreview(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0xFF6366F1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.play_circle_outline,
                      color: Color(0xFF6366F1),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Preview',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ],
                ),
              ),
            ),
          ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Image.asset(
                          'assets/images/ai_banner.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.code,
                            size: 80,
                            color: Color(0xFF6366F1),
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
      ),
    );
  }

  void _showVideoPreview(BuildContext context) {
    // YouTube video ID extracted from the full URL
    const String videoId = 'npSt5pUexhg';
    
    // Controller for the WebView
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // You could show a loading indicator here
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            // Handle any errors that occur while loading the web page
          },
        ),
      )
      // Load YouTube iframe HTML
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body { margin: 0; padding: 0; background-color: #000; }
              iframe { width: 100%; height: 100vh; border: none; }
            </style>
          </head>
          <body>
            <iframe 
              src="https://www.youtube.com/embed/$videoId?autoplay=1&rel=0" 
              frameborder="0" 
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
              allowfullscreen>
            </iframe>
          </body>
        </html>
      ''');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
      width: double.infinity,
            height: 300, // Increased height for better viewing
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Video Title Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
      child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Code the Ledger - Preview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // WebView for embedded YouTube
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: WebViewWidget(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
                  fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
                  ),
                ],
              ),
          const SizedBox(height: 5),
          Container(
            width: 35,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCourseCard(dynamic course) {
    // Calculate star rating
    final rating = course.average_rating is String 
        ? double.tryParse(course.average_rating) ?? 0.0
        : (course.average_rating ?? 0.0).toDouble();
    
    // Build star rating
    List<Widget> buildRatingStars() {
      List<Widget> stars = [];
      for (int i = 1; i <= 5; i++) {
        stars.add(
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            color: const Color(0xFFFFA000),
            size: 14,
          ),
        );
      }
      return stars;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            CourseDetailScreen.routeName,
            arguments: course.id,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * .65,
          height: 280,
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'course_${course.id}',
                    child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                    ),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/images/loading_animated.gif',
                      image: course.thumbnail.toString(),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                            ),
                          ),
                        ],
                      ),
              Expanded(
                child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Course Title
                      Text(
                        course.title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Instructor Name
                      Text(
                        course.instructor ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                      
                      // Star Rating and Enrollment Count
                    Row(
                      children: [
                          ...buildRatingStars(),
                          const SizedBox(width: 5),
                            Text(
                            '(${_parseEnrollmentCount(course)})',
                              style: const TextStyle(
                              fontSize: 12,
                                fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      
                      // Price
                      Text(
                        course.price.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                              ),
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

  Widget _buildContinueLearningCard(dynamic myCourse) {
    // Calculate progress percentage
    double progress = (myCourse.courseCompletion ?? 0).toDouble();
    
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * .75,
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 140),
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular progress indicator
              Container(
                width: 80,
                height: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                    borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular progress indicator
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 5,
                      ),
                    ),
                    // Progress percentage text
                    Text(
                      '${progress.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ),
              // Course information
              Expanded(
                child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      Text(
                        myCourse.title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                    Row(
                      children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.book,
                              color: Color(0xFF6366F1),
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${myCourse.totalNumberOfCompletedLessons ?? 0}/${myCourse.totalNumberOfLessons ?? 0} Lessons',
                          style: const TextStyle(
                                fontSize: 12,
                            fontWeight: FontWeight.w500,
                                color: kGreyLightColor,
                                overflow: TextOverflow.ellipsis,
                          ),
                        ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          ),
                          child: const Row(
                          mainAxisSize: MainAxisSize.min,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build trending instructor card
  Widget _buildTrendingInstructorCard(Map<String, dynamic> instructor) {
    // Generate a unique gradient color based on instructor name
    final List<List<Color>> gradientColors = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Purple
      [const Color(0xFF10B981), const Color(0xFF059669)], // Green
      [const Color(0xFFEF4444), const Color(0xFFDC2626)], // Red
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue
    ];
    
    // Use a simple hash function to get a consistent color for each instructor
    final int nameHash = instructor['name'].toString().hashCode.abs();
    final colorIndex = nameHash % gradientColors.length;
    final gradientColor = gradientColors[colorIndex];
    
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          // Future implementation: Show instructor profile or courses by this instructor
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                gradientColor[0].withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColor[0].withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: gradientColor[0].withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instructor badge - small icon showing trending
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColor,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColor[0].withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Text(
                    "TOP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Circular instructor avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColor,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientColor[0].withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: instructor['image'] != null && instructor['image'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/images/loading_animated.gif',
                          image: instructor['image'].toString(),
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                instructor['name'].toString()[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          instructor['name'].toString()[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              
                    const SizedBox(height: 8),
              
              // Instructor Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  instructor['name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gradientColor[0],
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Student count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gradientColor[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(
                      Icons.person,
                      size: 10,
                      color: gradientColor[0],
                    ),
                    const SizedBox(width: 2),
                        Text(
                      '${instructor['totalEnrollment']}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: gradientColor[0],
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

  // Build course card with free/paid badge
  Widget _buildCourseCardWithBadge(dynamic course, bool isFreeCourse) {
    // Calculate star rating
    final rating = course.average_rating is String 
        ? double.tryParse(course.average_rating) ?? 0.0
        : (course.average_rating ?? 0.0).toDouble();
    
    // Build star rating
    List<Widget> buildRatingStars() {
      List<Widget> stars = [];
      for (int i = 1; i <= 5; i++) {
        stars.add(
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            color: const Color(0xFFFFA000),
            size: 14,
          ),
        );
      }
      return stars;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            CourseDetailScreen.routeName,
            arguments: course.id,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * .65,
          height: 280,
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Course thumbnail image
                  Hero(
                    tag: 'course_${course.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/loading_animated.gif',
                        image: course.thumbnail.toString(),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) => Container(
                          height: 140,
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFF6366F1),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Free/Paid badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isFreeCourse
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: isFreeCourse
                                ? const Color(0xFF10B981).withOpacity(0.3)
                                : const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isFreeCourse ? 'FREE' : 'PREMIUM',
                          style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                        Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Title
                      Text(
                        course.title.toString(),
                        maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Instructor Name
                      Text(
                        course.instructor ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                              fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Star Rating and Enrollment Count
                      Row(
                        children: [
                          ...buildRatingStars(),
                          const SizedBox(width: 5),
                          Text(
                            '(${_parseEnrollmentCount(course)})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                      const SizedBox(height: 8),
                      
                      // Price
                      Text(
                        course.price.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isFreeCourse ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                        ),
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
        child: FadeTransition(
          opacity: _fadeAnimation!,
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
                    // Filter courses by free/paid status
                    final freeCourses = topCourses.where((course) => course.isPaid == 0).toList();
                    final paidCourses = topCourses.where((course) => course.isPaid == 1).toList();
                    
                    // Create a list of new courses (sorted by ID, assuming higher IDs are newer courses)
                    final newAddedCourses = List.from(topCourses);
                    newAddedCourses.sort((a, b) => b.id!.compareTo(a.id!));
                    final latestCourses = newAddedCourses.take(8).toList(); // Take top 8 newest courses
                    
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Welcome Message with User Name and Hand Wave
                      _buildWelcomeSection(),
                      
                      // Custom Banner with Join Now button
                      _buildCustomBanner(),
                      const SizedBox(height: 15),
                      
                      // Continue Learning Section
                      Consumer<MyCourses>(
                          builder: (ctx, myCourses, _) {
                            // Filter out courses with 100% completion
                            final inProgressCourses = myCourses.items
                                .where((course) => (course.courseCompletion ?? 0) < 100)
                                .toList();
                                
                            return inProgressCourses.isNotEmpty
                          ? Column(
                              children: [
                                    _buildSectionTitle('Continue Learning'),
                                Container(
                                      height: 120,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    scrollDirection: Axis.horizontal,
                                        itemCount: inProgressCourses.length,
                                    itemBuilder: (ctx, index) {
                                          return _buildContinueLearningCard(inProgressCourses[index]);
                                    },
                                  ),
                                ),
                              ],
                            )
                              : const SizedBox.shrink();
                          },
                      ),
                      
                      // Trending Courses Section
                        _buildSectionTitle('Trending Courses'),
                      
                      Container(
                          height: 280,
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
                        _buildSectionTitle('Trending Instructors'),
                        
                        Container(
                          height: 140,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Consumer<Courses>(
                            builder: (ctx, coursesData, _) {
                              final instructors = coursesData.topInstructors;
                              return instructors.isEmpty
                                ? const Center(child: Text('No trending instructors available'))
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: instructors.length > 5 ? 5 : instructors.length, // Limit to top 5
                                    itemBuilder: (ctx, index) {
                                      return _buildTrendingInstructorCard(instructors[index]);
                                    },
                                  );
                            },
                          ),
                        ),
                        
                        // Free Courses Section
                        if (freeCourses.isNotEmpty) ...[
                          _buildSectionTitle('Free Courses'),
                          Container(
                            height: 280,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: freeCourses.length,
                              itemBuilder: (ctx, index) {
                                return _buildCourseCardWithBadge(freeCourses[index], true);
                              },
                            ),
                          ),
                        ],
                        
                        // Paid Courses Section
                        if (paidCourses.isNotEmpty) ...[
                          _buildSectionTitle('Premium Courses'),
                          Container(
                            height: 280,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: paidCourses.length,
                              itemBuilder: (ctx, index) {
                                return _buildCourseCardWithBadge(paidCourses[index], false);
                              },
                            ),
                          ),
                        ],
                        
                        // New Added Courses Section
                        if (latestCourses.isNotEmpty) ...[
                          _buildSectionTitle('New Added Courses'),
                          Container(
                            height: 280,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: latestCourses.length,
                              itemBuilder: (ctx, index) {
                                final course = latestCourses[index];
                                return Stack(
                                  children: [
                                    _buildTrendingCourseCard(course),
                                    Positioned(
                                      top: 10,
                                      left: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFEF4444),
                                              Color(0xFFDC2626),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(20),
                                            bottomRight: Radius.circular(20),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFFEF4444),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'NEW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      
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
      ),
    );
  }
}


// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:academy_lms_app/models/course_detail.dart';
import 'package:academy_lms_app/screens/payment_webview.dart';
import 'package:academy_lms_app/screens/tab_screen.dart';
import 'package:academy_lms_app/widgets/from_vimeo_player.dart';
import 'package:academy_lms_app/widgets/new_youtube_player.dart';
import 'package:academy_lms_app/widgets/no_preview_video.dart';
import 'package:academy_lms_app/screens/webview_screen_iframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:pod_player/pod_player.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../providers/courses.dart';
import '../widgets/appbar_one.dart';
import '../widgets/common_functions.dart';
import '../widgets/from_network.dart';
import '../widgets/lesson_list_item.dart';
import '../widgets/tab_view_details.dart';
import '../widgets/util.dart';
import 'filter_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  static const routeName = '/course-details';
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? selected;
  dynamic token;
  bool _isInit = true;
  bool _isAuth = false;
  bool _isLoading = false;
  bool isLoading = false;
  dynamic courseId;
  CourseDetail? loadedCourseDetail;
  var msg = 'Removed from cart';
  var msg2 = 'Added to cart';
  var msg1 = 'please tap again to Buy Now';
  
  // Video player controllers
  PodPlayerController? _podController;
  bool isVideoLoaded = false;

  getEnroll(String course_id) async {
    setState(() {
      isLoading = true;
    });
    String url = "$baseUrl/api/free_course_enroll/$course_id";
    var navigator = Navigator.of(context);
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    token = sharedPreferences.getString("access_token");
    var response = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    print(url);
    print(token);

    final data = jsonDecode(response.body);
    // print(data['message']);
    // print(response.body);
    if (response.statusCode == 200) {
      navigator.pushReplacement(
        MaterialPageRoute(
            builder: (context) => TabsScreen(
                  pageIndex: 1,
                )),
      );
      setState(() {
        isLoading = false;
      });
    } else {
      Fluttertoast.showToast(msg: data['message']);
    }
    setState(() {
      isLoading = false;
    });
  }

  void _initializeVideoPlayer(String videoUrl) {
    // Clean up old controller if exists
    _podController?.dispose();
    
    if (videoUrl.isNotEmpty) {
      setState(() {
        isVideoLoaded = false;
      });
      
      // Initialize the new controller
      _podController = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(videoUrl),
      )..initialise().then((_) {
        if (mounted) {
          setState(() {
            isVideoLoaded = true;
          });
        }
      });
    }
  }

  void _openVideoPlayer(String videoUrl, String type) {
    if (type == "youtube") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => YoutubeVideoPlayerFlutter(
            courseId: loadedCourseDetail?.courseId ?? 0,
            videoUrl: videoUrl,
                ),
              ),
            );
    } else if (type == "drive") {
            final RegExp regExp = RegExp(r'[-\w]{25,}');
      final Match? match = regExp.firstMatch(videoUrl);
            if (match != null) {
              String iframeUrl = "https://drive.google.com/file/d/${match.group(0)}/preview";
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreenIframe(url: iframeUrl),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoPreviewVideo(),
                ),
              );
            }
    } else if (type == "vimeo") {
      String vimeoVideoId = videoUrl.split('/').last;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FromVimeoPlayer(
            courseId: loadedCourseDetail?.courseId ?? 0,
                  vimeoVideoId: vimeoVideoId
                ),
              )
            );
    } else if (type == "mp4") {
      _initializeVideoPlayer(videoUrl);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoPreviewVideo(),
        ),
      );
    }
  }

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    // Set the default orientation to portrait at the start
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    if (_isInit) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        token = (prefs.getString('access_token') ?? '');
      });
      setState(() {
        _isLoading = true;
        if (token != null && token.isNotEmpty) {
          _isAuth = true;
        } else {
          _isAuth = false;
        }
      });

      courseId = ModalRoute.of(context)!.settings.arguments as int;

      Provider.of<Courses>(context, listen: false)
          .fetchCourseDetailById(courseId)
          .then((_) {
        final courseDetail = Provider.of<Courses>(context, listen: false).getCourseDetail;
        loadedCourseDetail = courseDetail;
        setState(() {
          _isLoading = false;
        });
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _podController?.dispose();
    // Reset orientation when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // Helper widget to create stat items for course overview
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
                    Text(
          title,
                                  style: TextStyle(
            fontSize: 18,
                        fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          subtitle,
                                    style: TextStyle(
                                      fontSize: 13,
            color: Colors.grey.shade600,
                      ),
                    ),
            ],
        );
    }

  // Add helper function to calculate total duration for a section
  String _calculateTotalDuration(dynamic section) {
    if (section.mLesson == null || section.mLesson!.isEmpty) {
      return '0m';
    }
    
    int totalMinutes = 0;
    int totalHours = 0;
    
    for (final lesson in section.mLesson!) {
      if (lesson.duration != null && lesson.duration!.isNotEmpty) {
        // Parse duration strings like "12m", "1h 30m", etc.
        String duration = lesson.duration!;
        
        RegExp hourRegex = RegExp(r'(\d+)h');
        RegExp minuteRegex = RegExp(r'(\d+)m');
        
        // Extract hours
        final hourMatch = hourRegex.firstMatch(duration);
        if (hourMatch != null && hourMatch.groupCount >= 1) {
          totalHours += int.tryParse(hourMatch.group(1) ?? '0') ?? 0;
        }
        
        // Extract minutes
        final minuteMatch = minuteRegex.firstMatch(duration);
        if (minuteMatch != null && minuteMatch.groupCount >= 1) {
          totalMinutes += int.tryParse(minuteMatch.group(1) ?? '0') ?? 0;
        }
      }
    }
    
    // Convert excess minutes to hours
    totalHours += totalMinutes ~/ 60;
    totalMinutes = totalMinutes % 60;
    
    // Format the result
    if (totalHours > 0) {
      return totalMinutes > 0 ? '${totalHours}h ${totalMinutes}m' : '${totalHours}h';
    } else {
      return '${totalMinutes}m';
    }
  }

  // Helper function to get appropriate icon for lesson type
  IconData _getLessonIcon(String lessonType) {
    switch (lessonType.toLowerCase()) {
      case 'video':
      case 'youtube':
      case 'vimeo-url':
      case 'system-video':
        return Icons.play_circle_outline;
      case 'text':
        return Icons.article_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'pdf':
      case 'document_type':
        return Icons.insert_drive_file_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'iframe':
        return Icons.web_outlined;
      default:
        return Icons.play_lesson;
    }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarOne(logo: 'light_logo.png'),
      body: Container(
        height: MediaQuery.of(context).size.height * 1,
        color: const Color(0xFFF8F9FA),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kDefaultColor),
              )
            : Consumer<Courses>(builder: (context, courses, child) {
                CourseDetail loadedCourseDetails;
                
                try {
                  loadedCourseDetails = courses.getCourseDetail;
                  loadedCourseDetail = loadedCourseDetails;
                } catch (e) {
                  // If there's an error, show an error message
                  return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        SizedBox(height: 16),
                    Text(
                          'Failed to load course details',
                          style: TextStyle(
                            fontSize: 18,
                        fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please try again later',
                      style: TextStyle(
                        fontSize: 16,
                            color: Colors.grey,
                      ),
                    ),
            ],
          ),
        );
                }
                
                // Extract video URL for preview
                String? previewUrl = loadedCourseDetails.preview;
                
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Course thumbnail with play button
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(
                                        loadedCourseDetails.thumbnail.toString(),
                                      ),
                                    ),
                                    color: Colors.black,
                                  ),
                                ),
                                
                                // Video player overlay or play button
                                if (isVideoLoaded && _podController != null)
                                  Container(
                                    width: double.infinity,
                                    height: 220,
                                    child: PodVideoPlayer(
                                      controller: _podController!,
                                      podProgressBarConfig: const PodProgressBarConfig(
                                        playingBarColor: Color(0xFF6366F1),
                                        circleHandlerColor: Color(0xFF6366F1),
                                        backgroundColor: Colors.grey,
                                      ),
                                    ),
                                  )
                                else if (previewUrl != null && previewUrl.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                      if (previewUrl.contains("youtube.com") || previewUrl.contains("youtu.be")) {
                                      _openVideoPlayer(previewUrl, "youtube");
                                      } else if (previewUrl.contains("drive.google.com")) {
                                      _openVideoPlayer(previewUrl, "drive");
                                      } else if (previewUrl.contains("vimeo.com")) {
                                      _openVideoPlayer(previewUrl, "vimeo");
                                      } else if (RegExp(r"\.mp4(\?|$)").hasMatch(previewUrl) || 
                                                RegExp(r"\.webm(\?|$)").hasMatch(previewUrl) || 
                                                RegExp(r"\.ogg(\?|$)").hasMatch(previewUrl)) {
                                      _openVideoPlayer(previewUrl, "mp4");
                                    } else {
                                      _openVideoPlayer(previewUrl, "other");
                                    }
                                  },
                                  child: Container(
                                      width: 60,
                                      height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                        padding: const EdgeInsets.all(15.0),
                                      child: Image.asset(
                                        'assets/images/play.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Course tabs - now full width and with removed space above
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 0), // Removed space above
                              margin: const EdgeInsets.symmetric(horizontal: 0),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(horizontal: 0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(0), // Remove rounded corners at top
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TabBar(
                                          controller: _tabController,
                                          indicatorSize: TabBarIndicatorSize.tab,
                                          indicator: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF6366F1),
                                            Color(0xFF8B5CF6),
                                          ],
                                        ),
                                          ),
                                          unselectedLabelStyle: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                          labelStyle: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: kWhiteColor,
                                          ),
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                          dividerHeight: 0,
                                          tabs: const <Widget>[
                                            Tab(
                                              child: Text(
                                                "About",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Tab(
                                              child: Text(
                                                "Lessons",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                    ),
                                        ),
                                        Container(
                                    width: double.infinity, // Full width
                                          constraints: BoxConstraints(
                                            minHeight: 200,
                                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                                          ),
                                          padding: const EdgeInsets.only(top: 20),
                                          child: TabBarView(
                                            controller: _tabController,
                                            children: [
                                              // About Tab
                                              SingleChildScrollView(
                                          child: Container(
                                            width: double.infinity, // Full width
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Course Title
                                                    Text(
                                                      loadedCourseDetails.title.toString(),
                                                      style: const TextStyle(
                                                    fontSize: 22,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 15),
                                                    
                                                // Instructor information
                                                if (loadedCourseDetails.instructor != null && 
                                                   loadedCourseDetails.instructor!.isNotEmpty)
                                                  Container(
                                                    margin: const EdgeInsets.only(bottom: 10),
                                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF6366F1).withOpacity(0.05),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: const Color(0xFF6366F1).withOpacity(0.2),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF6366F1).withOpacity(0.1),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: loadedCourseDetails.instructorImage != null &&
                                                                loadedCourseDetails.instructorImage!.isNotEmpty
                                                            ? ClipRRect(
                                                                borderRadius: BorderRadius.circular(20),
                                                                child: Image.network(
                                                                  loadedCourseDetails.instructorImage!,
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return const Icon(
                                                                      Icons.person,
                                                                      color: Color(0xFF6366F1),
                                                                      size: 24,
                                                                    );
                                                                  },
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
                                                                ),
                                                              ),
                                                        Text(
                                                                loadedCourseDetails.instructor!,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Color(0xFF374151),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    ),
                                                    const SizedBox(height: 15),
                                                    
                                                    // Course Overview Section
                                                    Container(
                                                      margin: const EdgeInsets.only(bottom: 20),
                                                      padding: const EdgeInsets.all(15),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF6366F1).withOpacity(0.05),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          // Remove the section title and divider
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                            children: [
                                                              // Total lessons
                                                              Expanded(
                                                                child: _buildStatItem(
                                                                  icon: Icons.video_library_outlined,
                                                                  title: '${loadedCourseDetails.totalNumberOfLessons ?? loadedCourseDetails.mSection?.length ?? 0}',
                                                                  subtitle: 'Lessons',
                                                                  color: const Color(0xFF10B981),
                                                                ),
                                                              ),
                                                              
                                                              // Total enrollments
                                                              Expanded(
                                                                child: _buildStatItem(
                                                                  icon: Icons.people_outline,
                                                                  title: '${loadedCourseDetails.numberOfEnrollment ?? loadedCourseDetails.totalEnrollment ?? 0}',
                                                                  subtitle: 'Students',
                                                                  color: const Color(0xFF0EA5E9),
                                                                ),
                                                              ),
                                                              
                                                              // Rating if available
                                                              Expanded(
                                                                child: _buildStatItem(
                                                                  icon: Icons.star_outline,
                                                                  title: () {
                                                                    // Debug print to console
                                                                    print('Rating type: ${loadedCourseDetails.average_rating.runtimeType}');
                                                                    print('Rating value: ${loadedCourseDetails.average_rating}');
                                                                    
                                                                    if (loadedCourseDetails.average_rating == null) {
                                                                      return 'N/A';
                                                                    }
                                                                    
                                                                    // Handle different types
                                                                    if (loadedCourseDetails.average_rating is double) {
                                                                      return loadedCourseDetails.average_rating.toStringAsFixed(1);
                                                                    } else if (loadedCourseDetails.average_rating is int) {
                                                                      return loadedCourseDetails.average_rating.toString();
                                                                    } else {
                                                                      // Try to parse as double or int
                                                                      try {
                                                                        final value = double.parse(loadedCourseDetails.average_rating.toString());
                                                                        return value.toStringAsFixed(1);
                                                                      } catch (e) {
                                                                        return loadedCourseDetails.average_rating.toString();
                                                                      }
                                                                    }
                                                                  }(),
                                                                  subtitle: 'Rating',
                                                                  color: const Color(0xFFFFA000),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    
                                                    // What You Will Learn
                                                    const Text(
                                                      'What You Will Learn',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                    color: Color(0xFF6366F1),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    ...(loadedCourseDetails.courseOutcomes ?? []).map((item) => 
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 8.0),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                        const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 18),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                item,
                                                                style: const TextStyle(fontSize: 15),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    ).toList(),
                                                    const SizedBox(height: 25),
                                                    
                                                    // What is Included
                                                    const Text(
                                                      'What is Included',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                    color: Color(0xFF6366F1),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    ...(loadedCourseDetails.courseIncludes ?? []).map((item) => 
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 8.0),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                        const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 18),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                item,
                                                                style: const TextStyle(fontSize: 15),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    ).toList(),
                                                    const SizedBox(height: 25),
                                                    
                                                    // Course Requirements
                                                    const Text(
                                                      'Course Requirements',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                    color: Color(0xFF6366F1),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    ...(loadedCourseDetails.courseRequirements ?? []).map((item) => 
                                                      Padding(
                                                        padding: const EdgeInsets.only(bottom: 8.0),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                        const Icon(Icons.arrow_right, color: Color(0xFF6366F1), size: 22),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                item,
                                                                style: const TextStyle(fontSize: 15),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    ).toList(),
                                                    
                                                    // Certificate You'll Earn - New Section
                                                    const SizedBox(height: 25),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF6366F1).withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Icon(
                                                            Icons.workspace_premium,
                                                            color: Color(0xFFFFA000),
                                                            size: 24,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        const Text(
                                                          'Certificate you\'ll earn',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF6366F1),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 15),
                                                    Container(
                                                      padding: const EdgeInsets.all(15),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(16),
                                                        border: Border.all(
                                                          color: Colors.grey.withOpacity(0.2),
                                                          width: 1,
                                                        ),
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
                                                          // Certificate Preview - Horizontal Layout
                                                          Container(
                                                            width: double.infinity,
                                                            padding: const EdgeInsets.all(0),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(
                                                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: AspectRatio(
                                                              aspectRatio: 16 / 9, // Horizontal aspect ratio
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.white,
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(
                                                                    color: const Color(0xFF3B82F6),
                                                                    width: 2,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    // Left side - Logo and title
                                                                    Expanded(
                                                                      flex: 1,
                                                                      child: Column(
                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                        children: [
                                                                          // Logo
                                                                          Image.asset(
                                                                            'assets/images/light_logo.png',
                                                                            height: 25,
                                                                            fit: BoxFit.contain,
                                                                          ),
                                                                          const SizedBox(height: 10),
                                                                          // Title
                                                                          const Text(
                                                                            'Certificate of\nCompletion',
                                                                            textAlign: TextAlign.center,
                                                                            style: TextStyle(
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.bold,
                                                                              height: 1.2,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 6),
                                                                          // Signature
                                                                          Container(
                                                                            margin: const EdgeInsets.only(top: 8),
                                                                            child: Column(
                                                                              children: [
                                                                                Container(
                                                                                  width: 80,
                                                                                  height: 25,
                                                                                  decoration: const BoxDecoration(
                                                                                    image: DecorationImage(
                                                                                      fit: BoxFit.contain,
                                                                                      image: AssetImage(
                                                                                        'assets/images/signature.png',
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Container(
                                                                                  width: 80,
                                                                                  height: 1,
                                                                                  color: Colors.black,
                                                                                ),
                                                                                const SizedBox(height: 4),
                                                                                const Text(
                                                                                  'Musthafa CMA, CSCA',
                                                                                  style: TextStyle(
                                                                                    fontSize: 10,
                                                                                    fontWeight: FontWeight.w500,
                                                                                  ),
                                                                                ),
                                                                                const Text(
                                                                                  'CEO, Elegance',
                                                                                  style: TextStyle(
                                                                                    fontSize: 9,
                                                                                    color: Color(0xFF6B7280),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    
                                                                    // Vertical divider
                                                                    Container(
                                                                      height: double.infinity,
                                                                      width: 1,
                                                                      color: Colors.grey.withOpacity(0.3),
                                                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                                                    ),
                                                                    
                                                                    // Right side - Certificate details
                                                                    Expanded(
                                                                      flex: 2,
                                                                      child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                        children: [
                                                                          const Text(
                                                                            'This certificate is awarded to:',
                                                                            style: TextStyle(
                                                                              fontSize: 10,
                                                                              fontStyle: FontStyle.italic,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 6),
                                                                          Text(
                                                                            '[Your Name]',
                                                                            style: TextStyle(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Colors.blue.shade700,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 6),
                                                                          const Text(
                                                                            'for the successful completion of the course',
                                                                            style: TextStyle(
                                                                              fontSize: 10,
                                                                              fontStyle: FontStyle.italic,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 8),
                                                                          Text(
                                                                            loadedCourseDetails.title.toString().toUpperCase(),
                                                                            textAlign: TextAlign.center,
                                                                            style: const TextStyle(
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 10),
                                                                          // Date and duration
                                                                          Row(
                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                            children: [
                                                                              Text(
                                                                                'On ${DateTime.now().toString().substring(0, 10)}',
                                                                                style: const TextStyle(
                                                                                  fontSize: 9,
                                                                                  color: Color(0xFF6B7280),
                                                                                ),
                                                                              ),
                                                                              const Text(
                                                                                '  •  Course Duration: 2hr  •',
                                                                                style: TextStyle(
                                                                                  fontSize: 9,
                                                                                  color: Color(0xFF6B7280),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          const SizedBox(height: 6),
                                                                          Row(
                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                            children: [
                                                                              const Text(
                                                                                'Certificate ID: ',
                                                                                style: TextStyle(
                                                                                  fontSize: 8,
                                                                                  color: Color(0xFF6B7280),
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'EDP${loadedCourseDetails.courseId}${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}',
                                                                                style: const TextStyle(
                                                                                  fontSize: 8,
                                                                                  fontWeight: FontWeight.w500,
                                                                                  color: Color(0xFF6B7280),
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
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                const SizedBox(height: 80), // Increased bottom spacing
                                                  ],
                                            ),
                                                ),
                                              ),
                                              
                                              // Lessons Tab
                                              SingleChildScrollView(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                // Removed the "Course Curriculum" text 
                                                // Course sections and lessons with updated styling
                                                    ListView.builder(
                                                      key: Key('builder ${selected.toString()}'),
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      itemCount: loadedCourseDetails.mSection!.length,
                                                      itemBuilder: (ctx, index) {
                                                        final section = loadedCourseDetails.mSection![index];
                                                    
                                                    // Check if we have lessons
                                                    bool hasLessons = section.mLesson != null && section.mLesson!.isNotEmpty;
                                                    
                                                        return Padding(
                                                      padding: const EdgeInsets.only(bottom: 18),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(16),
                                                              boxShadow: [
                                                                BoxShadow(
                                                              color: Colors.black.withOpacity(0.05),
                                                              blurRadius: 12,
                                                              offset: const Offset(0, 3),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            // Section header
                                                            InkWell(
                                                              onTap: () {
                                                                    setState(() {
                                                                  if (selected == index) {
                                                                      selected = -1;
                                                                  } else {
                                                                    selected = index;
                                                                  }
                                                                });
                                                              },
                                                              borderRadius: selected == index
                                                                ? const BorderRadius.only(
                                                                    topLeft: Radius.circular(16),
                                                                    topRight: Radius.circular(16),
                                                                  )
                                                                : BorderRadius.circular(16),
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.white,
                                                                  borderRadius: selected == index
                                                                    ? const BorderRadius.only(
                                                                        topLeft: Radius.circular(16),
                                                                        topRight: Radius.circular(16),
                                                                      )
                                                                    : BorderRadius.circular(16),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      width: 36,
                                                                      height: 36,
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(0xFF6366F1).withOpacity(0.1),
                                                                        shape: BoxShape.circle,
                                                                      ),
                                                                      child: Center(
                                                                        child: Text(
                                                                          '${index + 1}',
                                                                          style: const TextStyle(
                                                                            fontWeight: FontWeight.bold,
                                                                            color: Color(0xFF6366F1),
                                                                            fontSize: 15,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 12),
                                                                    Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                            HtmlUnescape().convert(section.title.toString()),
                                                                        style: const TextStyle(
                                                                              fontSize: 15,
                                                                              fontWeight: FontWeight.w500, // Reduced from bold to w500
                                                                              color: Color(0xFF333333),
                                                                            ),
                                                                          ),
                                                                          // Return to container pills style matching my_course_detail.dart
                                                                          Padding(
                                                                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                                                                            child: Row(
                                                                        children: [
                                                                                Expanded(
                                                                                  flex: 1,
                                                                                  child: Container(
                                                                            decoration: BoxDecoration(
                                                                              color: kTimeBackColor.withOpacity(0.12),
                                                                              borderRadius: BorderRadius.circular(5),
                                                                            ),
                                                                                    padding: const EdgeInsets.symmetric(
                                                                                      vertical: 5.0,
                                                                                    ),
                                                                                    child: Align(
                                                                                      alignment: Alignment.center,
                                                                            child: Text(
                                                                                        section.totalDuration != null ? 
                                                                                          section.totalDuration.toString() : 
                                                                                          _calculateTotalDuration(section),
                                                                              style: const TextStyle(
                                                                                          fontSize: 10,
                                                                                fontWeight: FontWeight.w400,
                                                                                color: kTimeColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                            ),
                                                                                ),
                                                                                const SizedBox(width: 10.0),
                                                                                Expanded(
                                                                                  flex: 1,
                                                                                  child: Container(
                                                                            decoration: BoxDecoration(
                                                                              color: kLessonBackColor.withOpacity(0.12),
                                                                              borderRadius: BorderRadius.circular(5),
                                                                            ),
                                                                                    padding: const EdgeInsets.symmetric(
                                                                                      vertical: 5.0,
                                                                                    ),
                                                                                    child: Align(
                                                                                      alignment: Alignment.center,
                                                                            child: Text(
                                                                              '${section.mLesson!.length} Lessons',
                                                                              style: const TextStyle(
                                                                                          fontSize: 10,
                                                                                fontWeight: FontWeight.w400,
                                                                                color: kLessonColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                                  ),
                                                                                ),
                                                                                const Expanded(flex: 1, child: Text("")),
                                                                        ],
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(0xFF6366F1).withOpacity(0.1),
                                                                        borderRadius: BorderRadius.circular(16),
                                                                      ),
                                                                      child: Icon(
                                                                        selected == index ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                                        color: const Color(0xFF6366F1),
                                                                        size: 20,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            
                                                            // Lesson list (expanded/collapsed based on state)
                                                            AnimatedCrossFade(
                                                              firstChild: const SizedBox(height: 0),
                                                              secondChild: Column(
                                                                children: [
                                                                  ListView.separated(
                                                                    physics: const NeverScrollableScrollPhysics(),
                                                                    shrinkWrap: true,
                                                                    itemCount: section.mLesson!.length,
                                                                    separatorBuilder: (context, index) => Divider(
                                                                      height: 1,
                                                                      color: Colors.grey.shade200,
                                                                    ),
                                                                    itemBuilder: (ctx, i) {
                                                                      final lesson = section.mLesson![i];
                                                                      
                                                                      return Material(
                                                                        color: Colors.transparent,
                                                                        child: InkWell(
                                                                          highlightColor: const Color(0xFF6366F1).withOpacity(0.05),
                                                                          splashColor: const Color(0xFF6366F1).withOpacity(0.1),
                                                                          onTap: () {},
                                                                          child: Container(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                                            child: Row(
                                                                              children: [
                                                                                // Lesson icon based on type
                                                                                Container(
                                                                                  width: 32,
                                                                                  height: 32,
                                                                                  decoration: BoxDecoration(
                                                                                    color: Colors.grey.shade100,
                                                                                    borderRadius: BorderRadius.circular(10),
                                                                                  ),
                                                                                  child: Center(
                                                                                    child: Icon(
                                                                                      _getLessonIcon(lesson.lessonType ?? ''),
                                                                                      color: Colors.grey.shade600,
                                                                                      size: 18,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(width: 12),
                                                                                
                                                                                // Lesson title and duration
                                                                                Expanded(
                                                                        child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                          children: [
                                                                                      Text(
                                                                                        lesson.title ?? '',
                                                                                        style: const TextStyle(
                                                                                          fontWeight: FontWeight.w500,
                                                                                          fontSize: 14,
                                                                                          color: Color(0xFF333333),
                                                                                        ),
                                                                                      ),
                                                                                      if (lesson.duration != null && lesson.duration!.isNotEmpty)
                                                                                        Padding(
                                                                                          padding: const EdgeInsets.only(top: 2),
                                                                                          child: Row(
                                                                                            children: [
                                                                                              Icon(
                                                                                                Icons.access_time,
                                                                                                size: 10,
                                                                                                color: Colors.grey.shade600,
                                                                                              ),
                                                                                              const SizedBox(width: 3),
                                                                                              Text(
                                                                                                lesson.duration ?? '',
                                                                                                style: TextStyle(
                                                                                                  fontSize: 11,
                                                                                                  fontWeight: FontWeight.w500,
                                                                                                  color: Colors.grey.shade700,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                
                                                                                // Preview label if available
                                                                                if (hasLessons && i == 0)
                                                                                  Container(
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                                                    decoration: BoxDecoration(
                                                                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                                                                      borderRadius: BorderRadius.circular(4),
                                                                                    ),
                                                                                    child: const Text(
                                                                                      'Preview',
                                                                                      style: TextStyle(
                                                                                        fontSize: 10,
                                                                                        fontWeight: FontWeight.bold,
                                                                                        color: Color(0xFF6366F1),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                              crossFadeState: selected == index 
                                                                  ? CrossFadeState.showSecond 
                                                                  : CrossFadeState.showFirst,
                                                              duration: const Duration(milliseconds: 300),
                                                            ),
                                                          ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                const SizedBox(height: 30), // Added bottom spacing for Lessons tab
                                                  ],
                                                ),
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
                    ),
                  ],
                );
              }),
      ),
      bottomNavigationBar: Consumer<Courses>(builder: (context, courses, child) {
        final loadedCourseDetails = courses.getCourseDetail;
        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Price display
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      loadedCourseDetails.price.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Buy Now or Enroll button
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final authToken = (prefs.getString('access_token') ?? '');
                    if (authToken.isNotEmpty) {
                      if (loadedCourseDetails.isPurchased!) {
                        // Already purchased, go to my courses
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => TabsScreen(pageIndex: 1)
                          ),
                        );
                      } else if (loadedCourseDetails.isPaid == 1) {
                        // Paid course, go to payment
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
                        if (!loadedCourseDetails.is_cart!) {
                          Provider.of<Courses>(context, listen: false)
                              .toggleCart(loadedCourseDetails.courseId!, false);
                        }
                      } else {
                        // Free course, enroll
                        await getEnroll(loadedCourseDetails.courseId.toString());
                        CommonFunctions.showSuccessToast('Course Successfully Enrolled');
                      }
                    } else {
                      CommonFunctions.showWarningToast('Please login first');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: loadedCourseDetails.isPurchased!
                          ? null
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                      color: loadedCourseDetails.isPurchased! ? const Color(0xFF10B981) : null,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (loadedCourseDetails.isPurchased! 
                              ? const Color(0xFF10B981) 
                              : const Color(0xFF6366F1)).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        loadedCourseDetails.isPurchased!
                            ? 'Go to Course'
                            : loadedCourseDetails.isPaid == 1
                                ? 'Buy Now'
                                : 'Enroll Now',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

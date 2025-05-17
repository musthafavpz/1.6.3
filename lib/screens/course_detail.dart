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

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
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
        // _authToken = Provider.of<Auth>(context, listen: false).token;
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
        
        // Initialize video player if preview is available
        if (courseDetail.preview != null && courseDetail.preview!.isNotEmpty) {
          final previewUrl = courseDetail.preview!;
          
          // Handle different video types
          if (previewUrl.contains("youtube.com") || previewUrl.contains("youtu.be")) {
            // Set landscape orientation for YouTube videos
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => YoutubeVideoPlayerFlutter(
                  courseId: courseDetail.courseId!,
                  videoUrl: previewUrl,
                ),
              ),
            );
            // Reset to portrait orientation when returned
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          } else if (previewUrl.contains("drive.google.com")) {
            final RegExp regExp = RegExp(r'[-\w]{25,}');
            final Match? match = regExp.firstMatch(previewUrl);
            if (match != null) {
              // Use iframe for Google Drive
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
          } else if (previewUrl.contains("vimeo.com")) {
            String vimeoVideoId = previewUrl.split('/').last;
            // Set landscape orientation for Vimeo videos
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FromVimeoPlayer(
                  courseId: courseDetail.courseId!,
                  vimeoVideoId: vimeoVideoId
                ),
              )
            );
            // Reset to portrait orientation when returned
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          } else if (RegExp(r"\.mp4(\?|$)").hasMatch(previewUrl) || 
                     RegExp(r"\.webm(\?|$)").hasMatch(previewUrl) || 
                     RegExp(r"\.ogg(\?|$)").hasMatch(previewUrl)) {
            // Set landscape orientation for direct video files
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
            _initializeVideoPlayer(previewUrl);
            // Reset to portrait orientation when returned
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          }
        }

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
                
                // Try to extract video URL for preview
                String? previewUrl = loadedCourseDetails.preview;
                
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // YouTube-like thumbnail with embedded video player
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Course thumbnail with YouTube-like aspect ratio
                                Container(
                                  width: double.infinity,
                                  height: 220, // Standard YouTube-like height
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
                                        // Set landscape orientation for YouTube videos
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.landscapeLeft,
                                          DeviceOrientation.landscapeRight,
                                        ]);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => YoutubeVideoPlayerFlutter(
                                              courseId: loadedCourseDetails.courseId!,
                                              videoUrl: previewUrl,
                                            ),
                                          ),
                                        );
                                        // Reset to portrait orientation when returned
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                          DeviceOrientation.portraitDown,
                                        ]);
                                      } else if (previewUrl.contains("drive.google.com")) {
                                        final RegExp regExp = RegExp(r'[-\w]{25,}');
                                        final Match? match = regExp.firstMatch(previewUrl);
                                        if (match != null) {
                                          // Use iframe for Google Drive
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
                                      } else if (previewUrl.contains("vimeo.com")) {
                                        String vimeoVideoId = previewUrl.split('/').last;
                                        // Set landscape orientation for Vimeo videos
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.landscapeLeft,
                                          DeviceOrientation.landscapeRight,
                                        ]);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FromVimeoPlayer(
                                              courseId: loadedCourseDetails.courseId!,
                                              vimeoVideoId: vimeoVideoId
                                            ),
                                          )
                                        );
                                        // Reset to portrait orientation when returned
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                          DeviceOrientation.portraitDown,
                                        ]);
                                      } else if (RegExp(r"\.mp4(\?|$)").hasMatch(previewUrl) || 
                                                RegExp(r"\.webm(\?|$)").hasMatch(previewUrl) || 
                                                RegExp(r"\.ogg(\?|$)").hasMatch(previewUrl)) {
                                        // Set landscape orientation for direct video files
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.landscapeLeft,
                                          DeviceOrientation.landscapeRight,
                                        ]);
                                        _initializeVideoPlayer(previewUrl);
                                        // Reset to portrait orientation when returned
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                          DeviceOrientation.portraitDown,
                                        ]);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NoPreviewVideo(),
                                        ),
                                      );
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
                            
                            // Course tabs
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Container(
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
                                                const SizedBox(height: 60),
                                                  ],
                                            ),
                                                ),
                                              ),
                                              
                                              // Lessons Tab
                                              SingleChildScrollView(
                                          child: Container(
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
                                                    const Text(
                                                      'Course Curriculum',
                                                      style: TextStyle(
                                                          fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF6366F1),
                                                  ),
                                                    ),
                                                    const SizedBox(height: 15),
                                                    
                                                    // Course sections and lessons
                                                    ListView.builder(
                                                      key: Key('builder ${selected.toString()}'),
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      itemCount: loadedCourseDetails.mSection!.length,
                                                      itemBuilder: (ctx, index) {
                                                        final section = loadedCourseDetails.mSection![index];
                                                        return Padding(
                                                          padding: const EdgeInsets.only(bottom: 10.0),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: kBackButtonBorderColor.withOpacity(0.05),
                                                                  blurRadius: 10,
                                                                  offset: const Offset(0, 2),
                                                                ),
                                                              ],
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Card(
                                                              elevation: 0.5,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: ExpansionTile(
                                                                key: Key(index.toString()),
                                                                initiallyExpanded: index == selected,
                                                                onExpansionChanged: ((newState) {
                                                                  if (newState) {
                                                                    setState(() {
                                                                      selected = index;
                                                                    });
                                                                  } else {
                                                                    setState(() {
                                                                      selected = -1;
                                                                    });
                                                                  }
                                                                }),
                                                                iconColor: kDefaultColor,
                                                                collapsedIconColor: kSelectItemColor,
                                                                trailing: Icon(
                                                                  selected == index
                                                                      ? Icons.keyboard_arrow_up_rounded
                                                                      : Icons.keyboard_arrow_down_rounded,
                                                                  size: 30,
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(10),
                                                                ),
                                                                title: Padding(
                                                                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                        '${index + 1}. ${HtmlUnescape().convert(section.title.toString())}',
                                                                        style: const TextStyle(
                                                                          fontSize: 16,
                                                                          fontWeight: FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 8),
                                                                      Row(
                                                                        children: [
                                                                          Container(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal: 10,
                                                                              vertical: 5,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: kTimeBackColor.withOpacity(0.12),
                                                                              borderRadius: BorderRadius.circular(5),
                                                                            ),
                                                                            child: Text(
                                                                              section.totalDuration.toString(),
                                                                              style: const TextStyle(
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.w400,
                                                                                color: kTimeColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(width: 10),
                                                                          Container(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal: 10,
                                                                              vertical: 5,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: kLessonBackColor.withOpacity(0.12),
                                                                              borderRadius: BorderRadius.circular(5),
                                                                            ),
                                                                            child: Text(
                                                                              '${section.mLesson!.length} Lessons',
                                                                              style: const TextStyle(
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.w400,
                                                                                color: kLessonColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                children: [
                                                                  ListView.builder(
                                                                    shrinkWrap: true,
                                                                    physics: const NeverScrollableScrollPhysics(),
                                                                    itemCount: section.mLesson!.length,
                                                                    itemBuilder: (ctx, index) {
                                                                      return Padding(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                                                                        child: Column(
                                                                          children: [
                                                                            LessonListItem(
                                                                              lesson: section.mLesson![index],
                                                                              courseId: loadedCourseDetails.courseId!,
                                                                            ),
                                                                            if ((section.mLesson!.length - 1) != index)
                                                                              Divider(
                                                                                color: kGreyLightColor.withOpacity(0.3),
                                                                              ),
                                                                            if ((section.mLesson!.length - 1) == index)
                                                                              const SizedBox(height: 10),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    },
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
              
              // Buttons
              if (!loadedCourseDetails.isPurchased!)
                loadedCourseDetails.isPaid == 1 ? Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final authToken = (prefs.getString('access_token') ?? '');
                      if (authToken.isNotEmpty) {
                        // Call the provider method to toggle the cart state
                        Provider.of<Courses>(context, listen: false)
                            .toggleCart(loadedCourseDetails.courseId!, false);
                        // Show toast based on current state
                        if (loadedCourseDetails.is_cart!) {
                          CommonFunctions.showSuccessToast("Removed from cart");
                        } else {
                          CommonFunctions.showSuccessToast("Added to cart");
                        }
                      } else {
                        CommonFunctions.showWarningToast('Please login first');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: loadedCourseDetails.is_cart! 
                            ? const Color(0xFF6366F1).withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: loadedCourseDetails.is_cart!
                              ? const Color(0xFF6366F1)
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          loadedCourseDetails.is_cart! ? 'In Cart' : 'Add to Cart',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: loadedCourseDetails.is_cart!
                                ? const Color(0xFF6366F1)
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ) : const SizedBox(),
              
              const SizedBox(width: 10),
              
              // Buy Now or Enroll button
              Expanded(
                flex: 4,
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

// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'dart:convert'; // For jsonDecode
import 'dart:io'; // For File
import 'dart:typed_data'; // For Uint8List
import 'package:path_provider/path_provider.dart'; // For file system paths
// import 'package:open_file/open_file.dart'; // To open files
import 'package:pdf/pdf.dart'; // For PDF generation
import 'package:pdf/widgets.dart' as pw; // For PDF widgets
import 'package:printing/printing.dart'; // For printing/sharing PDF
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart'; // For user name
import 'package:flutter/services.dart';

import 'package:academy_lms_app/screens/course_detail.dart';
import 'package:academy_lms_app/screens/image_viewer_Screen.dart';
import 'package:academy_lms_app/widgets/appbar_one.dart';
import 'package:academy_lms_app/widgets/from_vimeo_player.dart';
import 'package:academy_lms_app/widgets/new_youtube_player.dart';
import 'package:academy_lms_app/widgets/vimeo_iframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/lesson.dart';
import '../providers/my_courses.dart';
import '../widgets/common_functions.dart';
import '../widgets/from_network.dart';
import '../widgets/live_class_tab_widget.dart';
import 'file_data_screen.dart';
import 'package:academy_lms_app/screens/webview_screen_iframe.dart';
import 'package:http/http.dart' as http;

class MyCourseDetailScreen extends StatefulWidget {
  final int courseId;
  final String enableDripContent;
  const MyCourseDetailScreen(
      {super.key, required this.courseId, required this.enableDripContent});

  @override
  State<MyCourseDetailScreen> createState() => _MyCourseDetailScreenState();
}

class _MyCourseDetailScreenState extends State<MyCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  int? selected;
  var _isInit = true;
  var _isLoading = false;
  Lesson? _activeLesson;
  
  // Set to store expanded section indices
  Set<int> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _scrollListener() {}

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      Provider.of<MyCourses>(context, listen: false)
          .fetchCourseSections(widget.courseId)
          .then((_) {
        final activeSections =
            Provider.of<MyCourses>(context, listen: false).sectionItems;
        if (mounted && activeSections.isNotEmpty && activeSections.first.mLesson != null && activeSections.first.mLesson!.isNotEmpty) {
          setState(() {
            _isLoading = false;
            _activeLesson = activeSections.first.mLesson!.first;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }
  
  // Toggle section expansion
  void _toggleSectionExpansion(int index) {
    setState(() {
      if (_expandedSections.contains(index)) {
        _expandedSections.remove(index);
      } else {
        _expandedSections.add(index);
      }
    });
  }

  Future<String> getGoogleDriveDownloadUrl(String fileId) async {
    try {
      final initialUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
      final response = await http.get(Uri.parse(initialUrl));

      if (response.headers.containsKey('set-cookie')) {
        final cookies = response.headers['set-cookie']!;
        final tokenMatch = RegExp(r'confirm=([0-9A-Za-z\-_]+)').firstMatch(cookies);

        if (tokenMatch != null) {
          final token = tokenMatch.group(1)!;
          return 'https://drive.google.com/uc?export=download&id=$fileId&confirm=$token';
        }
      }
      return initialUrl;
    } catch (e) {
      throw Exception('Failed to generate download URL: $e');
    }
  }

  void lessonAction(Lesson lesson) async {
    if (lesson.lessonType == 'text') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FileDataScreen(
                  attachment: lesson.attachment!, note: lesson.summary!)));
    } else if (lesson.lessonType == 'iframe') {
      final url = lesson.videoUrl;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WebViewScreenIframe(url: url)));
    } else if (lesson.lessonType == 'quiz') {
      Fluttertoast.showToast(
        msg: "This option is not available on Mobile Phone, Please go to the Browser",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        timeInSecForIosWeb: 15,
        fontSize: 16.0,
      );
    } else if (lesson.lessonType == 'image') {
      final url = lesson.attachmentUrl;
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => ImageViewrScreen(url: url)));
    } else if (lesson.lessonType == 'document_type') {
      final url = lesson.attachmentUrl;
      _launchURL(url);
    } else {
      if (lesson.lessonType == 'system-video') {
        // Rotate to landscape for video playback
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayVideoFromNetwork(
                  courseId: widget.courseId,
                  lessonId: lesson.id!,
                  videoUrl: lesson.videoUrl!)),
        );
        // Restore to portrait orientation
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else if (lesson.lessonType == 'google_drive') {
        final RegExp regExp = RegExp(r'[-\w]{25,}');
        final Match? match = regExp.firstMatch(lesson.videoUrl.toString());
        final fileId = match!.group(0)!;

        // Create an iframe URL for Google Drive
        String iframeUrl = "https://drive.google.com/file/d/$fileId/preview";
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreenIframe(url: iframeUrl),
          ),
        );
      } else if (lesson.lessonType == 'html5') {
        // Rotate to landscape for video playback
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayVideoFromNetwork(
                  courseId: widget.courseId,
                  lessonId: lesson.id!,
                  videoUrl: lesson.videoUrl!)),
        );
        // Restore to portrait orientation
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else if (lesson.lessonType == 'vimeo-url') {
        String vimeoVideoId = lesson.videoUrl!.split('/').last;

        // Rotate to landscape for video playback
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FromVimeoPlayer(
              courseId: widget.courseId,
              lessonId: lesson.id!,
              vimeoVideoId: vimeoVideoId,
            ),
          ),
        );
        // Restore to portrait orientation
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        // Rotate to landscape for video playback
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YoutubeVideoPlayerFlutter(
              courseId: widget.courseId,
              lessonId: lesson.id!,
              videoUrl: lesson.videoUrl!,
            ),
          ),
        );
        // Restore to portrait orientation
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    }
  }

  void _launchURL(lessonUrl) async {
    if (await canLaunch(lessonUrl)) {
      await launch(lessonUrl);
    } else {
      throw 'Could not launch $lessonUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final myLoadedCourse = Provider.of<MyCourses>(context, listen: false)
        .findById(widget.courseId);
    final sections =
        Provider.of<MyCourses>(context, listen: false).sectionItems;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Image.asset(
          'assets/images/light_logo.png',
          height: 32,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF6366F1)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.share_outlined, size: 18, color: Color(0xFF6366F1)),
            ),
            onPressed: () async {
              await Share.share(myLoadedCourse.shareableLink.toString());
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFFF8F9FA),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildCourseHeader(myLoadedCourse),
                    _buildLessonsContent(sections, myLoadedCourse),
                    _buildCertificateSection(myLoadedCourse),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCourseHeader(dynamic myLoadedCourse) {
    // Calculate progress percentage
    double progressPercent = myLoadedCourse.courseCompletion != null
        ? myLoadedCourse.courseCompletion / 100
        : 0.0;

    // Determine aspect ratio for thumbnail (e.g., 16:9)
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailHeight = screenWidth / (16 / 9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Image Banner
        Container(
          height: thumbnailHeight, // Adjusted height for 16:9 aspect ratio
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Course image
              Hero(
                tag: 'course_${myLoadedCourse.id}',
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/images/loading_animated.gif',
                  image: myLoadedCourse.thumbnail.toString(),
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF6366F1),
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Gradient overlay - removed the black shade
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
              // Course Title at bottom with additional info
              Positioned(
                bottom: 15,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myLoadedCourse.title.toString(),
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // Reduced from 22
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Rating display
                        if (myLoadedCourse.average_rating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  myLoadedCourse.average_rating.toString(),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 10),
                        // Lessons count
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.video_library_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${myLoadedCourse.totalNumberOfLessons ?? 0} lessons',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
        
        // Progress and status card - floating above sections - REDUCED SIZE
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(15), // Reduced padding
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
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Progress circle - smaller size
              SizedBox(
                width: 60, // Reduced from 70
                height: 60, // Reduced from 70
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: progressPercent),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return CircularPercentIndicator(
                      radius: 30.0, // Reduced from 35.0
                      lineWidth: 5.0, // Reduced from 6.0
                      percent: value,
                      center: Text(
                        '${myLoadedCourse.courseCompletion ?? 0}%',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // Reduced from 16
                          color: Colors.white,
                        ),
                      ),
                      progressColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      circularStrokeCap: CircularStrokeCap.round,
                    );
                  },
                ),
              ),
              const SizedBox(width: 15), // Reduced from 20
              // Status info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: GoogleFonts.montserrat(
                        fontSize: 16, // Reduced from 18
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6), // Reduced from 10
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 14, // Reduced from 16
                        ),
                        const SizedBox(width: 5), // Reduced from 8
                        Text(
                          '${myLoadedCourse.totalNumberOfCompletedLessons ?? 0}/${myLoadedCourse.totalNumberOfLessons ?? 0} lessons completed',
                          style: GoogleFonts.montserrat(
                            fontSize: 12, // Reduced from 14
                            color: Colors.white,
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
        
        // Title for course content section - REDUCED SIZE
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 15), // Reduced top padding from 30
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8), // Reduced from 10
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF6366F1),
                      size: 18, // Reduced from 20
                    ),
                  ),
                  const SizedBox(width: 8), // Reduced from 10
                  Text(
                    'Course Content',
                    style: GoogleFonts.montserrat(
                      fontSize: 18, // Reduced from 20
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              // Total lessons count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced padding
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${myLoadedCourse.totalNumberOfLessons ?? 0} lessons',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Reduced from 13
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsContent(List sections, dynamic myLoadedCourse) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: sections.length,
          itemBuilder: (ctx, index) {
            // Check if all lessons in this section are completed
            bool allLessonsCompleted = false;
            if (sections[index].mLesson != null && sections[index].mLesson!.isNotEmpty) {
              allLessonsCompleted = sections[index].mLesson!.every((lesson) => lesson.isCompleted == '1');
            }
            
            // Check if this section is expanded
            bool isExpanded = _expandedSections.contains(index);
            
            // Calculate completion percentage for this section
            double sectionCompletionPercentage = 0.0;
            if (sections[index].mLesson != null && sections[index].mLesson!.isNotEmpty) {
              int completedLessons = sections[index].mLesson!.where((lesson) => lesson.isCompleted == '1').length;
              sectionCompletionPercentage = completedLessons / sections[index].mLesson!.length;
            }
            
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 500),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18), // Increased from 15
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
                        // Section header (clickable to expand/collapse)
                        InkWell(
                          onTap: () => _toggleSectionExpansion(index),
                          borderRadius: isExpanded
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              )
                            : BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16), // Increased from 14
                            decoration: BoxDecoration(
                              gradient: allLessonsCompleted 
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF10B981), // Green color for completed sections
                                      Color(0xFF34D399),
                                    ],
                                  )
                                : null, // No gradient for incomplete sections
                              color: allLessonsCompleted ? null : Colors.white, // White background for incomplete sections
                              borderRadius: isExpanded
                                ? const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  )
                                : BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, // Increased from 32
                                  height: 36, // Increased from 32
                                  decoration: BoxDecoration(
                                    color: allLessonsCompleted 
                                      ? Colors.white.withOpacity(0.2) 
                                      : const Color(0xFF6366F1).withOpacity(0.1), // Light purple for incomplete
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: allLessonsCompleted
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontFamily: 'Arial',
                                              color: const Color(0xFF6366F1), // Purple number for incomplete
                                              fontWeight: FontWeight.bold,
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
                                        sections[index].title,
                                        style: TextStyle(
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15, // Increased from 14
                                          color: allLessonsCompleted 
                                            ? Colors.white // White text for completed sections
                                            : const Color(0xFF333333), // Dark text for incomplete sections
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Time and lessons info
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: allLessonsCompleted 
                                                    ? Colors.white.withOpacity(0.2) 
                                                    : kTimeBackColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 5.0,
                                                ),
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    sections[index].totalDuration != null ? 
                                                      sections[index].totalDuration.toString() : 
                                                      _calculateTotalDuration(sections[index]),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w400,
                                                      color: allLessonsCompleted 
                                                        ? Colors.white
                                                        : kTimeColor,
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
                                                  color: allLessonsCompleted 
                                                    ? Colors.white.withOpacity(0.2) 
                                                    : kLessonBackColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 5.0,
                                                ),
                                                child: Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '${sections[index].mLesson!.length} Lessons',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w400,
                                                      color: allLessonsCompleted 
                                                        ? Colors.white
                                                        : kLessonColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Expanded(flex: 1, child: Text("")),
                                          ],
                                        ),
                                      ),
                                      if (!allLessonsCompleted && sectionCompletionPercentage > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: LinearProgressIndicator(
                                                    value: sectionCompletionPercentage,
                                                    backgroundColor: const Color(0xFFE0E0E0), // Light gray background
                                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)), // Purple progress
                                                    minHeight: 4,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "${(sectionCompletionPercentage * 100).round()}%",
                                                style: TextStyle(
                                                  fontFamily: 'Arial',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF6366F1), // Purple text
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: allLessonsCompleted 
                                      ? Colors.white.withOpacity(0.2) 
                                      : const Color(0xFF6366F1).withOpacity(0.1), // Light purple for incomplete
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: allLessonsCompleted 
                                      ? Colors.white 
                                      : const Color(0xFF6366F1), // Purple icon for incomplete
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Animated lesson list (expanded/collapsed based on state)
                        AnimatedCrossFade(
                          firstChild: const SizedBox(height: 0),
                          secondChild: ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: sections[index].mLesson!.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (ctx, i) {
                              final lesson = sections[index].mLesson![i];
                              final isActive = _activeLesson != null && 
                                              _activeLesson!.id == lesson.id;
                              final bool isCompleted = lesson.isCompleted == '1';
                              
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  highlightColor: const Color(0xFF6366F1).withOpacity(0.05),
                                  splashColor: const Color(0xFF6366F1).withOpacity(0.1),
                                  onTap: () {
                                    setState(() {
                                      _activeLesson = lesson;
                                    });
                                    lessonAction(lesson);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isActive 
                                        ? const Color(0xFF6366F1).withOpacity(0.05) 
                                        : Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        // Checkbox to mark lesson as completed
                                        Theme(
                                          data: ThemeData(
                                            checkboxTheme: CheckboxThemeData(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                          child: Transform.scale(
                                            scale: 0.9,
                                            child: Checkbox(
                                              value: isCompleted,
                                              activeColor: const Color(0xFF10B981),
                                              checkColor: Colors.white,
                                              side: BorderSide(
                                                color: isCompleted 
                                                    ? const Color(0xFF10B981)
                                                    : Colors.grey.shade400,
                                                width: 2,
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  lesson.isCompleted = value! ? '1' : '0';
                                                  
                                                  if (value) {
                                                    if (myLoadedCourse.totalNumberOfCompletedLessons != null) {
                                                      myLoadedCourse.totalNumberOfCompletedLessons =
                                                          myLoadedCourse.totalNumberOfCompletedLessons! + 1;
                                                    } else {
                                                      myLoadedCourse.totalNumberOfCompletedLessons = 1;
                                                    }
                                                  } else {
                                                    if (myLoadedCourse.totalNumberOfCompletedLessons != null &&
                                                        myLoadedCourse.totalNumberOfCompletedLessons! > 0) {
                                                      myLoadedCourse.totalNumberOfCompletedLessons =
                                                          myLoadedCourse.totalNumberOfCompletedLessons! - 1;
                                                    }
                                                  }
                                                  
                                                  var completePerc = myLoadedCourse.totalNumberOfLessons! > 0
                                                      ? (myLoadedCourse.totalNumberOfCompletedLessons! / 
                                                      myLoadedCourse.totalNumberOfLessons!) * 100
                                                      : 0;
                                                  myLoadedCourse.courseCompletion = completePerc.round();
                                                
                                                Provider.of<MyCourses>(context, listen: false)
                                                    .toggleLessonCompleted(
                                                          lesson.id!,
                                                          value ? 1 : 0)
                                                    .then((_) => CommonFunctions.showSuccessToast(
                                                        'Course Progress Updated'));
                                              });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        
                                        // Lesson title, time duration and summary
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Title and duration in separate rows for better readability
                                              Text(
                                                lesson.title!,
                                                style: TextStyle(
                                                  fontFamily: 'Arial',
                                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                                  fontSize: 14, // Increased from 13
                                                  color: isActive 
                                                    ? const Color(0xFF6366F1)
                                                    : isCompleted
                                                        ? const Color(0xFF10B981)
                                                        : const Color(0xFF333333),
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
                                                        lesson.duration!,
                                                        style: TextStyle(
                                                          fontFamily: 'Arial',
                                                          fontSize: 11, // Increased from 10
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              if (lesson.summary != null && lesson.summary!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    lesson.summary!.length > 60
                                                        ? "${lesson.summary!.substring(0, 60)}..."
                                                        : lesson.summary!,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontFamily: 'Arial',
                                                      fontSize: 12, // Increased from 11
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Play button with updated style
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isActive 
                                              ? const Color(0xFF6366F1).withOpacity(0.1)
                                              : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(10),
                                              onTap: () {
                                                setState(() {
                                                  _activeLesson = lesson;
                                                });
                                                lessonAction(lesson);
                                              },
                                              child: Center(
                                                child: SvgPicture.asset(
                                                  'assets/icons/video.svg',
                                                  colorFilter: ColorFilter.mode(
                                                    isActive 
                                                      ? const Color(0xFF6366F1) 
                                                      : Colors.grey.shade600,
                                                    BlendMode.srcIn,
                                                  ),
                                                  width: 18,
                                                  height: 18,
                                                ),
                                              ),
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
                          crossFadeState: isExpanded 
                              ? CrossFadeState.showSecond 
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 0), // Removed animation by setting duration to 0
                        ),
                        
                        // Last lesson divider (only shown when expanded and has lessons)
                        if (isExpanded && sections[index].mLesson != null && sections[index].mLesson!.isNotEmpty)
                          Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Placeholder for actual instructor name retrieval
  String _getInstructorName(dynamic myLoadedCourse) {
    // TODO: Replace this with actual logic to get instructor name
    // e.g., return myLoadedCourse.instructorName ?? 'The Academy Team';
    if (myLoadedCourse.instructor != null && myLoadedCourse.instructor['name'] != null) {
      return myLoadedCourse.instructor['name'];
    }
    return 'The Academy Team';
  }

  Future<void> _generateCertificatePdf(BuildContext context, dynamic myLoadedCourse, {bool shouldShare = false}) async {
    try {
      // Show loading indicator
      Fluttertoast.showToast(
        msg: shouldShare ? "Preparing certificate to share..." : "Generating certificate...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      
      print("Starting certificate generation...");
      
      // Get user details - with error handling
      String candidateName = 'Valued Student';
      try {
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user');
        if (userDataString != null && userDataString.isNotEmpty) {
          final userData = jsonDecode(userDataString);
          if (userData != null && userData['name'] != null) {
            candidateName = userData['name'];
            print("Retrieved candidate name: $candidateName");
          }
        }
      } catch (userError) {
        print("Error getting user data: $userError");
        // Continue with default name
      }

      // Get course details - with error handling
      String courseName = "Course";
      String instructorName = "Instructor";
      try {
        courseName = myLoadedCourse.title?.toString() ?? "Course";
        instructorName = _getInstructorName(myLoadedCourse);
        print("Course name: $courseName, Instructor: $instructorName");
      } catch (courseError) {
        print("Error getting course data: $courseError");
        // Continue with defaults
      }
      
      final completionDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
      print("Date formatted: $completionDate");

      // Load logo image
      print("Loading logo image...");
      Uint8List? logoImageData;
      try {
        final ByteData logoData = await rootBundle.load('assets/images/light_logo.png');
        logoImageData = logoData.buffer.asUint8List();
        print("Logo loaded successfully");
      } catch (imageError) {
        print("Error loading logo: $imageError");
        // Continue without logo
      }

      // Create an elegant PDF certificate
      print("Creating PDF document...");
      final pdf = pw.Document();
      
      // Set page theme with a nice font
      const pageTheme = pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
      );
      
      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.indigo200,
                  width: 3,
                ),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Certificate header with logo and decorative element
                    pw.Container(
                      padding: const pw.EdgeInsets.only(top: 20, bottom: 24),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.indigo100,
                            width: 2,
                          ),
                        ),
                      ),
                      child: pw.Column(
                        children: [
                          // Logo image at the top
                          if (logoImageData != null)
                            pw.Container(
                              height: 50,
                              margin: const pw.EdgeInsets.only(bottom: 20),
                              child: pw.Image(
                                pw.MemoryImage(logoImageData),
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                            
                          // Decorative seal element
                          pw.Container(
                            width: 70,
                            height: 70,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.indigo100,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'E',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.indigo700,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 16),
                          
                          // Title
                          pw.Text(
                            'CERTIFICATE OF COMPLETION',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo900,
                              letterSpacing: 1.5,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          
                          pw.SizedBox(height: 8),
                          
                          // Subtitle
                          pw.Text(
                            'ONLINE COURSE',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.indigo700,
                              letterSpacing: 2.0,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Main certificate content
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'This is to certify that',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.grey700,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                          
                          pw.SizedBox(height: 12),
                          
                          // Certificate recipient name
                          pw.Text(
                            candidateName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo900,
                              letterSpacing: 1.0,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          
                          pw.SizedBox(height: 12),
                          
                          pw.Text(
                            'has successfully completed the online course',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.grey700,
                            ),
                          ),
                          
                          pw.SizedBox(height: 16),
                          
                          // Course name
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.indigo50,
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(
                                color: PdfColors.indigo200,
                                width: 1,
                              ),
                            ),
                            child: pw.Text(
                              courseName,
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.indigo800,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Footer section for date and signatures
                    pw.Container(
                      padding: const pw.EdgeInsets.only(
                        top: 30,
                        left: 20,
                        right: 20,
                        bottom: 20,
                      ),
                      child: pw.Column(
                        children: [
                          // Signature row
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              // Date section
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                    width: 140,
                                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                        bottom: pw.BorderSide(
                                          color: PdfColors.indigo200,
                                        ),
                                      ),
                                    ),
                                    child: pw.Text(
                                      completionDate,
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.SizedBox(height: 8),
                                  pw.Text(
                                    'Date',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Instructor signature
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                    width: 140,
                                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                        bottom: pw.BorderSide(
                                          color: PdfColors.indigo200,
                                        ),
                                      ),
                                    ),
                                    child: pw.Text(
                                      instructorName,
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.SizedBox(height: 8),
                                  pw.Text(
                                    'Instructor',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          pw.SizedBox(height: 30),
                          
                          // Academy seal and verification
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.indigo50,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Container(
                                  width: 20,
                                  height: 20,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.indigo700,
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  'Elegance - Official Certificate',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.indigo900,
                                    fontWeight: pw.FontWeight.bold,
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
            );
          },
        ),
      );

      print("PDF created, saving to bytes...");
      final Uint8List pdfBytes = await pdf.save();
      print("PDF saved to bytes, length: ${pdfBytes.length}");
      
      // Generate file name based on course title and date
      final String sanitizedCourseName = courseName
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .toLowerCase();
      final String fileName = 'certificate_${sanitizedCourseName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      if (shouldShare) {
        // Use printing package to share PDF
        print("Sharing PDF...");
        final result = await Printing.sharePdf(
          bytes: pdfBytes, 
          filename: fileName,
        );
        
        print("Share result: $result");
        
        Fluttertoast.showToast(
          msg: "Certificate ready to share",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
        );
      } else {
        // Save PDF to Downloads directory
        try {
          // Get the downloads directory
          Directory? downloadsDir;
          
          if (Platform.isAndroid) {
            // For Android, use the Downloads directory
            downloadsDir = Directory('/storage/emulated/0/Download');
            if (!await downloadsDir.exists()) {
              // Fallback to app documents directory
              downloadsDir = await getApplicationDocumentsDirectory();
            }
          } else {
            // For iOS, use the Documents directory
            downloadsDir = await getApplicationDocumentsDirectory();
          }
          
          // Create the file path
          final String filePath = '${downloadsDir.path}/$fileName';
          final File file = File(filePath);
          
          // Write the PDF bytes to the file
          await file.writeAsBytes(pdfBytes);
          
          print("PDF saved to: $filePath");
          
          Fluttertoast.showToast(
            msg: "Certificate saved to Downloads folder",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
          );
        } catch (saveError) {
          print("Error saving file: $saveError");
          Fluttertoast.showToast(
            msg: "Error saving certificate: $saveError",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
          );
        }
      }
      
    } catch (e, stackTrace) {
      // Detailed error reporting
      print("ERROR GENERATING PDF: $e");
      print("Stack trace: $stackTrace");
      
      Fluttertoast.showToast(
        msg: "Error: ${e.toString().substring(0, min(e.toString().length, 100))}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  // Add this utility function to get the minimum of two integers
  int min(int a, int b) {
    return a < b ? a : b;
  }

  Widget _buildCertificateSection(dynamic myLoadedCourse) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
            stops: [0.3, 0.9],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Certificate design elements
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Certificate icon with glowing effect
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.workspace_premium,
                        color: Color(0xFF6366F1),
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Certificate text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Course Certificate",
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Complete ${myLoadedCourse.courseCompletion}% to unlock your certificate",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Download button
                  if (myLoadedCourse.courseCompletion != null && myLoadedCourse.courseCompletion! >= 100)
                    Row(
                      children: [
                        // Download button
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _generateCertificatePdf(context, myLoadedCourse, shouldShare: false);
                              },
                              child: const Center(
                                child: Icon(
                                  Icons.download,
                                  size: 20,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 10),
                        
                        // Share button
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _generateCertificatePdf(context, myLoadedCourse, shouldShare: true);
                              },
                              child: const Center(
                                child: Icon(
                                  Icons.share,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Lock button when certificate is not unlocked
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Fluttertoast.showToast(
                              msg: "Complete the course to unlock certificate",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Locked",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}
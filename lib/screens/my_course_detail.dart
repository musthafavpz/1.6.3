// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

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
import 'webview_screen_iframe.dart';
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
    
    // By default, expand the first section
    _expandedSections.add(0);
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
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayVideoFromNetwork(
                  courseId: widget.courseId,
                  lessonId: lesson.id!,
                  videoUrl: lesson.videoUrl!)),
        );
      } else if (lesson.lessonType == 'google_drive') {
        final RegExp regExp = RegExp(r'[-\w]{25,}');
        final Match? match = regExp.firstMatch(lesson.videoUrl.toString());
        final fileId = match!.group(0)!;

        String url = "https://www.googleapis.com/drive/v3/files/$fileId?alt=media";

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayVideoFromNetwork(
                  courseId: widget.courseId,
                  lessonId: lesson.id!,
                  videoUrl: url)),
        );
      } else if (lesson.lessonType == 'html5') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayVideoFromNetwork(
                  courseId: widget.courseId,
                  lessonId: lesson.id!,
                  videoUrl: lesson.videoUrl!)),
        );
      } else if (lesson.lessonType == 'vimeo-url') {
        String vimeoVideoId = lesson.videoUrl!.split('/').last;

        // Directly use Vimeo player instead of showing dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FromVimeoPlayer(
                          courseId: widget.courseId,
                          lessonId: lesson.id!,
                          vimeoVideoId: vimeoVideoId,
                        ),
                      ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YoutubeVideoPlayerFlutter(
              courseId: widget.courseId,
              lessonId: lesson.id!,
              videoUrl: lesson.videoUrl!,
            ),
          ),
        );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Image Banner with Video Play Option and floating back button
        Container(
          height: 250, // Increased height for better visual impact
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Course image with shimmer loading effect
              Hero(
                tag: 'course_${myLoadedCourse.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
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
              ),
              // Gradient overlay
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              ),
              // Play button with ripple effect
              Center(
                child: InkWell(
                  onTap: () {
                    // Find first video lesson to use as a preview
                    final sections = Provider.of<MyCourses>(context, listen: false).sectionItems;
                    Lesson? videoLesson;
                    
                    // Search for a video lesson
                    for (var section in sections) {
                      if (section.mLesson != null && section.mLesson!.isNotEmpty) {
                        for (var lesson in section.mLesson!) {
                          if (lesson.lessonType == 'video' || 
                              lesson.lessonType == 'system-video' ||
                              lesson.lessonType == 'vimeo-url' ||
                              lesson.lessonType == 'youtube' ||
                              lesson.lessonType == 'google_drive') {
                            videoLesson = lesson;
                            break;
                          }
                        }
                      }
                      if (videoLesson != null) break;
                    }
                    
                    if (videoLesson != null) {
                      lessonAction(videoLesson);
                    } else {
                      // No video found, show a toast message
                      Fluttertoast.showToast(
                        msg: "No preview video available for this course",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF6366F1),
                      size: 50,
                    ),
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
                        fontSize: 22,
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
        
        // Progress and status card - floating above sections
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
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
              // Progress circle
              SizedBox(
                width: 70,
                height: 70,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: progressPercent),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return CircularPercentIndicator(
                      radius: 35.0,
                      lineWidth: 6.0,
                      percent: value,
                      center: Text(
                        '${myLoadedCourse.courseCompletion ?? 0}%',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                  fontSize: 16,
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
              const SizedBox(width: 20),
              // Status info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Your Progress',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                  Text(
                          '${myLoadedCourse.totalNumberOfCompletedLessons ?? 0}/${myLoadedCourse.totalNumberOfLessons ?? 0} lessons completed',
                          style: GoogleFonts.montserrat(
                      fontSize: 14,
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
        
        // Title for course content section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Course Content',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                ),
              ],
            ),
              // Total lessons count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${myLoadedCourse.totalNumberOfLessons ?? 0} lessons',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
                    margin: const EdgeInsets.only(bottom: 15),
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
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
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
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
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
                                  width: 32,
                                  height: 32,
                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
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
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white,
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
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.white,
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
                                                    backgroundColor: Colors.white.withOpacity(0.2),
                                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                    minHeight: 4,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                      Text(
                                                "${(sectionCompletionPercentage * 100).round()}%",
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
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
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_lesson,
                                        color: Colors.white,
                                        size: 10,
                      ),
                                      const SizedBox(width: 3),
                      Text(
                                        '${sections[index].mLesson!.length} lessons',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 20,
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
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                                  fontSize: 13,
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
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 10,
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
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 11,
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
                          duration: const Duration(milliseconds: 300),
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
                  
                  // Download/unlock button
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: (myLoadedCourse.courseCompletion != null && myLoadedCourse.courseCompletion! >= 100)
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (myLoadedCourse.courseCompletion != null && myLoadedCourse.courseCompletion! >= 100) {
                            // Handle certificate download logic
                            Fluttertoast.showToast(
                              msg: "Downloading certificate...",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                            );
                          } else {
                            Fluttertoast.showToast(
                              msg: "Complete the course to unlock certificate",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (myLoadedCourse.courseCompletion != null && myLoadedCourse.courseCompletion! >= 100)
                                      ? Icons.download
                                      : Icons.lock,
                                  size: 16,
                                  color: (myLoadedCourse.courseCompletion != null && myLoadedCourse.courseCompletion! >= 100)
                                      ? const Color(0xFF6366F1)
                                      : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (myLoadedCourse.courseCompletion != null && myLoadedCourse.courseCompletion! >= 100)
                                      ? "Download"
                                      : "Locked",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: (myLoadedCourse.courseCompletion != null && myLoadedCourse.courseCompletion! >= 100)
                                        ? const Color(0xFF6366F1)
                                        : Colors.white,
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
}

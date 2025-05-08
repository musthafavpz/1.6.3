// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:academy_lms_app/screens/course_detail.dart';
import 'package:academy_lms_app/screens/image_viewer_Screen.dart';
import 'package:academy_lms_app/widgets/appbar_one.dart';
import 'package:academy_lms_app/widgets/from_vimeo_player.dart';
import 'package:academy_lms_app/widgets/new_youtube_player.dart';
import 'package:academy_lms_app/widgets/vimeo_iframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  late TabController _tabController;
  late ScrollController _scrollController;

  int? selected;
  var _isInit = true;
  var _isLoading = false;
  Lesson? _activeLesson;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_smoothScrollToTop);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  _scrollListener() {}

  _smoothScrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

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

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: kBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              titlePadding: EdgeInsets.zero,
              title: const Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15, top: 20),
                child: Center(
                  child: Text('Choose Video player',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ),
              ),
              actions: <Widget>[
                const SizedBox(height: 20),
                _buildPlayerButton(
                  title: 'Vimeo Iframe',
                  onPressed: () {
                    String vimUrl = 'https://player.vimeo.com/video/$vimeoVideoId';
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VimeoIframe(url: vimUrl)),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildPlayerButton(
                  title: 'Vimeo',
                  onPressed: () {
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
                  },
                ),
                const SizedBox(height: 10),
              ],
            );
          },
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

  Widget _buildPlayerButton({required String title, required VoidCallback onPressed}) {
    return MaterialButton(
      elevation: 0,
      color: kPrimaryColor,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(lessonUrl) async {
    if (await canLaunch(lessonUrl)) {
      await launch(lessonUrl);
    } else {
      throw 'Could not launch $lessonUrl';
    }
  }

  Widget getLessonIcon(String lessonType) {
    if (lessonType == 'video-url' ||
        lessonType == 'vimeo-url' ||
        lessonType == 'google_drive' ||
        lessonType == 'system-video') {
      return SvgPicture.asset(
        'assets/icons/video.svg',
        colorFilter: const ColorFilter.mode(kGreyLightColor, BlendMode.srcIn),
      );
    } else if (lessonType == 'quiz') {
      return SvgPicture.asset(
        'assets/icons/book.svg',
        colorFilter: const ColorFilter.mode(kGreyLightColor, BlendMode.srcIn),
      );
    } else if (lessonType == 'text') {
      return SvgPicture.asset(
        'assets/icons/text.svg',
        colorFilter: const ColorFilter.mode(kGreyLightColor, BlendMode.srcIn),
      );
    } else if (lessonType == 'document_type') {
      return SvgPicture.asset(
        'assets/icons/document.svg',
        colorFilter: const ColorFilter.mode(kGreyLightColor, BlendMode.srcIn),
      );
    } else {
      return SvgPicture.asset(
        'assets/icons/iframe.svg',
        colorFilter: const ColorFilter.mode(kGreyLightColor, BlendMode.srcIn),
      );
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
        backgroundColor: kWhiteColor,
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
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: kDefaultColor),
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
              child: const Icon(Icons.share_outlined, size: 18, color: kDefaultColor),
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
        color: kBackGroundColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kDefaultColor),
              )
            : NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, value) {
                  return [
                    // Course Header with Image and Progress
                    SliverToBoxAdapter(
                      child: _buildCourseHeader(myLoadedCourse),
                    ),
                    // Tab Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: false,
                            dividerHeight: 0,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: kDefaultColor,
                            ),
                            labelColor: kWhiteColor,
                            unselectedLabelColor: Colors.grey.shade700,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            labelPadding: const EdgeInsets.symmetric(vertical: 12),
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.play_lesson, size: 20),
                                text: 'Lessons',
                              ),
                              Tab(
                                icon: Icon(Icons.video_call_outlined, size: 20),
                                text: 'Live Class',
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLessonsTabContent(sections, myLoadedCourse),
                    LiveClassTabWidget(courseId: widget.courseId),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCourseHeader(dynamic myLoadedCourse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Image Banner
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Course image
              FadeInImage.assetNetwork(
                placeholder: 'assets/images/loading_animated.gif',
                image: myLoadedCourse.thumbnail.toString(),
                fit: BoxFit.cover,
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Course title at bottom
              Positioned(
                bottom: 15,
                left: 20,
                right: 20,
                child: Text(
                  myLoadedCourse.title.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Progress card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              const Text(
                "Your Progress",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              LinearPercentIndicator(
                animation: true,
                animationDuration: 1000,
                lineHeight: 10.0,
                percent: myLoadedCourse.courseCompletion! / 100,
                backgroundColor: Colors.grey.shade200,
                progressColor: kDefaultColor,
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${myLoadedCourse.courseCompletion}% Completed',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: myLoadedCourse.courseCompletion! > 0 
                          ? kDefaultColor 
                          : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${myLoadedCourse.totalNumberOfCompletedLessons}/${myLoadedCourse.totalNumberOfLessons} lessons',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsTabContent(List sections, dynamic myLoadedCourse) {
    return sections.isEmpty
        ? const Center(child: Text('No lessons available'))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                ListView.builder(
                  key: Key('builder ${selected.toString()}'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sections.length,
                  itemBuilder: (ctx, index) {
                    final section = sections[index];
                    return _buildSectionCard(
                      section: section, 
                      index: index, 
                      myLoadedCourse: myLoadedCourse
                    );
                  },
                ),
              ],
            ),
          );
  }

  Widget _buildSectionCard({required dynamic section, required int index, required dynamic myLoadedCourse}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        key: Key(index.toString()),
        initiallyExpanded: index == selected,
        onExpansionChanged: ((newState) {
          setState(() {
            selected = newState ? index : -1;
          });
        }),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconColor: kDefaultColor,
        collapsedIconColor: Colors.grey.shade700,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 20),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected == index 
                ? kDefaultColor.withOpacity(0.1) 
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            selected == index
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 24,
            color: selected == index ? kDefaultColor : Colors.grey.shade700,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kDefaultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: kDefaultColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    HtmlUnescape().convert(section.title.toString()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Duration
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        section.totalDuration.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Lesson count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_lesson,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${section.mLesson!.length} Lessons',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.mLesson!.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey.shade200,
              height: 1,
            ),
            itemBuilder: (ctx, indexLess) {
              final lesson = section.mLesson![indexLess];
              final bool isCompleted = lesson.isCompleted == '1';
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _activeLesson = lesson;
                  });
                  lessonAction(_activeLesson!);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // Completion checkbox
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? kDefaultColor 
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Checkbox(
                          activeColor: Colors.transparent,
                          checkColor: Colors.white,
                          value: isCompleted,
                          shape: const CircleBorder(),
                          side: BorderSide.none,
                          onChanged: (bool? value) {
                            setState(() {
                              lesson.isCompleted = value! ? '1' : '0';
                              if (value) {
                                myLoadedCourse.totalNumberOfCompletedLessons =
                                    myLoadedCourse.totalNumberOfCompletedLessons! + 1;
                              } else {
                                myLoadedCourse.totalNumberOfCompletedLessons =
                                    myLoadedCourse.totalNumberOfCompletedLessons! - 1;
                              }
                              var completePerc = 
                                  (myLoadedCourse.totalNumberOfCompletedLessons! / 
                                  myLoadedCourse.totalNumberOfLessons!) * 100;
                              myLoadedCourse.courseCompletion = completePerc.round();
                            });
                            
                            Provider.of<MyCourses>(context, listen: false)
                                .toggleLessonCompleted(
                                    lesson.id!.toInt(),
                                    value! ? 1 : 0)
                                .then((_) => CommonFunctions.showSuccessToast(
                                    'Course Progress Updated'));
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      // Lesson icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: getLessonIcon(lesson.lessonType.toString()),
                      ),
                      
                      const SizedBox(width: 15),
                      
                      // Lesson title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCompleted 
                                    ? FontWeight.w500 
                                    : FontWeight.w400,
                                color: isCompleted 
                                    ? Colors.black87 
                                    : Colors.grey.shade700,
                              ),
                            ),
                            if (lesson.duration != null && lesson.duration!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  lesson.duration!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Play button
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kDefaultColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 16,
                            color: kDefaultColor,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _activeLesson = lesson;
                          });
                          lessonAction(_activeLesson!);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}

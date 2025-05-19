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
import 'package:academy_lms_app/screens/ai_assistant.dart'; // Import for AI Assistant
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
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../constants.dart';
import '../models/lesson.dart';
import '../providers/my_courses.dart';
import '../widgets/common_functions.dart';
import '../widgets/from_network.dart';
import '../widgets/live_class_tab_widget.dart';
import 'file_data_screen.dart';
import 'package:academy_lms_app/screens/webview_screen_iframe.dart';
import 'package:http/http.dart' as http;

// AI Chat Message model
class AIChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  AIChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert to map for storing locally
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Create from map when loading from storage
  factory AIChatMessage.fromMap(Map<String, dynamic> map) {
    return AIChatMessage(
      content: map['content'],
      isUser: map['isUser'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

// AI Chat Service
class AIChatService {
  static const String apiKey = 'AIzaSyDzZXEEf4Qq6RGZFspR7NJO3VsfT1NAJnI';
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final List<Map<String, dynamic>> _memory = [];
  String _systemPrompt = '';
  Map<String, dynamic> _config = {};
  List<Map<String, dynamic>> _predefinedPrompts = [];
  String _currentLessonName = '';
  String _currentLessonDescription = '';

  // Initialize with system message
  AIChatService() {
    _loadSystemPrompt();
  }

  // Set current lesson info
  void setCurrentLesson(String lessonName, String lessonDescription) {
    _currentLessonName = lessonName;
    _currentLessonDescription = lessonDescription;
    
    // Add current lesson context to memory if it changed
    if (_memory.length > 1) {
      // Add a system message with current lesson context
      _memory.add({
        'role': 'system',
        'content': 'User is currently viewing the lesson "$lessonName". $lessonDescription'
      });
    }
  }

  // Load system prompt from configuration file
  Future<void> _loadSystemPrompt() async {
    try {
      // Default system prompt in case file loading fails
      _systemPrompt = 'You are an educational AI tutor for Elegance, created by Musthafa. '
          'You specialize in explaining complex concepts in simple terms. '
          'You are friendly, supportive, and patient. '
          'Focus your answers on educational content related to the course lessons. '
          'Keep your responses concise but informative. '
          'If you don\'t know something, be honest about it rather than making up information.';
      
      // Try to load JSON config first
      try {
        final String configJson = await rootBundle.loadString('assets/config/ai_assistant_config.json');
        if (configJson.isNotEmpty) {
          _config = jsonDecode(configJson);
          _systemPrompt = _config['systemPrompt'] ?? _systemPrompt;
          _predefinedPrompts = List<Map<String, dynamic>>.from(_config['predefinedPrompts'] ?? []);
          print('Loaded AI assistant JSON configuration');
        }
      } catch (e) {
        print('Could not load AI assistant JSON config: $e');
        
        // Try to load text config as fallback
        try {
          final String configText = await rootBundle.loadString('assets/config/ai_assistant_config.txt');
          if (configText.isNotEmpty) {
            _systemPrompt = configText;
            print('Loaded AI assistant text configuration');
          }
        } catch (e) {
          print('Could not load AI assistant text config: $e');
          // Continue with default prompt
        }
      }
      
      // Add system message to memory
      _memory.add({
        'role': 'system',
        'content': _systemPrompt
      });
    } catch (e) {
      print('Error in _loadSystemPrompt: $e');
      // Ensure we at least have a basic system prompt
      _memory.add({
        'role': 'system',
        'content': 'You are an educational AI assistant for Elegance courses.'
      });
    }
  }

  // Get the list of predefined prompts
  List<Map<String, dynamic>> getPredefinedPrompts() {
    return _predefinedPrompts;
  }

  // Add a message to memory
  void addToMemory(String message, bool isUser) {
    _memory.add({
      'role': isUser ? 'user' : 'assistant',
      'content': message
    });
  }

  // Clear conversation memory but keep system prompt
  void clearMemory() {
    final systemMessage = _memory.first;
    _memory.clear();
    _memory.add(systemMessage);
  }

  Future<String> sendMessage(String message) async {
    try {
      // Check if message is asking about current lesson
      if (message.toLowerCase().contains("this lesson") || 
          message.toLowerCase().contains("current lesson") ||
          message.toLowerCase().contains("this topic")) {
        // Ensure we have current lesson context in the chat
        if (_currentLessonName.isNotEmpty && !_memory.any((msg) => 
            msg['role'] == 'system' && 
            msg['content'].contains('User is currently viewing the lesson "$_currentLessonName"'))) {
          // Add current lesson context
          _memory.add({
            'role': 'system',
            'content': 'User is currently viewing the lesson "$_currentLessonName". $_currentLessonDescription'
          });
        }
      }
      
      // Add user message to memory
      addToMemory(message, true);
      
      // Prepare the conversation history for Gemini
      List<Map<String, dynamic>> contents = [];
      
      // Add system message if available
      if (_memory.isNotEmpty && _memory.first['role'] == 'system') {
        contents.add({
          'role': 'user',
          'parts': [{'text': _memory.first['content']}]
        });
        contents.add({
          'role': 'model',
          'parts': [{'text': 'I understand. I will help you with the course content.'}]
        });
      }
      
      // Add conversation history
      for (int i = 1; i < _memory.length; i++) {
        final msg = _memory[i];
        contents.add({
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [{'text': msg['content']}]
        });
      }
      
      // Create request body for Gemini API
      final Map<String, dynamic> requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1000,
        },
      };
      
      // Send request to Gemini API
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Add AI response to memory
        addToMemory(aiResponse, false);
        
        return aiResponse;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I encountered an error. Please try again later.';
      }
    } catch (e) {
      print('Exception in AI Chat: $e');
      return 'Sorry, I encountered an error. Please try again later.';
    }
  }

  // Save conversation to local storage
  Future<void> saveConversation(int courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = _memory.where((msg) => msg['role'] != 'system').toList();
      await prefs.setString('chat_history_$courseId', jsonEncode(conversations));
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  // Load conversation from local storage
  Future<List<AIChatMessage>> loadConversation(int courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? chatHistoryString = prefs.getString('chat_history_$courseId');
      
      if (chatHistoryString == null || chatHistoryString.isEmpty) {
        return [];
      }
      
      final List<dynamic> chatHistoryJson = jsonDecode(chatHistoryString);
      final List<AIChatMessage> messages = [];
      
      // Restore memory
      for (var msg in chatHistoryJson) {
        if (msg['role'] != 'system') {
          addToMemory(msg['content'], msg['role'] == 'user');
          messages.add(AIChatMessage(
            content: msg['content'],
            isUser: msg['role'] == 'user',
          ));
        }
      }
      
      return messages;
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }
}

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
  
  // AI Chat related variables
  final AIChatService _aiChatService = AIChatService();
  final List<AIChatMessage> _chatMessages = [];
  final TextEditingController _chatTextController = TextEditingController();
  bool _isAILoading = false;
  bool _isChatHistoryLoaded = false;
  String? _selectedLessonName;
  List<String> _lessonNames = [];
  Map<String, String> _lessonDescriptions = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    if (!_isChatHistoryLoaded) {
      final loadedMessages = await _aiChatService.loadConversation(widget.courseId);
      if (loadedMessages.isNotEmpty && mounted) {
        setState(() {
          _chatMessages.addAll(loadedMessages);
          _isChatHistoryLoaded = true;
        });
      }
    }
  }

  // Extract lesson names and descriptions from sections
  void _extractLessonInfo(List sections) {
    _lessonNames.clear();
    _lessonDescriptions.clear();
    
    for (var section in sections) {
      if (section.mLesson != null && section.mLesson!.isNotEmpty) {
        for (var lesson in section.mLesson!) {
          if (lesson.title != null) {
            _lessonNames.add(lesson.title!);
            if (lesson.summary != null && lesson.summary!.isNotEmpty) {
              _lessonDescriptions[lesson.title!] = lesson.summary!;
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatTextController.dispose();
    // Save chat history before disposing
    _aiChatService.saveConversation(widget.courseId);
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
            // Extract lesson names and descriptions for AI chat
            _extractLessonInfo(activeSections);
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
    // Set the current lesson context for AI assistant
    if (lesson.title != null) {
      _aiChatService.setCurrentLesson(
        lesson.title!, 
        lesson.summary ?? 'No description available for this lesson.'
      );
    }
    
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
          // AI Chat icon - with the current course context
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 18, color: Color(0xFF6366F1)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIAssistantScreen(
                    currentScreen: 'Course Detail',
                    screenDetails: 'You are viewing the course "${myLoadedCourse.title}". '
                        'This course has ${myLoadedCourse.totalNumberOfLessons ?? 0} lessons and '
                        'you have completed ${myLoadedCourse.totalNumberOfCompletedLessons ?? 0} lessons '
                        '(${myLoadedCourse.courseCompletion ?? 0}% complete). The course includes '
                        'various types of content such as videos, text lessons, and quizzes.',
                  ),
                ),
              );
            },
          ),
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
      // Add floating chat button
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16, right: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _showAIChatDialog,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Elegance AI',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Ask me anything',
                            style: GoogleFonts.montserrat(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Notification dot
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  // Show AI Chat Dialog
  void _showAIChatDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                body: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuad,
                  child: _buildChatDialog(context, setState),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  // Build the chat dialog content
  Widget _buildChatDialog(BuildContext context, StateSetter setState) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Chat Dialog Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x29000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course AI Assistant',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Ask anything about your lessons',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Clear chat button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Clear Chat'),
                          content: const Text('Are you sure you want to clear the chat history?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Clear'),
                              onPressed: () {
                                setState(() {
                                  _chatMessages.clear();
                                  _aiChatService.clearMemory();
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Lesson selector
          if (_lessonNames.isNotEmpty) 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a lesson to discuss:',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _lessonNames.length > 8 ? 8 : _lessonNames.length, // Limit to 8 lessons
                    itemBuilder: (context, index) {
                      final lessonName = _lessonNames[index];
                      final isSelected = _selectedLessonName == lessonName;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            lessonName.length > 20 ? '${lessonName.substring(0, 20)}...' : lessonName,
                            style: GoogleFonts.montserrat(
                              color: isSelected ? Colors.white : const Color(0xFF6366F1),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.08),
                          selectedColor: const Color(0xFF6366F1),
                          onSelected: (selected) {
                            setState(() {
                              _selectedLessonName = selected ? lessonName : null;
                              if (selected) {
                                final lessonDescription = _lessonDescriptions[lessonName] ?? 'No description available for this lesson.';
                                _chatTextController.text = 'Tell me about $lessonName';
                                
                                // Update lesson context in AI service
                                _aiChatService.setCurrentLesson(lessonName, lessonDescription);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Suggestion chips
          if (_chatMessages.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can I help you?',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _aiChatService.getPredefinedPrompts().map((prompt) {
                      return _buildSuggestionChip(
                        prompt['label'], 
                        prompt['prefix'], 
                        setState,
                        iconName: prompt['icon'],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          
          // Chat Messages List
          Expanded(
            child: _chatMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/chat_bot.svg',
                          height: 80,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF6366F1),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask me anything about your course lessons',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your conversations are saved locally',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                    ),
                    child: ListView.builder(
                      reverse: false,
                      itemCount: _chatMessages.length,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemBuilder: (context, index) {
                        final message = _chatMessages[index];
                        return _buildChatMessage(message);
                      },
                    ),
                  ),
          ),
          
          // AI Thinking Indicator
          if (_isAILoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const SpinKitThreeBounce(
                    color: Color(0xFF6366F1),
                    size: 16,
                  ),
                ],
              ),
            ),
          
          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatTextController,
                    decoration: InputDecoration(
                      hintText: 'Type your question here...',
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.mic, color: Color(0xFF6366F1)),
                        onPressed: () {
                          // Voice input functionality could be added here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Voice input coming soon!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                    onSubmitted: (_) => _sendChatMessage(setState),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
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
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => _sendChatMessage(setState),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a suggestion chip
  Widget _buildSuggestionChip(String label, String prefix, StateSetter setState, {String? iconName}) {
    // Map string icon names to actual Icons
    IconData getIconData(String? name) {
      switch (name) {
        case 'lightbulb_outline': return Icons.lightbulb_outline;
        case 'book_outlined': return Icons.book_outlined;
        case 'help_outline': return Icons.help_outline;
        case 'school': return Icons.school;
        case 'compare_arrows': return Icons.compare_arrows;
        case 'summarize': return Icons.summarize;
        case 'lightbulb': return Icons.lightbulb;
        case 'quiz': return Icons.quiz;
        case 'assignment': return Icons.assignment;
        case 'psychology': return Icons.psychology;
        default: return Icons.lightbulb_outline;
      }
    }
    
    return InkWell(
      onTap: () {
        _chatTextController.text = '$prefix ';
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getIconData(iconName),
              size: 16,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: const Color(0xFF6366F1),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a single chat message
  Widget _buildChatMessage(AIChatMessage message) {
    final isUser = message.isUser;
    
    // Process formatting in the message content - only bold text wrapped in **text**
    Widget buildFormattedText(String content) {
      // If it's a user message, just return regular text
      if (isUser) {
        return Text(
          content,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 14,
          ),
        );
      }
      
      // For AI responses, only format text with markdown-style bold syntax
      List<TextSpan> spans = [];
      
      // Check for explicit markdown-style bold formatting (**text**)
      RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
      
      int lastMatchEnd = 0;
      for (Match match in boldPattern.allMatches(content)) {
        // Add text before the match
        if (match.start > lastMatchEnd) {
          spans.add(TextSpan(
            text: content.substring(lastMatchEnd, match.start),
            style: GoogleFonts.montserrat(
              color: const Color(0xFF333333),
              fontSize: 14,
            ),
          ));
        }
        
        // Add the bolded text (without the ** markers)
        String boldText = match.group(1) ?? '';
        spans.add(TextSpan(
          text: boldText,
          style: GoogleFonts.montserrat(
            color: const Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ));
        
        lastMatchEnd = match.end;
      }
      
      // Add any remaining text after the last match
      if (lastMatchEnd < content.length) {
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd),
          style: GoogleFonts.montserrat(
            color: const Color(0xFF333333),
            fontSize: 14,
          ),
        ));
      }
      
      // If no matches were found, just add the entire content as regular text
      if (spans.isEmpty) {
        spans.add(TextSpan(
          text: content,
          style: GoogleFonts.montserrat(
            color: const Color(0xFF333333),
            fontSize: 14,
          ),
        ));
      }
      
      return RichText(
        text: TextSpan(children: spans),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 300),
        child: SlideAnimation(
          horizontalOffset: isUser ? 50.0 : -50.0,
          child: FadeInAnimation(
            child: Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) 
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? const Color(0xFF6366F1)
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isUser ? 18 : 4),
                        topRight: Radius.circular(isUser ? 4 : 18),
                        bottomLeft: const Radius.circular(18),
                        bottomRight: const Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildFormattedText(message.content),
                        const SizedBox(height: 4),
                        Text(
                          // Format time as HH:MM
                          '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.montserrat(
                            color: isUser ? Colors.white.withOpacity(0.7) : Colors.grey[400],
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (isUser)
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Send a chat message
  void _sendChatMessage(StateSetter setState) async {
    final userMessage = _chatTextController.text.trim();
    if (userMessage.isEmpty) return;
    
    // Set the current lesson context if a lesson is selected
    if (_selectedLessonName != null) {
      final lessonDescription = _lessonDescriptions[_selectedLessonName] ?? 'No description available for this lesson.';
      _aiChatService.setCurrentLesson(_selectedLessonName!, lessonDescription);
    }
    
    setState(() {
      _chatMessages.add(AIChatMessage(
        content: userMessage,
        isUser: true,
      ));
      _isAILoading = true;
      _chatTextController.clear();
      _selectedLessonName = null; // Clear lesson selection after sending
    });
    
    try {
      final aiResponse = await _aiChatService.sendMessage(userMessage);
      
      if (mounted) {
        setState(() {
          _chatMessages.add(AIChatMessage(
            content: aiResponse,
            isUser: false,
          ));
          _isAILoading = false;
        });
        
        // Save conversation to local storage
        _aiChatService.saveConversation(widget.courseId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add(AIChatMessage(
            content: "Sorry, I encountered an error. Please try again.",
            isUser: false,
          ));
          _isAILoading = false;
        });
      }
    }
  }
}
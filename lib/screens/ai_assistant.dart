import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'package:flutter/services.dart';

// Reusing AIChatMessage and AIChatService from my_course_detail.dart
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

// AI Chat Service - adapted from my_course_detail.dart
class AppAIChatService {
  static const String apiKey = 'AIzaSyDzZXEEf4Qq6RGZFspR7NJO3VsfT1NAJnI';
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final List<Map<String, dynamic>> _memory = [];
  String _currentScreen = '';
  String _currentScreenDetails = '';
  String _systemPrompt = '';
  Map<String, dynamic> _config = {};
  List<Map<String, dynamic>> _predefinedPrompts = [
    {
      'label': 'Navigation',
      'prefix': 'How do I navigate to',
      'icon': 'navigation'
    },
    {
      'label': 'Features',
      'prefix': 'Explain the feature',
      'icon': 'features'
    },
    {
      'label': 'Help',
      'prefix': 'I need help with',
      'icon': 'help'
    },
    {
      'label': 'This Screen',
      'prefix': 'Explain this screen',
      'icon': 'screen'
    }
  ];

  // Initialize with system message
  AppAIChatService() {
    _loadSystemPrompt();
  }
  
  // Set current screen info
  void setCurrentScreen(String screenName, String screenDetails) {
    _currentScreen = screenName;
    _currentScreenDetails = screenDetails;
    
    // Add current screen context to memory if it changed
    if (_memory.length > 1) {
      // Add a system message with current screen context
      _memory.add({
        'role': 'system',
        'content': 'User is currently on the $screenName screen. $screenDetails'
      });
    }
  }

  // Load system prompt - navigation/support focused
  Future<void> _loadSystemPrompt() async {
    try {
      // Default navigation-focused system prompt
      _systemPrompt = 'You are an AI support agent for the Elegance educational app. '
          'Your role is to help users navigate the app, understand features, and solve any issues they encounter. '
          'The app has the following main sections: Home, Explore, My Courses, and Account. '
          'You should be friendly, concise, and helpful. '
          'If asked about course content, suggest they use the course-specific AI assistant available in each course detail screen. '
          'You are aware of the current screen the user is on and can provide specific help about it when asked. '
          'When user asks about "this screen", provide information about their current screen. '
          'Keep your responses brief and focused on helping users use the app effectively.';
      
      // Try to load JSON config first
      try {
        final String configJson = await rootBundle.loadString('assets/config/ai_assistant_config.json');
        if (configJson.isNotEmpty) {
          _config = jsonDecode(configJson);
          _systemPrompt = _config['appSystemPrompt'] ?? _systemPrompt; // Use appSystemPrompt for app navigation
          if (_config['appPredefinedPrompts'] != null) {
            _predefinedPrompts = List<Map<String, dynamic>>.from(_config['appPredefinedPrompts']);
          }
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
        'content': 'You are a support assistant for the Elegance app.'
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
    
    // Re-add current screen context if available
    if (_currentScreen.isNotEmpty) {
      _memory.add({
        'role': 'system',
        'content': 'User is currently on the $_currentScreen screen. $_currentScreenDetails'
      });
    }
  }

  Future<String> sendMessage(String message) async {
    try {
      // Check if message is asking about current screen
      if (message.toLowerCase().contains('this screen') || 
          message.toLowerCase().contains('current screen') ||
          message.toLowerCase().contains('here')) {
        // Ensure we have current screen context in the chat
        if (_currentScreen.isNotEmpty && !_memory.any((msg) => 
            msg['role'] == 'system' && 
            msg['content'].contains('User is currently on the $_currentScreen screen'))) {
          // Add current screen context
          _memory.add({
            'role': 'system',
            'content': 'User is currently on the $_currentScreen screen. $_currentScreenDetails'
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
          'parts': [{'text': 'I understand. I will help you with the Elegance educational app.'}]
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
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };
      
      // Send request to Gemini API
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract the response text from Gemini's response format
        String aiResponse = '';
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null && 
              candidate['content']['parts'].isNotEmpty) {
            aiResponse = candidate['content']['parts'][0]['text'];
          }
        }
        
        if (aiResponse.isEmpty) {
          aiResponse = 'I apologize, but I could not generate a proper response. Please try again.';
        }
        
        // Add AI response to memory
        addToMemory(aiResponse, false);
        
        return aiResponse;
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        // Provide more detailed error message
        if (response.statusCode == 401) {
          print('Authentication error - API key issue');
          return 'Sorry, I encountered an authentication error. Please check the API configuration.';
        } else if (response.statusCode == 429) {
          print('Rate limit exceeded');
          return 'Sorry, the AI service is currently busy. Please try again in a moment.';
        } else {
          print('Other API error: ${response.statusCode}');
          return 'Sorry, I encountered an error connecting to the AI service. Please try again later.';
        }
      }
    } catch (e) {
      print('Exception in AI Chat: $e');
      return 'Sorry, I encountered an error. Please check your internet connection and try again.';
    }
  }

  // Save conversation to local storage
  Future<void> saveConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = _memory.where((msg) => 
        msg['role'] != 'system' || 
        (msg['content'] as String).startsWith('You are')).toList();
      await prefs.setString('app_chat_history', jsonEncode(conversations));
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  // Load conversation from local storage
  Future<List<AIChatMessage>> loadConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? chatHistoryString = prefs.getString('app_chat_history');
      
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
        } else if ((msg['content'] as String).startsWith('You are')) {
          // Only add back the main system prompt
          if (_memory.isEmpty || !_memory.any((m) => m['role'] == 'system' && (m['content'] as String).startsWith('You are'))) {
            _memory.add(msg);
          }
        }
      }
      
      return messages;
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }
}

class AIAssistantScreen extends StatefulWidget {
  static const routeName = '/ai-assistant';
  final String? currentScreen;
  final String? screenDetails;

  const AIAssistantScreen({
    super.key, 
    this.currentScreen, 
    this.screenDetails
  });

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _chatTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AppAIChatService _aiChatService = AppAIChatService();
  final List<AIChatMessage> _chatMessages = [];
  bool _isAILoading = false;
  bool _isChatHistoryLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    
    // Set current screen info if available
    if (widget.currentScreen != null && widget.screenDetails != null) {
      _aiChatService.setCurrentScreen(
        widget.currentScreen!, 
        widget.screenDetails!
      );
    }
  }

  @override
  void didUpdateWidget(AIAssistantScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update screen context if changed
    if (widget.currentScreen != oldWidget.currentScreen ||
        widget.screenDetails != oldWidget.screenDetails) {
      if (widget.currentScreen != null && widget.screenDetails != null) {
        _aiChatService.setCurrentScreen(
          widget.currentScreen!, 
          widget.screenDetails!
        );
      }
    }
  }
  
  Future<void> _loadChatHistory() async {
    if (!_isChatHistoryLoaded) {
      final loadedMessages = await _aiChatService.loadConversation();
      if (loadedMessages.isNotEmpty && mounted) {
        setState(() {
          _chatMessages.addAll(loadedMessages);
          _isChatHistoryLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _chatTextController.dispose();
    _scrollController.dispose();
    // Save chat history before disposing
    _aiChatService.saveConversation();
    super.dispose();
  }

  // Send a chat message
  void _sendChatMessage() async {
    final userMessage = _chatTextController.text.trim();
    if (userMessage.isEmpty) return;
    
    setState(() {
      _chatMessages.add(AIChatMessage(
        content: userMessage,
        isUser: true,
      ));
      _isAILoading = true;
      _chatTextController.clear();
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
        _aiChatService.saveConversation();
        
        // Scroll to bottom
    _scrollToBottom();
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Build a suggestion chip
  Widget _buildSuggestionChip(String label, String prefix, {String? iconName}) {
    // Map string icon names to actual Icons
    IconData getIconData(String? name) {
      switch (name) {
        case 'navigation': return Icons.explore;
        case 'features': return Icons.star_border;
        case 'help': return Icons.help_outline;
        case 'settings': return Icons.settings;
        case 'screen': return Icons.phone_android;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Elegance AI Support',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Chat History'),
                  content: const Text('Are you sure you want to clear all messages?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                      ),
                      onPressed: () {
                        setState(() {
                          _chatMessages.clear();
                          _aiChatService.clearMemory();
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggestion chips
          if (_chatMessages.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  Text(
                    'How can I help you with the app?',
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
                          'Ask me anything about navigating the app',
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
                      controller: _scrollController,
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
                      hintText: 'Ask about app features or navigation...',
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
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
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
                    onPressed: _sendChatMessage,
                  ),
                ),
              ],
            ),
            ),
        ],
      ),
    );
  }
} 
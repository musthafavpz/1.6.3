import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_message.dart';
import '../constants.dart';

class AIAssistantProvider with ChangeNotifier {
  List<AIMessage> _messages = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Replace this with your actual OpenRouter API key
  static const String apiKey = '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';
  static const String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  List<AIMessage> get messages => [..._messages];
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // Load messages from SharedPreferences
  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('ai_messages');
    
    if (messagesJson != null) {
      try {
        final List<dynamic> decodedData = json.decode(messagesJson);
        _messages = decodedData
            .map((item) => AIMessage.fromJson(item))
            .toList();
        notifyListeners();
      } catch (e) {
        print('Error loading messages: $e');
      }
    }
  }
  
  // Save messages to SharedPreferences
  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesData = _messages.map((message) => message.toJson()).toList();
    await prefs.setString('ai_messages', json.encode(messagesData));
  }
  
  // Add a message to the chat
  void addMessage(String content, String role) {
    final message = AIMessage(
      content: content,
      role: role,
    );
    
    _messages.add(message);
    saveMessages();
    notifyListeners();
  }
  
  // Clear all messages
  Future<void> clearMessages() async {
    _messages = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_messages');
    notifyListeners();
  }
  
  // Send a text message to the AI and get a response
  Future<void> sendMessageToAI(String message) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    // Add user message to chat
    addMessage(message, 'user');
    
    try {
      // Prepare messages payload in the format required by OpenRouter
      final List<Map<String, dynamic>> messagesPayload = [];
      
      // Add previous messages
      for (var msg in _messages) {
        messagesPayload.add({
          'role': msg.role,
          'content': msg.content,
        });
      }
      
      // Create request body based on the Python OpenAI client format
      final Map<String, dynamic> requestBody = {
        'model': 'qwen/qwen3-235b-a22b:free',
        'messages': messagesPayload,
      };
      
      // Send request to OpenRouter API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://academy_lms_app.com',
          'X-Title': 'Academy LMS App',
        },
        body: json.encode(requestBody),
      );
      
      // Handle response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Extract message content based on the completion response format
        final assistantMessage = responseData['choices'][0]['message']['content'];
        
        // Add assistant response to chat
        addMessage(assistantMessage, 'assistant');
      } else {
        print('OpenRouter API Error: ${response.statusCode} - ${response.body}');
        
        if (response.statusCode == 401) {
          _errorMessage = 'Authentication error: Please check API key configuration';
        } else {
          _errorMessage = 'Error ${response.statusCode}: Unable to connect to AI service';
        }
        notifyListeners();
      }
    } catch (error) {
      print('Error connecting to AI service: $error');
      _errorMessage = 'Error connecting to AI service. Please try again.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Send a message with an image to the AI
  Future<void> sendMessageWithImageToAI(String message, String imageUrl) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    // Add user message to chat (we'll just show the text part in the UI)
    addMessage(message, 'user');
    
    try {
      // For the image-enabled model, we need to format content as an array of content blocks
      // Prepare messages payload
      final List<Map<String, dynamic>> messagesPayload = [];
      
      // Add previous text messages
      for (int i = 0; i < _messages.length - 1; i++) {
        var msg = _messages[i];
        messagesPayload.add({
          'role': msg.role,
          'content': msg.content,
        });
      }
      
      // Add the latest message with both text and image
      messagesPayload.add({
        'role': 'user',
        'content': [
          {
            'type': 'text',
            'text': message,
          },
          {
            'type': 'image_url',
            'image_url': {
              'url': imageUrl,
            },
          },
        ],
      });
      
      // Create request body
      final Map<String, dynamic> requestBody = {
        'model': 'qwen/qwen3-235b-a22b:free',
        'messages': messagesPayload,
      };
      
      // Send request to OpenRouter API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://academy_lms_app.com',
          'X-Title': 'Academy LMS App',
        },
        body: json.encode(requestBody),
      );
      
      // Handle response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Extract message content from response
        final assistantMessage = responseData['choices'][0]['message']['content'];
        
        // Handle case where content might be a string or an array with text content
        String finalMessage;
        if (assistantMessage is String) {
          finalMessage = assistantMessage;
        } else if (assistantMessage is List && assistantMessage.isNotEmpty) {
          // Extract text from content array
          final textContent = assistantMessage.firstWhere(
            (item) => item['type'] == 'text',
            orElse: () => {'text': 'No text response available'},
          );
          finalMessage = textContent['text'];
        } else {
          finalMessage = 'Unable to process response from AI assistant';
        }
        
        // Add assistant response to chat
        addMessage(finalMessage, 'assistant');
      } else {
        print('OpenRouter API Error: ${response.statusCode} - ${response.body}');
        
        if (response.statusCode == 401) {
          _errorMessage = 'Authentication error: Please check API key configuration';
        } else {
          _errorMessage = 'Error ${response.statusCode}: Unable to connect to AI service';
        }
        notifyListeners();
      }
    } catch (error) {
      print('Error connecting to AI service: $error');
      _errorMessage = 'Error connecting to AI service. Please try again.';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 
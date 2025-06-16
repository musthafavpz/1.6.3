import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../widgets/appbar_one.dart';
import '../providers/my_courses.dart';

class QuizScreen extends StatefulWidget {
  final int lessonId;
  final int courseId;
  final String quizTitle;

  const QuizScreen({
    Key? key, 
    required this.lessonId, 
    required this.courseId,
    required this.quizTitle,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  Map<String, dynamic>? _quizData;
  List<Map<String, dynamic>> _questions = [];
  Map<int, int> _selectedAnswers = {}; // questionId -> selected option index
  
  // Quiz navigation
  int _currentQuestionIndex = 0;
  
  // Quiz result data
  bool _showResults = false;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  double _percentage = 0.0;
  String _status = '';
  
  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }
  
  Future<void> _fetchQuizData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");
      
      print('Quiz API - Token: ${token != null ? (token.length > 10 ? token.substring(0, 10) + "..." : token) : "Not found"}');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      
      // Test API call to verify token validity
      print('Quiz API - Testing token validity with user API call');
      try {
        final testResponse = await http.get(
          Uri.parse('$baseUrl/api/user'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        
        print('Quiz API - Test API call status code: ${testResponse.statusCode}');
        print('Quiz API - Test API call response: ${testResponse.body}');
      } catch (e) {
        print('Quiz API - Test API call error: $e');
      }
      
      print('Quiz API - Making request to: $baseUrl/api/quiz/${widget.lessonId}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/quiz/${widget.lessonId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      print('Quiz API - Response status code: ${response.statusCode}');
      print('Quiz API - Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _quizData = data;
          _questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
          
          // Ensure question_id is an integer
          for (var i = 0; i < _questions.length; i++) {
            if (_questions[i]['question_id'] is String) {
              _questions[i]['question_id'] = int.tryParse(_questions[i]['question_id']) ?? i;
            } else if (_questions[i]['question_id'] is double) {
              _questions[i]['question_id'] = (_questions[i]['question_id'] as double).toInt();
            }
            
            // Log the question ID type
            print('Question ${i + 1} ID: ${_questions[i]['question_id']} (${_questions[i]['question_id'].runtimeType})');
          }
          
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Authentication error
        throw Exception('Authentication failed. Please try logging out and logging back in.');
      } else {
        throw Exception('Failed to load quiz: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Quiz API - Error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      // Show toast for authentication errors
      if (e.toString().contains('Authentication failed')) {
        Fluttertoast.showToast(
          msg: "Authentication error. Please log out and log back in.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
  
  Future<void> _submitQuiz() async {
    // Validate that all questions have answers
    if (_selectedAnswers.length < _questions.length) {
      Fluttertoast.showToast(
        msg: "Please answer all questions before submitting",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");
      
      print('Quiz Submit - Token: ${token != null ? "Found" : "Not found"}');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      
      // Prepare submission data
      final Map<String, List<String>> answers = {};
      int correctCount = 0;
      int wrongCount = 0;
      
      // Calculate correct and wrong answers
      for (var question in _questions) {
        // Make sure questionId is treated as an integer string
        final int questionIdInt = question['question_id'] is int 
            ? question['question_id'] 
            : int.tryParse(question['question_id'].toString()) ?? 0;
            
        final String questionId = questionIdInt.toString();
        final selectedIndex = _selectedAnswers[questionIdInt];
        
        if (selectedIndex != null) {
          // Ensure options is a List<String>
          List<String> options = [];
          if (question['options'] != null) {
            if (question['options'] is List) {
              options = List<String>.from(
                (question['options'] as List).map((e) => e.toString())
              );
            }
          }
          
          if (options.isNotEmpty && selectedIndex < options.length) {
            final selectedAnswer = options[selectedIndex];
            // Store answer as a list of strings for this question ID
            answers[questionId] = [selectedAnswer];
            
            // Check if answer is correct - handle different answer formats
            bool isCorrect = false;
            if (question['answer'] != null) {
              if (question['answer'] is List) {
                final correctAnswers = List<String>.from(
                  (question['answer'] as List).map((e) => e.toString())
                );
                isCorrect = correctAnswers.contains(selectedAnswer);
              } else if (question['answer'] is String) {
                isCorrect = question['answer'] == selectedAnswer;
              }
            }
            
            if (isCorrect) {
              correctCount++;
            } else {
              wrongCount++;
            }
          }
        }
      }
      
      // Debug the final answers format
      print('Quiz Submit - Answers format:');
      answers.forEach((questionId, answerList) {
        print('Question $questionId: $answerList');
      });
      
      // Calculate percentage score
      final double percentageScore = (_questions.length > 0) 
          ? (correctCount / _questions.length) * 100 
          : 0;
      
      // Course progress is automatically updated by the backend when score >= 70%
      final bool passedQuiz = percentageScore >= 70;
      
      // Create the request body
      final requestBody = {
        'quiz_id': widget.lessonId,
        'lesson_id': widget.lessonId,
        'answers': answers,
        'correct_answer': correctCount,
        'wrong_answer': wrongCount,
        'submits': 1,
        // Backend will use this to auto-update course progress
        'is_completed': passedQuiz ? 1 : 0,
      };
      
      // Debug output
      print('Quiz Submit - Sending data to: $baseUrl/api/quiz/submit');
      print('Quiz Submit - Data: ${json.encode(requestBody)}');
      print('Quiz Submit - Quiz passed (≥70%): $passedQuiz (Score: ${percentageScore.toStringAsFixed(1)}%)');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/quiz/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      print('Quiz Submit - Response status code: ${response.statusCode}');
      print('Quiz Submit - Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Ensure proper type casting for numeric values
        final obtainedMarks = (result['obtained_marks'] != null) 
            ? (result['obtained_marks'] is int 
                ? result['obtained_marks'] 
                : (result['obtained_marks'] is double 
                    ? result['obtained_marks'].toInt() 
                    : int.tryParse(result['obtained_marks'].toString()) ?? correctCount))
            : correctCount;
        
        final totalMarks = (result['total_marks'] != null)
            ? (result['total_marks'] is int 
                ? result['total_marks'] 
                : (result['total_marks'] is double 
                    ? result['total_marks'].toInt() 
                    : int.tryParse(result['total_marks'].toString()) ?? _questions.length))
            : _questions.length;
        
        final percentageValue = (result['percentage'] != null)
            ? (result['percentage'] is int 
                ? result['percentage'].toDouble() 
                : (result['percentage'] is double 
                    ? result['percentage'] 
                    : double.tryParse(result['percentage'].toString()) ?? ((correctCount / _questions.length) * 100)))
            : ((correctCount / _questions.length) * 100);
        
        // Check if user previously passed the quiz
        final bool previouslyPassed = result['previously_passed'] == true;
        final String statusValue = result['status'] ?? (_percentage >= 70 ? 'passed' : 'failed');
        
        setState(() {
          _isSubmitting = false;
          _showResults = true;
          _correctAnswers = obtainedMarks;
          _wrongAnswers = totalMarks - obtainedMarks;
          _percentage = percentageValue;
          _status = statusValue;
        });
        
        // Show toast message about course progress
        if (passedQuiz) {
          Fluttertoast.showToast(
            msg: "Quiz passed! Course progress updated.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            textColor: Colors.white,
          );
        } else if (previouslyPassed || statusValue == 'previously_passed') {
          // If user previously passed but failed now, show a different message
          Fluttertoast.showToast(
            msg: "You didn't pass this time, but you've previously passed this quiz. Your progress is already saved.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
        
        print('Quiz Results - Processed values:');
        print('Obtained marks: $_correctAnswers (${_correctAnswers.runtimeType})');
        print('Wrong answers: $_wrongAnswers (${_wrongAnswers.runtimeType})');
        print('Percentage: $_percentage (${_percentage.runtimeType})');
        print('Status: $_status');
        print('Previously passed: $previouslyPassed');
      } else if (response.statusCode == 422) {
        // Validation error
        final errorData = json.decode(response.body);
        print('Quiz Submit - Validation error: $errorData');
        throw Exception('Validation error: ${errorData['message'] ?? "Please check your answers"}');
      } else if (response.statusCode == 401) {
        // Authentication error
        throw Exception('Authentication failed. Please try logging out and logging back in.');
      } else {
        throw Exception('Failed to submit quiz: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Quiz Submit - Error: $e');
      setState(() {
        _isSubmitting = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      Fluttertoast.showToast(
        msg: "Error submitting quiz: ${e.toString().split(":").last.trim()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
  
  void _selectAnswer(int questionId, int optionIndex) {
    setState(() {
      _selectedAnswers[questionId] = optionIndex;
      
      // Auto-navigation to next question removed
      // Now the user must click the Next button
    });
    
    // Debug
    print('Selected answer for question $questionId: option $optionIndex');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Quiz',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF6366F1)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitThreeBounce(
              color: Color(0xFF6366F1),
              size: 30,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading quiz...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading quiz',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchQuizData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_showResults) {
      return _buildResultsScreen();
    }
    
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.quiz_outlined,
              color: Colors.grey,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'No questions available',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Progress indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    '${(_selectedAnswers.length * 100 / _questions.length).round()}% Completed',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
        ),
        
        // Current question
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildQuestionCard(_currentQuestionIndex),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuestionCard(int index) {
    if (index >= _questions.length) return Container();
    
    final question = _questions[index];
    
    // Make sure questionId is always an integer
    final dynamic rawQuestionId = question['question_id'];
    final int questionId = rawQuestionId is int 
        ? rawQuestionId
        : rawQuestionId is double 
            ? rawQuestionId.toInt()
            : rawQuestionId is String 
                ? int.tryParse(rawQuestionId) ?? index
                : index;
    
    // Ensure options is a List<String>
    List<String> options = [];
    if (question['options'] != null) {
      if (question['options'] is List) {
        options = List<String>.from(
          (question['options'] as List).map((e) => e.toString())
        );
      }
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${index + 1}',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question['question_text'],
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Options
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select one answer:',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  options.length,
                  (optionIndex) => _buildOptionItem(
                    options[optionIndex],
                    optionIndex,
                    questionId,
                    _selectedAnswers[questionId] == optionIndex,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuizInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOptionItem(String option, int optionIndex, int questionId, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectAnswer(questionId, optionIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ] 
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    )
                  : Center(
                      child: Text(
                        String.fromCharCode(65 + optionIndex), // A, B, C, D...
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF333333),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultsScreen() {
    final bool isPassed = _status == 'passed';
    final bool isPreviouslyPassed = _status == 'previously_passed';
    final totalQuestions = _correctAnswers + _wrongAnswers;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Trophy/Medal animation container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPassed || isPreviouslyPassed
                    ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                    : [const Color(0xFFF43F5E), const Color(0xFFFB7185)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isPassed || isPreviouslyPassed
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : const Color(0xFFF43F5E).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Trophy/Medal icon
                Icon(
                  isPassed ? Icons.emoji_events : (isPreviouslyPassed ? Icons.verified_user : Icons.psychology),
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 24),
                // Result title
                Text(
                  isPassed 
                      ? 'Congratulations!' 
                      : (isPreviouslyPassed ? 'Already Completed!' : 'Nice Try!'),
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Result subtitle
                Text(
                  isPassed
                      ? 'You have passed the quiz'
                      : (isPreviouslyPassed 
                          ? 'You\'ve previously passed this quiz' 
                          : 'Keep learning and try again'),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                if (isPreviouslyPassed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Your progress is already saved',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                // Score circle
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_percentage.round()}%',
                          style: GoogleFonts.montserrat(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Score',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Stats cards in a grid
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Summary',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildResultStatCard(
                      icon: Icons.check_circle,
                      color: const Color(0xFF10B981),
                      title: 'Correct',
                      value: '$_correctAnswers',
                      subtitle: 'Answers',
                    ),
                    const SizedBox(width: 15),
                    _buildResultStatCard(
                      icon: Icons.cancel,
                      color: const Color(0xFFF43F5E),
                      title: 'Wrong',
                      value: '$_wrongAnswers',
                      subtitle: 'Answers',
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildResultStatCard(
                      icon: Icons.quiz,
                      color: const Color(0xFF6366F1),
                      title: 'Total',
                      value: '$totalQuestions',
                      subtitle: 'Questions',
                    ),
                    const SizedBox(width: 15),
                    _buildResultStatCard(
                      icon: isPassed ? Icons.verified : (isPreviouslyPassed ? Icons.history : Icons.gpp_bad),
                      color: isPassed ? const Color(0xFF10B981) : (isPreviouslyPassed ? Colors.amber : const Color(0xFFF43F5E)),
                      title: 'Status',
                      value: isPreviouslyPassed ? 'SAVED' : _status.toUpperCase(),
                      subtitle: isPassed 
                          ? 'Congratulations!' 
                          : (isPreviouslyPassed ? 'Already completed' : 'Try again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Mark as Completed button (only shows when passed or previously passed)
          if (isPassed || isPreviouslyPassed)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Updating lesson status...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    
                    // Get provider instance
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString("access_token");
                    
                    if (token == null) {
                      throw Exception('Authentication token not found');
                    }
                    
                    // Call the API to mark lesson as completed
                    final response = await http.get(
                      Uri.parse('$baseUrl/api/save_course_progress?lesson_id=${widget.lessonId}'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                      },
                    );
                    
                    if (response.statusCode == 200) {
                      // Show success message
                      Fluttertoast.showToast(
                        msg: "Lesson marked as completed!",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: const Color(0xFF10B981),
                        textColor: Colors.white,
                      );
                      
                      // Pop with refresh flag
                      Navigator.of(context).pop(true);
                    } else {
                      throw Exception('Failed to update lesson status');
                    }
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: "Error updating lesson: ${e.toString()}",
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  'Mark Lesson as Completed',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showResults = false;
                      _selectedAnswers.clear();
                      _currentQuestionIndex = 0;
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'Try Again',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
                  label: Text(
                    'Back to Course',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget? _buildBottomBar() {
    if (_isLoading || _hasError || _showResults) {
      return null;
    }
    
    if (_questions.isEmpty) {
      return null;
    }
    
    final hasSelectedCurrentAnswer = _selectedAnswers.containsKey(
      _questions[_currentQuestionIndex]['question_id'] is int 
          ? _questions[_currentQuestionIndex]['question_id'] 
          : int.tryParse(_questions[_currentQuestionIndex]['question_id'].toString()) ?? _currentQuestionIndex
    );
    
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    final isFirstQuestion = _currentQuestionIndex == 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            if (!isFirstQuestion)
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentQuestionIndex--;
                    });
                  },
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF6366F1)),
                  label: Text(
                    'Previous',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
              ),
            
            if (!isFirstQuestion)
              const SizedBox(width: 12),
            
            // Next or Submit button
            Expanded(
              flex: isFirstQuestion ? 2 : 1,
              child: ElevatedButton.icon(
                onPressed: isLastQuestion 
                    ? (hasSelectedCurrentAnswer && _selectedAnswers.length == _questions.length 
                        ? (_isSubmitting ? null : _submitQuiz) 
                        : null) 
                    : (hasSelectedCurrentAnswer 
                        ? () {
                            setState(() {
                              _currentQuestionIndex++;
                            });
                          } 
                        : null),
                icon: Icon(
                  isLastQuestion ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  isLastQuestion ? 'Submit Quiz' : 'Next',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
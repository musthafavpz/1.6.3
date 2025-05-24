import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../widgets/appbar_one.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Map<String, String>> _faqCategories = [
    {'id': 'All', 'name': 'All Questions'},
    {'id': 'General', 'name': 'General'},
    {'id': 'Account', 'name': 'Account & Progress'},
    {'id': 'Technical', 'name': 'Technical Support'},
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'What is this app about?',
      'answer': 'This app is designed to help you learn and practice various subjects through interactive courses, quizzes, and AI-powered assistance.',
      'category': 'General',
    },
    {
      'question': 'How does the AI assistant work?',
      'answer': 'The AI assistant uses advanced language models to provide context-aware help. It can answer questions about your current course, explain concepts, and help you with your learning journey.',
      'category': 'Technical',
    },
    {
      'question': 'How do I track my progress?',
      'answer': 'Your progress is automatically tracked as you complete lessons and quizzes. You can view your progress in the course details screen and your profile.',
      'category': 'Account',
    },
    {
      'question': 'Can I download courses for offline use?',
      'answer': 'Yes, you can download courses for offline access. Look for the download icon in the course details screen.',
      'category': 'General',
    },
    {
      'question': 'How do I reset my progress?',
      'answer': 'You can reset your progress for a specific course by going to the course details screen and using the reset option in the settings menu.',
      'category': 'Account',
    },
    {
      'question': 'Is my data secure?',
      'answer': 'Yes, we take data security seriously. All your personal information and progress data are encrypted and stored securely.',
      'category': 'General',
    },
    {
      'question': 'How can I get help if I have issues?',
      'answer': 'You can contact our support team through the settings screen or email us directly at support@example.com.',
      'category': 'Technical',
    },
  ];

  List<Map<String, dynamic>> get _filteredFaqs {
    return _faqs.where((faq) {
      final matchesSearch = faq['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBarOne(
        title: 'Frequently Asked Questions',
      ),
      body: Column(
        children: [
          // Header section with gradient background
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.question_answer_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
          'Frequently Asked Questions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Find answers to common questions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
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
          ),
          
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                hintStyle: TextStyle(color: Colors.grey[500]),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              style: const TextStyle(color: Color(0xFF333333)),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _faqCategories.length,
              itemBuilder: (context, index) {
                final category = _faqCategories[index];
                final isSelected = category['id'] == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category['id']!;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No FAQs found',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term or category',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqs[index];
                      return FAQItem(
                        question: faq['question'],
                        answer: faq['answer'],
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement contact support functionality
              },
              icon: const Icon(Icons.support_agent, color: Colors.white),
              label: Text(
                'Contact Support',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 54),
                elevation: 2,
                shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItem({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 0.5),
      ),
      surfaceTintColor: Colors.white,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.question,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          collapsedIconColor: const Color(0xFF6366F1),
          iconColor: const Color(0xFF6366F1),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
              if (expanded) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            });
          },
          trailing: Container(
            decoration: BoxDecoration(
              color: _isExpanded ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: _isExpanded ? const Color(0xFF6366F1) : Colors.grey[600],
              ),
            ),
          ),
          children: [
            const SizedBox(height: 8),
            SizeTransition(
              sizeFactor: _animation,
              child: FadeTransition(
                opacity: _animation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.1),
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
            Text(
              widget.answer,
              style: GoogleFonts.poppins(
                fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
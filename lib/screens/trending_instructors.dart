import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../widgets/appbar_one.dart';
import 'instructor_screen.dart';

class TrendingInstructorsScreen extends StatefulWidget {
  final List instructors;
  final String title;
  
  const TrendingInstructorsScreen({
    Key? key,
    required this.instructors,
    required this.title,
  }) : super(key: key);

  @override
  State<TrendingInstructorsScreen> createState() => _TrendingInstructorsScreenState();
}

class _TrendingInstructorsScreenState extends State<TrendingInstructorsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor = isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF8F9FA);
    Color cardColor = isDarkMode ? const Color(0xFF374151) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);
    Color secondaryTextColor = isDarkMode ? Colors.grey[300]! : const Color(0xFF6B7280);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarOne(title: widget.title),
      body: SafeArea(
        child: _buildContent(isDarkMode, cardColor, textColor, secondaryTextColor),
      ),
    );
  }
  
  Widget _buildContent(bool isDarkMode, Color cardColor, Color textColor, Color secondaryTextColor) {
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: widget.instructors.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildInstructorCard(widget.instructors[index], isDarkMode, cardColor, textColor, secondaryTextColor),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInstructorCard(Map<String, dynamic> instructor, bool isDarkMode, Color cardColor, Color textColor, Color secondaryTextColor) {
    // Generate a unique gradient color based on instructor name
    final List<List<Color>> gradientColors = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Purple
      [const Color(0xFF10B981), const Color(0xFF059669)], // Green
      [const Color(0xFFEF4444), const Color(0xFFDC2626)], // Red
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue
    ];
    
    // Use a simple hash function to get a consistent color for each instructor
    final int nameHash = instructor['name'].toString().hashCode.abs();
    final colorIndex = nameHash % gradientColors.length;
    final gradientColor = gradientColors[colorIndex];
    
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InstructorScreen(
              instructorId: instructor['id']?.toString(),
              instructorName: instructor['name'],
              instructorImage: instructor['image'],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top badge
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: gradientColor,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructor badge - small icon showing trending
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColor,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradientColor[0].withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Text(
                "TOP INSTRUCTOR",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Circular instructor avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColor,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradientColor[0].withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: instructor['image'] != null && instructor['image'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: CachedNetworkImage(
                        imageUrl: instructor['image'].toString(),
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              instructor['name'].toString()[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        instructor['name'].toString()[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructor Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                instructor['name'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Instructor Title/Role
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                instructor['title'] ?? 'Instructor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Student count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: gradientColor[0].withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: gradientColor[0],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${instructor['totalEnrollment'] ?? 0} Students',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: gradientColor[0],
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
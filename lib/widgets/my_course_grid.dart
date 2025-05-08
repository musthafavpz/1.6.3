import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/my_course.dart';
import '../screens/my_course_detail.dart';

class MyCourseGrid extends StatefulWidget {
  const MyCourseGrid({
    super.key,
  });

  @override
  State<MyCourseGrid> createState() => _MyCourseGridState();
}

class _MyCourseGridState extends State<MyCourseGrid> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final myCourse = Provider.of<MyCourse>(context, listen: false);
    final courseProgress = myCourse.courseCompletion ?? 0;
    final isStarted = courseProgress > 0;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyCourseDetailScreen(
                courseId: myCourse.id!,
                enableDripContent: myCourse.enableDripContent.toString(),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kDefaultColor.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Thumbnail with overlay
                Stack(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Hero(
                          tag: 'course_image_${myCourse.id}',
                          child: FadeInImage.assetNetwork(
                            placeholder: 'assets/images/loading_animated.gif',
                            image: myCourse.thumbnail.toString(),
                            fit: BoxFit.cover,
                            imageErrorBuilder: (context, error, stackTrace) => 
                                Image.asset(
                                  'assets/images/course_thumbnail.png',
                                  fit: BoxFit.cover,
                                ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
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
                    ),
                    
                    // Progress indicator
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: CircularPercentIndicator(
                          radius: 20.0,
                          lineWidth: 3.0,
                          percent: courseProgress / 100,
                          center: Text(
                            '$courseProgress%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          progressColor: isStarted ? kDefaultColor : Colors.grey,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                      ),
                    ),
                    
                    // Status tag
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isStarted ? kDefaultColor : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          isStarted ? 'In Progress' : 'Not Started',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    // Lesson count
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_lesson,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${myCourse.totalNumberOfLessons ?? 0} Lessons',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Course title and details
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        myCourse.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Instructor
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: kGreyLightColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              myCourse.instructor ?? 'Unknown Instructor',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$courseProgress% completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isStarted ? kDefaultColor : Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${myCourse.totalNumberOfCompletedLessons ?? 0}/${myCourse.totalNumberOfLessons ?? 0}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearPercentIndicator(
                            animation: true,
                            animationDuration: 1000,
                            lineHeight: 8.0,
                            percent: courseProgress / 100,
                            progressColor: isStarted 
                                ? kDefaultColor 
                                : Colors.orange,
                            backgroundColor: Colors.grey[200],
                            barRadius: const Radius.circular(8),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      // Action button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MyCourseDetailScreen(
                                courseId: myCourse.id!,
                                enableDripContent: myCourse.enableDripContent.toString(),
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          isStarted ? Icons.play_circle_outline : Icons.school,
                          size: 18,
                        ),
                        label: Text(
                          isStarted ? 'Continue Learning' : 'Start Learning',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isStarted 
                              ? kDefaultColor 
                              : Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

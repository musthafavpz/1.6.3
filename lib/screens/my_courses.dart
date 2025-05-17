import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../constants.dart';
import '../providers/my_courses.dart';
import '../widgets/my_course_grid.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFFF8F9FA),
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () async {
            await Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const SizedBox(height: 16),
                  _buildCoursesStatus(),
                  const SizedBox(height: 20),
                  courseView(),
                  const SizedBox(height: 20),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesStatus() {
    return Consumer<MyCourses>(
      builder: (context, myCourseData, _) {
        // Calculate average progress across all courses
        double averageProgress = 0;
        int totalCompletedLessons = 0;
        int totalLessons = 0;
        
        if (myCourseData.items.isNotEmpty) {
          for (var course in myCourseData.items) {
            averageProgress += (course.courseCompletion ?? 0);
            totalCompletedLessons += (course.totalNumberOfCompletedLessons ?? 0);
            totalLessons += (course.totalNumberOfLessons ?? 0);
          }
          averageProgress = averageProgress / myCourseData.items.length;
        }
        
        return Container(
          padding: const EdgeInsets.all(15),
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
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${myCourseData.items.length} Courses',
                    style: const TextStyle(
                          fontSize: 18,
                      fontWeight: FontWeight.bold,
                          color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Continue your learning journey',
                    style: TextStyle(
                      fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to the first course or most recent one
                      if (myCourseData.items.isNotEmpty) {
                        // Handle navigation
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Progress section
              if (myCourseData.items.isNotEmpty) ...[
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${averageProgress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                  color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                LinearPercentIndicator(
                  lineHeight: 6.0,
                  percent: averageProgress / 100,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  progressColor: Colors.white,
                  barRadius: const Radius.circular(10),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 1000,
                ),
                const SizedBox(height: 10),
                
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.book_outlined,
                      value: '$totalCompletedLessons/$totalLessons',
                      label: 'Lessons Completed',
                    ),
                    _buildStatItem(
                      icon: Icons.access_time,
                      value: _formatLearningTime(myCourseData.items.length),
                      label: 'Learning Time',
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _formatLearningTime(int courseCount) {
    // This is a placeholder calculation
    // In a real app, this would calculate based on actual lesson durations
    final estimatedHours = courseCount * 2;
    return '$estimatedHours hrs';
  }

  Widget courseView() {
    final height = MediaQuery.of(context).size.height - 
                   MediaQuery.of(context).padding.top - 
                   kToolbarHeight - 150;
    
    return FutureBuilder(
      future: Provider.of<MyCourses>(context, listen: false).fetchMyCourses(),
      builder: (ctx, dataSnapshot) {
        if (dataSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: const Center(
              child: CupertinoActivityIndicator(color: Color(0xFF6366F1)),
            ),
          );
        } else {
          if (dataSnapshot.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Error occurred: ${dataSnapshot.error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return Consumer<MyCourses>(
              builder: (context, myCourseData, child) {
                if (myCourseData.items.isEmpty) {
                  return SizedBox(
                    height: height,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 80,
                            color: const Color(0xFF6366F1).withOpacity(0.7),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No courses yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Explore and enroll in courses to get started',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              // Navigate to explore courses screen
                            },
                            child: const Text('Explore Courses'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Split courses into In Progress and Completed
                final inProgressCourses = myCourseData.items
                    .where((course) => (course.courseCompletion ?? 0) < 100)
                    .toList();
                    
                final completedCourses = myCourseData.items
                    .where((course) => (course.courseCompletion ?? 0) == 100)
                    .toList();
                
                return DefaultTabController(
                  length: 2,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          dividerHeight: 0,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_outline),
                                  const SizedBox(width: 8),
                                  Text(
                                    "In Progress (${inProgressCourses.length})",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                              fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Completed (${completedCourses.length})",
                                    style: const TextStyle(
                              fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tab Bar View
                      Container(
                        constraints: BoxConstraints(
                          minHeight: 250,
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: TabBarView(
                          children: [
                            // In Progress Courses Tab
                            inProgressCourses.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          size: 60,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No courses in progress',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: AlignedGridView.count(
                                        shrinkWrap: true,
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: inProgressCourses.length,
                                        itemBuilder: (ctx, index) {
                                          return MyCourseGrid(
                                            myCourse: inProgressCourses[index],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  
                            // Completed Courses Tab
                            completedCourses.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 60,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No completed courses yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                                  )
                                : SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: AlignedGridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                                        itemCount: completedCourses.length,
                  itemBuilder: (ctx, index) {
                    return MyCourseGrid(
                                            myCourse: completedCourses[index],
                    );
                  },
                    ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                  ],
                  ),
                );
              },
            );
          }
        }
      },
    );
  }
}

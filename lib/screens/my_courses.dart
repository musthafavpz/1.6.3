import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/my_courses.dart';
import '../widgets/my_course_grid.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch courses when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: kBackGroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with improved styling
                const Text(
                  'My Courses',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kDefaultColor,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Custom tab bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: kDefaultColor,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    tabs: const [
                      Tab(text: 'In Progress'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCourseList(isCompleted: false),
                      _buildCourseList(isCompleted: true),
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

  Widget _buildCourseList({required bool isCompleted}) {
    return Consumer<MyCourses>(
      builder: (context, myCourseData, child) {
        if (myCourseData.isLoading) {
          return const Center(
            child: CupertinoActivityIndicator(color: kDefaultColor),
          );
        }
        
        if (myCourseData.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                TextButton(
                  onPressed: () {
                    Provider.of<MyCourses>(context, listen: false).fetchMyCourses();
                  },
                  child: const Text('Try Again'),
                )
              ],
            ),
          );
        }
        
        // Filter courses based on completion status
        final filteredCourses = myCourseData.items.where(
          (course) => course.isCompleted == isCompleted
        ).toList();
        
        if (filteredCourses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.school : Icons.menu_book,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  isCompleted 
                      ? 'No completed courses yet'
                      : 'No courses in progress',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCompleted 
                      ? 'Complete your courses to see them here'
                      : 'Enroll in courses to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          color: kDefaultColor,
          onRefresh: () => Provider.of<MyCourses>(
            context, 
            listen: false
          ).fetchMyCourses(),
          child: AlignedGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemCount: filteredCourses.length,
            padding: const EdgeInsets.only(bottom: 16),
            itemBuilder: (ctx, index) {
              return _buildCourseCard(filteredCourses[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(dynamic course) {
    // Enhanced course card with progress indicator
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                course.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, _) => Container(
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course title
                Text(
                  course.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Lesson progress
                Row(
                  children: [
                    Text(
                      '${course.completedLessons}/${course.totalLessons} lessons',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // Progress bar
                LinearProgressIndicator(
                  value: course.totalLessons > 0 
                      ? course.completedLessons / course.totalLessons 
                      : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(kDefaultColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                
                const SizedBox(height: 8),
                
                // Continue button
                if (!course.isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to course details
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDefaultColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                  
                if (course.isCompleted)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

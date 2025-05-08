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

class _MyCourseGridState extends State<MyCourseGrid> {
  @override
  Widget build(BuildContext context) {
    final myCourse = Provider.of<MyCourse>(context, listen: false);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
          borderRadius: BorderRadius.circular(16),
          splashColor: kDefaultColor.withOpacity(0.1),
          highlightColor: kDefaultColor.withOpacity(0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Thumbnail with overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
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
                                  'assets/images/placeholder.png',
                                  fit: BoxFit.cover,
                                ),
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay to make the title more readable
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
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Progress indicator as an overlay
                    Positioned(
                      top: 10,
                      right: 10,
                      child: CircularPercentIndicator(
                        radius: 18.0,
                        lineWidth: 3.0,
                        percent: (myCourse.courseCompletion ?? 0) / 100,
                        center: Text(
                          '${myCourse.courseCompletion}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        progressColor: kDefaultColor,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ),
                  ],
                ),
                // Course title
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: Text(
                    myCourse.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                // Rating and reviews
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: kStarColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${myCourse.average_rating ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${myCourse.total_reviews ?? 0})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearPercentIndicator(
                        animation: true,
                        animationDuration: 1000,
                        lineHeight: 8.0,
                        percent: (myCourse.courseCompletion ?? 0) / 100,
                        progressColor: kDefaultColor,
                        backgroundColor: Colors.grey[200],
                        barRadius: const Radius.circular(8),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(myCourse.courseCompletion ?? 0)}% completed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${myCourse.totalNumberOfCompletedLessons ?? 0}/${myCourse.totalNumberOfLessons ?? 0} lessons',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Continue button
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (myCourse.courseCompletion ?? 0) > 0 
                          ? kDefaultColor 
                          : Colors.grey[300],
                      foregroundColor: (myCourse.courseCompletion ?? 0) > 0 
                          ? Colors.white 
                          : Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      (myCourse.courseCompletion ?? 0) > 0 
                          ? 'Continue Learning' 
                          : 'Start Learning',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

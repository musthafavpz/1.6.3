import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../constants.dart';
import '../models/my_course.dart';
import '../screens/my_course_detail.dart';

class MyCourseGrid extends StatefulWidget {
  final MyCourse? myCourse;

  const MyCourseGrid({
    super.key,
    @required this.myCourse,
  });

  @override
  State<MyCourseGrid> createState() => _MyCourseGridState();
}

class _MyCourseGridState extends State<MyCourseGrid> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) {
          return MyCourseDetailScreen(
              courseId: widget.myCourse!.id!,
              enableDripContent: widget.myCourse!.enableDripContent.toString());
        }));
      },
      child: Container(
        width: MediaQuery.of(context).size.width * .45,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/images/loading_animated.gif',
                    image: widget.myCourse!.thumbnail.toString(),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: -15,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircularPercentIndicator(
                      radius: 18.0,
                      lineWidth: 3.0,
                      animation: true,
                      percent: widget.myCourse!.courseCompletion! / 100,
                      center: Text(
                        "${widget.myCourse!.courseCompletion}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 9.0,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      progressColor: const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Text(
                widget.myCourse!.title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                '${widget.myCourse!.totalNumberOfCompletedLessons}/${widget.myCourse!.totalNumberOfLessons} Lessons',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
          ],
        ),
      ),
    );
  }
}

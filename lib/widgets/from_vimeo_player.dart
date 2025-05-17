import 'dart:async';
import 'dart:convert';

import 'package:academy_lms_app/constants.dart';
import 'package:academy_lms_app/providers/my_courses.dart';
import 'package:academy_lms_app/providers/shared_pref_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vimeo_embed_player/vimeo_embed_player.dart';

class FromVimeoPlayer extends StatefulWidget {
  final int courseId;
  final int? lessonId;
  final String vimeoVideoId;

  const FromVimeoPlayer(
      {super.key,
      required this.vimeoVideoId,
      required this.courseId,
      this.lessonId});

  @override
  State<FromVimeoPlayer> createState() => _FromVimeoPlayerState();
}

class _FromVimeoPlayerState extends State<FromVimeoPlayer> {
  Timer? timer;
  bool isPlaying = false;
  int currentVideoPosition = 0;

  @override
  void initState() {
    super.initState();
    // Enter fullscreen and lock orientation to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (widget.lessonId != null) {
      timer = Timer.periodic(
          const Duration(seconds: 5), (Timer t) => updateWatchHistory());
    }
  }

  Future<void> updateWatchHistory() async {
    if (isPlaying) {
      var token = await SharedPreferenceHelper().getAuthToken();
      dynamic url;

      if (token != null && token.isNotEmpty) {
        url = "$baseUrl/api/update_watch_history/$token";
        try {
          final response = await http.post(
            Uri.parse(url),
            body: {
              'course_id': widget.courseId.toString(),
              'lesson_id': widget.lessonId.toString(),
              'current_duration': currentVideoPosition.toString(),
            },
          );

          final responseData = json.decode(response.body);
          print("Arif response here ::: $responseData");
          if (responseData != null) {
            var isCompleted = responseData['is_completed'];
            print("Arif output here ::: $isCompleted");
            if (isCompleted == 1) {
              Provider.of<MyCourses>(context, listen: false)
                  .updateDripContendLesson(
                      widget.courseId,
                      responseData['course_progress'],
                      responseData['number_of_completed_lessons']);
              print(
                  "Arif output here ::: $responseData['number_of_completed_lessons']");
            }
          }
        } catch (error) {
          rethrow;
        }
      }
    }
  }

  void onPlay() {
    setState(() {
      isPlaying = true;
      // Start a timer to simulate video position increment
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!isPlaying) {
          timer.cancel(); // Stop updating if video is not playing
        } else {
          currentVideoPosition++; // Increment position by 1 second
        }
      });
    });
  }

  void onPause() {
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: VimeoEmbedPlayer(
              vimeoId: widget.vimeoVideoId,
              autoPlay: true,
            ),
          ),
          // Block taps only on the top-left control area (3-dots/download)
          Positioned(
            top: 8,
            left: 8,
            child: SizedBox(
              width: 40,
              height: 40,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {},
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // Block taps on the top-right quadrant of the video
          Positioned.fill(
            child: Align(
              alignment: Alignment.topRight,
              child: FractionallySizedBox(
                widthFactor: 0.387,
                heightFactor: 0.387,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {},
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          // Block taps on the bottom-right control area (Vimeo logo, fullscreen)
          Positioned(
            bottom: 8,
            right: 8,
            child: SizedBox(
              width: 80,
              height: 50,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {},
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    // Exit fullscreen and restore portrait orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}

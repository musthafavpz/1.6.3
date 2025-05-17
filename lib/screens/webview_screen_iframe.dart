import 'package:academy_lms_app/widgets/appbar_one.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:pod_player/pod_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class WebViewScreenIframe extends StatefulWidget {
  static const routeName = '/webview-iframe';
  
  final String? url;

  const WebViewScreenIframe({super.key, required this.url});

  @override
  State<WebViewScreenIframe> createState() => _WebViewScreenIframeState();
}

class _WebViewScreenIframeState extends State<WebViewScreenIframe> {
  WebViewController? _controller;
  PodPlayerController? _podController;
  var loadingPercentage = 0;
  bool _isGoogleDriveVideo = false;
  String? _fileId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Process URL and set orientation
    _processUrl();
    
    // Handle different types of content
    if (_isGoogleDriveVideo && _fileId != null) {
      _initializePodPlayer();
    } else {
      _initializeWebView();
    }
  }
  
  void _processUrl() {
    if (widget.url == null) return;
    
    _isGoogleDriveVideo = widget.url!.contains('drive.google.com');
    
    if (_isGoogleDriveVideo) {
      // Set landscape orientation for Google Drive videos
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Extract file ID from various Google Drive URL formats
      final RegExp regExp = RegExp(r'[-\w]{25,}');
      final Match? match = regExp.firstMatch(widget.url!);
      
      if (match != null) {
        _fileId = match.group(0);
      }
    }
  }

  @override
  void dispose() {
    // Reset orientation when the screen is closed
    if (_isGoogleDriveVideo) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    
    // Dispose controllers
    _podController?.dispose();
    super.dispose();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              loadingPercentage = 0;
            });
          },
          onProgress: (int progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              loadingPercentage = 100;
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
      
    // Load the URL
    if (widget.url != null) {
      await _controller!.loadRequest(Uri.parse(widget.url!));
    }
  }
  
  Future<void> _initializePodPlayer() async {
    try {
      // Get direct video URL from Google Drive
      final directUrl = await _getGoogleDriveDirectUrl(_fileId!);
      
      if (directUrl != null) {
        _podController = PodPlayerController(
          playVideoFrom: PlayVideoFrom.network(
            directUrl,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
          ),
          podPlayerConfig: const PodPlayerConfig(
            autoPlay: true,
            isLooping: false,
          ),
        )..initialise().then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        // Fallback to WebView if direct URL couldn't be obtained
        _initializeWebView();
      }
    } catch (e) {
      debugPrint('Error initializing pod player: $e');
      // Fallback to WebView
      _initializeWebView();
    }
  }
  
  Future<String?> _getGoogleDriveDirectUrl(String fileId) async {
    try {
      final url = 'https://drive.google.com/uc?export=download&id=$fileId';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('video/') == true) {
          return url;
        }
        
        // If cookies are needed for confirmation
        if (response.headers.containsKey('set-cookie')) {
          final cookies = response.headers['set-cookie']!;
          final tokenMatch = RegExp(r'confirm=([0-9A-Za-z\-_]+)').firstMatch(cookies);
          
          if (tokenMatch != null) {
            final token = tokenMatch.group(1)!;
            return 'https://drive.google.com/uc?export=download&id=$fileId&confirm=$token';
          }
        }
      }
      
      // Fallback to a direct video URL format
      return 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media';
    } catch (e) {
      debugPrint('Error getting direct URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isGoogleDriveVideo ? null : const AppBarOne(title: 'Iframe'),
      body: _isLoading 
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6366F1),
            ),
          )
        : _isGoogleDriveVideo && _podController != null
            ? PodVideoPlayer(controller: _podController!)
            : _controller != null 
                ? Stack(
                    children: [
                      WebViewWidget(
                        controller: _controller!,
                      ),
                      if (loadingPercentage < 100)
                        LinearProgressIndicator(
                          value: loadingPercentage / 100.0,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                        ),
                    ],
                  )
                : const Center(
                    child: Text(
                      'Could not load content',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
    );
  }
}

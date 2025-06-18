import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiUtils {
  static final http.Client _client = http.Client();
  static final Map<String, Timer> _debounceTimers = {};
  static final Map<String, bool> _loadingStates = {};

  static void dispose() {
    _client.close();
    for (var timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    String? debounceKey,
    Duration debounceDelay = const Duration(milliseconds: 300),
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // If debounce key is provided, check if already loading
    if (debounceKey != null) {
      if (_loadingStates[debounceKey] == true) {
        throw Exception('Request already in progress');
      }
      _loadingStates[debounceKey] = true;
    }

    // Cancel existing debounce timer if any
    if (debounceKey != null && _debounceTimers.containsKey(debounceKey)) {
      _debounceTimers[debounceKey]!.cancel();
    }

    try {
      // Create a completer to handle the debounced request
      final completer = Completer<Map<String, dynamic>>();

      if (debounceKey != null) {
        _debounceTimers[debounceKey] = Timer(debounceDelay, () async {
          try {
            final result = await _performGet(url, headers: headers, timeout: timeout);
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          } catch (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          }
        });
      } else {
        final result = await _performGet(url, headers: headers, timeout: timeout);
        completer.complete(result);
      }

      return await completer.future;
    } finally {
      if (debounceKey != null) {
        _loadingStates[debounceKey] = false;
        _debounceTimers.remove(debounceKey);
      }
    }
  }

  static Future<Map<String, dynamic>> _performGet(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: headers ?? {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(timeout);

    if (response.statusCode == 200) {
      // Check if response is HTML (error page) instead of JSON
      if (response.body.trim().startsWith('<!DOCTYPE html>') || 
          response.body.trim().startsWith('<html>')) {
        throw Exception('Server returned HTML instead of JSON. Please try again later.');
      }

      try {
        final data = json.decode(response.body);
        return {'statusCode': response.statusCode, 'data': data};
      } catch (e) {
        throw Exception('Invalid JSON response from server');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  static bool isHtmlResponse(String responseBody) {
    final trimmed = responseBody.trim();
    return trimmed.startsWith('<!DOCTYPE html>') || 
           trimmed.startsWith('<html>') ||
           trimmed.startsWith('<?xml');
  }
} 
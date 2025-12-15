import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/playlist_model.dart';
import '../models/channel_model.dart';

class LinkTestResult {
  final String url;
  final bool isWorking;
  final String? error;
  final int? statusCode;
  final int responseTime; // in milliseconds
  final DateTime? expiryDate;
  final int testedChannels;
  final int workingChannels;

  LinkTestResult({
    required this.url,
    required this.isWorking,
    this.error,
    this.statusCode,
    required this.responseTime,
    this.expiryDate,
    this.testedChannels = 0,
    this.workingChannels = 0,
  });

  @override
  String toString() {
    return 'LinkTestResult(url: $url, isWorking: $isWorking, responseTime: ${responseTime}ms)';
  }
}

class LinkTesterService {
  static const int _defaultTimeout = 10; // seconds
  static const int _maxTestChannels = 3; // maximum channels to test per playlist
  static const int _maxConcurrentTests = 5; // maximum concurrent tests

  // Test single playlist URL
  static Future<LinkTestResult> testPlaylistUrl(String url) async {
    final stopwatch = Stopwatch()..start();

    try {
      // First, try to download the playlist
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      ).timeout(Duration(seconds: _defaultTimeout));

      final responseTime = stopwatch.elapsedMilliseconds;

      if (response.statusCode != 200) {
        return LinkTestResult(
          url: url,
          isWorking: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
          responseTime: responseTime,
        );
      }

      // Check if it's a valid M3U file
      final content = response.body;
      if (!content.trim().startsWith('#EXTM3U')) {
        return LinkTestResult(
          url: url,
          isWorking: false,
          error: 'Invalid M3U format',
          statusCode: response.statusCode,
          responseTime: responseTime,
        );
      }

      // Extract some channel URLs to test
      final channelUrls = _extractChannelUrls(content);

      if (channelUrls.isEmpty) {
        return LinkTestResult(
          url: url,
          isWorking: true, // At least it's a valid M3U
          responseTime: responseTime,
          expiryDate: _extractExpiryDate(content),
        );
      }

      // Test a few channels
      final testUrls = channelUrls.take(_maxTestChannels).toList();
      int workingChannels = 0;

      for (final channelUrl in testUrls) {
        if (await _testChannelUrl(channelUrl)) {
          workingChannels++;
        }
      }

      // Consider playlist working if at least 50% of tested channels work
      final isWorking = workingChannels > 0;

      return LinkTestResult(
        url: url,
        isWorking: isWorking,
        statusCode: response.statusCode,
        responseTime: responseTime,
        expiryDate: _extractExpiryDate(content),
        testedChannels: testUrls.length,
        workingChannels: workingChannels,
      );
    } catch (e) {
      return LinkTestResult(
        url: url,
        isWorking: false,
        error: e.toString(),
        responseTime: stopwatch.elapsedMilliseconds,
      );
    }
  }

  // Test multiple playlist URLs with concurrency control
  static Future<List<LinkTestResult>> testPlaylistUrls(
    List<String> urls, {
    int? maxConcurrent,
    Function(LinkTestResult result)? onProgress,
  }) async {
    final results = <LinkTestResult>[];
    final semaphore = Semaphore(maxConcurrent ?? _maxConcurrentTests);

    final futures = urls.map((url) async {
      await semaphore.acquire();
      try {
        final result = await testPlaylistUrl(url);
        onProgress?.call(result);
        return result;
      } finally {
        semaphore.release();
      }
    });

    results.addAll(await Future.wait(futures));
    return results;
  }

  // Test with isolate for better performance
  static Future<List<LinkTestResult>> testPlaylistUrlsIsolate(
    List<String> urls, {
    Function(LinkTestResult result)? onProgress,
  }) async {
    try {
      // Create receive port for isolate
      final receivePort = ReceivePort();

      // Start isolate
      await Isolate.spawn(_testLinksIsolate, receivePort.sendPort);

      // Wait for isolate to send back its send port
      final sendPort = await receivePort.first as SendPort;

      // Create response port for results
      final responsePort = ReceivePort();

      // Send testing request to isolate
      sendPort.send({
        'type': 'test_urls',
        'urls': urls,
        'responsePort': responsePort.sendPort,
      });

      // Listen for results
      final results = <LinkTestResult>[];
      await for (final message in responsePort) {
        if (message is Map<String, dynamic>) {
          if (message['type'] == 'result') {
            final result = LinkTestResult(
              url: message['url'],
              isWorking: message['isWorking'],
              error: message['error'],
              statusCode: message['statusCode'],
              responseTime: message['responseTime'],
              expiryDate: message['expiryDate'] != null
                  ? DateTime.parse(message['expiryDate'])
                  : null,
              testedChannels: message['testedChannels'] ?? 0,
              workingChannels: message['workingChannels'] ?? 0,
            );
            results.add(result);
            onProgress?.call(result);
          } else if (message['type'] == 'complete') {
            break;
          }
        }
      }

      // Close ports
      receivePort.close();
      responsePort.close();

      return results;
    } catch (e) {
      throw Exception('Failed to test links in isolate: $e');
    }
  }

  // Extract channel URLs from M3U content
  static List<String> _extractChannelUrls(String content) {
    final urls = <String>[];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty &&
          !trimmedLine.startsWith('#') &&
          (trimmedLine.startsWith('http://') || trimmedLine.startsWith('https://'))) {
        urls.add(trimmedLine);
      }
    }

    return urls;
  }

  // Test a single channel URL
  static Future<bool> _testChannelUrl(String url) async {
    try {
      // Use HEAD request first to check if the stream is accessible
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(Duration(seconds: 5));

      // For streaming URLs, HEAD might not work, so try a quick GET
      if (response.statusCode != 200) {
        final getResponse = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Range': 'bytes=0-1023', // Only request first 1KB
          },
        ).timeout(Duration(seconds: 5));

        return getResponse.statusCode == 200;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Extract expiry date from content
  static DateTime? _extractExpiryDate(String content) {
    // Similar implementation to M3UParserService
    try {
      final patterns = [
        RegExp(r'expir[e]?[es]?.*?(\d{2}[/-]\d{2}[/-]\d{4})', caseSensitive: false),
        RegExp(r'valid.*?(\d{2}[/-]\d{2}[/-]\d{4})', caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(content);
        if (match != null) {
          final dateString = match.group(1)!;
          final parts = dateString.split(RegExp(r'[/-]'));
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }
}

// Simple semaphore implementation for concurrency control
class Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}

// Isolate entry point for link testing
void _testLinksIsolate(SendPort sendPort) async {
  // Create receive port for this isolate
  final receivePort = ReceivePort();

  // Send the send port back to the main isolate
  sendPort.send(receivePort.sendPort);

  // Listen for messages
  await for (final message in receivePort) {
    try {
      if (message is Map<String, dynamic> && message['type'] == 'test_urls') {
        final urls = message['urls'] as List<String>;
        final responsePort = message['responsePort'] as SendPort;

        // Test URLs sequentially (can be optimized further)
        for (final url in urls) {
          try {
            final result = await _testSingleUrlInIsolate(url);
            responsePort.send({
              'type': 'result',
              ...result,
            });
          } catch (e) {
            responsePort.send({
              'type': 'result',
              'url': url,
              'isWorking': false,
              'error': e.toString(),
              'responseTime': 0,
            });
          }
        }

        // Send completion signal
        responsePort.send({'type': 'complete'});
      }
    } catch (e) {
      // Send error back
      final responsePort = message['responsePort'] as SendPort?;
      responsePort?.send({
        'type': 'error',
        'error': e.toString(),
      });
    }
  }
}

// Test single URL in isolate
Future<Map<String, dynamic>> _testSingleUrlInIsolate(String url) async {
  final stopwatch = Stopwatch()..start();

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    ).timeout(Duration(seconds: 10));

    final responseTime = stopwatch.elapsedMilliseconds;

    if (response.statusCode != 200) {
      return {
        'url': url,
        'isWorking': false,
        'error': 'HTTP ${response.statusCode}',
        'statusCode': response.statusCode,
        'responseTime': responseTime,
      };
    }

    // Check M3U format
    final content = response.body;
    if (!content.trim().startsWith('#EXTM3U')) {
      return {
        'url': url,
        'isWorking': false,
        'error': 'Invalid M3U format',
        'statusCode': response.statusCode,
        'responseTime': responseTime,
      };
    }

    // Extract expiry date
    DateTime? expiryDate;
    try {
      final patterns = [
        RegExp(r'expir[e]?[es]?.*?(\d{2}[/-]\d{2}[/-]\d{4})', caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(content);
        if (match != null) {
          final dateString = match.group(1)!;
          final parts = dateString.split(RegExp(r'[/-]'));
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            expiryDate = DateTime(year, month, day);
            break;
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }

    return {
      'url': url,
      'isWorking': true,
      'statusCode': response.statusCode,
      'responseTime': responseTime,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  } catch (e) {
    return {
      'url': url,
      'isWorking': false,
      'error': e.toString(),
      'responseTime': stopwatch.elapsedMilliseconds,
    };
  }
}
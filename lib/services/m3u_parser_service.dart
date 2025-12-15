import 'dart:convert';
import 'dart:isolate';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/channel_model.dart';
import '../models/playlist_model.dart';

// Message types for isolate communication
class ParserMessage {
  final String type;
  final dynamic data;

  ParserMessage(this.type, this.data);

  Map<String, dynamic> toMap() => {'type': type, 'data': data};

  factory ParserMessage.fromMap(Map<String, dynamic> map) {
    return ParserMessage(map['type'], map['data']);
  }
}

// Main parser service class
class M3UParserService {
  static const int _timeoutDuration = 30; // seconds

  // Parse M3U from URL with isolate
  static Future<PlaylistModel> parseFromUrl(String url, {String? playlistName}) async {
    try {
      // Create receive port for isolate
      final receivePort = ReceivePort();

      // Start isolate
      await Isolate.spawn(_parseIsolate, receivePort.sendPort);

      // Wait for isolate to send back its send port
      final sendPort = await receivePort.first as SendPort;

      // Create response port for results
      final responsePort = ReceivePort();

      // Send parsing request to isolate
      sendPort.send(ParserMessage('parse_url', {
        'url': url,
        'playlistName': playlistName ?? url.split('/').last,
        'responsePort': responsePort.sendPort,
      }).toMap());

      // Wait for result
      final result = await responsePort.first;

      // Close ports
      receivePort.close();
      responsePort.close();

      if (result['type'] == 'error') {
        throw Exception(result['data']);
      }

      return PlaylistModel.fromJson(result['data']);
    } catch (e) {
      throw Exception('Failed to parse M3U from URL: $e');
    }
  }

  // Parse M3U from content string with isolate
  static Future<PlaylistModel> parseFromContent(
    String content, {
    required String playlistName,
    String? sourceUrl,
  }) async {
    try {
      // Create receive port for isolate
      final receivePort = ReceivePort();

      // Start isolate
      await Isolate.spawn(_parseIsolate, receivePort.sendPort);

      // Wait for isolate to send back its send port
      final sendPort = await receivePort.first as SendPort;

      // Create response port for results
      final responsePort = ReceivePort();

      // Send parsing request to isolate
      sendPort.send(ParserMessage('parse_content', {
        'content': content,
        'playlistName': playlistName,
        'sourceUrl': sourceUrl,
        'responsePort': responsePort.sendPort,
      }).toMap());

      // Wait for result
      final result = await responsePort.first;

      // Close ports
      receivePort.close();
      responsePort.close();

      if (result['type'] == 'error') {
        throw Exception(result['data']);
      }

      return PlaylistModel.fromJson(result['data']);
    } catch (e) {
      throw Exception('Failed to parse M3U content: $e');
    }
  }

  // Generate M3U content from playlist
  static String generateM3UContent(PlaylistModel playlist, {List<String>? selectedGroups}) {
    final buffer = StringBuffer();

    // Write M3U header
    buffer.writeln('#EXTM3U');

    // Filter channels by selected groups if provided
    var channels = playlist.channels;
    if (selectedGroups != null && selectedGroups.isNotEmpty) {
      channels = channels.where((channel) =>
        selectedGroups.contains(channel.groupTitle)
      ).toList();
    }

    // Write each channel
    for (final channel in channels) {
      buffer.writeln('#EXTINF:-1');

      // Write channel attributes
      if (channel.groupTitle.isNotEmpty) {
        buffer.writeln('#EXTGRP:${channel.groupTitle}');
      }

      if (channel.logo != null && channel.logo!.isNotEmpty) {
        buffer.writeln('#EXTLOGO:${channel.logo}');
      }

      if (channel.category != null && channel.category!.isNotEmpty) {
        buffer.writeln('#EXTCATEGORY:${channel.category}');
      }

      // Write channel line
      final attributes = <String>[];
      if (channel.name.isNotEmpty) attributes.add('tvg-name="${channel.name}"');
      if (channel.groupTitle.isNotEmpty) attributes.add('group-title="${channel.groupTitle}"');
      if (channel.logo != null && channel.logo!.isNotEmpty) attributes.add('tvg-logo="${channel.logo}"');

      final attributeString = attributes.isEmpty ? '' : ' ${attributes.join(' ')}';
      buffer.writeln('#EXTINF:-1$attributeString,${channel.name}');
      buffer.writeln(channel.url);
      buffer.writeln(); // Empty line for readability
    }

    return buffer.toString();
  }

  // Get unique group titles from channels
  static List<String> getUniqueGroups(List<ChannelModel> channels) {
    final groups = channels
        .map((channel) => channel.groupTitle)
        .where((group) => group.isNotEmpty)
        .toSet()
        .toList();

    groups.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return groups;
  }

  // Extract expiry date from M3U content
  static DateTime? extractExpiryDate(String content) {
    try {
      // Look for common expiry date patterns
      final patterns = [
        RegExp(r'expir[e]?[es]?.*?(\d{2}[/-]\d{2}[/-]\d{4})', caseSensitive: false),
        RegExp(r'valid.*?(\d{2}[/-]\d{2}[/-]\d{4})', caseSensitive: false),
        RegExp(r'end.*?(\d{2}[/-]\d{2}[/-]\d{4})', caseSensitive: false),
        RegExp(r'(\d{2}[/-]\d{2}[/-]\d{4})'),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(content);
        if (match != null) {
          final dateString = match.group(1)!;
          // Try to parse the date
          final formats = ['dd/MM/yyyy', 'dd-MM-yyyy', 'MM/dd/yyyy', 'MM-dd-yyyy'];

          for (final format in formats) {
            try {
              final parts = dateString.split(RegExp(r'[/-]'));
              if (parts.length == 3) {
                final day = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                return DateTime(year, month, day);
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting expiry date: $e');
    }
    return null;
  }
}

// Isolate entry point
void _parseIsolate(SendPort sendPort) async {
  // Create receive port for this isolate
  final receivePort = ReceivePort();

  // Send the send port back to the main isolate
  sendPort.send(receivePort.sendPort);

  // Listen for messages
  await for (final message in receivePort) {
    try {
      final msgMap = message as Map<String, dynamic>;
      final msg = ParserMessage.fromMap(msgMap);

      switch (msg.type) {
        case 'parse_url':
          await _parseFromUrlInIsolate(msg, sendPort);
          break;
        case 'parse_content':
          await _parseFromContentInIsolate(msg, sendPort);
          break;
      }
    } catch (e) {
      sendPort.send({
        'type': 'error',
        'data': 'Isolate parsing error: $e',
      });
    }
  }
}

// Parse M3U from URL in isolate
Future<void> _parseFromUrlInIsolate(ParserMessage message, SendPort sendPort) async {
  try {
    final data = message.data as Map<String, dynamic>;
    final url = data['url'] as String;
    final playlistName = data['playlistName'] as String;
    final responsePort = data['responsePort'] as SendPort;

    // Download M3U content
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    ).timeout(Duration(seconds: M3UParserService._timeoutDuration));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: Failed to download playlist');
    }

    final content = response.body;
    final playlist = _parseM3UContent(content, playlistName, url);

    responsePort.send({
      'type': 'success',
      'data': playlist.toJson(),
    });
  } catch (e) {
    final responsePort = message.data['responsePort'] as SendPort;
    responsePort.send({
      'type': 'error',
      'data': e.toString(),
    });
  }
}

// Parse M3U from content in isolate
Future<void> _parseFromContentInIsolate(ParserMessage message, SendPort sendPort) async {
  try {
    final data = message.data as Map<String, dynamic>;
    final content = data['content'] as String;
    final playlistName = data['playlistName'] as String;
    final sourceUrl = data['sourceUrl'] as String?;
    final responsePort = data['responsePort'] as SendPort;

    final playlist = _parseM3UContent(content, playlistName, sourceUrl);

    responsePort.send({
      'type': 'success',
      'data': playlist.toJson(),
    });
  } catch (e) {
    final responsePort = message.data['responsePort'] as SendPort;
    responsePort.send({
      'type': 'error',
      'data': e.toString(),
    });
  }
}

// Core M3U parsing logic (runs in isolate)
PlaylistModel _parseM3UContent(String content, String playlistName, String? sourceUrl) {
  final lines = content.split('\n');
  final channels = <ChannelModel>[];

  String? currentName;
  String? currentGroup;
  String? currentLogo;
  String? currentCategory;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    if (line.isEmpty) continue;

    if (line.startsWith('#EXTINF:')) {
      // Parse channel info
      currentName = _extractChannelName(line);
      currentLogo = _extractAttributeValue(line, 'tvg-logo');
      currentGroup = _extractAttributeValue(line, 'group-title');
    } else if (line.startsWith('#EXTGRP:')) {
      currentGroup = line.substring(8).trim();
    } else if (line.startsWith('#EXTLOGO:')) {
      currentLogo = line.substring(9).trim();
    } else if (line.startsWith('#EXTCATEGORY:')) {
      currentCategory = line.substring(13).trim();
    } else if (!line.startsWith('#')) {
      // This is the URL line
      if (currentName != null) {
        channels.add(ChannelModel(
          name: currentName,
          url: line,
          groupTitle: currentGroup ?? 'Uncategorized',
          logo: currentLogo,
          category: currentCategory,
        ));
      }

      // Reset for next channel
      currentName = null;
      currentLogo = null;
      currentCategory = null;
    }
  }

  // Extract expiry date
  final expiryDate = M3UParserService.extractExpiryDate(content);

  return PlaylistModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: playlistName,
    url: sourceUrl ?? '',
    expiryDate: expiryDate,
    channels: channels,
    totalChannels: channels.length,
  );
}

// Extract channel name from EXTINF line
String _extractChannelName(String extinfLine) {
  // Remove #EXTINF:-1 part
  final cleanLine = extinfLine.replaceFirst(RegExp(r'#EXTINF:-1.*?'), '');

  // Extract name after comma
  final commaIndex = cleanLine.lastIndexOf(',');
  if (commaIndex != -1) {
    return cleanLine.substring(commaIndex + 1).trim();
  }

  // If no comma found, return the cleaned line
  return cleanLine.trim();
}

// Extract attribute value from EXTINF line
String? _extractAttributeValue(String extinfLine, String attribute) {
  final pattern = RegExp('$attribute="([^"]*)"');
  final match = pattern.firstMatch(extinfLine);
  return match?.group(1);
}

// For debugging
void debugPrint(String message) {
  // In isolate, we can't use Flutter's debugPrint
  // This is a simple replacement
  // ignore: avoid_print
  print('[Isolate Debug] $message');
}
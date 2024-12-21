// joke_service.dart
// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class JokeService {
  final Dio _dio = Dio();
  final SharedPreferences _prefs;
  static const String _cacheKey = 'cached_jokes';
  static const Duration _cacheExpiration = Duration(hours: 24);

  JokeService(this._prefs);

  static Future<JokeService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return JokeService(prefs);
  }

  Future fetchJokes() async {
    try {
      final response = await _dio.get(
        'https://v2.jokeapi.dev/joke/Any?amount=5',
      );

      if (response.statusCode == 200 && response.data != null) {
        await _cacheJokes(response.data['jokes']);
        return response.data['jokes'];
      }

      throw Exception('Failed to load jokes');
    } catch (e) {
      final cachedJokes = await getCachedJokes();
      if (cachedJokes != null && cachedJokes.isNotEmpty) {
        return cachedJokes;
      }

      throw Exception(
        'Error fetching jokes: $e. No cached jokes available.',
      );
    }
  }

  Future<void> _cacheJokes(List<dynamic> jokes) async {
    final cacheData = {
      'jokes': jokes,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs.setString(_cacheKey, jsonEncode(cacheData));
  }

  Future<List<dynamic>?> getCachedJokes() async {
    try {
      final cachedData = _prefs.getString(_cacheKey);
      if (cachedData != null) {
        final decodedData = jsonDecode(cachedData);
        final cacheTimestamp =
            DateTime.fromMillisecondsSinceEpoch(decodedData['timestamp']);

        if (DateTime.now().difference(cacheTimestamp) < _cacheExpiration) {
          return decodedData['jokes'];
        } else {
          await clearCache();
          throw Exception('Cache expired');
        }
      } else {
        throw Exception('No cached data available');
      }
    } catch (e) {
      print('Error fetching cached jokes: $e');
      return [];
    }
  }

  Future<void> clearCache() async {
    await _prefs.remove(_cacheKey);
  }
}

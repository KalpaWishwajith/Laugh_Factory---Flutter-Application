import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class JokeService {
  final Dio _dio = Dio();
  final SharedPreferences _prefs;
  static const String _cacheKey = 'cached_jokes';
  static const Duration _cacheExpiration = Duration(hours: 24);

  JokeService(this._prefs);

  // Factory constructor to initialize SharedPreferences
  static Future<JokeService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return JokeService(prefs);
  }

  Future<List<dynamic>> fetchJokes() async {
    try {
      // Try to fetch from network first
      final response = await _dio.get(
        'https://v2.jokeapi.dev/joke/Any?amount=5',
      );

      if (response.statusCode == 200 && response.data != null) {
        // Cache the successful response
        await _cacheJokes(response.data['jokes']);
        return response.data['jokes'];
      }

      throw Exception('Failed to load jokes');
    } catch (e) {
      // If network request fails, try to load cached jokes
      final cachedJokes = await getCachedJokes();
      if (cachedJokes != null) {
        return cachedJokes;
      }

      // If no cached jokes available, rethrow the error
      throw Exception('Error fetching jokes and no cached jokes available: $e');
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
    final cachedData = _prefs.getString(_cacheKey);
    if (cachedData != null) {
      final decodedData = jsonDecode(cachedData);
      final cacheTimestamp =
          DateTime.fromMillisecondsSinceEpoch(decodedData['timestamp']);

      // Check if cache is still valid
      if (DateTime.now().difference(cacheTimestamp) < _cacheExpiration) {
        return decodedData['jokes'];
      }
    }
    return null;
  }

  Future<void> clearCache() async {
    await _prefs.remove(_cacheKey);
  }
}

import 'package:dio/dio.dart';

class JokeService {
  final Dio _dio = Dio();

  Future<List<dynamic>> fetchJokes() async {
    try {
      final response = await _dio.get(
        'https://v2.jokeapi.dev/joke/Any?amount=5',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['jokes'];
      } else {
        throw Exception('Failed to load jokes');
      }
    } catch (e) {
      throw Exception('Error fetching jokes: $e');
    }
  }
}

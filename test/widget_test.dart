import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laugh_factory/main.dart';
import 'package:laugh_factory/joke_service.dart';

class MockJokeService implements JokeService {
  final List<Map<String, dynamic>> mockJokes = [
    {
      'setup': 'Mock Setup 1',
      'delivery': 'Mock Delivery 1',
    },
    {
      'joke': 'Mock Single Line Joke',
    },
  ];

  bool shouldThrowError = false;
  bool isOffline = false;

  @override
  Future<List<dynamic>> fetchJokes() async {
    if (shouldThrowError) {
      throw Exception('Mock network error');
    }
    return mockJokes;
  }

  @override
  Future<List<dynamic>?> getCachedJokes() async {
    if (isOffline) {
      return mockJokes;
    }
    return null;
  }

  @override
  Future<void> clearCache() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockJokeService mockJokeService;

  setUp(() {
    mockJokeService = MockJokeService();
  });

  testWidgets('App shows initial ready to laugh message',
      (WidgetTester tester) async {
    await tester.pumpWidget(LaughFactory(jokeService: mockJokeService));

    expect(find.text('Ready to Laugh? 😄'), findsOneWidget);
    expect(find.text('Unleash Humor'), findsOneWidget);
  });

  testWidgets('App shows jokes after tapping button',
      (WidgetTester tester) async {
    await tester.pumpWidget(LaughFactory(jokeService: mockJokeService));

    await tester.tap(find.text('Unleash Humor'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Mock Setup 1 \nMock Delivery 1 😂'), findsOneWidget);
    expect(find.text('Mock Single Line Joke'), findsOneWidget);
  });

  testWidgets('App shows error message when network fails',
      (WidgetTester tester) async {
    mockJokeService.shouldThrowError = true;
    mockJokeService.isOffline = false;

    await tester.pumpWidget(LaughFactory(jokeService: mockJokeService));

    await tester.tap(find.text('Unleash Humor'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
        find.textContaining('Oops! Jokes took a coffee break'), findsOneWidget);
  });

  testWidgets('App shows offline indicator and cached jokes',
      (WidgetTester tester) async {
    mockJokeService.shouldThrowError = true;
    mockJokeService.isOffline = true;

    await tester.pumpWidget(LaughFactory(jokeService: mockJokeService));

    await tester.tap(find.text('Unleash Humor'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.offline_bolt), findsOneWidget);
    expect(find.text('Try Online Jokes'), findsOneWidget);
    expect(find.textContaining('You\'re offline'), findsOneWidget);
  });

  testWidgets('App shows loading indicator while fetching jokes',
      (WidgetTester tester) async {
    await tester.pumpWidget(LaughFactory(jokeService: mockJokeService));

    await tester.tap(find.text('Unleash Humor'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

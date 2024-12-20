// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'joke_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final jokeService = await JokeService.create();
  runApp(LaughFactory(jokeService: jokeService));
}

class LaughFactory extends StatelessWidget {
  final JokeService jokeService;

  const LaughFactory({super.key, required this.jokeService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Laugh Factory',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A5ACD),
          brightness: Brightness.light,
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontFamily: GoogleFonts.rubik().fontFamily,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontFamily: GoogleFonts.rubik().fontFamily,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: MyHomePage(jokeService: jokeService),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final JokeService jokeService;

  const MyHomePage({super.key, required this.jokeService});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _jokes = [];
  bool _isLoading = false;
  bool _isOffline = false;
  bool _usingCachedData = false; // Tracks cached data usage while online
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    _loadCachedJokes();
  }

  Future<void> _loadCachedJokes() async {
    final cachedJokes = await widget.jokeService.getCachedJokes();
    if (cachedJokes != null) {
      setState(() {
        _jokes = cachedJokes;
        _isOffline = true;
        _animationController.forward();
      });
    }
  }

  Future<void> fetchJokes() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
      _usingCachedData = false;
    });

    try {
      final jokes = await widget.jokeService.fetchJokes();
      setState(() {
        _jokes = jokes.take(5).toList();
        _animationController.reset();
        _animationController.forward();
      });
    } catch (error) {
      final cachedJokes = await widget.jokeService.getCachedJokes();
      if (cachedJokes != null) {
        setState(() {
          _jokes = cachedJokes.take(5).toList();
          _isOffline = false; // Online but using cached data
          _usingCachedData = true; // Mark as using cached data
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _usingCachedData
                ? 'Online, but using cached jokes! 📱'
                : 'Oops! Jokes took a coffee break. $error',
            style: TextStyle(
              fontFamily: GoogleFonts.rubik().fontFamily,
              color: Colors.white,
            ),
          ),
          backgroundColor:
              _usingCachedData ? Colors.orange : Colors.deepPurpleAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Laugh Factory',
          style: TextStyle(
            fontFamily: GoogleFonts.rubik().fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_usingCachedData)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.cached,
                color: Colors.orange[300],
                semanticLabel: 'Using Cached Data',
              ),
            ),
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.offline_bolt,
                color: Colors.orange[300],
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5ACD), Color(0xFF4B0082)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Daily Dose of Humor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: GoogleFonts.rubik().fontFamily,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _jokes.isEmpty
                    ? Center(
                        child: Text(
                          'Ready to Laugh? 😄',
                          style: TextStyle(
                            fontFamily: GoogleFonts.rubik().fontFamily,
                            color: Colors.white70,
                            fontSize: 22,
                          ),
                        ),
                      )
                    : ScaleTransition(
                        scale: _animation,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _jokes.length,
                          itemBuilder: (context, index) {
                            final joke = _jokes[index];
                            return FadeTransition(
                              opacity: _animation,
                              child: Card(
                                elevation: 10,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.deepPurpleAccent,
                                        Colors.purpleAccent
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      joke['setup'] != null
                                          ? '${joke['setup']} \n${joke['delivery']} 😂'
                                          : joke['joke'] ?? 'No joke found',
                                      style: TextStyle(
                                        fontFamily:
                                            GoogleFonts.rubik().fontFamily,
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : fetchJokes,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: double.infinity,
                        minHeight: 60,
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isOffline ? 'Offline Jokes' : 'Unleash Humor',
                              style: TextStyle(
                                fontFamily: GoogleFonts.rubik().fontFamily,
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

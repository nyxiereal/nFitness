import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'screens/choose_club_screen.dart';
import 'screens/club_screen.dart';
import 'services/efitness_service.dart';
import 'services/updates_service.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  void _changeThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nFitness',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: AppWrapper(),
      builder: (context, child) {
        return ThemeProvider(
          changeTheme: _changeThemeMode,
          currentTheme: _themeMode,
          child: child!,
        );
      },
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdatesService.checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _checkInternetAndDetermineScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? _buildNoInternetScreen();
      },
    );
  }


  // Prevent logging out when there is no internet connection, basically fix a bug by patching it
  // wait holy shit i just invented fixing issues im such a genius
  Future<bool> _hasInternetConnection() async {
    try {
      final response = await http
          .get(Uri.parse('https://connectivitycheck.gstatic.com/generate_204'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Widget _buildNoInternetScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Widget> _checkInternetAndDetermineScreen() async {
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      return _buildNoInternetScreen();
    }
    return await _determineStartScreen();
  }

  Future<Widget> _determineStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final clubJson = prefs.getString('selectedClub');
    final accessToken = prefs.getString('accessToken');

    if (clubJson != null && clubJson.isNotEmpty && accessToken != null) {
      final tokenRefreshed = await EfitnessService().refreshTokenIfNeeded();
      if (!tokenRefreshed) {
        await prefs.clear();
        return const ChooseClubScreen();
      }

      final club = Map<String, dynamic>.from(jsonDecode(clubJson));
      return ClubScreen(club: club);
    }
    return const ChooseClubScreen();
  }
}

class ThemeProvider extends InheritedWidget {
  final Function(ThemeMode) changeTheme;
  final ThemeMode currentTheme;

  const ThemeProvider({
    super.key,
    required this.changeTheme,
    required this.currentTheme,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return currentTheme != oldWidget.currentTheme;
  }
}

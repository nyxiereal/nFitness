import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/efitness_service.dart';
import '../widgets/club_widget.dart';
import 'club_screen.dart';
import 'dart:convert';

class ChooseClubScreen extends StatefulWidget {
  const ChooseClubScreen({super.key});

  @override
  State<ChooseClubScreen> createState() => _ChooseClubScreenState();
}

class _ChooseClubScreenState extends State<ChooseClubScreen> {
  late Future<List<Map<String, dynamic>>> _clubsFuture = EfitnessService()
      .getClubs();
  List<Map<String, dynamic>> _clubs = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    _clubsFuture = EfitnessService().getClubs();
    _clubsFuture.then((clubs) {
      setState(() {
        _clubs = clubs;
      });
    });
  }

  Future<void> _onClubTap(Map<String, dynamic> club) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        return AlertDialog(
          title: Text('Log in to ${club['name'] ?? ''}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'email': emailController.text.trim(),
                  'password': passwordController.text,
                });
              },
              child: Text('Log In'),
            ),
          ],
        );
      },
    );
    if (result == null ||
        result['email']!.isEmpty ||
        result['password']!.isEmpty) {
      return;
    }

    final loginData = await EfitnessService().loginMember(
      clubId: club['clubId'],
      email: result['email']!,
      password: result['password']!,
    );
    if (loginData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedClub', jsonEncode(club));
    await prefs.setString('accessToken', loginData['accessToken']);
    await prefs.setString('refreshToken', loginData['refreshToken']);
    await prefs.setInt('expiresIn', loginData['expiresIn']);
    await prefs.setString('user_id', loginData['user_id'].toString());
    await prefs.setInt(
      'loginTime',
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
<<<<<<< HEAD
    await prefs.setString('savedEmail', result['email']!);
    await prefs.setString('savedPassword', result['password']!);
=======
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => ClubScreen(club: club)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose a Club')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search clubs...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _clubsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _clubs.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }
                final clubs = _clubs.isNotEmpty
                    ? _clubs
                    : (snapshot.data ?? []);
                final filtered = clubs.where((club) {
                  final name = (club['name'] ?? '').toString().toLowerCase();
                  final city = (club['city'] ?? '').toString().toLowerCase();
                  // Exclude clubs with "demo" in the name (case-insensitive)
                  // Yes, they aren't real clubs, they are for development probably, since ofc they test in prod.
                  if (RegExp(r'demo', caseSensitive: false).hasMatch(name)) {
                    return false;
                  }
                  return name.contains(_search) || city.contains(_search);
                }).toList();
                if (filtered.isEmpty) {
                  return Center(child: Text('No clubs found'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final club = filtered[index];
                    return ClubWidget(
                      club: club,
                      onTap: () => _onClubTap(club),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

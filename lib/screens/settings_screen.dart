import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Loading...';
  bool _woke = true;
  int? _gender;

  final genderOptions = const [
    {'label': 'Male', 'value': 1},
    {'label': 'Female', 'value': 2},
    {'label': 'Non-Binary', 'value': 3},
    {'label': 'Agender', 'value': 4},
    {'label': 'Business', 'value': 5},
  ];

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadWoke();
    _loadGender();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _loadWoke() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _woke = prefs.getBool('wokeSwitch') ?? true;
    });
  }

  Future<void> _setWoke(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wokeSwitch', value);
    setState(() {
      _woke = value;
    });
    if (!value) {
      await prefs.remove('genderOverride');
      await _loadGender();
    }
  }

  Future<void> _loadGender() async {
    final prefs = await SharedPreferences.getInstance();
    int? genderOverride = prefs.getInt('genderOverride');
    int? originalGender = prefs.getInt('originalGender');
    setState(() {
      _gender = genderOverride ?? originalGender ?? 1;
    });
  }

  Future<void> _setGender(int? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value != null) {
      await prefs.setInt('genderOverride', value);
      setState(() {
        _gender = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Theme Mode'),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.brightness_high),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.brightness_3),
                      ),
                    ],
                    selected: {themeProvider?.currentTheme ?? ThemeMode.system},
                    onSelectionChanged: (Set<ThemeMode> selection) {
                      themeProvider?.changeTheme(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personalization',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Switch(
                        value: _woke,
                        onChanged: (v) => _setWoke(v),
<<<<<<< HEAD
                        activeThumbColor: Theme.of(context).colorScheme.primary,
=======
                        activeColor: Theme.of(context).colorScheme.primary,
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
                      ),
                      const SizedBox(width: 8),
                      const Text('Enable gender switching'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_woke)
                    DropdownButtonFormField<int>(
<<<<<<< HEAD
                      initialValue: _gender,
=======
                      value: _gender,
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
                      decoration: const InputDecoration(
                        labelText: 'Gender changer (client-side)',
                        border: OutlineInputBorder(),
                      ),
                      items: genderOptions
                          .map((g) => DropdownMenuItem<int>(
                                value: g['value'] as int,
                                child: Text(g['label'] as String),
                              ))
                          .toList(),
                      onChanged: (v) => _setGender(v),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('App Version'),
                    subtitle: Text(_appVersion),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
<<<<<<< HEAD
                    title: const Text('Codeberg'),
                    subtitle: const Text('nxr/nfitness'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      launchUrl(
                        Uri.parse('https://codeberg.org/nxr/nfitness'),
=======
                    title: const Text('GitHub'),
                    subtitle: const Text('nyxiereal/nFitness'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      launchUrl(
                        Uri.parse('https://github.com/nyxiereal/nFitness'),
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
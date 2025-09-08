import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
=======
import 'dart:convert';
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
<<<<<<< HEAD
import 'package:xml/xml.dart';
=======
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80

class UpdatesService {
  static Future<void> checkForUpdates(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();

    final response = await http.get(
<<<<<<< HEAD
      Uri.parse('https://codeberg.org/nxr/nfitness/releases.rss'),
=======
      Uri.parse(
        'https://api.github.com/repos/nyxiereal/nFitness/releases/latest',
      ),
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
    );
    if (response.statusCode != 200) return;

    final currentVersionNum =
        int.tryParse(info.version.replaceAll('.', '')) ?? 0;
<<<<<<< HEAD

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    if (items.isEmpty) return;

    final latestItem = items.first;
    final title = latestItem.findElements('title').first.text;
    final link = latestItem.findElements('link').first.text;
    final content = latestItem.findElements('content:encoded').isNotEmpty
        ? latestItem.findElements('content:encoded').first.text
        : latestItem.findElements('description').first.text;

    // Extract version number from title (assuming format like "v1.2.3")
    final versionMatch = RegExp(r'v?(\d+)\.(\d+)\.(\d+)').firstMatch(title);
    if (versionMatch == null) return;

    final latestVersionNum =
        int.tryParse(
          '${versionMatch.group(1)}${versionMatch.group(2)}${versionMatch.group(3)}',
        ) ??
        0;
=======
    final release = jsonDecode(response.body);
    final changelog = release['body'] ?? '';
    final assets = release['assets'] as List<dynamic>? ?? [];
    final latestVersionNum =
        int.tryParse(release['tag_name'].replaceAll('.', '')) ?? 0;
    final apkAsset = assets.firstWhere(
      (a) => a['name'].toString().endsWith('.apk'),
      orElse: () => null,
    );
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80

    if (kDebugMode) {
      print(
        'Current version: $currentVersionNum, Latest version: $latestVersionNum',
      );
    }
<<<<<<< HEAD
    if (latestVersionNum <= currentVersionNum) {
      return;
    }

    // Fetch release page to get APK download link
    final releaseResponse = await http.get(Uri.parse(link));
    if (releaseResponse.statusCode != 200) return;

    // Look for APK download link in the release page
    final apkLinkMatch = RegExp(
      r'href="([^"]*\.apk)"',
    ).firstMatch(releaseResponse.body);
    if (apkLinkMatch == null) return;

    final apkPath = apkLinkMatch.group(1);
    final apkUrl = apkPath!.startsWith('http')
        ? apkPath
        : 'https://codeberg.org$apkPath';

=======
    if (latestVersionNum <= currentVersionNum || apkAsset == null) {
      return;
    }

>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
<<<<<<< HEAD
          title: Text('Update Available ($title)'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Changelog:'),
                const SizedBox(height: 8),
                Text(content.replaceAll(RegExp(r'<[^>]*>'), '')),
              ],
=======
          title: Text('Update Available (v${release['tag_name']})'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('Changelog:\n$changelog')],
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                // Request install unknown apps permission
                if (Platform.isAndroid) {
                  final status = await Permission.requestInstallPackages.status;
                  if (!status.isGranted) {
                    final result = await Permission.requestInstallPackages
                        .request();
                    if (!result.isGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Permission to install APKs denied.'),
                        ),
                      );
                      return;
                    }
                  }
                }
<<<<<<< HEAD
                final tempDir = await getTemporaryDirectory();
                final filePath = '${tempDir.path}/nfitness-latest.apk';
                final apkResp = await http.get(Uri.parse(apkUrl));
=======
                final url = apkAsset['browser_download_url'];
                final tempDir = await getTemporaryDirectory();
                final filePath = '${tempDir.path}/nfitness-latest.apk';
                final apkResp = await http.get(Uri.parse(url!));
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
                final file = File(filePath);
                await file.writeAsBytes(apkResp.bodyBytes);
                await OpenFile.open(filePath);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

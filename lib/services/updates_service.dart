import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdatesService {
  static Future<void> checkForUpdates(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();

    final response = await http.get(
      Uri.parse(
        'https://api.github.com/repos/nyxiereal/nFitness/releases/latest',
      ),
    );
    if (response.statusCode != 200) return;

    final currentVersionNum =
        int.tryParse(info.version.replaceAll('.', '')) ?? 0;
    final release = jsonDecode(response.body);
    final changelog = release['body'] ?? '';
    final assets = release['assets'] as List<dynamic>? ?? [];
    final latestVersionNum =
        int.tryParse(release['tag_name'].replaceAll('.', '')) ?? 0;
    final apkAsset = assets.firstWhere(
      (a) => a['name'].toString().endsWith('.apk'),
      orElse: () => null,
    );

    if (kDebugMode) {
      print(
        'Current version: $currentVersionNum, Latest version: $latestVersionNum',
      );
    }
    if (latestVersionNum <= currentVersionNum || apkAsset == null) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Update Available (v${release['tag_name']})'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('Changelog:\n$changelog')],
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
                final url = apkAsset['browser_download_url'];
                final tempDir = await getTemporaryDirectory();
                final filePath = '${tempDir.path}/nfitness-latest.apk';
                final apkResp = await http.get(Uri.parse(url!));
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

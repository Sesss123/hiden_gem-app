import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class ScreenshotService {
  final ScreenshotController controller = ScreenshotController();

  Future<void> captureAndShare(BuildContext context) async {
    try {
      final Uint8List? imageBytes = await controller.capture();
      
      if (imageBytes == null) return;

      if (kIsWeb) {
        // Handle web download/share
        final blob = html.Blob([imageBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "trip_me_plan_${DateTime.now().millisecondsSinceEpoch}.png")
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Screenshot saved to downloads")),
          );
        }
      } else {
        // Handle mobile/desktop share
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/screenshot.png').create();
        await imagePath.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Check out my Sri Lanka trip plan from TripMe.ai!',
        );
      }
    } catch (e) {
      debugPrint("Screenshot Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error capturing screenshot: $e")),
        );
      }
    }
  }
}

import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveAndDownloadFile(
  String filename,
  String content,
  String mimeType,
) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
  } catch (e) {
    // Graceful fallback for headless or restricted environments
  }
}

import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart';

/// Downloads or saves a file across Web and Native platforms.
Future<void> downloadReportFile({
  required String filename,
  required String content,
  required String mimeType,
}) async {
  await saveAndDownloadFile(filename, content, mimeType);
}

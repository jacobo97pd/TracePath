import 'file_download_stub.dart' if (dart.library.html) 'file_download_web.dart'
    as impl;

void downloadTextFile({required String fileName, required String content}) {
  impl.downloadTextFile(fileName: fileName, content: content);
}

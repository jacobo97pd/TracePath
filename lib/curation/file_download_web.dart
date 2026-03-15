import 'dart:convert';
import 'dart:html' as html;

void downloadTextFile({required String fileName, required String content}) {
  final bytes = utf8.encode(content);
  final blob = html.Blob(<List<int>>[bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

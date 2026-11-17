import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> downloadJsonFileImpl({
  required String filename,
  required String jsonContent,
}) async {
  final bytes = utf8.encode(jsonContent);
  final jsBytes = bytes.toJS;
  final blob = web.Blob(
    <JSAny>[jsBytes].toJS,
    web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}

Future<String?> pickJsonFileContentImpl() async {
  final completer = Completer<String?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = '.json,application/json';

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.length == 0) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final reader = web.FileReader();
    reader.onLoadEnd.first.then((_) {
      final result = reader.result;
      if (result != null && result.isA<JSString>()) {
        if (!completer.isCompleted) {
          completer.complete((result as JSString).toDart);
        }
      } else {
        if (!completer.isCompleted) completer.complete(null);
      }
    });
    reader.readAsText(file);
  });

  input.click();
  return completer.future;
}

bool get supportsBrowserFileTransferImpl => true;

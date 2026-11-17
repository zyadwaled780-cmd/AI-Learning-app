import 'json_transfer_stub.dart'
    if (dart.library.js_interop) 'json_transfer_web.dart'
    as impl;

/// Downloads a JSON file on Web; returns false on platforms where browser
/// file downloads are unavailable (caller falls back to clipboard / copy dialog).
Future<bool> downloadJsonFile({
  required String filename,
  required String jsonContent,
}) {
  return impl.downloadJsonFileImpl(
    filename: filename,
    jsonContent: jsonContent,
  );
}

/// Prompts the browser file picker for a .json file on Web; returns null
/// on unsupported platforms or when cancelled.
Future<String?> pickJsonFileContent() {
  return impl.pickJsonFileContentImpl();
}

bool get supportsBrowserFileTransfer => impl.supportsBrowserFileTransferImpl;

import 'dart:typed_data';

Future<String> savePngToDocuments(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Saving to filesystem is not supported on web.');
}

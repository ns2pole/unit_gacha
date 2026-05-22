// Writes android/app/google-services.json from CI secrets (Codemagic / GitHub Actions).
// Set GOOGLE_SERVICES_JSON to the full file contents from Firebase Console,
// or GOOGLE_SERVICES_JSON_BASE64 for the same JSON base64-encoded.
// If unset and android/app/google-services.json already exists, exits 0.

import 'dart:convert';
import 'dart:io';

void main() {
  const outPath = 'android/app/google-services.json';
  final out = File(outPath);

  String? env(String k) {
    final v = Platform.environment[k];
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  String? jsonContent;
  final raw = env('GOOGLE_SERVICES_JSON');
  if (raw != null) {
    jsonContent = raw;
  } else {
    final b64 = env('GOOGLE_SERVICES_JSON_BASE64');
    if (b64 != null) {
      try {
        jsonContent = utf8.decode(base64Decode(b64));
      } on FormatException catch (e) {
        stderr.writeln('inject_google_services_json: invalid base64: $e');
        exit(1);
      }
    }
  }

  if (jsonContent == null) {
    if (out.existsSync()) {
      stdout.writeln(
        'inject_google_services_json: no GOOGLE_SERVICES_JSON; '
        'keeping existing $outPath.',
      );
      exit(0);
    }
    stderr.writeln(
      'inject_google_services_json: missing $outPath.\n'
      'Local: download from Firebase Console → Project settings → Your apps → Android\n'
      '  and save as $outPath (see android/app/google-services.json.example).\n'
      'CI: add secret GOOGLE_SERVICES_JSON (full JSON) or GOOGLE_SERVICES_JSON_BASE64, '
      'then run `dart run tool/inject_google_services_json.dart` before `flutter build`.',
    );
    exit(1);
  }

  try {
    final decoded = jsonDecode(jsonContent);
    if (decoded is! Map) {
      stderr.writeln('inject_google_services_json: JSON root must be an object.');
      exit(1);
    }
  } on FormatException catch (e) {
    stderr.writeln('inject_google_services_json: invalid JSON: $e');
    exit(1);
  }

  out.parent.createSync(recursive: true);
  final normalized = const JsonEncoder.withIndent('  ').convert(jsonDecode(jsonContent));
  out.writeAsStringSync('$normalized\n');
  stdout.writeln('Wrote $outPath from environment.');
}

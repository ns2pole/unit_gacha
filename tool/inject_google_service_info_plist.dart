// Writes ios/Runner/GoogleService-Info.plist from CI secrets (Codemagic / GitHub Actions).
// Set GOOGLE_SERVICE_INFO_PLIST to the full plist contents,
// or GOOGLE_SERVICE_INFO_PLIST_BASE64 for the same contents base64-encoded.
// If unset and ios/Runner/GoogleService-Info.plist already exists, exits 0.

import 'dart:convert';
import 'dart:io';

void main() {
  const outPath = 'ios/Runner/GoogleService-Info.plist';
  final out = File(outPath);

  String? env(String k) {
    final v = Platform.environment[k];
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  String? plistContent;
  final raw = env('GOOGLE_SERVICE_INFO_PLIST');
  if (raw != null) {
    plistContent = raw;
  } else {
    final b64 = env('GOOGLE_SERVICE_INFO_PLIST_BASE64');
    if (b64 != null) {
      try {
        plistContent = utf8.decode(base64Decode(b64));
      } on FormatException catch (e) {
        stderr.writeln(
          'inject_google_service_info_plist: invalid base64: $e',
        );
        exit(1);
      }
    }
  }

  if (plistContent == null) {
    if (out.existsSync()) {
      stdout.writeln(
        'inject_google_service_info_plist: no GOOGLE_SERVICE_INFO_PLIST; '
        'keeping existing $outPath.',
      );
      exit(0);
    }
    stderr.writeln(
      'inject_google_service_info_plist: missing $outPath.\n'
      'Local: copy ios/Runner/GoogleService-Info.plist.example and fill Firebase values.\n'
      'CI: add GOOGLE_SERVICE_INFO_PLIST (full plist) or GOOGLE_SERVICE_INFO_PLIST_BASE64, '
      'then run `dart run tool/inject_google_service_info_plist.dart` before iOS build.',
    );
    exit(1);
  }

  if (!plistContent.contains('<plist')) {
    stderr.writeln(
      'inject_google_service_info_plist: input does not look like a plist.',
    );
    exit(1);
  }

  out.parent.createSync(recursive: true);
  out.writeAsStringSync(plistContent.trimRight() + '\n');
  stdout.writeln('Wrote $outPath from environment.');
}

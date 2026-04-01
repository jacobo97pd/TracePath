import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LevelReportException implements Exception {
  const LevelReportException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'LevelReportException(code=$code, message=$message)';
}

class LevelReportResult {
  const LevelReportResult({
    required this.ok,
    required this.unlocked,
    required this.reportCreated,
    required this.emailSent,
  });

  final bool ok;
  final bool unlocked;
  final bool reportCreated;
  final bool emailSent;
}

class LevelReportService {
  FirebaseFunctions _functions() =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<LevelReportResult> reportLevelAndUnlockNext({
    required String levelId,
    required String nextLevelId,
    String reason = 'Nivel reportado como imposible',
    int? nextLevelIndex,
  }) async {
    final normalizedLevelId = levelId.trim();
    final normalizedNextLevelId = nextLevelId.trim();
    if (normalizedLevelId.isEmpty || normalizedNextLevelId.isEmpty) {
      throw const LevelReportException(
        'invalid-argument',
        'Missing required level report parameters.',
      );
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final callable = _functions().httpsCallable('reportLevelAndUnlockNext');

    try {
      final response = await callable.call(<String, dynamic>{
        'levelId': normalizedLevelId,
        'nextLevelId': normalizedNextLevelId,
        'reason': reason,
        'nextLevelIndex': nextLevelIndex,
        'platform': _platformTag(),
        'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
      });
      final raw = response.data;
      if (raw is! Map) {
        throw const LevelReportException(
          'invalid-response',
          'Unexpected response from report function.',
        );
      }
      final data = Map<String, dynamic>.from(raw);
      final ok = data['ok'] == true;
      final unlocked = data['unlocked'] == true;
      if (!ok || !unlocked) {
        throw const LevelReportException(
          'invalid-response',
          'Report function did not confirm unlock.',
        );
      }
      return LevelReportResult(
        ok: ok,
        unlocked: unlocked,
        reportCreated: data['reportCreated'] == true,
        emailSent: data['emailSent'] == true,
      );
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[report-level] callable error code=${e.code} message=${e.message} details=${e.details}',
        );
      }
      throw LevelReportException(
        e.code,
        (e.message ?? 'Could not report this level.').trim(),
      );
    } catch (e) {
      if (e is LevelReportException) rethrow;
      if (kDebugMode) {
        debugPrint('[report-level] callable unexpected error: $e');
      }
      throw const LevelReportException('unknown', 'Could not report this level.');
    }
  }

  String _platformTag() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}

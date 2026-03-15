import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/app_data.dart';

void main() {
  test('reason sample architect', () {
    debugPrint = (String? message, {int? wrapWidth}) {};
    final counts = <String,int>{};
    var ok = 0;
    for (var i=1;i<=60;i++) {
      try {
        loadCampaignLevel('architect', ((i*53)%200)+1, retryNonce: i);
        ok++;
      } catch (e) {
        final s = e.toString();
        final key = RegExp(r'reason=([^\] ]+)').firstMatch(s)?.group(1) ?? 'unknown';
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    // ignore: avoid_print
    print('OK=$ok FAIL=${60-ok} counts=$counts');
    expect(true, isTrue);
  });
}

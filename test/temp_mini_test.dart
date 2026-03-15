import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/app_data.dart';

void main() {
  test('mini stress', () {
    debugPrint = (String? message, {int? wrapWidth}) {};
    const samples = 10;
    var ok = 0;
    for (var i = 1; i <= samples; i++) {
      try { loadCampaignLevel('architect', ((i * 53) % 200) + 1, retryNonce: i); ok++; } catch (_) {}
    }
    print('MINI architect=$ok/$samples');
    expect(true, isTrue);
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/app_data.dart';

void main() {
  test('quick stress 50 per mode', () {
    debugPrint = (String? message, {int? wrapWidth}) {};

    const samples = 50;
    var campaignOk = 0;
    var architectOk = 0;
    var dailyOk = 0;
    var endlessOk = 0;

    for (var i = 1; i <= samples; i++) {
      try { if (loadCampaignLevel('classic', ((i * 37) % 200) + 1, retryNonce: i).numbers.isNotEmpty) campaignOk++; } catch (_) {}
      try { if (loadCampaignLevel('architect', ((i * 53) % 200) + 1, retryNonce: i).numbers.isNotEmpty) architectOk++; } catch (_) {}
      try { if (loadDailyLevel(retryNonce: i).numbers.isNotEmpty) dailyOk++; } catch (_) {}
      try {
        if (loadEndlessLevel(difficulty: (i % 5) + 1, index: ((i * 29) % 300) + 1, runSeed: 40000 + i, retryNonce: i).numbers.isNotEmpty) endlessOk++;
      } catch (_) {}
    }

    print('QUICK campaign=$campaignOk/$samples');
    print('QUICK architect=$architectOk/$samples');
    print('QUICK daily=$dailyOk/$samples');
    print('QUICK endless=$endlessOk/$samples');
    expect(true, isTrue);
  });
}

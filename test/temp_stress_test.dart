import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/app_data.dart';

void main() {
  test('generator stress 200 per mode', () {
    debugPrint = (String? message, {int? wrapWidth}) {};

    const samples = 200;
    var campaignOk = 0;
    var architectOk = 0;
    var dailyOk = 0;
    var endlessOk = 0;

    for (var i = 1; i <= samples; i++) {
      try {
        final level = loadCampaignLevel('classic', ((i * 37) % 200) + 1, retryNonce: i);
        if (level.numbers.isNotEmpty) campaignOk++;
      } catch (_) {}

      try {
        final level = loadCampaignLevel('architect', ((i * 53) % 200) + 1, retryNonce: i);
        if (level.numbers.isNotEmpty) architectOk++;
      } catch (_) {}

      try {
        final level = loadDailyLevel(retryNonce: i);
        if (level.numbers.isNotEmpty) dailyOk++;
      } catch (_) {}

      try {
        final level = loadEndlessLevel(
          difficulty: (i % 5) + 1,
          index: ((i * 29) % 300) + 1,
          runSeed: 40000 + i,
          retryNonce: i,
        );
        if (level.numbers.isNotEmpty) endlessOk++;
      } catch (_) {}
    }

    final campaignRate = campaignOk / samples;
    final architectRate = architectOk / samples;
    final dailyRate = dailyOk / samples;
    final endlessRate = endlessOk / samples;

    // ignore: avoid_print
    print('STRESS campaign=$campaignOk/$samples (${(campaignRate * 100).toStringAsFixed(1)}%)');
    // ignore: avoid_print
    print('STRESS architect=$architectOk/$samples (${(architectRate * 100).toStringAsFixed(1)}%)');
    // ignore: avoid_print
    print('STRESS daily=$dailyOk/$samples (${(dailyRate * 100).toStringAsFixed(1)}%)');
    // ignore: avoid_print
    print('STRESS endless=$endlessOk/$samples (${(endlessRate * 100).toStringAsFixed(1)}%)');

    expect(campaignRate, greaterThanOrEqualTo(0.99));
    expect(architectRate, greaterThanOrEqualTo(0.99));
    expect(dailyRate, greaterThanOrEqualTo(0.99));
    expect(endlessRate, greaterThanOrEqualTo(0.99));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/app_data.dart';

void main() {
  test('seed export registry', () async {
    for (var i = 1; i <= 20; i++) {
      await loadCampaignLevelAsync('classic', i, retryNonce: 0);
    }
    await loadDailyLevelAsync(retryNonce: 0);
  });
}

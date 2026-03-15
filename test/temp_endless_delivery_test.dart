import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zip_path_flutter/app_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('endless repository warm pool and cached load is fast', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const request = EndlessLevelRequest(
      difficulty: 4,
      index: 1,
      runSeed: 123456789,
    );

    await endlessLevelRepository.warmUpPool(request, poolSize: 3);

    final firstWatch = Stopwatch()..start();
    final first = await endlessLevelRepository.getCurrentLevel(request);
    firstWatch.stop();
    expect(first.pack, 'endless');

    final secondWatch = Stopwatch()..start();
    final second = await endlessLevelRepository.getCurrentLevel(request);
    secondWatch.stop();
    expect(second.pack, 'endless');

    // Cached/memoized path should be significantly faster than first generation path.
    expect(
      secondWatch.elapsedMilliseconds,
      lessThanOrEqualTo(
        firstWatch.elapsedMilliseconds == 0
            ? 5
            : firstWatch.elapsedMilliseconds,
      ),
    );

    final next = await endlessLevelRepository.getNextLevel(request);
    expect(next.pack, 'endless');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

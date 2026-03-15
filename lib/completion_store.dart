import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompletionStore extends ChangeNotifier {
  CompletionStore(this._prefs);

  final SharedPreferences _prefs;

  bool isCompleted(String packId, int levelNumber) {
    return _prefs.getBool(_key(packId, levelNumber)) ?? false;
  }

  Future<void> markCompleted(String packId, int levelNumber) async {
    if (isCompleted(packId, levelNumber)) {
      return;
    }

    await _prefs.setBool(_key(packId, levelNumber), true);
    notifyListeners();
  }

  String _key(String packId, int levelNumber) {
    return 'completion:$packId:$levelNumber';
  }
}

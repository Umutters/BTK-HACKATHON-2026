import 'package:flutter/foundation.dart';

class NavigationViewModel extends ChangeNotifier {
  int _currentIndex = 0;
  bool _fabVisible = true;

  int get currentIndex => _currentIndex;
  bool get fabVisible => _fabVisible;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      // FAB yalnızca home tab'ında görünür; tab değişince sıfırla
      if (_fabVisible != true) {
        _fabVisible = true;
      }
      notifyListeners();
    }
  }

  void setFabVisible(bool value) {
    if (_fabVisible != value) {
      _fabVisible = value;
      notifyListeners();
    }
  }
}

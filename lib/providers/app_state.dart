import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static const String _strengthKey = 'strength_level';
  
  int _currentStrength = 5; // 魅力レベル（1-10）
  bool _isLoading = false;
  String? _errorMessage;

  int get currentStrength => _currentStrength; // 魅力レベルを取得
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AppState() {
    _loadStrength();
  }

  Future<void> _loadStrength() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentStrength = prefs.getInt(_strengthKey) ?? 5;
      notifyListeners();
    } catch (e) {
      _setError('設定の読み込みに失敗しました');
    }
  }

  Future<void> updateStrength(int strength) async {
    if (strength < 1 || strength > 10) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_strengthKey, strength);
      _currentStrength = strength;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('設定の保存に失敗しました');
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
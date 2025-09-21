import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/usage_limit_service.dart';

class AppState extends ChangeNotifier {
  static const String _strengthKey = 'strength_level';
  
  int _currentStrength = 5; // 魅力レベル（1-10）
  bool _isLoading = false;
  String? _errorMessage;
  
  // 使用制限関連
  UsageLimitInfo? _usageLimitInfo;
  bool _isLoadingUsageInfo = false;

  int get currentStrength => _currentStrength; // 魅力レベルを取得
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // 使用制限関連のゲッター
  UsageLimitInfo? get usageLimitInfo => _usageLimitInfo;
  bool get isLoadingUsageInfo => _isLoadingUsageInfo;
  bool get canUseToday => _usageLimitInfo?.canUse ?? false;
  int get remainingUsage => _usageLimitInfo?.remainingCount ?? 0;
  int get usedCount => _usageLimitInfo?.usedCount ?? 0;
  int get dailyLimit => _usageLimitInfo?.dailyLimit ?? 10;

  AppState() {
    _loadStrength();
    _loadUsageLimitInfo();
    _cleanupOldData();
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
  
  // 使用制限関連のメソッド
  
  /// 使用制限情報を読み込み
  Future<void> _loadUsageLimitInfo() async {
    _isLoadingUsageInfo = true;
    notifyListeners();
    
    try {
      _usageLimitInfo = await UsageLimitService.getUsageLimitInfo();
    } catch (e) {
      debugPrint('使用制限情報の読み込みに失敗しました: $e');
    } finally {
      _isLoadingUsageInfo = false;
      notifyListeners();
    }
  }
  
  /// 使用制限情報を更新
  Future<void> refreshUsageLimitInfo() async {
    await _loadUsageLimitInfo();
  }
  
  /// AI加工使用前のチェック
  Future<bool> checkUsageLimit() async {
    await _loadUsageLimitInfo();
    return canUseToday;
  }
  
  /// AI加工使用回数を増やす
  Future<bool> incrementUsage() async {
    try {
      final success = await UsageLimitService.incrementUsage();
      if (success) {
        await _loadUsageLimitInfo(); // 最新情報に更新
      }
      return success;
    } catch (e) {
      debugPrint('使用回数の更新に失敗しました: $e');
      return false;
    }
  }
  
  /// 古いデータのクリーンアップ
  Future<void> _cleanupOldData() async {
    try {
      await UsageLimitService.cleanupOldData();
    } catch (e) {
      debugPrint('データクリーンアップに失敗しました: $e');
    }
  }
  
  /// 使用制限エラーメッセージを取得
  String getUsageLimitErrorMessage() {
    if (_usageLimitInfo == null) {
      return '使用制限情報を読み込み中です...';
    }
    
    if (_usageLimitInfo!.canUse) {
      return '';
    }
    
    final timeUntilReset = _usageLimitInfo!.timeUntilReset;
    final hours = timeUntilReset.inHours;
    final minutes = timeUntilReset.inMinutes % 60;
    
    return '本日の使用制限（${_usageLimitInfo!.dailyLimit}回）に達しました。\n'
           '次回使用可能まで: ${hours}時間${minutes}分';
  }
}
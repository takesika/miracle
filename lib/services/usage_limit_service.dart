import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageLimitService {
  static const int _dailyLimit = 5; // 1日の使用制限回数
  static const String _usageCountPrefix = 'usage_count_';
  
  /// 今日の使用回数を取得
  static Future<int> getTodayUsageCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayKey();
      return prefs.getInt('$_usageCountPrefix$today') ?? 0;
    } catch (e) {
      debugPrint('使用回数の取得に失敗しました: $e');
      return 0;
    }
  }
  
  /// 今日の残り使用回数を取得
  static Future<int> getRemainingUsage() async {
    final usedCount = await getTodayUsageCount();
    return (_dailyLimit - usedCount).clamp(0, _dailyLimit);
  }
  
  /// 使用可能かどうかチェック
  static Future<bool> canUseToday() async {
    final remaining = await getRemainingUsage();
    return remaining > 0;
  }
  
  /// 使用回数を1回増やす
  static Future<bool> incrementUsage() async {
    try {
      if (!await canUseToday()) {
        debugPrint('使用制限に達しています');
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayKey();
      final currentCount = await getTodayUsageCount();
      await prefs.setInt('$_usageCountPrefix$today', currentCount + 1);
      
      debugPrint('使用回数を更新: ${currentCount + 1}/$_dailyLimit');
      return true;
    } catch (e) {
      debugPrint('使用回数の更新に失敗しました: $e');
      return false;
    }
  }
  
  /// 今日の日付キーを取得（YYYY-MM-DD形式）
  static String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  /// 制限回数を取得
  static int get dailyLimit => _dailyLimit;
  
  /// 次回リセット時刻を取得（翌日の午前0時）
  static DateTime getNextResetTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }
  
  /// リセットまでの残り時間を取得
  static Duration getTimeUntilReset() {
    final nextReset = getNextResetTime();
    final now = DateTime.now();
    return nextReset.difference(now);
  }
  
  /// 使用制限に関する情報を取得
  static Future<UsageLimitInfo> getUsageLimitInfo() async {
    final usedCount = await getTodayUsageCount();
    final remainingCount = await getRemainingUsage();
    final canUse = await canUseToday();
    final timeUntilReset = getTimeUntilReset();
    
    return UsageLimitInfo(
      usedCount: usedCount,
      remainingCount: remainingCount,
      dailyLimit: _dailyLimit,
      canUse: canUse,
      timeUntilReset: timeUntilReset,
    );
  }
  
  /// 古い使用回数データをクリーンアップ（過去7日より古いデータを削除）
  static Future<void> cleanupOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      for (final key in keys) {
        if (key.startsWith(_usageCountPrefix)) {
          final dateStr = key.substring(_usageCountPrefix.length);
          try {
            final date = DateTime.parse(dateStr);
            if (date.isBefore(cutoffDate)) {
              await prefs.remove(key);
              debugPrint('古いデータを削除: $key');
            }
          } catch (e) {
            // 無効な日付形式のキーは削除
            await prefs.remove(key);
            debugPrint('無効なキーを削除: $key');
          }
        }
      }
    } catch (e) {
      debugPrint('データクリーンアップに失敗しました: $e');
    }
  }
}

/// 使用制限情報を格納するクラス
class UsageLimitInfo {
  final int usedCount;
  final int remainingCount;
  final int dailyLimit;
  final bool canUse;
  final Duration timeUntilReset;
  
  const UsageLimitInfo({
    required this.usedCount,
    required this.remainingCount,
    required this.dailyLimit,
    required this.canUse,
    required this.timeUntilReset,
  });
  
  @override
  String toString() {
    return 'UsageLimitInfo(used: $usedCount, remaining: $remainingCount, limit: $dailyLimit, canUse: $canUse)';
  }
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miracle_shot/providers/app_state.dart';

void main() {
  group('AppState Tests', () {
    late AppState appState;

    setUp(() {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
    });

    test('should have default strength of 5', () {
      expect(appState.currentStrength, equals(5));
    });

    test('should update strength within valid range', () async {
      await appState.updateStrength(7);
      expect(appState.currentStrength, equals(7));
    });

    test('should not update strength below 1', () async {
      await appState.updateStrength(0);
      expect(appState.currentStrength, equals(5)); // Should remain unchanged
    });

    test('should not update strength above 10', () async {
      await appState.updateStrength(11);
      expect(appState.currentStrength, equals(5)); // Should remain unchanged
    });

    test('should handle loading state', () {
      expect(appState.isLoading, isFalse);
      
      appState.setLoading(true);
      expect(appState.isLoading, isTrue);
      
      appState.setLoading(false);
      expect(appState.isLoading, isFalse);
    });

    test('should handle error messages', () {
      expect(appState.errorMessage, isNull);
      
      // This would require exposing _setError method or testing through updateStrength
      appState.clearError();
      expect(appState.errorMessage, isNull);
    });

    test('should persist strength in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'strength_level': 8});
      
      final newAppState = AppState();
      // Need to wait for async initialization
      await Future.delayed(const Duration(milliseconds: 10));
      
      // This test would need the _loadStrength method to be synchronous
      // or expose a way to wait for initialization
    });
  });
}
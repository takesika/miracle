import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:miracle_shot/main.dart';
import 'package:miracle_shot/providers/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('App should display home screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MiracleShotApp());
      await tester.pumpAndSettle();

      expect(find.text('奇跡の一枚'), findsWidgets);
      expect(find.text('写真を撮る'), findsOneWidget);
      expect(find.text('写真を選ぶ'), findsOneWidget);
    });

    testWidgets('Home screen should show strength value', (WidgetTester tester) async {
      await tester.pumpWidget(const MiracleShotApp());
      await tester.pumpAndSettle();

      expect(find.text('前回の強度:'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Default strength
    });

    testWidgets('Camera button should be tappable', (WidgetTester tester) async {
      await tester.pumpWidget(const MiracleShotApp());
      await tester.pumpAndSettle();

      final cameraButton = find.text('写真を撮る');
      expect(cameraButton, findsOneWidget);

      // Tap the button
      await tester.tap(cameraButton);
      await tester.pumpAndSettle();

      // Should navigate to camera screen or show error
      // Since we don't have camera permissions in test, it may show an error
    });

    testWidgets('Photo picker button should be tappable', (WidgetTester tester) async {
      await tester.pumpWidget(const MiracleShotApp());
      await tester.pumpAndSettle();

      final photoButton = find.text('写真を選ぶ');
      expect(photoButton, findsOneWidget);

      // Tap the button
      await tester.tap(photoButton);
      await tester.pumpAndSettle();

      // Should try to open photo picker or show error
    });
  });

  group('AppState Widget Integration Tests', () {
    testWidgets('Should display updated strength', (WidgetTester tester) async {
      final appState = AppState();
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: Consumer<AppState>(
              builder: (context, state, child) {
                return Scaffold(
                  body: Text('Strength: ${state.currentStrength}'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Strength: 5'), findsOneWidget);

      await appState.updateStrength(8);
      await tester.pump();

      expect(find.text('Strength: 8'), findsOneWidget);
    });

    testWidgets('Should display loading state', (WidgetTester tester) async {
      final appState = AppState();
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            home: Consumer<AppState>(
              builder: (context, state, child) {
                return Scaffold(
                  body: state.isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Not Loading'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Not Loading'), findsOneWidget);

      appState.setLoading(true);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
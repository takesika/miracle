import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
// import 'screens/test_api_screen.dart';
import 'providers/app_state.dart';
import 'services/ai_enhancement_service.dart';

void main() {
  // Initialize OpenAI API (環境変数またはここで設定)
  const String openaiApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: 'your_api_key_here');
  
  AIEnhancementService.initialize(openaiApiKey);
  
  runApp(const MiracleShotApp());
}

class MiracleShotApp extends StatelessWidget {
  const MiracleShotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: '奇跡の一枚',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        // home: const TestAPIScreen(), // テスト用
        home: const HomeScreen(), // 本番用
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
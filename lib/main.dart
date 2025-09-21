import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
// import 'screens/test_api_screen.dart';
import 'providers/app_state.dart';
import 'services/ai_enhancement_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  final String openaiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  
  if (openaiApiKey.isEmpty) {
    throw Exception('OPENAI_API_KEY not found in .env file');
  }
  
  debugPrint('使用するAPIキー: ${openaiApiKey.substring(0, 20)}...');
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
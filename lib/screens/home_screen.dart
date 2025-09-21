import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/photo_picker_service.dart';
import '../screens/image_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});


  Future<void> _pickPhoto(BuildContext context) async {
    try {
      final File? imageFile = await PhotoPickerService.pickImage();
      
      if (imageFile != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageEditorScreen(imageFile: imageFile),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写真選択エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('奇跡の一枚'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Title
              const Icon(
                Icons.photo_library,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                '奇跡の一枚',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AIで写真をかっこよく補正',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),
              
              // Current Strength Display
              Consumer<AppState>(
                builder: (context, appState, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '前回の強度: ',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${appState.currentStrength > 5 ? 5 : appState.currentStrength}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => _pickPhoto(context),
                  icon: const Icon(Icons.photo_library, size: 28),
                  label: const Text(
                    '写真を選んで加工する',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_enhancement_service_dio.dart';
import '../services/error_handler.dart';

class TestAPIScreen extends StatefulWidget {
  const TestAPIScreen({Key? key}) : super(key: key);

  @override
  State<TestAPIScreen> createState() => _TestAPIScreenState();
}

class _TestAPIScreenState extends State<TestAPIScreen> {
  File? _selectedImage;
  File? _enhancedImage;
  bool _isProcessing = false;
  int _strength = 5;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize with API key from environment or hardcoded for testing
    final apiKey = const String.fromEnvironment('OPENAI_API_KEY').isNotEmpty
        ? const String.fromEnvironment('OPENAI_API_KEY')
        : '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';
    AIEnhancementServiceDio.initialize(apiKey);
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _enhancedImage = null;
        _statusMessage = '画像が選択されました';
      });
    }
  }

  Future<void> _enhanceImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = '処理中... (強度: $_strength)';
    });

    try {
      final enhanced = await AIEnhancementServiceDio.enhanceImage(
        _selectedImage!,
        _strength,
      );
      
      setState(() {
        _enhancedImage = enhanced;
        _isProcessing = false;
        _statusMessage = '処理完了！';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'エラー: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test - gpt-image-1'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status message
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage.isEmpty ? 'APIテストツール' : _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('エラー') ? Colors.red : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image selection button
              ElevatedButton.icon(
                onPressed: _selectImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('画像を選択'),
              ),
              const SizedBox(height: 16),

              // Strength slider
              Text('強度: $_strength'),
              Slider(
                value: _strength.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _strength.toString(),
                onChanged: (value) {
                  setState(() {
                    _strength = value.round();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Process button
              ElevatedButton.icon(
                onPressed: _selectedImage != null && !_isProcessing ? _enhanceImage : null,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isProcessing ? '処理中...' : '画像を加工'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Image display
              if (_selectedImage != null || _enhancedImage != null)
                Row(
                  children: [
                    // Original image
                    if (_selectedImage != null)
                      Expanded(
                        child: Column(
                          children: [
                            const Text('オリジナル'),
                            const SizedBox(height: 8),
                            Image.file(
                              _selectedImage!,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    if (_selectedImage != null && _enhancedImage != null)
                      const SizedBox(width: 16),
                    // Enhanced image
                    if (_enhancedImage != null)
                      Expanded(
                        child: Column(
                          children: [
                            const Text('加工済み'),
                            const SizedBox(height: 8),
                            Image.file(
                              _enhancedImage!,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
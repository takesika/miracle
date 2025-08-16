import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/ai_enhancement_service.dart';
import '../services/photo_save_service.dart';

class ImageEditorScreen extends StatefulWidget {
  final File imageFile;

  const ImageEditorScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  late double _currentStrength;
  File? _processedImage;
  bool _isProcessing = false;
  String? _error;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentStrength = context.read<AppState>().currentStrength.toDouble();
    _processInitialImage();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleProcessing() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _processImage();
    });
  }

  Future<void> _processInitialImage() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await AIEnhancementService.enhanceImage(
        widget.imageFile,
        _currentStrength.round(),
      );
      
      if (result != null) {
        setState(() {
          _processedImage = result;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _error = '画像処理に失敗しました';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '処理エラー: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await AIEnhancementService.enhanceImage(
        widget.imageFile,
        _currentStrength.round(),
      );
      
      if (result != null) {
        setState(() {
          _processedImage = result;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _error = '画像処理に失敗しました';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '処理エラー: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final success = await PhotoSaveService.saveToGallery(_processedImage!);
      
      if (success && mounted) {
        // Update strength preference
        await context.read<AppState>().updateStrength(_currentStrength.round());
        
        // Show success message and go back to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('写真を保存しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像編集'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_processedImage != null && !_isProcessing)
            TextButton(
              onPressed: _saveImage,
              child: const Text(
                '保存',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildImagePreview(),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _processImage,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('画像を処理中...'),
                ],
              ),
            )
          : Image.file(
              _processedImage ?? widget.imageFile,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'かっこよさ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentStrength.round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('1'),
              Expanded(
                child: Slider(
                  value: _currentStrength,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: _isProcessing
                      ? null
                      : (value) {
                          setState(() {
                            _currentStrength = value;
                          });
                        },
                  onChangeEnd: _isProcessing ? null : (value) => _scheduleProcessing(),
                ),
              ),
              const Text('10'),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '原状維持',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '最大補正',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
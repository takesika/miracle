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
  bool _isSaving = false;
  String? _error;
  Timer? _debounceTimer;
  int _imageKey = 0; // 画像更新を強制するためのキー

  @override
  void initState() {
    super.initState();
    _currentStrength = context.read<AppState>().currentStrength.toDouble();
    // 初期画像は元画像を表示（自動処理しない）
    _processedImage = widget.imageFile;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 自動処理を削除し、手動実行に変更

  Future<void> _processImage() async {
    final strengthLevel = _currentStrength.round();
    debugPrint('画像処理開始 - 魅力レベル: $strengthLevel');
    debugPrint('加工対象: 元画像 (${widget.imageFile.path})');
    
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // 加工対象は常に最初に選択した元画像（widget.imageFile）を使用
      final result = await AIEnhancementService.enhanceImage(
        widget.imageFile,  // 前回の加工結果ではなく、常に元画像を対象とする
        strengthLevel,
      );
      
      if (result != null) {
        debugPrint('AI処理完了 - 新しい画像: ${result.path}');
        setState(() {
          _processedImage = result;
          _isProcessing = false;
          _imageKey++; // 画像キーを更新して強制再描画
        });
      } else {
        setState(() {
          _error = 'AI画像処理に失敗しました。ネットワーク接続を確認してください。';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        String errorMessage = 'AI処理エラーが発生しました';
        if (e.toString().contains('API')) {
          errorMessage = 'OpenAI APIエラー: APIキーを確認してください';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'ネットワークエラー: インターネット接続を確認してください';
        } else if (e.toString().contains('サイズ')) {
          errorMessage = '画像サイズが大きすぎます。別の画像をお試しください。';
        }
        _error = errorMessage;
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;

    setState(() => _isSaving = true);

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
          if (_processedImage != null && !_isProcessing && !_isSaving)
            TextButton(
              onPressed: _saveImage,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  : const Text(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _processImage,
                  child: const Text('再試行'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _processedImage = widget.imageFile;  // 元画像に戻す
                      _error = null;
                    });
                  },
                  child: const Text('元画像を表示'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 画像状態の表示
          if (!_isProcessing && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _processedImage == widget.imageFile 
                    ? Colors.grey[200] 
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _processedImage == widget.imageFile 
                      ? Colors.grey[400]! 
                      : Colors.blue[300]!,
                ),
              ),
              child: Text(
                _processedImage == widget.imageFile 
                    ? '元画像を表示中' 
                    : '魅力レベル ${_currentStrength.round()} で加工済み',
                style: TextStyle(
                  fontSize: 12,
                  color: _processedImage == widget.imageFile 
                      ? Colors.grey[600] 
                      : Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // 画像表示部分
          Expanded(
            child: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('AI画像処理中...'),
                  const SizedBox(height: 8),
                  Text(
                    '処理には1〜3分程度かかる場合があります',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Image.file(
              _processedImage ?? widget.imageFile,
              key: ValueKey(_imageKey), // キーを使って強制再描画
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Image display error: $error');
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
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
                '魅力レベル',
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
                  onChanged: (_isProcessing || _isSaving)
                      ? null
                      : (value) {
                          setState(() {
                            _currentStrength = value;
                          });
                        },
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
          const SizedBox(height: 20),
          // AI処理実行ボタンを追加
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isProcessing || _isSaving) ? null : _processImage,
              icon: _isProcessing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isProcessing ? '処理中...' : 'AI加工を実行'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
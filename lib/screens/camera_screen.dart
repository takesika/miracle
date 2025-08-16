import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import 'image_editor_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Dispose camera when app goes to background
      CameraService.dispose();
      setState(() {
        _isInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed && !_isInitialized) {
      // Reinitialize when app comes back to foreground
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await CameraService.initialize();
      if (success) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      } else {
        final isSimulator = kDebugMode && !Platform.isAndroid && Platform.isIOS;
        setState(() {
          _error = isSimulator 
              ? 'シミュレーターではカメラが使用できません\n実機でテストしてください'
              : 'カメラの初期化に失敗しました';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'カメラエラー: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (!_isInitialized) return;

    setState(() => _isLoading = true);

    try {
      final File? imageFile = await CameraService.takePicture();
      if (imageFile != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ImageEditorScreen(imageFile: imageFile),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真の撮影に失敗しました')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('撮影エラー: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _switchCamera() async {
    if (!_isInitialized) return;

    setState(() => _isLoading = true);
    await CameraService.switchCamera();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('写真を撮る'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCameraPreview(),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || CameraService.controller == null) {
      return const Center(
        child: Text(
          'カメラを準備中...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return CameraPreview(CameraService.controller!);
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Switch Camera Button
          if (CameraService.hasBackCamera && CameraService.hasFrontCamera)
            IconButton(
              onPressed: _isLoading ? null : _switchCamera,
              icon: Icon(
                Icons.cameraswitch,
                color: _isLoading ? Colors.grey : Colors.white,
                size: 32,
              ),
            )
          else
            const SizedBox(width: 48),

          // Capture Button
          GestureDetector(
            onTap: _isLoading ? null : _takePicture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: _isLoading ? Colors.grey : Colors.transparent,
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.camera,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),

          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
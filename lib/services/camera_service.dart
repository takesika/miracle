import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;

  static Future<bool> initialize() async {
    try {
      // Check if running on simulator
      if (kDebugMode && !Platform.isAndroid && Platform.isIOS) {
        debugPrint('Running on iOS Simulator - Camera not available');
        return false;
      }

      // Dispose existing controller first
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      // Check camera permission
      final permission = await Permission.camera.status;
      debugPrint('Camera permission status: $permission');
      
      if (!permission.isGranted) {
        final result = await Permission.camera.request();
        debugPrint('Camera permission request result: $result');
        if (!result.isGranted) {
          debugPrint('Camera permission denied');
          return false;
        }
      }

      // Get available cameras
      _cameras = await availableCameras();
      debugPrint('Available cameras: ${_cameras?.length}');
      
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      // Initialize camera controller with back camera by default
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      debugPrint('Initializing camera controller...');
      await _controller!.initialize();
      debugPrint('Camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
      return false;
    }
  }

  static CameraController? get controller => _controller;
  static List<CameraDescription>? get cameras => _cameras;

  static Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2 || _controller == null) {
      return;
    }

    try {
      final currentCamera = _controller!.description;
      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection != currentCamera.lensDirection,
      );

      await _controller!.dispose();
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
    } catch (e) {
      debugPrint('Camera switch failed: $e');
    }
  }

  static Future<File?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      debugPrint('Picture capture failed: $e');
      return null;
    }
  }

  static Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  static bool get hasBackCamera => 
      _cameras?.any((camera) => camera.lensDirection == CameraLensDirection.back) ?? false;

  static bool get hasFrontCamera => 
      _cameras?.any((camera) => camera.lensDirection == CameraLensDirection.front) ?? false;

  static bool get isBackCameraActive => 
      _controller?.description.lensDirection == CameraLensDirection.back;
}
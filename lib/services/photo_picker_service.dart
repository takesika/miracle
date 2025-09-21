import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoPickerService {
  static final ImagePicker _picker = ImagePicker();
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  static Future<bool> _requestPhotoPermission() async {
    final permission = await Permission.photos.status;
    debugPrint('Photo permission status: $permission');
    
    if (permission.isGranted) {
      return true;
    }

    if (permission.isPermanentlyDenied) {
      debugPrint('Photo permission permanently denied');
      return false;
    }

    final result = await Permission.photos.request();
    debugPrint('Photo permission request result: $result');
    
    if (result.isPermanentlyDenied) {
      debugPrint('Photo permission permanently denied after request');
      return false;
    }
    
    return result.isGranted;
  }

  static Future<File?> pickImage() async {
    try {
      // Skip permission check - let system handle it
      debugPrint('Skipping permission check - system will handle');

      // Pick image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: null,
        maxHeight: null,
        imageQuality: null, // Keep original quality
      );

      if (pickedFile == null) {
        return null;
      }

      final File imageFile = File(pickedFile.path);

      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        debugPrint('File size too large: ${fileSize / (1024 * 1024)} MB');
        throw Exception('ファイルサイズが大きすぎます（最大10MB）');
      }

      // Verify file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('選択されたファイルが見つかりません');
      }

      return imageFile;
    } catch (e) {
      debugPrint('Photo picker error: $e');
      rethrow;
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  static Future<int?> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      debugPrint('Failed to get file size: $e');
      return null;
    }
  }

  static bool isSupportedFormat(String path) {
    final extension = path.toLowerCase();
    return extension.endsWith('.jpg') ||
           extension.endsWith('.jpeg') ||
           extension.endsWith('.heic') ||
           extension.endsWith('.heif') ||
           extension.endsWith('.png');
  }
}
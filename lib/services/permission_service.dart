import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    return false;
  }

  static Future<bool> requestPhotoPermission() async {
    final status = await Permission.photos.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    return false;
  }

  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> isPhotoPermissionGranted() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  static Future<bool> isCameraPermissionPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  static Future<bool> isPhotoPermissionPermanentlyDenied() async {
    final status = await Permission.photos.status;
    return status.isPermanentlyDenied;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static void showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('設定'),
            ),
          ],
        );
      },
    );
  }

  static void showCameraPermissionDialog(BuildContext context) {
    showPermissionDialog(
      context,
      'カメラ権限が必要です',
      '写真を撮影するためにカメラへのアクセスが必要です。設定でカメラを許可してください。',
      () => openAppSettings(),
    );
  }

  static void showPhotoPermissionDialog(BuildContext context) {
    showPermissionDialog(
      context,
      'フォトライブラリ権限が必要です',
      '写真を選択・保存するためにフォトライブラリへのアクセスが必要です。設定で写真を許可してください。',
      () => openAppSettings(),
    );
  }
}
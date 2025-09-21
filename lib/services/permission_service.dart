import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {

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


  static Future<bool> isPhotoPermissionGranted() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }


  static Future<bool> isPhotoPermissionPermanentlyDenied() async {
    final status = await Permission.photos.status;
    return status.isPermanentlyDenied;
  }

  static Future<bool> openSettings() async {
    return await openAppSettings();
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


  static void showPhotoPermissionDialog(BuildContext context) {
    showPermissionDialog(
      context,
      'フォトライブラリ権限が必要です',
      '写真を選択・保存するためにフォトライブラリへのアクセスが必要です。設定で写真を許可してください。',
      () => openSettings(),
    );
  }
}
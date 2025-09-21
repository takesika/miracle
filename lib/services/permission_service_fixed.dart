import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionServiceFixed {

  static Future<bool> requestPhotoPermission() async {
    final status = await Permission.photos.status;
    debugPrint('Photo permission status: $status');
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.photos.request();
      debugPrint('Photo permission request result: $result');
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      debugPrint('Photo permission permanently denied after request');
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
    // permission_handlerパッケージの正しいメソッドを使用
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text(
                '設定手順:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. 設定アプリを開く\n'
                '2. プライバシーとセキュリティ\n'
                '3. 写真\n'
                '4. アプリ名をタップ\n'
                '5. "すべての写真"を選択',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
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
              child: const Text('設定を開く'),
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
      '写真を選択・保存するためにフォトライブラリへのアクセスが必要です。',
      () => openSettings(),
    );
  }
}
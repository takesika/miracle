import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ErrorType {
  network,
  permission,
  fileSize,
  fileFormat,
  processing,
  general,
}

class ErrorHandler {
  static void handleError(
    BuildContext context,
    dynamic error,
    {ErrorType? type, bool showRetry = false, VoidCallback? onRetry}
  ) {
    final errorType = type ?? _determineErrorType(error);
    final message = _getErrorMessage(errorType, error);
    
    if (showRetry && onRetry != null) {
      _showErrorDialog(context, message, onRetry);
    } else {
      _showErrorSnackBar(context, message);
    }
    
    // Log error for debugging
    debugPrint('Error [${errorType.name}]: $error');
  }

  static ErrorType _determineErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return ErrorType.network;
    }
    
    if (errorString.contains('permission')) {
      return ErrorType.permission;
    }
    
    if (errorString.contains('file size') || 
        errorString.contains('ファイルサイズ')) {
      return ErrorType.fileSize;
    }
    
    if (errorString.contains('format') || 
        errorString.contains('decode')) {
      return ErrorType.fileFormat;
    }
    
    if (errorString.contains('processing') ||
        errorString.contains('enhancement')) {
      return ErrorType.processing;
    }
    
    return ErrorType.general;
  }

  static String _getErrorMessage(ErrorType type, dynamic error) {
    switch (type) {
      case ErrorType.network:
        return '通信に失敗しました。ネットワーク接続を確認してください。';
      case ErrorType.permission:
        return '権限が必要です。設定で許可してください。';
      case ErrorType.fileSize:
        return 'ファイルサイズが大きすぎます（最大10MB）。';
      case ErrorType.fileFormat:
        return 'サポートされていないファイル形式です。';
      case ErrorType.processing:
        return '画像処理に失敗しました。再試行してください。';
      case ErrorType.general:
        return 'エラーが発生しました。再試行してください。';
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void _showErrorDialog(
    BuildContext context, 
    String message, 
    VoidCallback onRetry
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('エラー'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('再試行'),
            ),
          ],
        );
      },
    );
  }

  static void showToast(String message, {bool isError = true}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showNetworkError(BuildContext context, VoidCallback onRetry) {
    handleError(
      context,
      '通信エラーが発生しました',
      type: ErrorType.network,
      showRetry: true,
      onRetry: onRetry,
    );
  }

  static void showPermissionError(BuildContext context, String permissionType) {
    final message = '$permissionType権限が必要です。設定で許可してください。';
    _showErrorSnackBar(context, message);
  }

  static void showFileSizeError(BuildContext context) {
    handleError(
      context,
      'ファイルサイズエラー',
      type: ErrorType.fileSize,
    );
  }

  static void showProcessingError(BuildContext context, VoidCallback onRetry) {
    handleError(
      context,
      '画像処理エラー',
      type: ErrorType.processing,
      showRetry: true,
      onRetry: onRetry,
    );
  }

  static bool isNetworkError(dynamic error) {
    return _determineErrorType(error) == ErrorType.network;
  }

  static bool isPermissionError(dynamic error) {
    return _determineErrorType(error) == ErrorType.permission;
  }

  static bool isRetriableError(dynamic error) {
    final type = _determineErrorType(error);
    return type == ErrorType.network || type == ErrorType.processing;
  }
}
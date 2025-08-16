import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class PhotoSaveService {
  static const String albumName = '奇跡の一枚';
  static AssetPathEntity? _miracleAlbum;

  static Future<bool> requestPermission() async {
    final permission = await Permission.photos.status;
    debugPrint('Save permission status: $permission');
    
    if (permission.isGranted) {
      return true;
    }

    if (permission.isPermanentlyDenied) {
      debugPrint('Save permission permanently denied - opening settings');
      await openAppSettings();
      return false;
    }

    final result = await Permission.photos.request();
    debugPrint('Save permission request result: $result');
    return result.isGranted;
  }

  static Future<bool> saveToGallery(File imageFile) async {
    try {
      // Read image bytes first
      final imageBytes = await imageFile.readAsBytes();
      
      // Try to save using alternative method for simulator
      if (kDebugMode) {
        debugPrint('Trying to save to simulator photo library...');
        try {
          final result = await ImageGallerySaver.saveImage(
            imageBytes,
            name: 'miracle_shot_${DateTime.now().millisecondsSinceEpoch}',
            isReturnImagePathOfIOS: true,
          );
          
          debugPrint('Save result: $result');
          if (result != null) {
            _showToast('写真を保存しました');
            return true;
          }
        } catch (e) {
          debugPrint('Alternative save method failed: $e');
        }
      }
      
      // Request photo library permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('Photo library permission denied');
        return false;
      }

      // Use the imageBytes variable already defined above

      // Ensure album exists
      await _ensureAlbumExists();

      // Save to gallery
      final entity = await PhotoManager.editor.saveImage(
        imageBytes,
        title: 'miracle_shot_${DateTime.now().millisecondsSinceEpoch}',
        filename: 'miracle_shot_${DateTime.now().millisecondsSinceEpoch}.jpg',
        relativePath: albumName,
      );

      if (entity != null) {
        // Show success toast
        _showToast('写真を保存しました');
        return true;
      } else {
        debugPrint('Failed to save image to gallery');
        return false;
      }
    } catch (e) {
      debugPrint('Photo save error: $e');
      return false;
    }
  }

  static Future<bool> saveImageBytes(Uint8List imageBytes) async {
    try {
      // Try alternative save method first for all platforms
      debugPrint('Trying ImageGallerySaver...');
      try {
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name: 'miracle_shot_${DateTime.now().millisecondsSinceEpoch}',
          isReturnImagePathOfIOS: true,
        );
        
        debugPrint('ImageGallerySaver result: $result');
        if (result != null && (result['isSuccess'] == true || result['filePath'] != null)) {
          _showToast('写真を保存しました');
          return true;
        }
      } catch (e) {
        debugPrint('ImageGallerySaver failed: $e');
      }

      // Request photo library permission (skip check on simulator)
      try {
        final hasPermission = await requestPermission();
        if (!hasPermission) {
          debugPrint('Photo library permission denied - trying anyway on simulator');
          // Continue anyway for simulator testing
        }
      } catch (e) {
        debugPrint('Permission check failed, continuing anyway: $e');
      }

      // Ensure album exists
      await _ensureAlbumExists();

      // Save to gallery
      final entity = await PhotoManager.editor.saveImage(
        imageBytes,
        title: 'miracle_shot_${DateTime.now().millisecondsSinceEpoch}',
        filename: 'miracle_shot_${DateTime.now().millisecondsSinceEpoch}.jpg',
        relativePath: albumName,
      );

      if (entity != null) {
        // Show success toast
        _showToast('写真を保存しました');
        return true;
      } else {
        debugPrint('Failed to save image bytes to gallery');
        return false;
      }
    } catch (e) {
      debugPrint('Photo save error: $e');
      return false;
    }
  }

  static Future<void> _ensureAlbumExists() async {
    try {
      if (_miracleAlbum != null) {
        return;
      }

      // Get all albums
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
      );

      // Check if our album already exists
      for (final album in albums) {
        if (album.name == albumName) {
          _miracleAlbum = album;
          return;
        }
      }

      // Album doesn't exist, but PhotoManager.editor.saveImage with relativePath
      // will create it automatically, so we don't need to create it manually
      debugPrint('Album "$albumName" will be created automatically');
    } catch (e) {
      debugPrint('Album check error: $e');
      // Continue anyway, saveImage will handle album creation
    }
  }

  static void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static Future<List<AssetEntity>> getSavedImages() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return [];
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: false,
      );

      for (final album in albums) {
        if (album.name == albumName) {
          final assets = await album.getAssetListRange(
            start: 0,
            end: 100, // Get last 100 images
          );
          return assets;
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get saved images error: $e');
      return [];
    }
  }

  static Future<bool> deleteImage(AssetEntity asset) async {
    try {
      final result = await PhotoManager.editor.deleteWithIds([asset.id]);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Delete image error: $e');
      return false;
    }
  }

  static Future<File?> getImageFile(AssetEntity asset) async {
    try {
      return await asset.file;
    } catch (e) {
      debugPrint('Get image file error: $e');
      return null;
    }
  }

  static Future<Uint8List?> getImageBytes(AssetEntity asset) async {
    try {
      return await asset.originBytes;
    } catch (e) {
      debugPrint('Get image bytes error: $e');
      return null;
    }
  }

  static Future<bool> isAlbumEmpty() async {
    try {
      final images = await getSavedImages();
      return images.isEmpty;
    } catch (e) {
      debugPrint('Check album empty error: $e');
      return true;
    }
  }

  static Future<int> getImageCount() async {
    try {
      final images = await getSavedImages();
      return images.length;
    } catch (e) {
      debugPrint('Get image count error: $e');
      return 0;
    }
  }
}
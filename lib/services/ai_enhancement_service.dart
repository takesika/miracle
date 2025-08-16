import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'exif_service.dart';

class AIEnhancementService {
  static const String _baseUrl = 'https://api.example.com'; // TODO: Replace with actual API URL
  static const String _apiKey = 'YOUR_API_KEY'; // TODO: Replace with actual API key
  static const Duration _timeout = Duration(seconds: 10);
  
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'multipart/form-data',
      },
    ),
  );

  static Future<File?> enhanceImage(File imageFile, int strength) async {
    try {
      // Validate strength parameter
      if (strength < 1 || strength > 10) {
        throw ArgumentError('Strength must be between 1 and 10');
      }

      // For strength 1, just remove EXIF and return
      if (strength == 1) {
        return await _processStrengthOne(imageFile);
      }

      // Check file size and compress if needed
      final processedFile = await _preprocessImage(imageFile);
      
      // Call AI enhancement API (using mock for development)
      final enhancedBytes = await _mockEnhanceAPI(processedFile, strength);
      
      if (enhancedBytes == null) {
        return null;
      }

      // Remove EXIF from the result
      final cleanBytes = await EXIFService.removeEXIF(enhancedBytes);
      
      // Save to temporary file
      final tempFile = await _saveTempFile(cleanBytes, 'enhanced.jpg');
      
      return tempFile;
    } catch (e) {
      debugPrint('AI Enhancement error: $e');
      rethrow;
    }
  }

  static Future<File> _processStrengthOne(File imageFile) async {
    try {
      // Read original image
      final imageBytes = await imageFile.readAsBytes();
      
      // Remove EXIF only
      final cleanBytes = await EXIFService.removeEXIF(imageBytes);
      
      // Save to temporary file
      return await _saveTempFile(cleanBytes, 'original_clean.jpg');
    } catch (e) {
      debugPrint('Strength 1 processing error: $e');
      rethrow;
    }
  }

  static Future<File> _preprocessImage(File imageFile) async {
    final fileSize = await imageFile.length();
    const maxSize = 10 * 1024 * 1024; // 10MB
    
    if (fileSize <= maxSize) {
      return imageFile;
    }

    // TODO: Implement image compression if needed
    // For now, throw an error for oversized files
    throw Exception('ファイルサイズが大きすぎます（最大10MB）');
  }

  static Future<Uint8List?> _callEnhancementAPI(File imageFile, int strength) async {
    try {
      // Prepare multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
        'strength': strength,
      });

      // Make API call
      final response = await _dio.post(
        '/v1/enhance',
        data: formData,
      );

      if (response.statusCode == 200) {
        // API returns JPEG bytes
        return Uint8List.fromList(response.data);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('通信がタイムアウトしました。再試行してください。');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('ネットワークに接続できません。');
      } else {
        throw Exception('API通信エラー: ${e.message}');
      }
    } catch (e) {
      debugPrint('API call error: $e');
      rethrow;
    }
  }

  static Future<File> _saveTempFile(Uint8List bytes, String filename) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, filename));
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      debugPrint('Temp file save error: $e');
      rethrow;
    }
  }

  // Mock API call for development
  static Future<Uint8List?> _mockEnhanceAPI(File imageFile, int strength) async {
    try {
      // Simulate network delay based on strength
      await Future.delayed(Duration(milliseconds: 1000 + (strength * 200)));
      
      // Read original image
      final imageBytes = await imageFile.readAsBytes();
      
      // Return the bytes (EXIF removal will be handled later)
      return imageBytes;
    } catch (e) {
      debugPrint('Mock API error: $e');
      return null;
    }
  }

  // Mock implementation for development/testing
  static Future<File?> enhanceImageMock(File imageFile, int strength) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Read original image
      final imageBytes = await imageFile.readAsBytes();
      
      // Remove EXIF (this is the real functionality we can implement)
      final cleanBytes = await EXIFService.removeEXIF(imageBytes);
      
      // Save to temporary file with mock enhancement
      final tempFile = await _saveTempFile(cleanBytes, 'mock_enhanced.jpg');
      
      return tempFile;
    } catch (e) {
      debugPrint('Mock enhancement error: $e');
      return null;
    }
  }

  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      ).timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection check failed: $e');
      return false;
    }
  }
}
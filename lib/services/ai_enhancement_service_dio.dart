import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'exif_service.dart';

class AIEnhancementServiceDio {
  static String? _apiKey;
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.openai.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));
  
  static void initialize(String apiKey) {
    _apiKey = apiKey;
    _dio.options.headers['Authorization'] = 'Bearer $apiKey';
  }

  static Future<File?> enhanceImage(File imageFile, int strength) async {
    try {
      // Validate strength parameter
      if (strength < 1 || strength > 10) {
        throw ArgumentError('Strength must be between 1 and 10');
      }

      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('OpenAI APIキーが設定されていません');
      }

      // For strength 1, just remove EXIF and return
      if (strength == 1) {
        return await _processStrengthOne(imageFile);
      }

      // Check file size and compress if needed
      final processedFile = await _preprocessImage(imageFile);
      
      // Call OpenAI API for enhancement using gpt-image-1 model
      final enhancedBytes = await _enhanceWithOpenAI(processedFile, strength);
      
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
    const maxSize = 4 * 1024 * 1024; // 4MB (OpenAI limit)
    
    if (fileSize <= maxSize) {
      return imageFile;
    }

    // Compress image if too large
    return await _compressImage(imageFile, maxSize);
  }
  
  static Future<File> _compressImage(File imageFile, int maxSize) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('画像のデコードに失敗しました');
      }
      
      // Reduce quality gradually until under size limit
      int quality = 85;
      Uint8List compressedBytes;
      
      do {
        compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: quality));
        quality -= 10;
      } while (compressedBytes.length > maxSize && quality > 10);
      
      if (compressedBytes.length > maxSize) {
        throw Exception('画像サイズを十分に縮小できませんでした');
      }
      
      // Save compressed image to temp file
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(path.join(tempDir.path, 'compressed_${path.basename(imageFile.path)}'));
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      debugPrint('Image compression error: $e');
      rethrow;
    }
  }

  static Future<Uint8List?> _enhanceWithOpenAI(File imageFile, int strength) async {
    try {
      // Generate enhancement prompt based on strength
      final prompt = _generatePrompt(strength);
      
      // Prepare form data with gpt-image-1 model
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
        'prompt': prompt,
        'model': 'gpt-image-1',
        'response_format': 'b64_json',
        'size': '1024x1024',
      });
      
      // Make API call
      final response = await _dio.post(
        '/v1/images/edits',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        final result = response.data;
        if (result['data'] != null && (result['data'] as List).isNotEmpty) {
          final base64Data = result['data'][0]['b64_json'];
          if (base64Data != null) {
            return base64Decode(base64Data);
          }
        }
      }
      
      throw Exception('OpenAI APIからの応答が空でした');
    } on DioException catch (e) {
      debugPrint('OpenAI API error: ${e.message}');
      if (e.response != null) {
        debugPrint('Error response: ${e.response?.data}');
        if (e.response?.statusCode == 401) {
          throw Exception('APIキーが無効です');
        } else if (e.response?.statusCode == 400) {
          // Check if it's a model access error
          final errorData = e.response?.data;
          if (errorData != null && errorData['error'] != null) {
            final errorMessage = errorData['error']['message'] ?? '';
            if (errorMessage.contains('does not have access to model')) {
              // Fallback to dall-e-2
              debugPrint('gpt-image-1 not available, falling back to dall-e-2');
              return await _enhanceWithDallE2(imageFile, strength);
            }
          }
        }
      }
      throw Exception('AI処理エラー: ${e.message}');
    } catch (e) {
      debugPrint('Enhancement error: $e');
      throw Exception('画像加工に失敗しました: $e');
    }
  }
  
  static Future<Uint8List?> _enhanceWithDallE2(File imageFile, int strength) async {
    try {
      final prompt = _generatePrompt(strength);
      
      // Prepare form data without model parameter (defaults to dall-e-2)
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
        'prompt': prompt,
        'response_format': 'b64_json',
        'size': '1024x1024',
      });
      
      final response = await _dio.post(
        '/v1/images/edits',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        final result = response.data;
        if (result['data'] != null && (result['data'] as List).isNotEmpty) {
          final base64Data = result['data'][0]['b64_json'];
          if (base64Data != null) {
            return base64Decode(base64Data);
          }
        }
      }
      
      throw Exception('OpenAI APIからの応答が空でした');
    } catch (e) {
      debugPrint('DALL-E 2 enhancement error: $e');
      rethrow;
    }
  }
  
  static String _generatePrompt(int strength) {
    // Japanese prompt style inspired by the Python script
    final basePrompt = "この写真を編集してください。魅力レベルを1~10で指定します。5が標準の魅力レベルで、5より低い値は魅力を下げ、5より高い値は魅力を上げます。1は最も魅力が低く、10は限界まで魅力的にしますが、あくまで同一人物の域を出ないレベルでお願いします。";
    final userPrompt = "魅力レベル: $strengthでお願いします。";
    
    // Combine prompts
    return "$basePrompt $userPrompt";
  }
  
  static String _generatePromptEnglish(int strength) {
    // Keep English prompts as fallback
    switch (strength) {
      case 2:
      case 3:
        return 'Enhance this photo with subtle improvements. Slightly increase contrast and saturation while keeping it natural.';
      case 4:
      case 5:
        return 'Make this photo look cooler and more attractive. Enhance colors, improve lighting, and add subtle stylistic improvements.';
      case 6:
      case 7:
        return 'Transform this photo to look significantly cooler and more stylish. Enhance colors, improve contrast, add dramatic lighting effects.';
      case 8:
      case 9:
        return 'Make this photo look very cool and stylish with dramatic enhancements. Add strong color grading, dramatic lighting, and artistic effects.';
      case 10:
        return 'Transform this photo into an extremely cool and stylish image with maximum enhancement. Apply dramatic color grading, cinematic lighting, and artistic effects to make it amazing.';
      default:
        return 'Enhance this photo to make it look cooler and more attractive.';
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

  static Future<bool> checkConnection() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return false;
    }
    
    try {
      // Try a simple API call to check connectivity
      final response = await _dio.get('/v1/models');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('OpenAI connection check failed: $e');
      return false;
    }
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'exif_service.dart';

class AIEnhancementService {
  static String? _apiKey;
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.openai.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 3), // 3分に延長
    sendTimeout: const Duration(minutes: 2), // 2分に延長
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

      // Check file size and compress if needed
      final processedFile = await _preprocessImage(imageFile);
      
      // Call OpenAI API for enhancement
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
      debugPrint('使用する魅力レベル: $strength');
      debugPrint('生成されたプロンプト: $prompt');
      
      // Prepare form data with gpt-image-1 model
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
        'prompt': prompt,
        'model': 'gpt-image-1',
        'size': '1024x1024',
        'n': 1,
      });
      
      // Make API call
      final response = await _dio.post(
        '/v1/images/edits',
        data: formData,
      );
      
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final result = response.data;
        debugPrint('Response data type: ${result.runtimeType}');
        debugPrint('Response data: $result');
        
        if (result is Map && result['data'] != null) {
          final dataList = result['data'] as List;
          debugPrint('Data list length: ${dataList.length}');
          
          if (dataList.isNotEmpty) {
            final firstData = dataList[0];
            debugPrint('First data item: $firstData');
            
            // Try both 'url' and 'b64_json' formats
            if (firstData['url'] != null) {
              final imageUrl = firstData['url'];
              debugPrint('Image URL: $imageUrl');
              
              // Download image from URL
              final imageResponse = await _dio.get(
                imageUrl,
                options: Options(responseType: ResponseType.bytes),
              );
              return Uint8List.fromList(imageResponse.data);
            } else if (firstData['b64_json'] != null) {
              final base64Data = firstData['b64_json'];
              debugPrint('Base64 data available');
              return base64Decode(base64Data);
            }
          }
        }
      }
      
      throw Exception('OpenAI APIからの応答が空または無効でした: ${response.data}');
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
        'size': '1024x1024',
        'n': 1,
      });
      
      final response = await _dio.post(
        '/v1/images/edits',
        data: formData,
      );
      
      debugPrint('DALL-E 2 Response Status: ${response.statusCode}');
      debugPrint('DALL-E 2 Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final result = response.data;
        
        if (result is Map && result['data'] != null) {
          final dataList = result['data'] as List;
          
          if (dataList.isNotEmpty) {
            final firstData = dataList[0];
            
            // Try both 'url' and 'b64_json' formats
            if (firstData['url'] != null) {
              final imageUrl = firstData['url'];
              
              // Download image from URL
              final imageResponse = await _dio.get(
                imageUrl,
                options: Options(responseType: ResponseType.bytes),
              );
              return Uint8List.fromList(imageResponse.data);
            } else if (firstData['b64_json'] != null) {
              final base64Data = firstData['b64_json'];
              return base64Decode(base64Data);
            }
          }
        }
      }
      
      throw Exception('DALL-E 2 APIからの応答が空または無効でした: ${response.data}');
    } catch (e) {
      debugPrint('DALL-E 2 enhancement error: $e');
      rethrow;
    }
  }
  
  static String _generatePrompt(int strength) {
    // 具体的で明確な画像編集指示
    switch (strength) {
      case 1:
        return "この写真の人物の顔の特徴や表情は変更せず、画質のみを向上させてください。ノイズを軽減し、色調を少し整える程度の最小限の調整をお願いします。";
      case 2:
        return "この人の顔立ちや表情を変えずに、照明と色調を微調整してください。明るさとコントラストを自然に改善し、肌の色味を健康的に見せてください。";
      case 3:
        return "顔の形や特徴は保持したまま、肌の色味を自然に整え、目を少し明るく見せてください。骨格や輪郭は一切変更しないでください。";
      case 4:
        return "骨格や顔の輪郭は維持しながら、肌を滑らかにし、目の明度を上げて表情を生き生きと見せてください。顔の基本構造は変更しないでください。";
      case 5:
        return "本人の特徴的な顔立ちは保持したまま、肌の質感を改善し、目を輝かせ、全体的に健康的で生き生きとした印象にしてください。";
      case 6:
        return "顔の基本的な形状は保ちながら、肌を美しくし、目を印象的にし、全体的により良い印象になるよう調整してください。";
      case 7:
        return "本人らしい特徴を残しつつ、肌を滑らかにし、目を大きく明るくし、全体的により洗練された印象に仕上げてください。";
      case 8:
        return "本人の雰囲気と個性は保ちながら、肌を完璧に美しくし、目を大きく輝かせ、プロの写真のような仕上がりにしてください。";
      case 9:
        return "その人らしさを失わずに、肌・目・全体の印象を最高レベルで改善し、非常に印象的で美しい姿に仕上げてください。";
      case 10:
        return "本人の本質的な特徴を保持しながら、肌・目・表情のすべてを最高レベルで美しくし、圧倒的に美しい姿に仕上げてください。";
      default:
        return "この人の個性を保ちながら美しく仕上げてください。";
    }
  }

  static Future<File> _saveTempFile(Uint8List bytes, String filename) async {
    try {
      Directory tempDir;
      
      try {
        tempDir = await getTemporaryDirectory();
      } catch (e) {
        debugPrint('Failed to get temporary directory: $e');
        // フォールバック：アプリのDocumentsディレクトリを使用
        final appDir = await getApplicationDocumentsDirectory();
        tempDir = Directory(path.join(appDir.path, 'temp'));
      }
      
      // ディレクトリの存在確認と作成
      if (!await tempDir.exists()) {
        debugPrint('Creating temp directory: ${tempDir.path}');
        await tempDir.create(recursive: true);
      }
      
      // 古いキャッシュファイルをクリア（1時間以上古いファイル）
      await _cleanOldTempFiles(tempDir);
      
      // ユニークなファイル名を生成してキャッシュ問題を回避
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFilename = '${timestamp}_$filename';
      final tempFile = File(path.join(tempDir.path, uniqueFilename));
      
      // ファイル書き込み前に親ディレクトリの存在確認
      final parentDir = tempFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      
      await tempFile.writeAsBytes(bytes);
      debugPrint('Temp file saved: ${tempFile.path} (${bytes.length} bytes)');
      return tempFile;
    } catch (e) {
      debugPrint('Temp file save error: $e');
      rethrow;
    }
  }
  
  static Future<void> _cleanOldTempFiles(Directory tempDir) async {
    try {
      // ディレクトリが存在しない場合はスキップ
      if (!await tempDir.exists()) {
        debugPrint('Temp directory does not exist, skipping cleanup');
        return;
      }
      
      final now = DateTime.now();
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('enhanced')) {
          try {
            final stat = await file.stat();
            final age = now.difference(stat.modified);
            
            // 1時間以上古いファイルを削除
            if (age.inHours >= 1) {
              await file.delete();
              debugPrint('Deleted old temp file: ${file.path}');
            }
          } catch (e) {
            debugPrint('Error processing file ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning temp files: $e');
      // クリーニングエラーは致命的ではないので、処理を続行
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
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class EXIFService {
  static Future<Uint8List> removeEXIF(Uint8List imageBytes) async {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Re-encode as JPEG with quality 95, which removes all EXIF data
      final cleanBytes = img.encodeJpg(image, quality: 95);
      
      return Uint8List.fromList(cleanBytes);
    } catch (e) {
      debugPrint('EXIF removal error: $e');
      rethrow;
    }
  }

  static Future<File> removeEXIFFromFile(File imageFile) async {
    try {
      // Read the original file
      final originalBytes = await imageFile.readAsBytes();
      
      // Remove EXIF
      final cleanBytes = await removeEXIF(originalBytes);
      
      // Write back to the same file
      await imageFile.writeAsBytes(cleanBytes);
      
      return imageFile;
    } catch (e) {
      debugPrint('EXIF removal from file error: $e');
      rethrow;
    }
  }

  static Future<bool> hasEXIF(Uint8List imageBytes) async {
    try {
      // Check for EXIF marker (0xFFE1) in JPEG
      if (imageBytes.length < 4) return false;
      
      // JPEG files start with 0xFFD8
      if (imageBytes[0] != 0xFF || imageBytes[1] != 0xD8) {
        return false;
      }
      
      // Look for EXIF marker
      for (int i = 2; i < imageBytes.length - 1; i++) {
        if (imageBytes[i] == 0xFF && imageBytes[i + 1] == 0xE1) {
          // Check if this is an EXIF segment
          if (i + 10 < imageBytes.length) {
            final exifHeader = String.fromCharCodes(imageBytes.sublist(i + 4, i + 8));
            if (exifHeader == 'Exif') {
              return true;
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('EXIF detection error: $e');
      return false;
    }
  }

  static Future<bool> verifyEXIFRemoval(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      return !(await hasEXIF(imageBytes));
    } catch (e) {
      debugPrint('EXIF verification error: $e');
      return false;
    }
  }

  // Advanced EXIF removal using more thorough approach
  static Future<Uint8List> removeEXIFAdvanced(Uint8List imageBytes) async {
    try {
      if (imageBytes.length < 4) {
        throw Exception('Invalid image data');
      }

      // For JPEG files
      if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
        return _removeJPEGEXIF(imageBytes);
      }
      
      // For other formats, use the standard method
      return await removeEXIF(imageBytes);
    } catch (e) {
      debugPrint('Advanced EXIF removal error: $e');
      rethrow;
    }
  }

  static Uint8List _removeJPEGEXIF(Uint8List jpegBytes) {
    final List<int> cleanBytes = [];
    
    // Add JPEG header
    cleanBytes.addAll([0xFF, 0xD8]);
    
    int i = 2;
    while (i < jpegBytes.length - 1) {
      if (jpegBytes[i] == 0xFF) {
        final marker = jpegBytes[i + 1];
        
        // Skip EXIF and other metadata segments
        if (_isMetadataMarker(marker)) {
          // Get segment length
          if (i + 3 < jpegBytes.length) {
            final length = (jpegBytes[i + 2] << 8) | jpegBytes[i + 3];
            i += length + 2; // Skip entire segment
          } else {
            break;
          }
        } else {
          // Keep other segments
          cleanBytes.add(jpegBytes[i]);
          i++;
        }
      } else {
        cleanBytes.add(jpegBytes[i]);
        i++;
      }
    }
    
    return Uint8List.fromList(cleanBytes);
  }

  static bool _isMetadataMarker(int marker) {
    return marker == 0xE0 || // APP0
           marker == 0xE1 || // APP1 (EXIF)
           marker == 0xE2 || // APP2
           marker == 0xE3 || // APP3
           marker == 0xE4 || // APP4
           marker == 0xE5 || // APP5
           marker == 0xE6 || // APP6
           marker == 0xE7 || // APP7
           marker == 0xE8 || // APP8
           marker == 0xE9 || // APP9
           marker == 0xEA || // APP10
           marker == 0xEB || // APP11
           marker == 0xEC || // APP12
           marker == 0xED || // APP13
           marker == 0xEE || // APP14
           marker == 0xEF;   // APP15
  }

  static Future<Map<String, dynamic>> getImageInfo(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      return {
        'width': image.width,
        'height': image.height,
        'format': image.format.name,
        'hasEXIF': await hasEXIF(imageBytes),
        'fileSizeBytes': imageBytes.length,
        'fileSizeMB': (imageBytes.length / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('Get image info error: $e');
      rethrow;
    }
  }
}
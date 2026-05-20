// file_upload_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Dedicated service for offloading large files to free persistent file hosting (Catbox).
/// This prevents heavy base64 strings from bloating the primary database and crashing clients. - SV
class FileUploadService {
  static const String _catboxApiUrl = 'https://catbox.moe/user/api.php';

  /// Uploads a file to Catbox.moe.
  /// Supports path-based streaming for efficiency or raw bytes.
  static Future<String?> uploadFile({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_catboxApiUrl));
      request.fields['reqtype'] = 'fileupload';

      if (filePath != null && filePath.isNotEmpty) {
        // Stream the file directly from disk to save device RAM and prevent OutOfMemory crash - SV
        request.files.add(await http.MultipartFile.fromPath(
          'fileToUpload',
          filePath,
          filename: fileName,
        ));
      } else if (fileBytes != null) {
        // Fallback for in-memory bytes (e.g. camera capture or web platform) - SV
        request.files.add(http.MultipartFile.fromBytes(
          'fileToUpload',
          fileBytes,
          filename: fileName,
        ));
      } else {
        return null;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final url = response.body.trim();
        // Catbox returns the direct URL to the uploaded file as plain text - SV
        if (url.startsWith('http')) {
          return url;
        }
      }
      return null;
    } catch (e) {
      print('FileUploadService: Upload error: $e');
      return null;
    }
  }
}

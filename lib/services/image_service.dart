import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ImageService {
  // Download image for viewing/processing
  Future<void> downloadImage(
    String imageUrl, {
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        onSuccess();
      } else {
        onError('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      onError('Error downloading image: $e');
    }
  }

  // Verify image data is valid
  bool isValidImageData(Uint8List? data) {
    if (data == null || data.isEmpty) {
      return false;
    }

    // Check for common image format headers
    if (data.length > 4) {
      // Check for JPEG header (starts with FF D8 FF)
      if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
        return true;
      }

      // Check for PNG header (starts with 89 50 4E 47)
      if (data[0] == 0x89 &&
          data[1] == 0x50 &&
          data[2] == 0x4E &&
          data[3] == 0x47) {
        return true;
      }
    }
    return false;
  }
}


import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryUploadService {
  CloudinaryUploadService._();

  static const String _cloudName = 'mdpqtvkq';
  static const String _uploadPreset = 'pawly_animal_uploads';

  static const int _maxFileBytes = 5 * 1024 * 1024;

  static Future<String> uploadAnimalImage(File imageFile) async {
    // Make sure the selected image exists.
    if (!await imageFile.exists()) {
      throw Exception('Selected image was not found.');
    }

    // Limit photo size to 5 MB.
    final fileSize = await imageFile.length();

    if (fileSize > _maxFileBytes) {
      throw Exception('Image must be smaller than 5 MB.');
    }

    // Check supported file extensions.
    final extension = imageFile.path.split('.').last.toLowerCase();

    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw Exception('Please select a JPG, PNG or WEBP image.');
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = _uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );

      final response = await http.Response.fromStream(streamedResponse);

      final body = jsonDecode(response.body);

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          'Image upload failed: ${body is Map ? body['error'] : response.statusCode}',
        );
      }

      if (body is! Map || body['secure_url'] is! String) {
        throw Exception('Cloudinary did not return a valid image URL.');
      }

      return body['secure_url'] as String;
    } catch (error) {
      throw Exception('Unable to upload animal image: $error');
    }
  }
}

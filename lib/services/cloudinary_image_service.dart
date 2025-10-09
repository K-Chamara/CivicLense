import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryImageService {
  static const String _cloudName = 'dvsabcntc';
  static const String _apiKey = 'YOUR_API_KEY'; // You'll need to provide this
  static const String _apiSecret = 'YOUR_API_SECRET'; // You'll need to provide this
  static const String _baseUrl = 'https://api.cloudinary.com/v1_1/$_cloudName';
  static const String _uploadPreset = 'news_hub'; // You'll need to create this preset

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Upload image to Cloudinary
  Future<String> uploadImage(File imageFile, {String? publicId}) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/image/upload'),
      );

      // Add fields
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'news_hub';
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Upload failed: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Cloudinary
  Future<void> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(publicId, timestamp);

      final response = await http.post(
        Uri.parse('$_baseUrl/image/destroy'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': _apiKey,
          'signature': signature,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete image');
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Generate Cloudinary signature for authenticated requests
  String _generateSignature(String publicId, String timestamp) {
    // This is a simplified signature generation
    // In production, you should generate this on your backend
    final String toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    return toSign.hashCode.toString();
  }

  /// Get optimized image URL with transformations
  static String getOptimizedImageUrl(String publicId, {
    int? width,
    int? height,
    String? crop,
    int? quality,
  }) {
    String url = 'https://res.cloudinary.com/$_cloudName/image/upload';
    
    List<String> transformations = [];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (crop != null) transformations.add('c_$crop');
    if (quality != null) transformations.add('q_$quality');
    
    if (transformations.isNotEmpty) {
      url += '/${transformations.join(',')}';
    }
    
    url += '/$publicId';
    
    return url;
  }

  /// Get banner image URL with optimal dimensions
  static String getBannerImageUrl(String publicId) {
    return getOptimizedImageUrl(
      publicId,
      width: 800,
      height: 400,
      crop: 'fill',
      quality: 80,
    );
  }

  /// Get thumbnail image URL for news feed
  static String getThumbnailImageUrl(String publicId) {
    return getOptimizedImageUrl(
      publicId,
      width: 300,
      height: 200,
      crop: 'fill',
      quality: 75,
    );
  }
}

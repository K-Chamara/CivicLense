import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class CloudinaryService {
  // Replace these with your actual Cloudinary credentials
  static const String _cloudName = "dcwsjskej"; // Your cloud name from Cloudinary dashboard
  static const String _uploadPreset = "public_upload"; // Your unsigned upload preset name
  
  /// Upload a file to Cloudinary and return the secure URL
  static Future<String?> uploadFile(File file) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/auto/upload");
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath(
          'file', 
          file.path, 
          filename: path.basename(file.path)
        ));
      
      print('📤 Uploading file to Cloudinary: ${path.basename(file.path)}');
      
      // Send request
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody.body);
        final secureUrl = data["secure_url"];
        print('✅ File uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        print('❌ Cloudinary upload failed: ${response.statusCode}');
        print('Response body: ${responseBody.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading to Cloudinary: $e');
      return null;
    }
  }
  
  /// Upload multiple files to Cloudinary
  static Future<List<String>> uploadFiles(List<File> files) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < files.length; i++) {
      print('📤 Uploading file ${i + 1}/${files.length}');
      final url = await uploadFile(files[i]);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }
  
  /// Get file extension for content type
  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}

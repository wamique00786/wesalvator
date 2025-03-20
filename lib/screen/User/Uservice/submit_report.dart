import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wesalvator/services/compressImage.dart';

class ApiService {
  static Future<http.Response> submitReport({
    required String token,
    required String description,
    required String priority,
    required double latitude,
    required double longitude,
    required List<XFile> images,
  }) async {
    final baseurl = await FlutterSecureStorage().read(key: "BASE_URL");
    final uri = Uri.parse('$baseurl/user_report/');
    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Token $token'
          ..headers['Accept'] = 'application/json'
          ..fields['description'] = description
          ..fields['priority'] = priority
          ..fields['latitude'] = latitude.toString()
          ..fields['longitude'] = longitude.toString();

    for (final image in images) {
      final compressed = await compressImage(File(image.path));
      final mimeType = lookupMimeType(compressed.path) ?? 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          compressed.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    final response = await request.send();
    return http.Response.fromStream(response);
  }
}

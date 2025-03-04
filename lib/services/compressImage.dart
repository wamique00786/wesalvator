import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

Future<File> compressImage(File file) async {
  final Uint8List imageBytes = await file.readAsBytes();
  img.Image? image = img.decodeImage(imageBytes);

  if (image == null) return file;

  // Resize image to reduce size (optional)
  final img.Image resized = img.copyResize(image, width: 800);

  // Compress image and save
  final Directory tempDir = await getTemporaryDirectory();
  final String tempPath =
      '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final File compressedFile = File(tempPath)
    ..writeAsBytesSync(img.encodeJpg(resized, quality: 80));

  return compressedFile;
}

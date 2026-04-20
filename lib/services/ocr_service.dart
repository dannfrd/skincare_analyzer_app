import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OcrService {
  static const MethodChannel _channel = MethodChannel('flutter_tesseract_ocr');
  static const String _trainedDataAsset = 'assets/tessdata/eng.traineddata';

  static Future<String> extractText(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file not found for OCR: ${imageFile.path}');
    }

    try {
      final tessDataRoot = await _prepareTessData();
      final text = await _channel.invokeMethod<String>('extractText', {
        'imagePath': imageFile.path,
        'tessData': tessDataRoot,
        'language': 'eng',
        'args': {'psm': '6', 'preserve_interword_spaces': '1'},
      });

      final cleaned = (text ?? '').trim();
      if (cleaned.isEmpty) {
        throw Exception('OCR did not detect any text in the image.');
      }

      return cleaned;
    } on MissingPluginException catch (e) {
      throw Exception(
        'OCR native plugin is unavailable on this platform/build: $e',
      );
    } on PlatformException catch (e) {
      throw Exception('Native OCR failed: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Failed to run on-device OCR: $e');
    }
  }

  static Future<String> _prepareTessData() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final tessdataDirectory = Directory('${appDirectory.path}/tessdata');

    if (!await tessdataDirectory.exists()) {
      await tessdataDirectory.create(recursive: true);
    }

    final trainedDataFile = File('${tessdataDirectory.path}/eng.traineddata');
    final shouldCopy =
        !await trainedDataFile.exists() || await trainedDataFile.length() == 0;

    if (shouldCopy) {
      final ByteData data = await rootBundle.load(_trainedDataAsset);
      final Uint8List bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await trainedDataFile.writeAsBytes(bytes, flush: true);
    }

    return appDirectory.path;
  }
}

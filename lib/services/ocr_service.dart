import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'ingredient_text_filter.dart';

class OcrService {
  static const MethodChannel _channel = MethodChannel('flutter_tesseract_ocr');
  static const String _trainedDataAsset = 'assets/tessdata/eng.traineddata';

  static Future<String> extractText(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file not found for OCR: ${imageFile.path}');
    }

    try {
      final mlKitText = await _extractWithMlKit(imageFile);
      if (!_looksWeak(mlKitText)) {
        return mlKitText;
      }

      final tessDataRoot = await _prepareTessData();
      final processedFile = await _prepareImageForOcr(imageFile);

      final candidates = <String>[mlKitText];
      candidates.add(
        IngredientTextFilter.selectFromPlainText(
          await _runOcr(processedFile, tessDataRoot, psm: '6'),
        ),
      );

      if (_looksWeak(candidates.first)) {
        candidates.add(
          IngredientTextFilter.selectFromPlainText(
            await _runOcr(processedFile, tessDataRoot, psm: '11'),
          ),
        );
        candidates.add(
          IngredientTextFilter.selectFromPlainText(
            await _runOcr(processedFile, tessDataRoot, psm: '4'),
          ),
        );
      }

      if (processedFile.path != imageFile.path) {
        candidates.add(
          IngredientTextFilter.selectFromPlainText(
            await _runOcr(imageFile, tessDataRoot, psm: '6'),
          ),
        );
      }

      final best = _pickBest(candidates);
      if (best.trim().isEmpty) {
        throw Exception('OCR did not detect any text in the image.');
      }

      return best.trim();
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

  static Future<String> _extractWithMlKit(File imageFile) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final result = await recognizer.processImage(inputImage);
      final lines = <OcrTextLine>[
        for (final block in result.blocks)
          for (final line in block.lines)
            OcrTextLine(
              text: line.text,
              top: line.boundingBox.top,
              left: line.boundingBox.left,
            ),
      ];
      return IngredientTextFilter.selectFromLines(lines);
    } catch (_) {
      return '';
    } finally {
      try {
        await recognizer.close();
      } catch (_) {
        // A missing native ML Kit plugin must not block the Tesseract fallback.
      }
    }
  }

  static Future<String> _runOcr(
    File imageFile,
    String tessDataRoot, {
    required String psm,
  }) async {
    final text = await _channel.invokeMethod<String>('extractText', {
      'imagePath': imageFile.path,
      'tessData': tessDataRoot,
      'language': 'eng',
      'args': {'psm': psm, 'preserve_interword_spaces': '1'},
    });

    return (text ?? '').trim();
  }

  static Future<File> _prepareImageForOcr(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return imageFile;
      }

      final targetWidth = decoded.width < 1400 ? 1400 : decoded.width;
      final resized = img.copyResize(
        decoded,
        width: targetWidth,
        interpolation: img.Interpolation.cubic,
      );

      final grayscale = img.grayscale(resized);
      final enhanced = img.adjustColor(
        grayscale,
        contrast: 1.2,
        brightness: 0.05,
      );

      final tempDir = await getTemporaryDirectory();
      final output = File(
        '${tempDir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await output.writeAsBytes(img.encodePng(enhanced));
      return output;
    } catch (_) {
      return imageFile;
    }
  }

  static bool _looksWeak(String text) {
    final cleaned = text.trim();
    if (cleaned.length < 20) {
      return true;
    }
    final alphaCount = RegExp(r'[A-Za-z]').allMatches(cleaned).length;
    final digitCount = RegExp(r'[0-9]').allMatches(cleaned).length;
    return (alphaCount + digitCount) < 12;
  }

  static String _pickBest(List<String> candidates) {
    var best = '';
    var bestScore = -1;

    for (final candidate in candidates) {
      final score = _scoreText(candidate);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best;
  }

  static int _scoreText(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return 0;

    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final alphaCount = RegExp(r'[A-Za-z]').allMatches(cleaned).length;
    final digitCount = RegExp(r'[0-9]').allMatches(cleaned).length;
    return words * 10 + alphaCount + digitCount;
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

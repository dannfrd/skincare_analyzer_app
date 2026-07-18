import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'ingredient_text_filter.dart';

class OcrService {
  // ==================================================
  // KONFIGURASI ENGINE PENELITIAN (TA):
  // - 'server'    : Server-Driven OCR (Mengirim foto yang sudah dikompres langsung ke backend PP-OCRv4 / Cloud AI)
  // - 'mlkit'     : Menggunakan Google MLKit murni di HP (On-Device Fallback)
  // ==================================================
  static const String activeEngine = 'server';

  static Future<String> extractText(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file not found for OCR: ${imageFile.path}');
    }

    try {
      if (activeEngine == 'server') {
        // Pada mode Server-Driven, ekstraksi teks diproses langsung di Backend API (/analyze-image).
        return '';
      }

      if (activeEngine == 'mlkit') {
        return await _extractWithMlKit(imageFile);
      }

      return '';
    } catch (e) {
      return 'Error extracting text: $e';
    }
  }

  static Future<String> _extractWithMlKit(File imageFile) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      // 1. Coba baca gambar asli (raw) murni dengan MLKit
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
      String rawText = IngredientTextFilter.selectFromLines(lines);

      // 2. Jika hasil murni MLKit lemah/rusak akibat pantulan silau kemasan,
      // jalankan MLKit pada gambar hasil peningkatan kontras (_prepareImageForOcr)
      if (_looksWeak(rawText)) {
        try {
          final processedFile = await _prepareImageForOcr(imageFile);
          if (processedFile.path != imageFile.path) {
            final processedImage = InputImage.fromFile(processedFile);
            final processedResult = await recognizer.processImage(
              processedImage,
            );
            final processedLines = <OcrTextLine>[
              for (final block in processedResult.blocks)
                for (final line in block.lines)
                  OcrTextLine(
                    text: line.text,
                    top: line.boundingBox.top,
                    left: line.boundingBox.left,
                  ),
            ];
            String enhancedText = IngredientTextFilter.selectFromLines(
              processedLines,
            );
            if (enhancedText.trim().length > rawText.trim().length) {
              return enhancedText;
            }
          }
        } catch (_) {
          // Abaikan error preprocessing dan kembalikan rawText
        }
      }

      return rawText;
    } catch (_) {
      return '';
    } finally {
      try {
        await recognizer.close();
      } catch (_) {
        // Ignore close errors
      }
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

  static Future<File> _prepareImageForOcr(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return imageFile;
      }

      int targetWidth = decoded.width;
      if (decoded.width > 1600) {
        targetWidth = 1600;
      } else if (decoded.width < 1000) {
        targetWidth = 1000;
      }

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
        '${tempDir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await output.writeAsBytes(img.encodeJpg(enhanced, quality: 95));
      return output;
    } catch (_) {
      return imageFile;
    }
  }
}

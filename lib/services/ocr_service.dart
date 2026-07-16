import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_paddle_ocr/flutter_paddle_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'ingredient_text_filter.dart';

class OcrService {
  static const MethodChannel _channel = MethodChannel('flutter_tesseract_ocr');
  static const String _trainedDataAsset = 'assets/tessdata/eng.traineddata';
  static PaddleOcr? _paddleOcr;
  static Future<PaddleOcr>? _paddleOcrInit;
  static const String _paddleModelBaseUrl = 'https://paddleocr.bj.bcebos.com/PP-OCRv3/english';
  static const String _paddleDictUrl = 'https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/en_dict.txt';

  // ==================================================
  // KONFIGURASI ENGINE PENELITIAN (TA):
  // Ubah konstanta ini untuk mengganti engine utama aplikasi:
  // - 'hybrid'    : Menggunakan MLKit dengan fallback Tesseract (Default)
  // - 'mlkit'     : Menggunakan Google MLKit murni (Aktif untuk Pengujian TA)
  // - 'tesseract' : Menggunakan Tesseract murni
  // - 'paddleocr' : Menggunakan PaddleOCR secara lokal di perangkat
  // ==================================================
  static const String activeEngine = 'paddleocr';

  static Future<String> extractText(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file not found for OCR: ${imageFile.path}');
    }

    try {
      String mlKitText = '';
      String tessText = '';
      String hybridText = '';
      String paddleText = '';
      String tessDataRoot = '';
      File? processedFile;

      int mlKitTimeMs = 0;
      int tessTimeMs = 0;
      int hybridTimeMs = 0;
      int paddleTimeMs = 0;

      final totalWatch = Stopwatch()..start();

      // 1. Ekstrak dengan PaddleOCR Local (Bila engine aktif adalah paddleocr)
      if (activeEngine == 'paddleocr') {
        final watch = Stopwatch()..start();
        try {
          paddleText = await _extractWithPaddleOcr(imageFile);
        } catch (e) {
          paddleText = 'Error running PaddleOCR: $e';
        }
        watch.stop();
        paddleTimeMs = watch.elapsedMilliseconds;
      }

      // 2. Ekstrak dengan MLKit Murni jika engine aktif membutuhkannya
      if (activeEngine == 'mlkit' || activeEngine == 'hybrid') {
        final watch = Stopwatch()..start();
        mlKitText = await _extractWithMlKit(imageFile);
        watch.stop();
        mlKitTimeMs = watch.elapsedMilliseconds;
      }

      // 2. Ekstrak dengan Tesseract Murni jika engine aktif membutuhkannya
      if (activeEngine == 'tesseract' || activeEngine == 'hybrid') {
        final watch = Stopwatch()..start();
        try {
          tessDataRoot = await _prepareTessData();
          processedFile = await _prepareImageForOcr(imageFile);
          tessText = await _runOcr(processedFile, tessDataRoot, psm: '6');

          // Fallback 1: Coba dengan gambar asli jika gambar hasil pemrosesan kosong
          if (tessText.trim().isEmpty) {
            tessText = await _runOcr(imageFile, tessDataRoot, psm: '6');
          }

          // Fallback 2: Coba dengan PSM 3 (Automatic) jika masih kosong
          if (tessText.trim().isEmpty) {
            tessText = await _runOcr(processedFile, tessDataRoot, psm: '3');
          }

          // Fallback 3: Coba dengan PSM 11 jika masih kosong
          if (tessText.trim().isEmpty) {
            tessText = await _runOcr(processedFile, tessDataRoot, psm: '11');
          }
        } catch (e) {
          tessText = 'Error running Tesseract: $e';
        }
        watch.stop();
        tessTimeMs = watch.elapsedMilliseconds;
      }

      // 3. Proses Hybrid (Logika Cerdas Fallback) hanya jika engine hybrid aktif
      if (activeEngine == 'hybrid') {
        final watch = Stopwatch()..start();
        hybridText = mlKitText;
        if (_looksWeak(mlKitText)) {
          final candidates = <String>[mlKitText];
          if (tessText.isNotEmpty && !tessText.startsWith('Error')) {
            candidates.add(IngredientTextFilter.selectFromPlainText(tessText));
          }

          try {
            if (processedFile != null) {
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
            if (processedFile != null && processedFile.path != imageFile.path) {
              candidates.add(
                IngredientTextFilter.selectFromPlainText(
                  await _runOcr(imageFile, tessDataRoot, psm: '6'),
                ),
              );
            }
          } catch (_) {}

          hybridText = _pickBest(candidates);
        }
        watch.stop();
        hybridTimeMs = mlKitTimeMs + tessTimeMs + watch.elapsedMilliseconds;
      }
      totalWatch.stop();

      // Cetak semua hasil ke Konsol Debug Flutter untuk kebutuhan PENELITIAN
      // ignore: avoid_print
      print("\n==================================================");
      // ignore: avoid_print
      print("      [PENELITIAN OCR] HASIL SCAN BATCH DATA      ");
      // ignore: avoid_print
      print("==================================================");
      // ignore: avoid_print
      print("Active Engine: ${activeEngine.toUpperCase()}");
      // ignore: avoid_print
      print("--------------------------------------------------");
      
      if (activeEngine == 'paddleocr') {
        // ignore: avoid_print
        print(">>> PADDLE OCR MURNI LOKAL (Waktu: $paddleTimeMs ms):");
        // ignore: avoid_print
        print(paddleText.trim().isEmpty ? "[Tidak ada teks terdeteksi]" : paddleText.trim());
        // ignore: avoid_print
        print("--------------------------------------------------");
      }

      if (activeEngine == 'mlkit' || activeEngine == 'hybrid') {
        // ignore: avoid_print
        print(">>> MLKIT MURNI (Waktu Eksekusi: $mlKitTimeMs ms):");
        // ignore: avoid_print
        print(mlKitText.trim().isEmpty ? "[Tidak ada teks terdeteksi]" : mlKitText.trim());
        // ignore: avoid_print
        print("--------------------------------------------------");
      }
      
      if (activeEngine == 'tesseract' || activeEngine == 'hybrid') {
        // ignore: avoid_print
        print(">>> TESSERACT MURNI (Waktu Eksekusi: $tessTimeMs ms):");
        // ignore: avoid_print
        print(tessText.trim().isEmpty ? "[Tidak ada teks terdeteksi]" : tessText.trim());
        // ignore: avoid_print
        print("--------------------------------------------------");
      }
      
      if (activeEngine == 'hybrid') {
        // ignore: avoid_print
        print(">>> HYBRID MLKIT + TESSERACT (Waktu Eksekusi: $hybridTimeMs ms):");
        // ignore: avoid_print
        print(hybridText.trim().isEmpty ? "[Tidak ada teks terdeteksi]" : hybridText.trim());
        // ignore: avoid_print
        print("--------------------------------------------------");
      }
      // ignore: avoid_print
      print("==================================================\n");

      // Menentukan teks mana yang akan dikembalikan sesuai konfigurasi penelitian
      String returnedText = '';
      if (activeEngine == 'mlkit') {
        returnedText = mlKitText;
      } else if (activeEngine == 'tesseract') {
        returnedText = tessText;
      } else if (activeEngine == 'paddleocr') {
        returnedText = paddleText;
      } else {
        returnedText = hybridText;
      }

      if (returnedText.trim().isEmpty) {
        throw Exception('OCR did not detect any text in the image using ${activeEngine.toUpperCase()}');
      }

      return returnedText.trim();
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

  static Future<String> _extractWithPaddleOcr(File imageFile) async {
    final engine = await _getPaddleOcr();
    final imageBytes = await imageFile.readAsBytes();
    final results = await engine.recognize(imageBytes);
    final lines = <String>[];

    for (final result in results) {
      final text = result.text.trim();
      if (text.isNotEmpty) {
        lines.add(text);
      }
    }

    return IngredientTextFilter.selectFromPlainText(lines.join('\n'));
  }

  static Future<PaddleOcr> _getPaddleOcr() {
    final cached = _paddleOcr;
    if (cached != null) {
      return Future.value(cached);
    }

    final pending = _paddleOcrInit;
    if (pending != null) {
      return pending;
    }

    final initialized = _createPaddleOcr().then((ocr) {
      _paddleOcr = ocr;
      return ocr;
    });

    _paddleOcrInit = initialized;
    return initialized;
  }

  static Future<PaddleOcr> _createPaddleOcr() async {
    final modelsDir = await _getPaddleModelsDirectory();
    final detPath = await _ensureDownloadedFile(
      url: '$_paddleModelBaseUrl/en_PP-OCRv3_det_slim_infer.nb',
      directory: modelsDir,
      fileName: 'en_PP-OCRv3_det_slim_infer.nb',
    );
    final recPath = await _ensureDownloadedFile(
      url: '$_paddleModelBaseUrl/en_PP-OCRv3_rec_slim_infer.nb',
      directory: modelsDir,
      fileName: 'en_PP-OCRv3_rec_slim_infer.nb',
    );
    final dictPath = await _ensureDownloadedFile(
      url: _paddleDictUrl,
      directory: modelsDir,
      fileName: 'en_dict.txt',
    );

    return PaddleOcr.create(
      source: FilePathsModelSource(
        det: detPath.path,
        rec: recPath.path,
        dict: dictPath.path,
      ),
      cpuThreadNum: 4,
      cpuPower: CpuPower.high,
      useOpenCL: false,
    );
  }

  static Future<Directory> _getPaddleModelsDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final modelsDirectory = Directory('${appDirectory.path}${Platform.pathSeparator}paddleocr_models');
    if (!await modelsDirectory.exists()) {
      await modelsDirectory.create(recursive: true);
    }
    return modelsDirectory;
  }

  static Future<File> _ensureDownloadedFile({
    required String url,
    required Directory directory,
    required String fileName,
  }) async {
    final targetFile = File('${directory.path}${Platform.pathSeparator}$fileName');
    if (await targetFile.exists() && await targetFile.length() > 0) {
      return targetFile;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download PaddleOCR model: $url (${response.statusCode})');
    }

    await targetFile.writeAsBytes(response.bodyBytes, flush: true);
    return targetFile;
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

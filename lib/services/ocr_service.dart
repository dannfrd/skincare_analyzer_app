import 'dart:io';

class OcrService {
  // ==================================================
  // KONFIGURASI ENGINE PENELITIAN (TA):
  // - 'server'    : Server-Driven OCR (Mengirim foto yang sudah dikompres langsung ke backend PaddleOCR / Cloud AI)
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

      return '';
    } catch (e) {
      return 'Error extracting text: $e';
    }
  }
}

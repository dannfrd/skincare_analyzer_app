class OcrTextLine {
  final String text;
  final double top;
  final double left;

  const OcrTextLine({
    required this.text,
    required this.top,
    required this.left,
  });
}

class IngredientTextFilter {
  static final RegExp _headerPattern = RegExp(
    r'\b(ingredients?|komposisi(?:\s+bahan)?|composition|'
    r'bahan(?:[-\s]+bahan)?|kandungan|inci(?:\s+name)?)\b'
    r'\s*[:\-/]?\s*',
    caseSensitive: false,
  );

  static final RegExp _stopPattern = RegExp(
    r'\b(how\s+to\s+use|directions?|usage|cara\s+pakai|'
    r'cara\s+penggunaan|aturan\s+pakai|peringatan|warning|caution|'
    r'netto|net\s*(?:wt|content)|berat\s+bersih|bpom|'
    r'no\.?\s*reg|nomor\s+registrasi|p-?irt|exp(?:ired)?|'
    r'kedaluwarsa|kadaluarsa|batch|lot\s*no|made\s+in|'
    r'diproduksi|distributor|alamat|address|website|www\.|https?)\b',
    caseSensitive: false,
  );

  static final RegExp _ingredientHintPattern = RegExp(
    r'\b(aqua|water|glycerin|glycerine|niacinamide|acid|extract|'
    r'oil|alcohol|glycol|glyceride|siloxane|silicone|dimethicone|'
    r'parfum|fragrance|tocopherol|panthenol|ceramide|peptide|'
    r'chloride|sulfate|phosphate|benzoate|sorbate|salicylate|'
    r'hyaluronate|allantoin|retinol|collagen|butter|wax)\b',
    caseSensitive: false,
  );

  static final RegExp _noisePattern = RegExp(
    r'\b(whitening|brightening|moisturizing|dermatologically|'
    r'tested|new|original|exclusive|formula|benefit|manfaat|'
    r'produk|product|customer|service|instagram|facebook|'
    r'gram|ml|isi\s+bersih|barcode)\b',
    caseSensitive: false,
  );

  static String selectFromLines(List<OcrTextLine> inputLines) {
    final lines =
        inputLines.where((line) => line.text.trim().isNotEmpty).toList()
          ..sort((a, b) {
            final vertical = a.top.compareTo(b.top);
            return vertical != 0 ? vertical : a.left.compareTo(b.left);
          });

    if (lines.isEmpty) return '';

    final headerIndex = lines.indexWhere(
      (line) => _headerPattern.hasMatch(line.text),
    );
    if (headerIndex >= 0) {
      final selected = <String>[];
      final headerLine = lines[headerIndex].text.trim();
      final inlineText = headerLine.replaceFirst(_headerPattern, '').trim();
      if (inlineText.isNotEmpty && !_stopPattern.hasMatch(inlineText)) {
        selected.add(inlineText);
      }

      for (var index = headerIndex + 1; index < lines.length; index++) {
        final text = lines[index].text.trim();
        if (_stopPattern.hasMatch(text)) break;
        selected.add(text);
      }

      final result = _normalize(selected.join('\n'));
      if (_looksLikeIngredientList(result)) return result;
    }

    final candidates = lines
        .where((line) => _ingredientLineScore(line.text) > 0)
        .map((line) => line.text.trim())
        .toList();
    final candidateText = _normalize(candidates.join('\n'));
    if (_looksLikeIngredientList(candidateText)) return candidateText;

    // Fail closed instead of sending unrelated packaging text for analysis.
    return '';
  }

  static String selectFromPlainText(String rawText) {
    final lines = rawText
        .replaceAll('\r', '\n')
        .split('\n')
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    return selectFromLines([
      for (var index = 0; index < lines.length; index++)
        OcrTextLine(text: lines[index], top: index.toDouble(), left: 0),
    ]);
  }

  static int _ingredientLineScore(String text) {
    final normalized = text.trim();
    if (normalized.length < 3 || _stopPattern.hasMatch(normalized)) {
      return -10;
    }

    var score = 0;
    score += ','.allMatches(normalized).length * 3;
    score += ';'.allMatches(normalized).length * 2;
    score += _ingredientHintPattern.allMatches(normalized).length * 2;
    if (_noisePattern.hasMatch(normalized)) score -= 3;

    final letters = RegExp(r'[A-Za-z]').allMatches(normalized).length;
    final digits = RegExp(r'\d').allMatches(normalized).length;
    if (letters >= 8 && digits == 0) score += 1;
    return score;
  }

  static bool _looksLikeIngredientList(String text) {
    if (text.length < 8) return false;
    return text.contains(',') ||
        text.contains(';') ||
        _ingredientHintPattern.hasMatch(text);
  }

  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'-\s*\n\s*'), '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
  }
}

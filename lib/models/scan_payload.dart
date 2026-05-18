import 'dart:io';

class ScanPayload {
  final File imageFile;
  final String? productName;
  final String? productBrand;
  final String? productCategory;

  const ScanPayload({
    required this.imageFile,
    this.productName,
    this.productBrand,
    this.productCategory,
  });

  bool get hasProductInfo {
    return _hasText(productName) || _hasText(productBrand) || _hasText(productCategory);
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

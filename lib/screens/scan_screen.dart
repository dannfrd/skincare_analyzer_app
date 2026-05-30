import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/models/scan_payload.dart';

const List<String> _kProductCategories = [
  'Toner',
  'Serum',
  'Moisturizer',
  'Sunscreen',
  'Cleanser',
  'Exfoliator',
  'Eye Cream',
  'Lip Care',
  'Mask',
  'Body Lotion',
  'Body Wash',
  'Essence',
  'Primer',
  'BB / CC Cream',
];

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  bool _isCameraOpening = false;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productBrandController = TextEditingController();
  final TextEditingController _productCategoryController =
      TextEditingController();

  String? _selectedCategory;
  bool _showManualCategory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showImageSourceActionSheet();
    });
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Gambar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                  title: const Text('Kamera',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _openCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library,
                      color: AppColors.primaryGreen),
                  title: const Text('Galeri',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCamera() async {
    if (_isCameraOpening) return;
    setState(() => _isCameraOpening = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (!mounted) return;
      if (image != null) {
        setState(() => _isCameraOpening = false);
        await _cropImage(image.path);
      } else {
        setState(() => _isCameraOpening = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCameraOpening = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error membuka kamera: $e')));
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (image != null) await _cropImage(image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error memilih gambar: $e')));
    }
  }

  Future<void> _cropImage(String path) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Gambar',
            toolbarColor: AppColors.primaryGreen,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Gambar'),
        ],
      );
      if (croppedFile != null && mounted) {
        setState(() => _capturedImage = File(croppedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error crop gambar: $e')));
    }
  }

  void _onCategoryChipSelected(String category) {
    setState(() {
      if (category == 'Lainnya...') {
        _showManualCategory = true;
        _selectedCategory = 'Lainnya...';
        _productCategoryController.clear();
      } else {
        _showManualCategory = false;
        _selectedCategory = category;
        _productCategoryController.text = category;
      }
    });
  }

  void _proceedToAnalysis() {
    if (_capturedImage == null) return;
    final payload = ScanPayload(
      imageFile: _capturedImage!,
      productName: _productNameController.text,
      productBrand: _productBrandController.text,
      productCategory: _productCategoryController.text,
    );
    Navigator.pushReplacementNamed(context, '/progress', arguments: payload);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productBrandController.dispose();
    _productCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Label',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textDark),
            onPressed: _showScanTips,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: _capturedImage != null
                    ? _buildImagePreview()
                    : _buildEmptyState(),
              ),
              const SizedBox(height: 20),
              Text(
                _capturedImage != null ? 'Foto Dipilih' : 'Pilih Gambar',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _capturedImage != null
                      ? 'Tinjau foto di atas, isi info produk, lalu mulai analisis.'
                      : 'Pilih sumber gambar untuk memindai label produk skincare.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textGray, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              if (_capturedImage != null) ...[
                _buildProductForm(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _proceedToAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.science),
                    label: const Text(
                      'Analisis Bahan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openCamera,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          side: const BorderSide(
                              color: AppColors.primaryGreen, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Ulangi',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: BorderSide(
                              color: Colors.grey.shade300, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.photo_library_outlined,
                            size: 18),
                        label: const Text('Galeri',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 Tip: Foto dekat bagian "Ingredients / Komposisi", hindari pantulan cahaya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11.5,
                      height: 1.4),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_capturedImage!, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline,
                  size: 15, color: AppColors.primaryGreenDark),
              SizedBox(width: 6),
              Text(
                'Info Produk (Opsional)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProductField(
            controller: _productNameController,
            label: 'Nama Produk',
            hint: 'cth. Acne Moisturizer',
            icon: Icons.spa_outlined,
          ),
          const SizedBox(height: 10),
          _buildProductField(
            controller: _productBrandController,
            label: 'Brand',
            hint: 'cth. Skintific',
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 12),
          const Text(
            'Kategori',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          _buildCategoryChips(),
          if (_showManualCategory) ...[
            const SizedBox(height: 10),
            _buildProductField(
              controller: _productCategoryController,
              label: 'Ketik kategori lainnya',
              hint: 'cth. Hair Tonic',
              icon: Icons.edit_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [..._kProductCategories, 'Lainnya...'];
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        final isOther = cat == 'Lainnya...';
        return GestureDetector(
          onTap: () => _onCategoryChipSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isOther
                      ? const Color(0xFFF0F4FF)
                      : AppColors.primaryGreen.withValues(alpha: 0.12))
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (isOther
                        ? const Color(0xFF3B82F6)
                        : AppColors.primaryGreenDark)
                    : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              cat,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isOther
                        ? const Color(0xFF1D4ED8)
                        : AppColors.primaryGreenDark)
                    : AppColors.textGray,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 17, color: AppColors.textGray),
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide:
                  const BorderSide(color: AppColors.primaryGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 56,
            color: AppColors.primaryGreen.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'Scan Label Produk',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gunakan kamera atau pilih gambar\nuntuk menganalisis bahan skincare.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGray, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeri'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showScanTips() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tips_and_updates, color: AppColors.primaryGreenDark),
            SizedBox(width: 8),
            Text('Tips Scan', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipItem(
              icon: Icons.crop_free,
              text: 'Pastikan bagian "Ingredients / Komposisi" memenuhi frame.',
            ),
            SizedBox(height: 8),
            _TipItem(
              icon: Icons.wb_sunny_outlined,
              text: 'Hindari pantulan cahaya / glare pada kemasan.',
            ),
            SizedBox(height: 8),
            _TipItem(
              icon: Icons.center_focus_strong_outlined,
              text: 'Foto dari jarak dekat (10–20 cm) agar teks tajam.',
            ),
            SizedBox(height: 8),
            _TipItem(
              icon: Icons.crop,
              text: 'Gunakan fitur crop untuk memotong bagian ingredients saja.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti',
                style: TextStyle(color: AppColors.primaryGreenDark)),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreenDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textDark, height: 1.4),
          ),
        ),
      ],
    );
  }
}

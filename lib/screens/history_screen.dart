import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/screens/result_screen.dart';
import 'package:skincare_analyzer_app/services/api_service.dart';
import 'package:skincare_analyzer_app/services/user_session.dart';
import 'package:skincare_analyzer_app/utils/smooth_page_transitions.dart';

// ─── Data Model ─────────────────────────────────────────────────────────────

class ScanHistoryItem {
  final int? analysisId;
  final String productBrand; // Nama brand yang diisi user saat scan
  final String productCategory; // Kategori yang dipilih saat scan
  final String date;
  final String summary;
  final String recommendation;
  final String? localImagePath;
  final String? imageUrl;
  final int warningsCount;
  final int unknownCount;

  const ScanHistoryItem({
    required this.analysisId,
    required this.productBrand,
    required this.productCategory,
    required this.date,
    required this.summary,
    required this.recommendation,
    this.localImagePath,
    this.imageUrl,
    this.warningsCount = 0,
    this.unknownCount = 0,
  });
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<ScanHistoryItem> _allItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final List<dynamic> historyData = await ApiService.getHistory();
      final prefs = await SharedPreferences.getInstance();
      final docDir = await getApplicationDocumentsDirectory();

      final List<ScanHistoryItem> parsedItems = [];
      for (var e in historyData) {
        if (e is! Map) continue;
        final product = e['product'] is Map ? e['product'] as Map : {};
        final analysis =
            e['analyses'] is List && (e['analyses'] as List).isNotEmpty
                ? e['analyses'][0]
                : e;

        final analysisId = _toInt(e['analysis_id']) ?? _toInt(analysis['id']) ?? _toInt(e['id']);

        // Periksa gambar dari SharedPreferences / direktori dokumen lokal
        String? imgPath;
        if (analysisId != null && analysisId > 0) {
          final savedPath = prefs.getString('scan_img_$analysisId');
          if (savedPath != null && await File(savedPath).exists()) {
            imgPath = savedPath;
          } else {
            final defaultPath = '${docDir.path}/scan_images/scan_$analysisId.jpg';
            if (await File(defaultPath).exists()) {
              imgPath = defaultPath;
            }
          }
        }
        if (imgPath == null) {
          final pStr = _str(e['image_path']) ?? _str(analysis['image_path']);
          if (pStr != null && await File(pStr).exists()) {
            imgPath = pStr;
          }
        }

        final imgUrl = _str(e['image_url']) ?? _str(analysis['image_url']) ?? _str(product['image_url']);

        // Brand: prioritize product_brand → product['brand'] → product['name'] → fallback
        final brand = _str(product['brand']) ??
            _str(e['product_brand']) ??
            _str(product['name']) ??
            _str(e['product_name']) ??
            'Unknown Product';

        // Category: prioritize product['category'] → e['product_category']
        final category = _str(product['category']) ??
            _str(e['product_category']) ??
            '';

        final summaryText = _str(analysis['summary']) ??
            _str(e['summary']) ??
            'Summary analysis not available.';
        final recText = _str(analysis['recommendation']) ??
            _str(e['recommendation']) ??
            'No additional recommendations.';

        final warnings = _toInt(analysis['warnings_count']) ?? _toInt(e['warnings_count']) ?? 0;
        final unknown = _toInt(analysis['unknown_count']) ?? _toInt(e['unknown_count']) ?? 0;

        parsedItems.add(ScanHistoryItem(
          analysisId: analysisId,
          productBrand: brand,
          productCategory: category,
          date: e['created_at'] != null
              ? _formatDate(e['created_at'].toString())
              : 'Tanggal tidak diketahui',
          summary: summaryText,
          recommendation: recText,
          localImagePath: imgPath,
          imageUrl: imgUrl,
          warningsCount: warnings,
          unknownCount: unknown,
        ));
      }

      if (mounted) {
        setState(() {
          _allItems = parsedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final tokenStatus =
              UserSession.token != null ? 'Present' : 'Null';
          _errorMessage =
              '${e.toString().replaceAll('Exception: ', '')}\n[Debug: Token is $tokenStatus]';
          _isLoading = false;
        });
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String? _str(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isNotEmpty ? s : null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.split('T')[0];
    }
  }

  /// Infer a color + icon from the product category.
  static (Color, IconData) _styleFromCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('sunscreen') || c.contains('spf')) {
      return (const Color(0xFF4A90D9), Icons.wb_sunny_rounded);
    }
    if (c.contains('serum') || c.contains('essence') || c.contains('ampoule')) {
      return (const Color(0xFF9B59B6), Icons.science_rounded);
    }
    if (c.contains('moisturizer') || c.contains('cream') || c.contains('lotion')) {
      return (const Color(0xFF16A085), Icons.water_drop_rounded);
    }
    if (c.contains('toner') || c.contains('mist')) {
      return (const Color(0xFFF39C12), Icons.opacity_rounded);
    }
    if (c.contains('cleanser') || c.contains('wash') ||
        c.contains('foam') || c.contains('cleansing')) {
      return (const Color(0xFF2ECC71), Icons.soap_rounded);
    }
    if (c.contains('exfoliat') || c.contains('peeling')) {
      return (const Color(0xFFE74C3C), Icons.auto_fix_high_rounded);
    }
    if (c.contains('eye')) {
      return (const Color(0xFF8E44AD), Icons.remove_red_eye_rounded);
    }
    if (c.contains('lip')) {
      return (const Color(0xFFE91E7A), Icons.face_retouching_natural_rounded);
    }
    if (c.contains('mask') || c.contains('sheet')) {
      return (const Color(0xFF1ABC9C), Icons.masks_rounded);
    }
    if (c.contains('body') || c.contains('lotion')) {
      return (const Color(0xFFE67E22), Icons.water_rounded);
    }
    if (c.contains('primer') || c.contains('bb') || c.contains('cc')) {
      return (const Color(0xFFC0392B), Icons.brush_rounded);
    }
    return (AppColors.primaryGreenDark, Icons.spa_rounded);
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  Map<String, dynamic> _buildFallbackAnalysisData(ScanHistoryItem item) {
    return {
      'analysis_id': item.analysisId ?? 0,
      'summary': item.summary,
      'recommendation': item.recommendation,
      'product': {
        'brand': item.productBrand,
        'category': item.productCategory,
      },
      'expert_analysis': {
        'warnings_found': 0,
        'total_ingredients_identified': 0,
        'total_unknown': 0,
        'flags': const [],
        'unknown_list': const [],
      },
      'matched_ingredients': const [],
      'ai_analysis': {
        'text': item.recommendation,
        'model': '-',
        'models_tried': const [],
      },
    };
  }

  void _openResultScreen(Map<String, dynamic> data, {File? imageFile}) {
    Navigator.push(
      context,
      SmoothPageRoute(
        builder: (context) => ResultScreen(analysisData: data, imageFile: imageFile),
      ),
    );
  }

  Future<void> _openHistoryDetail(ScanHistoryItem item) async {
    final analysisId = item.analysisId;
    final file = item.localImagePath != null ? File(item.localImagePath!) : null;

    if (analysisId == null || analysisId <= 0) {
      _openResultScreen(_buildFallbackAnalysisData(item), imageFile: file);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening analysis details...')),
    );

    try {
      final detail = await ApiService.getAnalysisDetail(analysisId);
      if (!mounted) return;

      final mergedData = Map<String, dynamic>.from(detail);
      mergedData.putIfAbsent('analysis_id', () => mergedData['id'] ?? analysisId);
      if (item.localImagePath != null) {
        mergedData['local_image_path'] = item.localImagePath;
      }
      if (item.imageUrl != null && mergedData['image_url'] == null) {
        mergedData['image_url'] = item.imageUrl;
      }

      // Skema lama: JSON utuh disimpan di ai_analysis
      if (mergedData['ai_analysis'] is Map &&
          mergedData['ai_analysis']['expert_analysis'] != null) {
        final payload =
            Map<String, dynamic>.from(mergedData['ai_analysis'] as Map);
        mergedData.addAll(payload);
      }

      // Skema baru: tabel analyses — rekonstruksi untuk ResultScreen
      if (mergedData['expert_analysis'] == null) {
        List<Map<String, dynamic>> flags = [];
        List<String> unknownList = [];
        int unknownCount = 0;
        final matchedIngredients = detail['matched_ingredients'] is List
            ? detail['matched_ingredients'] as List
            : [];

        for (var ing in matchedIngredients) {
          final name = ing['name']?.toString() ?? 'Unknown';
          final risk = ing['risk']?.toString() ??
              ing['dataset_warnings']?.toString() ??
              '';

          if (risk.isNotEmpty && risk != 'No specific risk flagged') {
            flags.add({'ingredient': name, 'message': risk});
          }

          ing['dataset_description'] ??= ing['benefit'] ?? ing['description'];
          ing['dataset_functions'] ??= ing['function'] ?? ing['functions'];
          ing['dataset_warnings'] ??=
              (risk != 'No specific risk flagged' ? risk : null);

          final status = ing['status']?.toString().toLowerCase();
          final isUnknown =
              status == 'unknown' || ing['found_in_dataset'] == false;
          ing['found_in_dataset'] ??= !isUnknown;

          if (isUnknown) {
            unknownList.add(name);
            unknownCount++;
          }

          ing['comedogenic_rating'] ??= ing['comedogenic'];
          ing['is_allergen'] ??= ing['allergen'];
          ing['unsafe_for_pregnancy'] ??=
              ing['pregnancy_safe'] == false || ing['unsafe_for_pregnancy'];
          ing['dataset_origin'] ??= ing['origin'];
          ing['dataset_harmful'] ??= ing['harmful'];
          ing['dataset_bpom_warning'] ??= ing['bpom_warning'];
        }

        mergedData['expert_analysis'] = {
          'warnings_found': flags.length,
          'total_ingredients_identified':
              matchedIngredients.length - unknownCount,
          'total_unknown': unknownCount,
          'flags': flags,
          'unknown_list': unknownList,
        };
      }

      if (mergedData['ai_analysis'] == null ||
          mergedData['ai_analysis'] is! Map ||
          (mergedData['ai_analysis']['text'] == null &&
              mergedData['ai_analysis']['model_output'] == null)) {
        mergedData['ai_analysis'] = {
          'text': mergedData['recommendation'] ?? mergedData['summary'],
          'model': 'Dataset RAG',
          'models_tried': [],
        };
      }

      _openResultScreen(mergedData, imageFile: file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to fetch full details, displaying summary data. ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
      _openResultScreen(_buildFallbackAnalysisData(item), imageFile: file);
    }
  }

  // ── Filter ───────────────────────────────────────────────────────────────

  List<ScanHistoryItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _allItems;
    return _allItems
        .where((item) =>
            item.productBrand
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item.productCategory
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 12.0),
                child: Column(
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryGreen))
                    : _errorMessage != null
                        ? Center(
                            child: Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red)))
                        : _filteredItems.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                color: AppColors.primaryGreen,
                                onRefresh: _fetchHistory,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 4.0),
                                  itemCount: _filteredItems.length,
                                  itemBuilder: (context, index) {
                                    return _buildHistoryCard(
                                        _filteredItems[index], index);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo3_home.png',
                width: 36,
                height: 36,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Dermify',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreenDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Scan History',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGray.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (!_isLoading) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppColors.primaryGreenDark,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_allItems.length} Scans',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? AppColors.primaryGreen.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: 'Search brand name or product category...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _searchQuery.isNotEmpty
                ? AppColors.primaryGreenDark
                : Colors.grey.shade400,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade600,
                      size: 14,
                    ),
                  ),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ScanHistoryItem item, int index) {
    final (color, icon) = _styleFromCategory(item.productCategory);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Left Accent Strip (Compact)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openHistoryDetail(item),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Compact Thumbnail (54x54) ──
                            _buildThumbnail(color, icon, item),
                            const SizedBox(width: 12),
                            // ── Brand, Date & Category Info ──
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.productBrand,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            item.date,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  // Category & Warnings Badges (Compact)
                                  Row(
                                    children: [
                                      if (item.productCategory.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color:
                                                color.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: color.withValues(
                                                    alpha: 0.25),
                                                width: 0.8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(icon,
                                                  size: 10, color: color),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.productCategory,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: color,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Text(
                                          'No category',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade400,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      if (item.warningsCount > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3F2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFFECDCA),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 10,
                                                  color: Color(0xFFB42318)),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${item.warningsCount} Warning',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFB42318),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        // ── Kotakan Kecil Hasil Analisis (Single Line Compact) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.16),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.text_snippet_outlined,
                                  size: 12, color: color),
                              const SizedBox(width: 5),
                              Text(
                                'Hasil: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _cleanMarkdownSymbols(item.summary),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 15, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Color color, IconData icon, ScanHistoryItem item) {
    final hasLocalImage =
        item.localImagePath != null && File(item.localImagePath!).existsSync();
    final hasNetworkImage = !hasLocalImage &&
        item.imageUrl != null &&
        item.imageUrl!.startsWith('http');
    final hasAnyImage = hasLocalImage || hasNetworkImage;

    return GestureDetector(
      onTap: () {
        if (hasLocalImage) {
          _showFullImageDialog(context, file: File(item.localImagePath!));
        } else if (hasNetworkImage) {
          _showFullImageDialog(context, url: item.imageUrl!);
        } else {
          _openHistoryDetail(item);
        }
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.85),
              color.withValues(alpha: 0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasLocalImage)
                Image.file(File(item.localImagePath!), fit: BoxFit.cover)
              else if (hasNetworkImage)
                Image.network(item.imageUrl!, fit: BoxFit.cover)
              else
                Center(
                  child: Icon(icon,
                      size: 24, color: Colors.white.withValues(alpha: 0.9)),
                ),
              if (hasAnyImage)
                Positioned(
                  right: 3,
                  bottom: 3,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.zoom_in_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanMarkdownSymbols(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(RegExp(r'^[#]+\s*'), '')
        .replaceAll(RegExp(r'\*\*|\*'), '')
        .replaceAll(RegExp(r'__|_(?=[a-zA-Z0-9])|(?<=[a-zA-Z0-9])_'), '')
        .replaceAll(RegExp(r'```|`'), '')
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m[1] ?? '')
        .trim();
  }

  void _showFullImageDialog(BuildContext context, {File? file, String? url}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 5.0,
                child: file != null && file.existsSync()
                    ? Image.file(
                        file,
                        fit: BoxFit.contain,
                      )
                    : (url != null && url.startsWith('http')
                        ? Image.network(
                            url,
                            fit: BoxFit.contain,
                          )
                        : const SizedBox()),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pinch_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Pinch to Zoom In / Out',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surfaceGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.history_rounded,
                  size: 46,
                  color: AppColors.primaryGreenDark,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No scan results matched'
                  : 'No Scan History Yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'Try searching with a different product brand or category keyword ("$_searchQuery").'
                    : 'Scan your first skincare product to check ingredients, safety ratings, and detailed analysis.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/scan'),
                icon: const Icon(Icons.document_scanner_rounded, size: 18),
                label: const Text('Start First Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

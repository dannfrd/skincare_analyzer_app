import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/screens/result_screen.dart';
import 'package:skincare_analyzer_app/services/api_service.dart';
import 'package:skincare_analyzer_app/services/user_session.dart';

// ─── Data Model ─────────────────────────────────────────────────────────────

class ScanHistoryItem {
  final int? analysisId;
  final String productBrand; // Nama brand yang diisi user saat scan
  final String productCategory; // Kategori yang dipilih saat scan
  final String date;
  final String summary;
  final String recommendation;

  const ScanHistoryItem({
    required this.analysisId,
    required this.productBrand,
    required this.productCategory,
    required this.date,
    required this.summary,
    required this.recommendation,
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

      final List<ScanHistoryItem> parsedItems = historyData.map((e) {
        final product = e['product'] is Map ? e['product'] as Map : {};
        final analysis =
            e['analyses'] is List && (e['analyses'] as List).isNotEmpty
                ? e['analyses'][0]
                : e;

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

        return ScanHistoryItem(
          analysisId: _toInt(e['analysis_id']) ?? _toInt(analysis['id']),
          productBrand: brand,
          productCategory: category,
          date: e['created_at'] != null
              ? _formatDate(e['created_at'].toString())
              : 'Tanggal tidak diketahui',
          summary: _str(analysis['summary']) ??
              'Summary analysis not available.',
          recommendation: _str(analysis['recommendation']) ??
              'No additional recommendations.',
        );
      }).toList();

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

  void _openResultScreen(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(analysisData: data),
      ),
    );
  }

  Future<void> _openHistoryDetail(ScanHistoryItem item) async {
    final analysisId = item.analysisId;
    if (analysisId == null || analysisId <= 0) {
      _openResultScreen(_buildFallbackAnalysisData(item));
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
      mergedData.putIfAbsent('analysis_id', () => mergedData['id']);

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

      _openResultScreen(mergedData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to fetch full details, displaying summary data. ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
      _openResultScreen(_buildFallbackAnalysisData(item));
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 20),
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
                                    horizontal: 20.0),
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
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        Image.asset('assets/images/logo3_home.png', width: 32, height: 32),
        const SizedBox(width: 10),
        const Text(
          'Scan History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const Spacer(),
        if (!_isLoading)
          Text(
            '${_allItems.length} scan',
            style: const TextStyle(fontSize: 13, color: AppColors.textGray),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search product brand or category...',
          hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w400),
          prefixIcon:
              Icon(Icons.search, color: Colors.grey.shade400, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: Colors.grey.shade400, size: 20),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ScanHistoryItem item, int index) {
    final (color, icon) = _styleFromCategory(item.productCategory);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openHistoryDetail(item),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // ── Thumbnail (kategori-based) ───────────────────────
                  _buildThumbnail(color, icon),
                  const SizedBox(width: 14),
                  // ── Info ────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand name (judul utama)
                        Text(
                          item.productBrand,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        // Category badge
                        if (item.productCategory.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 10, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  item.productCategory,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'No category selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 6),
                        // Date
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              item.date,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade300, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Color color, IconData icon) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: 30, color: Colors.white.withValues(alpha: 0.9)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surfaceGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history,
                size: 40, color: AppColors.primaryGreenDark),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada scan',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'Scan your first skincare product!',
            style:
                const TextStyle(fontSize: 14, color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

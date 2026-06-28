import 'dart:io';

import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> analysisData;
  final File? imageFile;

  const ResultScreen({super.key, required this.analysisData, this.imageFile});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;

  // Recommendation async state
  bool _isLoadingRecs = true;
  List<Map<String, dynamic>> _recommendations = [];

  Map<String, dynamic> get analysisData => widget.analysisData;
  File? get imageFile => widget.imageFile;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final matched = _asMapList(widget.analysisData['matched_ingredients']);
    final names = matched
        .map((i) => (_asString(i['name']) ?? '').trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (names.isEmpty) {
      if (mounted) setState(() => _isLoadingRecs = false);
      return;
    }

    final productMap = _asMap(widget.analysisData['product']);
    final category = _asString(productMap['category']);

    final recs = await ApiService.getRecommendations(names, category: category);
    if (mounted) {
      setState(() {
        _recommendations = recs;
        _isLoadingRecs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expertAnalysis = _asMap(analysisData['expert_analysis']);
    final matchedIngredients = _asMapList(analysisData['matched_ingredients']);
    final flags = _asMapList(expertAnalysis['flags']);
    final unknownIngredients = _asStringList(expertAnalysis['unknown_list']);
    final aiAnalysis = _asMap(analysisData['ai_analysis']);

    final identifiedCount =
        _toInt(expertAnalysis['total_ingredients_identified']) ??
        matchedIngredients.where((item) => !_isUnknown(item)).length;
    final unknownCount =
        _toInt(expertAnalysis['total_unknown']) ?? unknownIngredients.length;
    final warningCount =
        _toInt(expertAnalysis['warnings_found']) ?? flags.length;

    final summary =
        _asString(analysisData['summary']) ?? 'Ringkasan analisis belum tersedia.';
    final recommendation =
        _asString(analysisData['recommendation']) ?? 'Belum ada rekomendasi tambahan.';

    final aiText = _resolveAiText(aiAnalysis, recommendation);
    final modelUsed = _asString(aiAnalysis['model_used']) ??
        _asString(aiAnalysis['model']) ??
        '-';
    final modelsTried = _asStringList(aiAnalysis['models_tried']);

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
          'Hasil Analisis',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageHeader(),
                    const SizedBox(height: 16),
                    _buildOverviewCard(
                      identifiedCount: identifiedCount,
                      unknownCount: unknownCount,
                      warningCount: warningCount,
                    ),
                    const SizedBox(height: 14),
                    _buildSectionCard(
                      title: 'Ringkasan Cepat',
                      icon: Icons.insights_rounded,
                      child: Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.textDark,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildIngredientSection(matchedIngredients),
                    if (unknownIngredients.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildUnknownIngredientSection(unknownIngredients),
                    ],
                    if (flags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildFlagSection(flags),
                    ],
                    const SizedBox(height: 14),
                    _buildAiSection(
                      aiText: aiText,
                      modelUsed: modelUsed,
                      modelsTried: modelsTried,
                    ),
                    const SizedBox(height: 14),
                    _buildRecommendationSection(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 185,
            child: imageFile != null
                ? Image.file(imageFile!, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFFE7EFE9),
                    child: const Icon(
                      Icons.spa,
                      size: 62,
                      color: AppColors.primaryGreenDark,
                    ),
                  ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreenDark.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'OCR + AI + RAG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required int identifiedCount,
    required int unknownCount,
    required int warningCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.13),
            AppColors.cardLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGreenDark.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Analisis',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Berdasarkan pencocokan bahan + analisis AI',
            style: TextStyle(fontSize: 12.5, color: AppColors.textGray),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _buildMetricChip(
                icon: Icons.science_rounded,
                text: '$identifiedCount bahan dikenali',
                color: AppColors.primaryGreenDark,
                bgColor: const Color(0xFFE8F5E9),
              ),
              if (unknownCount > 0)
                _buildMetricChip(
                  icon: Icons.help_outline_rounded,
                  text: '$unknownCount belum dikenali',
                  color: const Color(0xFFB7791F),
                  bgColor: const Color(0xFFFFF8E1),
                ),
              if (warningCount > 0)
                _buildMetricChip(
                  icon: Icons.warning_amber_rounded,
                  text: '$warningCount perlu perhatian',
                  color: const Color(0xFFB42318),
                  bgColor: const Color(0xFFFFF0F0),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? accentColor,
  }) {
    final color = accentColor ?? AppColors.primaryGreenDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildIngredientSection(List<Map<String, dynamic>> ingredients) {
    if (ingredients.isEmpty) {
      return _buildSectionCard(
        title: 'Bahan Terdeteksi',
        icon: Icons.list_alt_rounded,
        child: const Text(
          'Belum ada bahan yang terdeteksi dari hasil scan.',
          style: TextStyle(fontSize: 14, color: AppColors.textGray),
        ),
      );
    }

    return _buildSectionCard(
      title: 'Bahan Terdeteksi (${ingredients.length})',
      icon: Icons.list_alt_rounded,
      child: Column(children: ingredients.map(_buildIngredientTile).toList()),
    );
  }

  Widget _buildIngredientTile(Map<String, dynamic> ingredient) {
    final name = _asString(ingredient['name']) ?? 'Unnamed ingredient';
    final function = _asString(ingredient['function']);
    final description = _asString(ingredient['description']);
    final comedogenic = _toInt(ingredient['comedogenic_rating']) ?? 0;
    final isAllergen = _toBool(ingredient['is_allergen']);
    final notPregnancySafe = _toBool(ingredient['unsafe_for_pregnancy']);

    final datasetDescription = _asString(ingredient['dataset_description']);
    final datasetFunctions = _asString(ingredient['dataset_functions']);
    final datasetWarnings = _asString(ingredient['dataset_warnings']);
    final datasetOrigin = _asString(ingredient['dataset_origin']);
    final datasetHarmful = _toBool(ingredient['dataset_harmful']);
    final datasetBpomWarning = _asString(ingredient['dataset_bpom_warning']);
    final foundInDataset = _toBool(ingredient['found_in_dataset']);
    final unknown = _isUnknown(ingredient);

    Color tone = AppColors.primaryGreenDark;
    IconData icon = Icons.check_circle_outline_rounded;
    String statusLabel = 'Aman untuk pemakaian normal';

    if (datasetHarmful && datasetBpomWarning != null) {
      tone = const Color(0xFFB42318);
      icon = Icons.dangerous_rounded;
      statusLabel = '🚨 $datasetBpomWarning';
    } else if (unknown && !foundInDataset) {
      tone = const Color(0xFFB7791F);
      icon = Icons.help_outline_rounded;
      statusLabel = 'Belum ada data di dataset';
    } else if (notPregnancySafe) {
      tone = const Color(0xFFB42318);
      icon = Icons.pregnant_woman_rounded;
      statusLabel = 'Perhatian khusus untuk ibu hamil';
    } else if (isAllergen) {
      tone = const Color(0xFFB42318);
      icon = Icons.warning_amber_rounded;
      statusLabel = 'Potensi alergen / iritan';
    } else if (comedogenic >= 4) {
      tone = const Color(0xFFB42318);
      icon = Icons.error_outline_rounded;
      statusLabel = 'Komedogenik tinggi ($comedogenic/5)';
    } else if (comedogenic == 3) {
      tone = const Color(0xFFD97706);
      icon = Icons.error_outline_rounded;
      statusLabel = 'Komedogenik sedang ($comedogenic/5)';
    } else if (foundInDataset) {
      tone = AppColors.primaryGreenDark;
      icon = Icons.check_circle_outline_rounded;
      statusLabel = 'Bahan ditemukan di dataset';
    }

    final details = <_DetailItem>[];
    if (datasetDescription != null && datasetDescription.isNotEmpty) {
      details.add(_DetailItem('📖', _clip(datasetDescription, maxLen: 160)));
    } else if (description != null && description.isNotEmpty) {
      details.add(_DetailItem('📖', _clip(description, maxLen: 160)));
    }
    if (datasetWarnings != null && datasetWarnings.isNotEmpty) {
      details.add(_DetailItem('⚠️', datasetWarnings));
    }
    if (datasetOrigin != null && datasetOrigin.isNotEmpty) {
      details.add(_DetailItem('🌿', 'Asal: $datasetOrigin'));
    }

    final funcLabel = (datasetFunctions?.isNotEmpty == true)
        ? datasetFunctions!
        : ((function?.isNotEmpty == true) ? function! : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tone, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: tone,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (funcLabel != null && funcLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: funcLabel
                        .split(RegExp(r'[,;|]'))
                        .map((f) => f.trim())
                        .where((f) => f.isNotEmpty)
                        .take(4)
                        .map(
                          (f) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.primaryGreenDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...details.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${item.emoji} ${item.text}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagSection(List<Map<String, dynamic>> flags) {
    return _buildSectionCard(
      title: 'Perlu Perhatian (${flags.length})',
      icon: Icons.warning_amber_rounded,
      accentColor: const Color(0xFFD97706),
      child: Column(
        children: flags.map((flag) {
          final ingredient = _asString(flag['ingredient']) ?? '-';
          final message =
              _asString(flag['message']) ?? 'Detail warning tidak tersedia.';

          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCCB9A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredient,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUnknownIngredientSection(List<String> unknownIngredients) {
    return _buildSectionCard(
      title: 'Bahan Belum Dikenali (${unknownIngredients.length})',
      icon: Icons.help_center_rounded,
      accentColor: const Color(0xFFB7791F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bahan-bahan ini tidak ditemukan di dataset kami. Kemungkinan nama INCI atau bahan lokal yang kurang umum.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: unknownIngredients
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFF9E19A)),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF9A6700),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSection({
    required String aiText,
    required String modelUsed,
    required List<String> modelsTried,
  }) {
    final sections = _parseMarkdownSections(aiText);

    return _buildSectionCard(
      title: 'Insight AI + RAG',
      icon: Icons.auto_awesome_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _buildSoftChip(
                  Icons.memory_rounded, 'Model: $modelUsed', const Color(0xFF4A6FA5)),
              _buildSoftChip(
                  Icons.dataset_rounded, 'Sumber: RAG Dataset', AppColors.primaryGreenDark),
            ],
          ),
          const SizedBox(height: 14),
          if (sections.isEmpty)
            const Text(
              'Insight AI belum tersedia.',
              style: TextStyle(fontSize: 14, color: AppColors.textGray),
            )
          else
            ...sections.map((s) => _buildMarkdownBlock(s)),
          const SizedBox(height: 6),
          Theme(
            data: ThemeData(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Row(
                children: [
                  Icon(Icons.unfold_more_rounded,
                      size: 15, color: AppColors.primaryGreenDark),
                  SizedBox(width: 6),
                  Text(
                    'Lihat analisis AI lengkap',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreenDark,
                    ),
                  ),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FAF6),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                        color: AppColors.primaryGreenDark.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    aiText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_MarkdownSection> _parseMarkdownSections(String text) {
    if (text.trim().isEmpty) return [];
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    // Match numbered section headers: "1) Title" or "1. Title"
    final sectionRegex = RegExp(r'(^|\n)(\d+[).]\s+[^\n]+)');
    final matches = sectionRegex.allMatches(normalized).toList();

    if (matches.isEmpty) {
      return [_MarkdownSection(heading: null, body: normalized)];
    }

    final sections = <_MarkdownSection>[];
    for (int i = 0; i < matches.length; i++) {
      final headingRaw = matches[i].group(2)!.trim();
      final heading = headingRaw.replaceFirst(RegExp(r'^\d+[).]\s*'), '');
      final bodyStart = matches[i].end;
      final bodyEnd =
          i + 1 < matches.length ? matches[i + 1].start : normalized.length;
      final body = normalized.substring(bodyStart, bodyEnd).trim();
      sections.add(_MarkdownSection(heading: heading, body: body));
    }
    return sections;
  }

  Widget _buildMarkdownBlock(_MarkdownSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.heading != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                section.heading!,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreenDark,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(height: 7),
          ],
          ...section.body
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .map((line) {
            final isBullet = line.startsWith('-') ||
                line.startsWith('*') ||
                line.startsWith('•');
            final displayText =
                isBullet ? line.replaceFirst(RegExp(r'^[-*•]\s*'), '') : line;
            final clean = displayText.replaceAll(RegExp(r'\*\*'), '');

            if (isBullet) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreenDark.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clean,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                clean,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textDark,
                  height: 1.55,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Recommendation Section (API-backed) ─────────────────────────────────

  Widget _buildRecommendationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.recommend_rounded,
                size: 16,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Produk Serupa',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Content: loading / empty / list
        if (_isLoadingRecs)
          _buildRecommendationLoading()
        else if (_recommendations.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.search_off_rounded,
                    color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tidak ditemukan produk serupa dari dataset.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 4),
              itemCount: _recommendations.length,
              separatorBuilder: (_, i) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _buildRecommendationCard(_recommendations[index], index),
            ),
          ),

        const SizedBox(height: 4),
        Center(
          child: Text(
            '💡 Produk serupa berdasarkan kemiripan semantik komposisi bahan aktif',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationLoading() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 4),
        itemCount: 4,
        separatorBuilder: (_, i) => const SizedBox(width: 12),
        itemBuilder: (_, b) => Container(
          width: 175,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 9,
                        width: 50,
                        color: Colors.grey.shade200),
                    const SizedBox(height: 6),
                    Container(
                        height: 11,
                        width: 130,
                        color: Colors.grey.shade200),
                    const SizedBox(height: 4),
                    Container(
                        height: 11,
                        width: 90,
                        color: Colors.grey.shade200),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
      Map<String, dynamic> product, int index) {
    final name = _asString(product['name']) ?? 'Unknown Product';
    final pct = product['similarity_pct'] is int
        ? product['similarity_pct'] as int
        : int.tryParse(product['similarity_pct']?.toString() ?? '') ?? 0;
    final matchReason = _asString(product['match_reason']);

    final (color, icon) = _inferProductStyle(name);

    return GestureDetector(
      onTap: () => _showRecommendationDetailsSheet(product),
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header
            Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.88),
                    color.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(icon,
                        size: 30,
                        color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  Positioned(
                    top: 8,
                    right: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$pct% mirip',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand label hidden to show generic product recommendations
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    if (matchReason != null && matchReason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          matchReason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5,
                            color: color.withValues(alpha: 0.75),
                            fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecommendationDetailsSheet(Map<String, dynamic> product) {
    final name = _asString(product['name']) ?? 'Unknown Product';
    final pct = product['similarity_pct'] is int
        ? product['similarity_pct'] as int
        : int.tryParse(product['similarity_pct']?.toString() ?? '') ?? 0;
    final matched = _asStringList(product['matched_ingredients']);
    final matchReason = _asString(product['match_reason']) ?? 'Komposisi bahan serupa';
    final url = _asString(product['url']) ?? '';
    final tags = _asString(product['category_tags']) ?? '';

    final (color, icon) = _inferProductStyle(name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handlebar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Product Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand label hidden in detail sheet
                        const SizedBox(height: 3),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Match Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pct%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kecocokan Formula',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            matchReason,
                            style: TextStyle(
                              fontSize: 13,
                              color: color.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tags
              if (tags.isNotEmpty) ...[
                const Text(
                  'Kategori / Karakteristik',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Matched Ingredients Section
              const Text(
                'Bahan Aktif & Serupa Yang Cocok',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              if (matched.isEmpty)
                const Text(
                  'Pencocokan bahan umum.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textGray),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 180,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: matched
                            .map(
                              (k) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: color.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 12, color: color),
                                    const SizedBox(width: 4),
                                    Text(
                                      k,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      icon: const Icon(Icons.close, color: AppColors.textDark, size: 18),
                      label: const Text(
                        'Tutup',
                        style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (url.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.tryParse(url);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                        label: const Text(
                          'Lihat Produk',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Infer a color + icon pair from the product name keywords.
  static (Color, IconData) _inferProductStyle(String name) {
    final n = name.toLowerCase();
    if (n.contains('sunscreen') || n.contains('spf') || n.contains(' uv ')) {
      return (const Color(0xFF4A90D9), Icons.wb_sunny_rounded);
    }
    if (n.contains('serum') || n.contains('essence') || n.contains('ampoule')) {
      return (const Color(0xFF9B59B6), Icons.science_rounded);
    }
    if (n.contains('moisturizer') || n.contains('cream') || n.contains('lotion')) {
      return (const Color(0xFF16A085), Icons.water_drop_rounded);
    }
    if (n.contains('toner') || n.contains('mist')) {
      return (const Color(0xFFF39C12), Icons.opacity_rounded);
    }
    if (n.contains('cleanser') ||
        n.contains('wash') ||
        n.contains('foam') ||
        n.contains('cleansing')) {
      return (const Color(0xFF2ECC71), Icons.soap_rounded);
    }
    if (n.contains('exfoliat') || n.contains('peeling') || n.contains('peel')) {
      return (const Color(0xFFE74C3C), Icons.auto_fix_high_rounded);
    }
    if (n.contains('eye')) { return (const Color(0xFF8E44AD), Icons.remove_red_eye_rounded); }
    if (n.contains('lip')) { return (const Color(0xFFE91E7A), Icons.face_retouching_natural_rounded); }
    if (n.contains('mask') || n.contains('sheet')) {
      return (const Color(0xFF1ABC9C), Icons.masks_rounded);
    }
    if (n.contains('oil') || n.contains('balm')) {
      return (const Color(0xFFE67E22), Icons.water_rounded);
    }
    return (AppColors.primaryGreenDark, Icons.spa_rounded);
  }

  Widget _buildSoftChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bookmark_added_outlined),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan Hasil',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'Scan ulang jika hasil belum sesuai',
              style: TextStyle(
                color: AppColors.primaryGreenDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResult() async {
    final analysisId = _toInt(analysisData['analysis_id']);
    if (analysisId == null || analysisId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hasil belum tersimpan di database. Silakan ulangi analisis.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final saved = await ApiService.saveAnalysisHistory(analysisId);
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan hasil ke histori. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Berhasil disimpan di Histori!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
  }

  // ─── Helpers ───────────────────────────────────────────

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => item.map((key, val) => MapEntry(key.toString(), val)))
        .toList();
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final n = value.trim().toLowerCase();
      return n == 'true' || n == '1' || n == 'yes';
    }
    return false;
  }

  static bool _isUnknown(Map<String, dynamic> ingredient) {
    final status = _asString(ingredient['status'])?.toLowerCase();
    return status == 'unknown';
  }

  static String _resolveAiText(
    Map<String, dynamic> aiAnalysis,
    String fallbackRecommendation,
  ) {
    String? rawText;
    final modelOutput = _asString(aiAnalysis['model_output']);
    if (modelOutput != null && modelOutput.isNotEmpty) {
      rawText = modelOutput;
    } else {
      final text = _asString(aiAnalysis['text']);
      rawText =
          (text != null && text.isNotEmpty) ? text : fallbackRecommendation;
    }
    return rawText
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'#{1,6}\s*'), '');
  }

  static String _clip(String value, {int maxLen = 100}) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLen) return compact;
    return '${compact.substring(0, maxLen - 3)}...';
  }
}

class _MarkdownSection {
  final String? heading;
  final String body;
  const _MarkdownSection({required this.heading, required this.body});
}

class _DetailItem {
  final String emoji;
  final String text;
  const _DetailItem(this.emoji, this.text);
}

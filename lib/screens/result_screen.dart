import 'dart:io';

import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/services/api_service.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> analysisData;
  final File? imageFile;

  const ResultScreen({super.key, required this.analysisData, this.imageFile});

  @override
  Widget build(BuildContext context) {
    final expertAnalysis = _asMap(analysisData['expert_analysis']);
    final matchedIngredients = _asMapList(analysisData['matched_ingredients']);
    final flags = _asMapList(expertAnalysis['flags']);
    final unknownIngredients = _asStringList(expertAnalysis['unknown_list']);
    final aiAnalysis = _asMap(analysisData['ai_analysis']);

    final warningCount =
        _toInt(expertAnalysis['warnings_found']) ?? flags.length;
    final identifiedCount =
        _toInt(expertAnalysis['total_ingredients_identified']) ??
        matchedIngredients.where((item) => !_isUnknown(item)).length;
    final unknownCount =
        _toInt(expertAnalysis['total_unknown']) ?? unknownIngredients.length;
    final summary =
        _asString(analysisData['summary']) ??
        'Ringkasan analisis belum tersedia.';
    final recommendation =
        _asString(analysisData['recommendation']) ??
        'Belum ada rekomendasi tambahan.';

    final aiText = _resolveAiText(aiAnalysis, recommendation);
    final aiInsightItems = _splitAiInsight(aiText);
    final modelUsed = _asString(aiAnalysis['model']) ?? '-';
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
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageHeader(),
                    const SizedBox(height: 16),
                    _buildOverviewCard(
                      identifiedCount: identifiedCount,
                      warningCount: warningCount,
                      unknownCount: unknownCount,
                    ),
                    const SizedBox(height: 14),
                    _buildSectionCard(
                      title: 'Ringkasan Cepat',
                      icon: Icons.insights,
                      child: Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildSectionCard(
                      title: 'Saran Pemakaian',
                      icon: Icons.health_and_safety,
                      child: Text(
                        recommendation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildIngredientSection(matchedIngredients),
                    const SizedBox(height: 14),
                    _buildFlagSection(flags),
                    if (unknownIngredients.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildUnknownIngredientSection(unknownIngredients),
                    ],
                    const SizedBox(height: 14),
                    _buildAiSection(
                      aiInsightItems: aiInsightItems,
                      aiText: aiText,
                      modelUsed: modelUsed,
                      modelsTried: modelsTried,
                    ),
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
            height: 190,
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
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Analisis berbasis OCR + AI + RAG dataset ingredients',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required int identifiedCount,
    required int warningCount,
    required int unknownCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.16),
            AppColors.cardLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGreenDark.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Berbasis Dataset',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hasil dirangkum dari pencocokan ingredient + insight AI dengan RAG.',
            style: TextStyle(fontSize: 13, color: AppColors.textGray),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricChip(
                icon: Icons.science,
                text: '$identifiedCount bahan dikenali',
              ),
              _buildMetricChip(
                icon: Icons.warning_amber_rounded,
                text: '$warningCount warning',
              ),
              _buildMetricChip(
                icon: Icons.help_outline,
                text: '$unknownCount belum dikenali',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFDDE5DF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreenDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
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
  }) {
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
              Icon(icon, size: 19, color: AppColors.primaryGreenDark),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildIngredientSection(List<Map<String, dynamic>> ingredients) {
    if (ingredients.isEmpty) {
      return _buildSectionCard(
        title: 'Bahan Terdeteksi',
        icon: Icons.list_alt,
        child: const Text(
          'Belum ada bahan yang terdeteksi dari hasil scan.',
          style: TextStyle(fontSize: 14, color: AppColors.textGray),
        ),
      );
    }

    return _buildSectionCard(
      title: 'Bahan Terdeteksi (${ingredients.length})',
      icon: Icons.list_alt,
      child: Column(children: ingredients.map(_buildIngredientTile).toList()),
    );
  }

  Widget _buildIngredientTile(Map<String, dynamic> ingredient) {
    final name = _asString(ingredient['name']) ?? 'Unnamed ingredient';
    final function = _asString(ingredient['function']);
    final description = _asString(ingredient['description']);
    final status = _asString(ingredient['status']) ?? '';
    final comedogenic = _toInt(ingredient['comedogenic_rating']) ?? 0;
    final isAllergen = _toBool(ingredient['is_allergen']);
    final notPregnancySafe = _toBool(ingredient['unsafe_for_pregnancy']);

    final unknown = _isUnknown(ingredient);

    Color tone = AppColors.primaryGreenDark;
    IconData icon = Icons.check_circle_outline;
    String subtitle = 'Cenderung aman pada penggunaan normal.';

    if (unknown) {
      tone = const Color(0xFFB7791F);
      icon = Icons.help_outline;
      subtitle = 'Belum ada kecocokan di dataset.';
    } else if (notPregnancySafe) {
      tone = const Color(0xFFB42318);
      icon = Icons.pregnant_woman;
      subtitle = 'Perlu perhatian khusus untuk ibu hamil.';
    } else if (isAllergen) {
      tone = const Color(0xFFB42318);
      icon = Icons.warning_amber_rounded;
      subtitle = 'Ditandai sebagai potensi alergen/iritan.';
    } else if (comedogenic >= 4) {
      tone = const Color(0xFFB42318);
      icon = Icons.error_outline;
      subtitle = 'Nilai komedogenik tinggi ($comedogenic/5).';
    } else if (comedogenic == 3) {
      tone = const Color(0xFFD97706);
      icon = Icons.error_outline;
      subtitle = 'Nilai komedogenik sedang ($comedogenic/5).';
    }

    final details = <String>[];
    if (status.isNotEmpty && status.toLowerCase() == 'unknown') {
      details.add('Status: unknown');
    }
    if (function != null && function.isNotEmpty) {
      details.add('Fungsi: $function');
    }
    if (description != null && description.isNotEmpty) {
      details.add(_clip(description));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: tone,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...details.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                          height: 1.35,
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
    if (flags.isEmpty) {
      return _buildSectionCard(
        title: 'Perlu Perhatian',
        icon: Icons.warning_amber_rounded,
        child: const Text(
          'Tidak ada warning signifikan terdeteksi dari rule-based analysis.',
          style: TextStyle(fontSize: 14, color: AppColors.textGray),
        ),
      );
    }

    return _buildSectionCard(
      title: 'Perlu Perhatian (${flags.length})',
      icon: Icons.warning_amber_rounded,
      child: Column(
        children: flags.map((flag) {
          final ingredient = _asString(flag['ingredient']) ?? '-';
          final message =
              _asString(flag['message']) ?? 'Warning detail tidak tersedia.';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
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
                  Icons.error_outline,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredient,
                        style: const TextStyle(
                          fontSize: 14,
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
      title: 'Bahan Belum Dikenali',
      icon: Icons.help_center,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: unknownIngredients
            .map(
              (item) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEA),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFF9E19A)),
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A6700),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAiSection({
    required List<String> aiInsightItems,
    required String aiText,
    required String modelUsed,
    required List<String> modelsTried,
  }) {
    return _buildSectionCard(
      title: 'Insight AI + RAG',
      icon: Icons.auto_awesome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSoftChip('Model: $modelUsed'),
              _buildSoftChip('RAG source: ingredientsList.csv'),
              if (modelsTried.isNotEmpty)
                _buildSoftChip('Fallback: ${modelsTried.join(' -> ')}'),
            ],
          ),
          const SizedBox(height: 10),
          if (aiInsightItems.isEmpty)
            const Text(
              'Insight AI belum tersedia.',
              style: TextStyle(fontSize: 14, color: AppColors.textGray),
            )
          else
            ...aiInsightItems
                .take(7)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreenDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 6),
          Theme(
            data: ThemeData(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text(
                'Lihat analisis AI lengkap',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreenDark,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FAF6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    aiText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                      height: 1.45,
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

  Widget _buildSoftChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primaryGreenDark,
          fontWeight: FontWeight.w600,
        ),
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
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final analysisId = _toInt(analysisData['analysis_id']) ?? 0;
                
                // Show loading snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menyimpan hasil ke histori...')),
                );

                if (analysisId > 0) {
                  await ApiService.saveAnalysisHistory(analysisId);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berhasil disimpan di Histori!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Return to main layout and force history refresh (we navigate to route /main which re-inits)
                  Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.bookmark_added_outlined),
              label: const Text(
                'Simpan Hasil',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
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

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => item.map((key, val) => MapEntry(key.toString(), val)))
        .toList();
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) {
      return [];
    }
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
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
    final modelOutput = _asString(aiAnalysis['model_output']);
    if (modelOutput != null && modelOutput.isNotEmpty) {
      return modelOutput;
    }

    final text = _asString(aiAnalysis['text']);
    if (text != null && text.isNotEmpty) {
      return text;
    }

    return fallbackRecommendation;
  }

  static List<String> _splitAiInsight(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    if (normalized.isEmpty) {
      return [];
    }

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final withoutBullet = line
              .replaceFirst(RegExp(r'^[-*]\s*'), '')
              .replaceFirst(RegExp(r'^\d+[\.)]\s*'), '');
          return withoutBullet.trim();
        })
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length <= 1) {
      return normalized
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
    }

    return lines;
  }

  static String _clip(String value, {int maxLen = 100}) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLen) {
      return compact;
    }
    return '${compact.substring(0, maxLen - 3)}...';
  }
}

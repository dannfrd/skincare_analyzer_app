import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/models/ingredient_metric.dart';
import 'package:skincare_analyzer_app/services/api_service.dart';

class IngredientDatabaseScreen extends StatefulWidget {
  const IngredientDatabaseScreen({super.key});

  @override
  State<IngredientDatabaseScreen> createState() => _IngredientDatabaseScreenState();
}

class _IngredientDatabaseScreenState extends State<IngredientDatabaseScreen> {
  List<IngredientMetric> _ingredients = [];
  List<IngredientMetric> _filteredIngredients = [];
  bool _isLoading = true;
  String _errorMessage = "";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchIngredients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final data = await ApiService.getIngredientMetrics(limit: 500);
      setState(() {
        _ingredients = data;
        _filteredIngredients = _filterList(data, _searchQuery);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  List<IngredientMetric> _filterList(List<IngredientMetric> list, String query) {
    if (query.isEmpty) return list;
    return list
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()) || 
                         item.function.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredIngredients = _filterList(_ingredients, query);
    });
  }

  void _showIngredientDetails(IngredientMetric ingredient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IngredientDetailSheet(ingredient: ingredient),
    );
  }

  Widget _buildRiskBadge(String riskLevel) {
    final cleanRisk = riskLevel.trim().toLowerCase();
    Color badgeColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade700;
    String label = "N/A";

    if (cleanRisk == 'high' || cleanRisk == 'tinggi') {
      badgeColor = const Color(0xFFFFEAEA);
      textColor = const Color(0xFFD32F2F);
      label = "High Risk";
    } else if (cleanRisk == 'medium' || cleanRisk == 'sedang' || cleanRisk == 'moderate') {
      badgeColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFE65100);
      label = "Medium Risk";
    } else if (cleanRisk == 'low' || cleanRisk == 'rendah' || cleanRisk == 'safe') {
      badgeColor = const Color(0xFFE8F6EA);
      textColor = const Color(0xFF2E7D32);
      label = "Low Risk";
    } else if (riskLevel.isNotEmpty) {
      label = riskLevel;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Ingredient Database',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: _fetchIngredients,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchIngredients,
        color: AppColors.primaryGreen,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search ingredient...',
                    hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textGray),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged("");
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),


            // Content
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 80,
                  color: AppColors.textGray,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal Terhubung ke Server',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchIngredients,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredIngredients.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 60,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ingredient not found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try searching with other keywords.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = _filteredIngredients[index];
        final cleanRisk = ingredient.riskLevel.trim().toLowerCase();
        
        Color itemColor = AppColors.primaryGreenDark;
        IconData itemIcon = Icons.gpp_good_outlined;
        Color bgColor = AppColors.surfaceGreen;

        if (cleanRisk == 'high' || cleanRisk == 'tinggi') {
          itemColor = const Color(0xFFD32F2F);
          itemIcon = Icons.warning_amber_rounded;
          bgColor = const Color(0xFFFFEAEA);
        } else if (cleanRisk == 'medium' || cleanRisk == 'sedang' || cleanRisk == 'moderate') {
          itemColor = const Color(0xFFE65100);
          itemIcon = Icons.info_outline;
          bgColor = const Color(0xFFFFF3E0);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.cardLight,
          surfaceTintColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
          child: InkWell(
            onTap: () => _showIngredientDetails(ingredient),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      itemIcon,
                      color: itemColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredient.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ingredient.function.isNotEmpty 
                              ? ingredient.function 
                              : '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Risk Badge
                  _buildRiskBadge(ingredient.riskLevel),
                  const SizedBox(width: 8),

                  // Action Arrow
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textGray,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IngredientDetailSheet extends StatelessWidget {
  final IngredientMetric ingredient;

  const _IngredientDetailSheet({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final String description = ingredient.description.trim().isNotEmpty
        ? ingredient.description
        : 'Deskripsi tidak tersedia untuk bahan kandungan ini.';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredient.name,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textGray),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 24, thickness: 1),

          // Body
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Ingredient',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

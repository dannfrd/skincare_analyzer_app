import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:flutter/services.dart';
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/models/skincare_tip.dart';

class SkincareTipsScreen extends StatefulWidget {
  const SkincareTipsScreen({super.key});

  @override
  State<SkincareTipsScreen> createState() => _SkincareTipsScreenState();
}

class _SkincareTipsScreenState extends State<SkincareTipsScreen> {
  String _searchQuery = "";
  String _selectedCategory = "All";
  final TextEditingController _searchController = TextEditingController();

  List<SkincareTip> get _filteredTips {
    return SkincareTip.sampleTips.where((tip) {
      final matchesCategory = _selectedCategory == 'All' || tip.category == _selectedCategory;
      final matchesSearch = tip.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tip.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tip.sections.any((s) => s.content.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredTips;

<<<<<<< HEAD
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Skincare Tips',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search articles or topics...',
                  hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textGray),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Categories Filter Row
          _buildCategorySelector(),
          
          const SizedBox(height: 16),

          // Article List
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final tip = filteredList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildTipCard(tip),
                      );
                    },
                  ),
          ),
        ],
=======
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
        appBar: AppBar(
          title: const Text(
            'Skincare Tips & Guides',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: 19,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search articles or topics...',
                    hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGray),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textGray),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  ),
                ),
              ),
            ),

            // Categories Filter Row
            _buildCategorySelector(),
            
            const SizedBox(height: 16),

            // Article List
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final tip = filteredList[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: _buildTipCard(tip),
                        );
                      },
                    ),
            ),
          ],
        ),
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['All', 'Cleansing', 'Hydration', 'Protection', 'Actives', 'Barrier Care'];
    return SizedBox(
<<<<<<< HEAD
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
=======
      height: 40,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDark,
<<<<<<< HEAD
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
=======
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                }
              },
<<<<<<< HEAD
              selectedColor: AppColors.primaryGreen,
              backgroundColor: AppColors.cardLight,
              checkmarkColor: Colors.white,
=======
              selectedColor: AppColors.primaryGreenDark,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              showCheckmark: false,
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
              elevation: 0,
              pressElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
<<<<<<< HEAD
                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
=======
                  color: isSelected ? Colors.transparent : Colors.black.withValues(alpha: 0.08),
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipCard(SkincareTip tip) {
    return Container(
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
=======
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/tip-detail', arguments: tip);
          },
<<<<<<< HEAD
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
=======
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
            child: Row(
              children: [
                // Cover Image
                ClipRRect(
<<<<<<< HEAD
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    tip.imageUrl,
                    width: 90,
                    height: 90,
=======
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    tip.imageUrl,
                    width: 96,
                    height: 96,
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
<<<<<<< HEAD
                        width: 90,
                        height: 90,
                        color: AppColors.surfaceGreen,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
=======
                        width: 96,
                        height: 96,
                        color: AppColors.surfaceGreen,
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreenDark),
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
<<<<<<< HEAD
                      width: 90,
                      height: 90,
                      color: AppColors.surfaceGreen,
                      child: const Icon(Icons.spa_outlined, color: AppColors.primaryGreen, size: 30),
=======
                      width: 96,
                      height: 96,
                      color: AppColors.surfaceGreen,
                      child: const Icon(Icons.spa_rounded, color: AppColors.primaryGreenDark, size: 32),
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Category Tag and Read Time Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
<<<<<<< HEAD
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGreen,
                              borderRadius: BorderRadius.circular(6),
=======
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGreen,
                              borderRadius: BorderRadius.circular(8),
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                            ),
                            child: Text(
                              tip.category,
                              style: const TextStyle(
<<<<<<< HEAD
                                fontSize: 10,
=======
                                fontSize: 10.5,
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreenDark,
                              ),
                            ),
                          ),
                          Row(
                            children: [
<<<<<<< HEAD
                              const Icon(Icons.access_time, size: 12, color: AppColors.textGray),
                              const SizedBox(width: 4),
                              Text(
                                tip.readTime,
                                style: const TextStyle(fontSize: 10, color: AppColors.textGray),
=======
                              Icon(Icons.access_time_rounded, size: 13, color: AppColors.textGray.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Text(
                                tip.readTime,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGray.withValues(alpha: 0.8)),
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                              ),
                            ],
                          ),
                        ],
                      ),
<<<<<<< HEAD
                      const SizedBox(height: 8),
=======
                      const SizedBox(height: 10),
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                      // Title
                      Text(
                        tip.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
<<<<<<< HEAD
                          fontSize: 14,
=======
                          fontSize: 15,
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Subtitle
                      Text(
                        tip.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
<<<<<<< HEAD
                          fontSize: 12,
=======
                          fontSize: 12.5,
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
<<<<<<< HEAD
                Icons.search_off_outlined,
=======
                Icons.search_off_rounded,
>>>>>>> 24ea4c50eee912499c504bcc9e46bc5c4c05b6ff
                size: 60,
                color: AppColors.primaryGreenDark,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Artikel tidak ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coba cari dengan kata kunci lain atau pilih kategori yang berbeda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

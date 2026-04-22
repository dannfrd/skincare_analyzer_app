import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/services/api_service.dart';
import 'package:skincare_analyzer_app/services/user_session.dart';

// Dummy data model
class ScanHistoryItem {
  final String productName;
  final String brand;
  final String date;
  final String riskLevel; // 'safe', 'moderate', 'high'
  final Color imageColor;
  final IconData imageIcon;

  const ScanHistoryItem({
    required this.productName,
    required this.brand,
    required this.date,
    required this.riskLevel,
    required this.imageColor,
    required this.imageIcon,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
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
        final product = e['product'] ?? {};
        final analysis = e['analyses'] is List && e['analyses'].isNotEmpty ? e['analyses'][0] : {};
        
        // Try to guess risk level based on info or default to safe
        String riskStr = 'safe';
        if (analysis['risk_level'] != null) {
          riskStr = analysis['risk_level'].toString().toLowerCase();
        }

        return ScanHistoryItem(
          productName: product['name'] ?? 'Unknown Product',
          brand: product['brand'] ?? 'Unknown Brand',
          date: e['created_at'] != null 
              ? e['created_at'].toString().split('T')[0] 
              : 'Unknown Date',
          riskLevel: riskStr,
          imageColor: const Color(0xFFD6EAF0),
          imageIcon: Icons.water_drop_outlined,
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
          final tokenStatus = UserSession.token != null ? 'Present' : 'Null';
          _errorMessage = '${e.toString().replaceAll('Exception: ', '')}\n[Debug: Token is $tokenStatus]';
          _isLoading = false;
        });
      }
    }
  }

  List<ScanHistoryItem> get _filteredItems {
    List<ScanHistoryItem> items = _allItems;

    // Apply filter
    if (_selectedFilter == 'Safe') {
      items = items.where((item) => item.riskLevel == 'safe').toList();
    } else if (_selectedFilter == 'Risky') {
      items = items.where((item) => item.riskLevel != 'safe').toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((item) =>
              item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.brand.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // Top App Bar
                  _buildAppBar(),
                  const SizedBox(height: 20),
                  // Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  // Filter Chips
                  _buildFilterChips(),
                ],
              ),
            ),
            // Scrollable list section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                      : _filteredItems.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              itemCount: _filteredItems.length + 1, // +1 for bottom page indicator
                              itemBuilder: (context, index) {
                                if (index == _filteredItems.length) {
                                  return _buildPageIndicator();
                                }
                                return _buildHistoryCard(_filteredItems[index], index);
                              },
                            ),
            ),
          ],
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
            Image.asset(
              'assets/images/logo3_home.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              'Scan History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search your scans...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade400,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Safe', 'Risky'];
    return Row(
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryCard(ScanHistoryItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
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
            onTap: () {
              // TODO: Navigate to detail screen
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Product Image / Thumbnail
                  _buildProductThumbnail(item),
                  const SizedBox(width: 14),
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildRiskBadge(item.riskLevel),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.brand,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.date,
                              style: TextStyle(
                                fontSize: 12,
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
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade300,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(ScanHistoryItem item) {
    final bool isDark = item.imageColor.computeLuminance() < 0.4;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: item.imageColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          item.imageIcon,
          size: 32,
          color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String riskLevel) {
    Color bgColor;
    Color textColor;
    String label;

    switch (riskLevel) {
      case 'safe':
        bgColor = const Color(0xFFE8F6EA);
        textColor = const Color(0xFF2E7D32);
        label = 'SAFE';
        break;
      case 'moderate':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = 'MODERATE\nRISK';
        break;
      case 'high':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        label = 'HIGH\nRISK';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey;
        label = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.3,
          letterSpacing: 0.3,
        ),
      ),
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
            decoration: BoxDecoration(
              color: AppColors.surfaceGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 40,
              color: AppColors.primaryGreenDark,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No scans found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Container(
            width: index == 0 ? 10 : 8,
            height: index == 0 ? 10 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 0
                  ? AppColors.primaryGreen
                  : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }
}

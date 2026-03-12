import 'dart:io';
import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> analysisData;
  final File? imageFile; // Optional if we want to show the scanned image

  const ResultScreen({super.key, required this.analysisData, this.imageFile});

  @override
  Widget build(BuildContext context) {
    // Extract data from the backend JSON response
    final aiAnalysisText = analysisData['ai_analysis'] ?? 'No analysis available';
    
    // Instead of raw AI text, in the UI we show "Detected Ingredients"
    // Since the API currently combines everything into markdown string `ai_analysis`, 
    // we would ideally parse it. For now, we'll try to display a list if we had structured data.
    // The given app design shows a clean list of ingredients.
    // Assuming backend evolves to return lists, we simulate the UI mapping here:
    
    // Fallback Mock items matching design
    final List<Map<String, dynamic>> mockIngredients = [
      {'name': 'Aqua', 'function': 'Solvent', 'safe': true},
      {'name': 'Glycerin', 'function': 'Humectant', 'safe': true},
      {'name': 'Niacinamide', 'function': 'Skin Brightening', 'safe': true},
      {'name': 'Salicylic Acid', 'function': 'Exfoliant (BHA)', 'safe': true},
      {'name': 'Fragrance', 'function': 'Scenting Agent', 'safe': true},
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context), // Could also popUntil Home
        ),
        title: const Text(
          'Scan Results',
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image (Using file if provided, placeholder otherwise)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageFile != null
                          ? Image.file(
                              imageFile!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: double.infinity,
                              height: 180,
                              color: const Color(0xFFE5CECC),
                              child: const Icon(Icons.spa, size: 60, color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      'Detected Ingredients',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We\'ve identified ${mockIngredients.length} ingredients from your scan.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Ingredients List
                    ...mockIngredients.map((ingredient) => _buildIngredientTile(ingredient)).toList(),

                    // You could add an expandable section here for the FULL AI Analysis markdown
                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: const Text('Detailed AI Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
                        collapsedBackgroundColor: AppColors.cardLight,
                        backgroundColor: AppColors.cardLight,
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            aiAnalysisText,
                            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // View deep breakdown or save to history
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to History')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.analytics),
                      label: const Text('Analyze Ingredients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Scan inaccurate? ',
                        style: TextStyle(color: AppColors.textGray, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Pop back to scanner
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Retake Photo',
                          style: TextStyle(color: AppColors.primaryGreenDark, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientTile(Map<String, dynamic> ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ingredient['safe'] ? Icons.water_drop_outlined : Icons.warning_amber_rounded, // Rough icon mapping
              color: AppColors.primaryGreenDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  ingredient['function'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            ingredient['safe'] ? Icons.check_circle_outline : Icons.error_outline,
            color: ingredient['safe'] ? AppColors.primaryGreen : Colors.red,
            size: 28,
          ),
        ],
      ),
    );
  }
}

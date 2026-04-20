import 'dart:io';

import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/screens/result_screen.dart';
import 'package:skincare_analyzer_app/services/api_service.dart';
import 'package:skincare_analyzer_app/services/ocr_service.dart';

class ScanProgressScreen extends StatefulWidget {
  final File imageFile;

  const ScanProgressScreen({super.key, required this.imageFile});

  @override
  State<ScanProgressScreen> createState() => _ScanProgressScreenState();
}

class _ScanProgressScreenState extends State<ScanProgressScreen> {
  int _currentStep = 0;
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    // Stage 1: Fast mock delay for Image Processing
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _currentStep = 1); // Extracting Text

    try {
      // Stage 2: Run OCR locally in Flutter app
      final extractedText = await OcrService.extractText(widget.imageFile);

      if (!mounted) return;
      setState(() => _currentStep = 2); // AI analysis

      // Stage 3: Send extracted text to backend analysis endpoint
      final result = await ApiService.analyzeText(extractedText);

      // Stage 4: Short delay then navigate to results
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResultScreen(analysisData: result, imageFile: widget.imageFile),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
    }
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
          'Scan in Progress',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Page indicators mock
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Active Step Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentStep == 0
                          ? 'Image Processing'
                          : _currentStep == 1
                          ? 'OCR Text Extraction'
                          : 'AI Ingredient Analysis',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentStep == 0
                              ? 'Optimizing image quality...'
                              : _currentStep == 1
                              ? 'Extracting text from image...'
                              : 'Analyzing safely...',
                          style: const TextStyle(
                            color: AppColors.primaryGreenDark,
                            fontSize: 13,
                          ),
                        ),
                        if (_isAnalyzing)
                          const Text(
                            '65%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ), // Mock percentage
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isAnalyzing)
                      LinearProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen,
                        ),
                        backgroundColor: AppColors.secondaryGreen,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Steps List
              Expanded(
                child: Column(
                  children: [
                    _buildStepRow(
                      icon: Icons.check,
                      title: 'Image Processing',
                      subtitle: 'Completed',
                      isActive: _currentStep >= 1,
                      isDone: _currentStep >= 1,
                    ),
                    _buildStepLineContainer(isActive: _currentStep >= 1),
                    _buildStepRow(
                      icon: Icons.sync,
                      title: 'OCR Text Extraction',
                      subtitle: _currentStep >= 2
                          ? 'Completed'
                          : (_currentStep == 1 ? 'In Progress' : 'Upcoming'),
                      isActive: _currentStep >= 1,
                      isDone: _currentStep >= 2,
                    ),
                    _buildStepLineContainer(isActive: _currentStep >= 2),
                    _buildStepRow(
                      icon: Icons.more_horiz,
                      title: 'AI Ingredient Analysis',
                      subtitle: _currentStep == 2 ? 'In Progress' : 'Upcoming',
                      isActive: _currentStep >= 2,
                      isDone: false,
                    ),
                  ],
                ),
              ),

              // Bottom status text
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppColors.primaryGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Analyzing ingredients using\nAI...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Our neural network is identifying potential allergens and nutritional components.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // In a real app, cancel the API request token
                    Navigator.pop(context);
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
                  child: const Text(
                    'Cancel Processing',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isDone,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.primaryGreen
                : (isActive ? Colors.white : AppColors.backgroundLight),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone
                  ? AppColors.primaryGreen
                  : (isActive ? AppColors.primaryGreen : Colors.grey.shade300),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDone
                ? Colors.white
                : (isActive ? AppColors.primaryGreen : Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.textDark : Colors.grey.shade400,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDone
                    ? AppColors.primaryGreenDark
                    : (isActive
                          ? AppColors.primaryGreen
                          : Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepLineContainer({required bool isActive}) {
    return Container(
      height: 30,
      margin: const EdgeInsets.only(left: 20),
      alignment: Alignment.centerLeft,
      child: Container(
        width: 2,
        color: isActive ? AppColors.primaryGreen : Colors.grey.shade300,
      ),
    );
  }
}

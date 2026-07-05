import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/models/skincare_tip.dart';

class TipDetailScreen extends StatelessWidget {
  const TipDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tip = ModalRoute.of(context)!.settings.arguments as SkincareTip;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium Sliver App Bar with header image
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primaryGreenDark,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    tip.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceGreen,
                      child: const Icon(Icons.spa, color: AppColors.primaryGreen, size: 64),
                    ),
                  ),
                  // Gradient overlay to darken image slightly at bottom
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Article Content
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.backgroundLight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and Read Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tip.category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreenDark,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: AppColors.textGray),
                            const SizedBox(width: 4),
                            Text(
                              tip.readTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      tip.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: AppColors.textDark,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle / Intro
                    Text(
                      tip.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textGray.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 20),
                    
                    // Content Sections
                    ...tip.sections.map((section) => _buildSection(section)),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(SkincareTipSection section) {
    if (section.isHighlight) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceGreen,
            borderRadius: BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(
                color: AppColors.primaryGreenDark,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    color: AppColors.primaryGreenDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreenDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                section.content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

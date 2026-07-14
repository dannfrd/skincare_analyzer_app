import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/models/skincare_tip.dart';

class TipDetailScreen extends StatelessWidget {
  const TipDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tip = ModalRoute.of(context)!.settings.arguments as SkincareTip;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium Sliver App Bar with header image
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.primaryGreenDark,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
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
                        child: const Icon(Icons.spa_rounded, color: AppColors.primaryGreenDark, size: 64),
                      ),
                    ),
                    // Gradient overlay to darken image slightly at bottom
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.0, 0.4, 1.0],
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
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category and Read Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGreen,
                              borderRadius: BorderRadius.circular(10),
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
                              Icon(Icons.access_time_rounded, size: 15, color: AppColors.textGray.withValues(alpha: 0.85)),
                              const SizedBox(width: 5),
                              Text(
                                tip.readTime,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textGray.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 18),
                      
                      // Title
                      Text(
                        tip.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Subtitle / Intro
                      Text(
                        tip.subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textGray.withValues(alpha: 0.95),
                          height: 1.45,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 24),
                      
                      // Content Sections
                      ...tip.sections.map((section) => _buildSection(section)),
                      
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(SkincareTipSection section) {
    if (section.isHighlight) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceGreen,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              left: BorderSide(
                color: AppColors.primaryGreenDark,
                width: 4.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_rounded,
                    color: AppColors.primaryGreenDark,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreenDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                section.content,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.content,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

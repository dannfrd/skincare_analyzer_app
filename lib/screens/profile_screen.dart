import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/services/api_service.dart';
import 'package:skincare_analyzer_app/services/fcm_service.dart';
import 'package:skincare_analyzer_app/services/user_session.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;

  const ProfileScreen({super.key, this.onNavigateToHistory});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalScans = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTotalScans();
  }

  Future<void> _fetchTotalScans() async {
    try {
      final history = await ApiService.getHistory();
      if (mounted) {
        setState(() {
          _totalScans = history.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assuming UserSession has been loaded during splash screen
    final String userName = UserSession.userName ?? 'User';
    final String userEmail = UserSession.userEmail ?? 'No email';

    // ignore: avoid_print
    print('DEBUG: ProfileScreen build. userProfilePic = ${UserSession.userProfilePic}');

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
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // ── Top App Bar ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen
                                      .withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo3_home.png',
                              width: 36,
                              height: 36,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Dermify',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryGreenDark,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Skincare Analyzer',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textGray.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Notification icon dengan badge unread count
                      ValueListenableBuilder<List<FcmNotification>>(
                        valueListenable: FcmService.instance.notifications,
                        builder: (context, notifications, _) {
                          final unread = FcmService.instance.unreadCount;
                          return GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/notifications'),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryGreen
                                          .withValues(alpha: 0.3),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: AppColors.primaryGreenDark,
                                    size: 22,
                                  ),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF5252),
                                            Color(0xFFD50000)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red
                                                .withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Profile Avatar ───────────────────────────────────
                  Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondaryGreen,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.18),
                              blurRadius: 22,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: UserSession.userProfilePic != null
                              ? (UserSession.userProfilePic!.startsWith('http')
                                  ? NetworkImage(UserSession.userProfilePic!)
                                  : (UserSession.userProfilePic!.startsWith('/uploads/')
                                      ? NetworkImage('${ApiService.baseUrl}${UserSession.userProfilePic}')
                                      : FileImage(File(UserSession.userProfilePic!)))) as ImageProvider?
                              : null,
                          child: UserSession.userProfilePic == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: Colors.grey.shade500,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () async {
                            final res = await Navigator.pushNamed(context, '/edit-profile');
                            if (res == true && mounted) {
                              setState(() {});
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User Name & Email
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreenDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ── Total Scans Stats Card ───────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surfaceGreen,
                          const Color(0xFFD3F1DC).withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Icon(
                            Icons.auto_graph_rounded,
                            size: 65,
                            color: AppColors.primaryGreen.withValues(alpha: 0.15),
                          ),
                        ),
                        Center(
                          child: Column(
                            children: [
                              _isLoading
                                  ? const SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.primaryGreenDark,
                                      ),
                                    )
                                  : Text(
                                      '$_totalScans',
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryGreenDark,
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              const Text(
                                'TOTAL SCANS COMPLETED',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGreenDark,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Account Settings Section ─────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        'ACCOUNT SETTINGS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textGray.withValues(alpha: 0.85),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Settings Menu Items
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.04),
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
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profile',
                          onTap: () async {
                            final res = await Navigator.pushNamed(context, '/edit-profile');
                            if (res == true && mounted) {
                              setState(() {});
                            }
                          },
                        ),
                        Divider(height: 1, indent: 64, color: Colors.grey.shade100),
                        _buildMenuItem(
                          icon: Icons.history_rounded,
                          title: 'Scan History',
                          onTap: () {
                            if (widget.onNavigateToHistory != null) {
                              widget.onNavigateToHistory!();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.04),
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
                    child: _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(
                              'Confirm Logout',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text('Are you sure you want to log out from your account?'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel', style: TextStyle(color: AppColors.textGray, fontWeight: FontWeight.bold)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        await UserSession.clearSession();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        }
                      },
                      iconColor: Colors.redAccent,
                      textColor: Colors.redAccent,
                      showChevron: false,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primaryGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primaryGreenDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? AppColors.textDark,
                  ),
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/services/permission_service.dart';
import 'package:skincare_analyzer_app/services/user_session.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  bool _isRequesting = false;
  Map<Permission, PermissionStatus> _statuses = {};

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _permissions = [
    _PermissionItem(
      permission: Permission.camera,
      icon: Icons.camera_alt_rounded,
      title: 'Kamera',
      description: 'Untuk memfoto label bahan produk skincare secara langsung.',
      color: const Color(0xFF4CB35B),
      bgColor: const Color(0xFFE8F6EA),
      required: true,
    ),
    _PermissionItem(
      permission: Permission.photos,
      icon: Icons.photo_library_rounded,
      title: 'Galeri / Foto',
      description: 'Untuk memilih foto produk dari galeri perangkat Anda.',
      color: const Color(0xFF4A6FA5),
      bgColor: const Color(0xFFE8F0FB),
      required: true,
    ),
    _PermissionItem(
      permission: Permission.notification,
      icon: Icons.notifications_active_rounded,
      title: 'Notifikasi',
      description: 'Untuk mengirim pembaruan analisis dan tips skincare.',
      color: const Color(0xFFD97706),
      bgColor: const Color(0xFFFFF8E1),
      required: false,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();

    _loadCurrentStatuses();
  }

  Future<void> _loadCurrentStatuses() async {
    final statuses = await PermissionService.currentStatuses();
    if (mounted) setState(() => _statuses = statuses);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    setState(() => _isRequesting = true);

    final statuses = await PermissionService.requestAll();
    if (mounted) {
      setState(() {
        _statuses = statuses;
        _isRequesting = false;
      });
    }

    // Check if essential permissions granted
    final granted = await PermissionService.areEssentialGranted();
    if (!mounted) return;

    if (granted) {
      _navigateNext();
    } else {
      _showDeniedDialog();
    }
  }

  void _navigateNext() {
    final route =
        UserSession.isLoggedIn ? '/main' : '/login';
    Navigator.pushReplacementNamed(context, route);
  }

  void _showDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text(
              'Izin Diperlukan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Kamera dan Galeri diperlukan untuk memindai produk skincare. '
          'Buka pengaturan untuk mengaktifkan izin secara manual.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateNext(); // Skip — let user proceed with limited features
            },
            child: const Text('Lewati', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await PermissionService.openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  PermissionStatus? _statusOf(Permission p) => _statuses[p];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ── Header ──────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryGreen,
                            AppColors.primaryGreenDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreenDark.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Center(
                    child: Text(
                      'Izin Aplikasi',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Dermify memerlukan beberapa izin\nuntuk berfungsi dengan optimal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppColors.textGray,
                        height: 1.55,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Permission Cards ────────────────────────────────────
                  Expanded(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _permissions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final item = _permissions[i];
                        final status = _statusOf(item.permission);
                        return _PermissionCard(
                          item: item,
                          status: status,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Privacy note ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 15, color: AppColors.primaryGreenDark),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Data Anda aman. Izin hanya digunakan untuk fungsionalitas aplikasi dan tidak dibagikan ke pihak ketiga.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.primaryGreenDark,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── CTA Button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreenDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primaryGreenDark.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Izinkan & Lanjutkan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),

                  // Skip button
                  TextButton(
                    onPressed: _isRequesting
                        ? null
                        : () async {
                            await PermissionService.markRequested();
                            _navigateNext();
                          },
                    child: const Text(
                      'Lewati untuk sekarang',
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Permission Item Model ───────────────────────────────────────────────────

class _PermissionItem {
  final Permission permission;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color bgColor;
  final bool required;

  const _PermissionItem({
    required this.permission,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.required,
  });
}

// ─── Permission Card Widget ──────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  final _PermissionItem item;
  final PermissionStatus? status;

  const _PermissionCard({required this.item, this.status});

  @override
  Widget build(BuildContext context) {
    final isGranted = status?.isGranted ?? false;
    final isDenied = status?.isPermanentlyDenied ?? false;

    Widget? badge;
    if (isGranted) {
      badge = _StatusBadge(
        label: 'Diizinkan',
        color: const Color(0xFF4CB35B),
        icon: Icons.check_circle_rounded,
      );
    } else if (isDenied) {
      badge = _StatusBadge(
        label: 'Ditolak',
        color: const Color(0xFFB42318),
        icon: Icons.cancel_rounded,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF4CB35B).withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (item.required)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Wajib',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFFB42318),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (badge != null) badge,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textGray,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

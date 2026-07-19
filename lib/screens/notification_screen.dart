import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/services/fcm_service.dart';

// ─────────────────────────────────────────────────────────────
// Notification Screen — UI/UX Modern & Premium
// Menggunakan data FCM real tanpa mengubah alur logika fungsi
// ─────────────────────────────────────────────────────────────
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();

    // Dengarkan perubahan list notifikasi dari FCM service
    FcmService.instance.notifications.addListener(_onNotificationsChanged);
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FcmService.instance.notifications.removeListener(_onNotificationsChanged);
    _fadeController.dispose();
    super.dispose();
  }

  List<FcmNotification> get _notifications =>
      FcmService.instance.notifications.value;
  int get _unreadCount => FcmService.instance.unreadCount;

  // ── Helpers ─────────────────────────────────────────────────
  String _formatTimestamp(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${ts.day}/${ts.month}/${ts.year}';
  }

  // ── Warna & Kategori Badge ──────────────────────────────────
  Color _getBadgeColor(FcmNotification n) {
    final title = n.title.toLowerCase();
    if (title.contains('scan') || title.contains('selesai')) {
      return AppColors.primaryGreenDark;
    }
    if (title.contains('tip') || title.contains('perawatan')) {
      return const Color(0xFFF59E0B);
    }
    if (title.contains('ingat') || title.contains('reminder')) {
      return const Color(0xFF3B82F6);
    }
    return AppColors.primaryGreenDark; // update / lainnya → hijau utama
  }

  Color _getBadgeBg(FcmNotification n) {
    final title = n.title.toLowerCase();
    if (title.contains('scan') || title.contains('selesai')) {
      return AppColors.surfaceGreen;
    }
    if (title.contains('tip') || title.contains('perawatan')) {
      return const Color(0xFFFEF3C7);
    }
    if (title.contains('ingat') || title.contains('reminder')) {
      return const Color(0xFFEFF6FF);
    }
    return AppColors.surfaceGreen; // update / lainnya → hijau utama
  }

  IconData _getIcon(FcmNotification n) {
    final title = n.title.toLowerCase();
    if (title.contains('scan') || title.contains('selesai')) {
      return Icons.document_scanner_rounded;
    }
    if (title.contains('tip') || title.contains('perawatan')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (title.contains('ingat') || title.contains('reminder')) {
      return Icons.alarm_rounded;
    }
    return Icons.notifications_outlined;
  }

  String _getCategoryLabel(FcmNotification n) {
    final title = n.title.toLowerCase();
    if (title.contains('scan') || title.contains('selesai')) {
      return 'Scan Result';
    }
    if (title.contains('tip') || title.contains('perawatan')) {
      return 'Skincare Tips';
    }
    if (title.contains('ingat') || title.contains('reminder')) {
      return 'Reminder';
    }
    return 'Update';
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _notifications.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    if (_unreadCount > 0) _buildUnreadBanner(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 20),
                        itemCount: _notifications.length,
                        itemBuilder: (ctx, i) => _buildCard(_notifications[i], i),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Colors.black.withValues(alpha: 0.06),
          height: 1.0,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppColors.textDark,
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          const Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          if (_notifications.isNotEmpty)
            Text(
              '${_notifications.length} total pembaruan',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textGray.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        if (_notifications.isNotEmpty)
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textDark, size: 20),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            offset: const Offset(0, 45),
            onSelected: (value) async {
              if (value == 'read_all') {
                await FcmService.instance.markAllAsRead();
              } else if (value == 'clear_all') {
                _showClearDialog();
              }
            },
            itemBuilder: (_) => [
              if (_unreadCount > 0)
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded,
                          size: 20, color: AppColors.primaryGreenDark),
                      SizedBox(width: 12),
                      Text(
                        'Tandai semua dibaca',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded,
                        size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Hapus semua',
                      style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.red,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Unread banner modern ─────────────────────────────────────
  Widget _buildUnreadBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceGreen,
            const Color(0xFFD9F4DF).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreenDark.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_unreadCount Notifikasi Baru',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Ketuk untuk membaca detail',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textGray.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => FcmService.instance.markAllAsRead(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryGreenDark,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreenDark.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.done_all_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Baca Semua',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state modern ───────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceGreen,
                    AppColors.surfaceGreen.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.25),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: AppColors.primaryGreenDark.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Kotak Notifikasi Bersih!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Semua pembaruan, hasil scan, dan tips\nperawatan kulit dari Dermify akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notification card modern ─────────────────────────────────
  Widget _buildCard(FcmNotification n, int index) {
    final badgeColor = _getBadgeColor(n);
    final badgeBg = _getBadgeBg(n);
    final categoryLabel = _getCategoryLabel(n);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 60).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Dismissible(
        key: Key(n.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => FcmService.instance.deleteNotification(n.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Hapus',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () => FcmService.instance.markAsRead(n.id),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: n.isRead ? Colors.white : const Color(0xFFF2FAF3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: n.isRead
                    ? Colors.black.withValues(alpha: 0.05)
                    : AppColors.primaryGreen.withValues(alpha: 0.45),
                width: n.isRead ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: n.isRead
                      ? Colors.black.withValues(alpha: 0.03)
                      : AppColors.primaryGreen.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: BoxDecoration(
                  border: !n.isRead
                      ? Border(
                          left: BorderSide(color: badgeColor, width: 4.5),
                        )
                      : null,
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            badgeBg,
                            badgeBg.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getIcon(n),
                        color: badgeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category tag + Timestamp
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: badgeBg.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  categoryLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: AppColors.textGray.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimestamp(n.receivedAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGray.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Title & Unread indicator dot
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: n.isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                    color: AppColors.textDark,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              if (!n.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: badgeColor.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Body
                          Text(
                            n.body,
                            style: TextStyle(
                              fontSize: 13,
                              color: n.isRead
                                  ? AppColors.textGray
                                  : AppColors.textDark.withValues(alpha: 0.85),
                              height: 1.45,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Mark as read action prompt if unread
                          if (!n.isRead) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () =>
                                        FcmService.instance.markAsRead(n.id),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 14,
                                            color: badgeColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Tandai dibaca',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: badgeColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Confirm clear all dialog ─────────────────────────────────
  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Hapus Semua?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Semua riwayat notifikasi Anda akan dihapus secara permanen dari perangkat ini.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Batal',
                style: TextStyle(
                    color: AppColors.textGray, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FcmService.instance.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus Semua',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

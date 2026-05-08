import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/services/fcm_service.dart';

// ─────────────────────────────────────────────────────────────
// Notification Screen — menggunakan data FCM real
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
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${ts.day}/${ts.month}/${ts.year}';
  }

  // ── Warna badge ──────────────────────────────────────────────
  Color _getBadgeColor(FcmNotification n) {
    final title = n.title.toLowerCase();
    if (title.contains('scan') || title.contains('selesai')) {
      return AppColors.primaryGreen;
    }
    if (title.contains('tip') || title.contains('perawatan')) {
      return const Color(0xFFFFA726);
    }
    if (title.contains('ingat') || title.contains('reminder')) {
      return const Color(0xFF42A5F5);
    }
    return const Color(0xFFAB47BC); // update / lainnya
  }

  Color _getBadgeBg(FcmNotification n) {
    final title = n.title.toLowerCase();
    if (title.contains('scan') || title.contains('selesai')) {
      return AppColors.surfaceGreen;
    }
    if (title.contains('tip') || title.contains('perawatan')) {
      return const Color(0xFFFFF3E0);
    }
    if (title.contains('ingat') || title.contains('reminder')) {
      return const Color(0xFFE3F2FD);
    }
    return const Color(0xFFF3E5F5);
  }

  IconData _getIcon(FcmNotification n) {
    final title = n.title.toLowerCase();
    if (title.contains('scan') || title.contains('selesai')) {
      return Icons.document_scanner;
    }
    if (title.contains('tip') || title.contains('perawatan')) {
      return Icons.lightbulb_outline;
    }
    if (title.contains('ingat') || title.contains('reminder')) {
      return Icons.alarm;
    }
    return Icons.notifications_outlined;
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _notifications.length,
                      itemBuilder: (ctx, i) =>
                          _buildCard(_notifications[i]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: AppColors.textDark,
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Notifikasi',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_notifications.isNotEmpty)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textDark),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      Icon(Icons.done_all, size: 18,
                          color: AppColors.primaryGreenDark),
                      SizedBox(width: 10),
                      Text('Tandai semua dibaca'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Hapus semua',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Unread banner ────────────────────────────────────────────
  Widget _buildUnreadBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.surfaceGreen,
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'notifikasi belum dibaca',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primaryGreenDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => FcmService.instance.markAllAsRead(),
            child: const Text(
              'Baca Semua',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 52,
              color: AppColors.primaryGreen.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi dari Dermify akan muncul di sini',
            style: TextStyle(fontSize: 14, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  // ── Notification card ────────────────────────────────────────
  Widget _buildCard(FcmNotification n) {
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => FcmService.instance.deleteNotification(n.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () => FcmService.instance.markAsRead(n.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.isRead
                ? Colors.white
                : AppColors.surfaceGreen.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: !n.isRead
                ? Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.35), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getBadgeBg(n),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(n),
                  color: _getBadgeColor(n),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined,
                            size: 11,
                            color: AppColors.textGray.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(n.receivedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textGray.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!n.isRead) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                FcmService.instance.markAsRead(n.id),
                            child: const Text(
                              'Tandai dibaca',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryGreenDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus semua notifikasi?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Semua notifikasi akan dihapus secara permanen.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FcmService.instance.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

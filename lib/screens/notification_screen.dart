import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';

// --- Notification Model ---
enum NotificationType { scanComplete, tip, reminder, update }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

// --- Dummy Data ---
List<NotificationItem> generateDummyNotifications() {
  final now = DateTime.now();
  return [
    NotificationItem(
      id: '1',
      title: 'Scan Selesai',
      message: 'Analisis untuk "CeraVe Moisturizing Cream" telah selesai. Lihat hasilnya sekarang!',
      type: NotificationType.scanComplete,
      timestamp: now.subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Tips Perawatan Kulit',
      message: 'Tahukah kamu? Niacinamide dapat membantu memperbaiki tekstur kulit dan menyamarkan pori-pori.',
      type: NotificationType.tip,
      timestamp: now.subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Pengingat Rutinitas',
      message: 'Jangan lupa aplikasikan sunscreen sebelum keluar rumah hari ini! ☀️',
      type: NotificationType.reminder,
      timestamp: now.subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Scan Selesai',
      message: 'Analisis untuk "The Ordinary Hyaluronic Acid" telah selesai. Skor keamanan: 92/100.',
      type: NotificationType.scanComplete,
      timestamp: now.subtract(const Duration(hours: 6)),
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: 'Update Aplikasi',
      message: 'Dermify v2.1 tersedia! Fitur baru: deteksi alergen dan rekomendasi produk pengganti.',
      type: NotificationType.update,
      timestamp: now.subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationItem(
      id: '6',
      title: 'Tips Perawatan Kulit',
      message: 'Retinol sebaiknya digunakan pada malam hari dan selalu diikuti dengan moisturizer.',
      type: NotificationType.tip,
      timestamp: now.subtract(const Duration(days: 1, hours: 5)),
      isRead: true,
    ),
    NotificationItem(
      id: '7',
      title: 'Scan Selesai',
      message: 'Analisis untuk "Somethinc Niacinamide Serum" telah selesai. Ditemukan 3 bahan aktif utama.',
      type: NotificationType.scanComplete,
      timestamp: now.subtract(const Duration(days: 2)),
      isRead: true,
    ),
    NotificationItem(
      id: '8',
      title: 'Pengingat Rutinitas',
      message: 'Sudah waktunya mengganti sunscreen kamu. Produk sunscreen terbuka sebaiknya diganti setiap 6 bulan.',
      type: NotificationType.reminder,
      timestamp: now.subtract(const Duration(days: 3)),
      isRead: true,
    ),
    NotificationItem(
      id: '9',
      title: 'Tips Perawatan Kulit',
      message: 'Hindari mencampurkan Vitamin C dan AHA/BHA dalam satu waktu pemakaian untuk menghindari iritasi.',
      type: NotificationType.tip,
      timestamp: now.subtract(const Duration(days: 5)),
      isRead: true,
    ),
  ];
}

// --- Notification Screen ---
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = generateDummyNotifications();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.scanComplete:
        return Icons.document_scanner;
      case NotificationType.tip:
        return Icons.lightbulb_outline;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.update:
        return Icons.system_update;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.scanComplete:
        return AppColors.primaryGreen;
      case NotificationType.tip:
        return const Color(0xFFFFA726);
      case NotificationType.reminder:
        return const Color(0xFF42A5F5);
      case NotificationType.update:
        return const Color(0xFFAB47BC);
    }
  }

  Color _getIconBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.scanComplete:
        return AppColors.surfaceGreen;
      case NotificationType.tip:
        return const Color(0xFFFFF3E0);
      case NotificationType.reminder:
        return const Color(0xFFE3F2FD);
      case NotificationType.update:
        return const Color(0xFFF3E5F5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
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
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Baca Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreenDark,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Unread count badge
                if (_unreadCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: AppColors.surfaceGreen,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      ],
                    ),
                  ),
                // Notification list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.primaryGreen.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua notifikasi kamu akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification.id),
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
        onTap: () => _markAsRead(notification.id),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.cardLight
                : AppColors.surfaceGreen.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: !notification.isRead
                ? Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                  color: _getIconBgColor(notification.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(notification.type),
                  color: _getIconColor(notification.type),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
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
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGray.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
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
}

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// Top-level background message handler (harus di luar class)
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Simpan notifikasi ke SharedPreferences agar bisa ditampilkan di in-app list
  await FcmService._saveNotificationToPrefs(message);
}

// ─────────────────────────────────────────────────────────────
// Model notifikasi FCM yang disimpan secara lokal
// ─────────────────────────────────────────────────────────────
class FcmNotification {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  bool isRead;

  FcmNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'isRead': isRead,
      };

  factory FcmNotification.fromJson(Map<String, dynamic> json) =>
      FcmNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        receivedAt: DateTime.parse(json['receivedAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );

  factory FcmNotification.fromRemoteMessage(RemoteMessage message) =>
      FcmNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Notifikasi Baru',
        body: message.notification?.body ?? '',
        receivedAt: message.sentTime ?? DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────
// FCM Service
// ─────────────────────────────────────────────────────────────
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static const String _prefKey = 'fcm_notifications';
  static const String _fcmTopic = 'all'; // Harus sama dengan backend

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // Notifier agar UI bisa update otomatis saat ada notif baru
  final ValueNotifier<List<FcmNotification>> notifications =
      ValueNotifier<List<FcmNotification>>([]);

  // ── Channel ID Android ──────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'dermify_high_importance', // id
    'Dermify Notifications', // name
    description: 'Notifikasi dari Dermify Skincare Analyzer',
    importance: Importance.high,
    playSound: true,
  );

  // ── Inisialisasi utama ──────────────────────────────────────
  Future<void> init() async {
    // 1. Setup flutter_local_notifications
    await _setupLocalNotifications();

    // 2. Minta izin notifikasi dari user
    await _requestPermission();

    // 3. Subscribe ke topic 'all' (sesuai backend)
    await _fcm.subscribeToTopic(_fcmTopic);

    // 4. Load notifikasi yang sudah tersimpan
    await _loadFromPrefs();

    // 5. Handle notifikasi saat app di FOREGROUND
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6. Handle tap notifikasi saat app di BACKGROUND (bukan terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 7. Handle notifikasi saat app TERMINATED lalu dibuka dari notif
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      await _saveAndRefresh(initialMessage);
    }

    // 8. Print FCM token (berguna untuk testing kirim ke device tertentu)
    final token = await _fcm.getToken();
    debugPrint('📲 FCM Token: $token');
  }

  // ── Setup local notifications ───────────────────────────────
  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Bisa navigasi ke halaman notifikasi jika perlu
        debugPrint('Local notification tapped: ${details.payload}');
      },
    );

    // Buat channel high importance di Android
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // ── Request permission ──────────────────────────────────────
  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint(
        '🔔 FCM Permission status: ${settings.authorizationStatus}');
  }

  // ── Foreground message handler ──────────────────────────────
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('📩 Foreground FCM: ${message.notification?.title}');

    // Tampilkan local notification di status bar
    await _showLocalNotification(message);

    // Simpan ke list & prefs
    await _saveAndRefresh(message);
  }

  // ── Background app opened from notification ─────────────────
  Future<void> _onMessageOpenedApp(RemoteMessage message) async {
    debugPrint('📨 App opened from notification: ${message.notification?.title}');
    await _saveAndRefresh(message);
  }

  // ── Tampilkan local notification ────────────────────────────
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF68D377), // primaryGreen
          styleInformation: BigTextStyleInformation(notification.body ?? ''),
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Simpan notifikasi ke prefs & refresh list ───────────────
  Future<void> _saveAndRefresh(RemoteMessage message) async {
    await _saveNotificationToPrefs(message);
    await _loadFromPrefs();
  }

  // ── Static helper: simpan ke SharedPreferences ──────────────
  // (static agar bisa dipanggil dari background handler top-level)
  static Future<void> _saveNotificationToPrefs(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefKey) ?? [];
      final notif = FcmNotification.fromRemoteMessage(message);
      raw.insert(0, jsonEncode(notif.toJson())); // terbaru di atas
      // Batasi maksimal 50 notifikasi
      if (raw.length > 50) raw.removeLast();
      await prefs.setStringList(_prefKey, raw);
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  // ── Load dari SharedPreferences ─────────────────────────────
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefKey) ?? [];
      notifications.value = raw
          .map((s) => FcmNotification.fromJson(
              jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  // ── Mark as read ────────────────────────────────────────────
  Future<void> markAsRead(String id) async {
    final updated = notifications.value.map((n) {
      if (n.id == id) {
        return FcmNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          receivedAt: n.receivedAt,
          isRead: true,
        );
      }
      return n;
    }).toList();
    await _persistList(updated);
  }

  // ── Mark all as read ────────────────────────────────────────
  Future<void> markAllAsRead() async {
    final updated = notifications.value.map((n) => FcmNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          receivedAt: n.receivedAt,
          isRead: true,
        )).toList();
    await _persistList(updated);
  }

  // ── Delete satu notifikasi ──────────────────────────────────
  Future<void> deleteNotification(String id) async {
    final updated =
        notifications.value.where((n) => n.id != id).toList();
    await _persistList(updated);
  }

  // ── Clear semua ─────────────────────────────────────────────
  Future<void> clearAll() async {
    await _persistList([]);
  }

  // ── Simpan list ke prefs ────────────────────────────────────
  Future<void> _persistList(List<FcmNotification> list) async {
    notifications.value = list;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefKey, list.map((n) => jsonEncode(n.toJson())).toList());
  }

  // ── Getter unread count ─────────────────────────────────────
  int get unreadCount =>
      notifications.value.where((n) => !n.isRead).length;

  // ── Dapatkan FCM Token (untuk kirim ke device tertentu) ──────
  Future<String?> getToken() => _fcm.getToken();
}

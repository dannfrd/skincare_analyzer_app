import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'user_session.dart';

class AuthService {
  static bool _isGoogleLoginInProgress = false;
  static bool _isGoogleSignInInitialized = false;

  static Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) {
      return;
    }

    await GoogleSignIn.instance.initialize();
    _isGoogleSignInInitialized = true;
  }

  static Future<UserCredential> _authenticateWithGoogleFirebase() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      return FirebaseAuth.instance.signInWithPopup(googleProvider);
    }

    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate(scopeHint: const <String>['email', 'profile']);

    final String? googleIdToken = googleUser.authentication.idToken;
    if (googleIdToken == null || googleIdToken.isEmpty) {
      throw Exception('Google Sign-In tidak mengembalikan ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// Melakukan proses login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Berhasil login (misalnya menerima token dan/atau data user)
        await UserSession.saveSession(data);
        return data;
      } else {
        throw Exception(
          data['detail'] ?? data['message'] ?? 'Gagal melakukan login',
        );
      }
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Pastikan backend aktif.',
      );
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception(
          'Koneksi terputus. Pastikan internet aktif dan backend berjalan.',
        );
      }
      if (e.toString().contains('Exception:')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception('Terjadi kesalahan saat login: $e');
    }
  }

  /// Melakukan proses registrasi manual
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'provider': 'manual',
        }),
      );

      final data = jsonDecode(response.body);

      // Status 200 (OK) atau 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        await UserSession.saveSession(data);
        return data;
      } else {
        throw Exception(
          data['detail'] ?? data['message'] ?? 'Gagal membuat akun',
        );
      }
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Pastikan backend aktif.',
      );
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception(
          'Koneksi terputus. Pastikan internet aktif dan backend berjalan.',
        );
      }
      if (e.toString().contains('Exception:')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception('Terjadi kesalahan saat mendaftar: $e');
    }
  }

  /// Melakukan proses login dengan Google Sign-In via Firebase Auth
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    if (_isGoogleLoginInProgress) {
      throw Exception(
        'Proses login Google masih berjalan. Silakan tunggu sebentar.',
      );
    }

    _isGoogleLoginInProgress = true;

    try {
      // 1. Login Google (native di mobile, popup di web), lalu autentikasi Firebase.
      final UserCredential userCredential =
          await _authenticateWithGoogleFirebase();

      // 2. Jika user membatalkan, userCredential.user akan null.
      if (userCredential.user == null) {
        throw Exception('Login Google dibatalkan oleh pengguna.');
      }

      // 3. Dapatkan Firebase ID Token terbaru untuk dikirim ke backend.
      final String? firebaseToken = await userCredential.user!.getIdToken(true);

      if (firebaseToken == null) {
        throw Exception('Gagal mendapatkan token kredensial Firebase.');
      }

      // 4. Kirim id_token ke backend dalam JSON body (lebih aman daripada query string).
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id_token': firebaseToken}),
      );

      final data = jsonDecode(response.body);

      // 5. Tangkap token JWT dari backend dan data User.
      if (response.statusCode == 200 || response.statusCode == 201) {
        await UserSession.saveSession(data);
        return data;
      } else {
        throw Exception(
          data['detail'] ?? data['message'] ?? 'Login Google gagal',
        );
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw Exception('Login Google dibatalkan oleh pengguna.');
      }

      final description = (e.description ?? '').toLowerCase();
      if (description.contains('sha-1') ||
          description.contains('sha-256') ||
          description.contains('certificate')) {
        throw Exception(
          'Login Google gagal karena SHA/certificate hash Android belum cocok dengan Firebase. '
          'Tambahkan SHA-1 dan SHA-256 dari debug ke Firebase Console, lalu unduh ulang google-services.json.',
        );
      }

      throw Exception('Gagal autentikasi Google: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      final message = (e.message ?? '').toLowerCase();
      if (e.code == 'web-context-cancelled' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'canceled' ||
          message.contains('canceled by the user') ||
          message.contains('cancelled by the user') ||
          message.contains('web operation was canceled')) {
        throw Exception('Login Google dibatalkan oleh pengguna.');
      }
      if (message.contains('missing initial state') ||
          message.contains('sessionstorage')) {
        throw Exception(
          'Login Google gagal menyelesaikan redirect browser. Coba ulangi login. '
          'Jika masih gagal, update Chrome/Android System WebView lalu restart aplikasi.',
        );
      }
      if (message.contains('package certificate hash') ||
          message.contains('certificate hash') ||
          message.contains('sha-1') ||
          message.contains('sha-256')) {
        throw Exception(
          'Login Google gagal karena SHA/certificate hash Android belum cocok dengan Firebase. '
          'Tambahkan SHA-1 dan SHA-256 dari debug ke Firebase Console, lalu unduh ulang google-services.json.',
        );
      }
      throw Exception('Gagal autentikasi Google: ${e.message}');
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Pastikan backend aktif.',
      );
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception(
          'Koneksi terputus. Pastikan internet aktif dan backend berjalan.',
        );
      }
      if (e.toString().contains('Exception:')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception('Terjadi kesalahan Google Login: $e');
    } finally {
      _isGoogleLoginInProgress = false;
    }
  }
}

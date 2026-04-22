import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'user_session.dart';

class AuthService {
  /// Melakukan proses login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Berhasil login (misalnya menerima token dan/atau data user)
        await UserSession.saveSession(data);
        return data;
      } else {
        throw Exception(data['detail'] ?? data['message'] ?? 'Gagal melakukan login');
      }
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Pastikan backend aktif.');
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Koneksi terputus. Pastikan internet aktif dan backend berjalan.');
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
        throw Exception(data['detail'] ?? data['message'] ?? 'Gagal membuat akun');
      }
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Pastikan backend aktif.');
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Koneksi terputus. Pastikan internet aktif dan backend berjalan.');
      }
      if (e.toString().contains('Exception:')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception('Terjadi kesalahan saat mendaftar: $e');
    }
  }

  /// Melakukan proses login dengan Google Sign-In via Firebase Auth
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // 1. Gunakan GoogleAuthProvider dari Firebase Auth langsung
      //    Ini kompatibel dengan google_sign_in v7.x
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // 2. Tampilkan popup Google Sign-In dan autentikasi dengan Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithProvider(googleProvider);

      // 3. Jika user membatalkan, userCredential.user akan null
      if (userCredential.user == null) {
        throw Exception('Login Google dibatalkan oleh pengguna.');
      }

      // 4. Dapatkan Firebase ID Token untuk dikirim ke backend
      final String? firebaseToken = await userCredential.user!.getIdToken();

      if (firebaseToken == null) {
        throw Exception('Gagal mendapatkan token kredensial Firebase.');
      }

      // 5. Kirim id_token ke Backend FastAPI untuk verifikasi & buat JWT
      final String urlStr =
          '${ApiService.baseUrl}/auth/google?id_token=$firebaseToken';
      final response = await http.post(
        Uri.parse(urlStr),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      // 6. Tangkap token JWT dari backend dan data User
      if (response.statusCode == 200 || response.statusCode == 201) {
        await UserSession.saveSession(data);
        return data;
      } else {
        throw Exception(
            data['detail'] ?? data['message'] ?? 'Login Google gagal');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-cancelled' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        throw Exception('Login Google dibatalkan oleh pengguna.');
      }
      throw Exception('Gagal autentikasi Google: ${e.message}');
    } on SocketException {
      throw Exception(
          'Tidak dapat terhubung ke server. Pastikan backend aktif.');
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception(
            'Koneksi terputus. Pastikan internet aktif dan backend berjalan.');
      }
      if (e.toString().contains('Exception:')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception('Terjadi kesalahan Google Login: $e');
    }
  }
}

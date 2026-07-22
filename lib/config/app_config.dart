import 'dart:io';

/// Application configuration for different environments
/// 
/// Backend menggunakan Multi-Dataset RAG (Retrieval-Augmented Generation):
/// - Dataset 1: 1000+ ingredient dengan deskripsi lengkap
/// - Dataset 2: 500+ ingredient dengan kategori dan fungsi
/// - Dataset 3: BPOM data ingredient berbahaya/dilarang
/// - AI Model: Google Gemini 2.5 Flash dengan fallback
/// - Context-Aware: AI mendapat konteks dari 3 dataset sebelum analisis
/// - Fuzzy Matching: Mencocokkan ingredient dengan threshold 84%
/// - Merge Strategy: Data dari 3 dataset digabung untuk context lengkap
/// 
/// Flutter app hanya perlu kirim request ke backend,
/// semua proses Multi-Dataset RAG terjadi di backend secara otomatis.
class AppConfig {
	// Environment types
	static const String dev = 'dev';
	static const String staging = 'staging';
	static const String production = 'production';

	// Get current environment from build arguments
	static const String _environment = String.fromEnvironment(
		'ENV',
		defaultValue: dev,
	);

	// Get custom API URL from build arguments (highest priority)
	static const String _customApiUrl = String.fromEnvironment(
		'API_BASE_URL',
		defaultValue: '',
	);

	/// Get the appropriate base URL based on environment and platform
	static String get baseUrl {
		// Priority 1: Custom API URL from build arguments
		if (_customApiUrl.trim().isNotEmpty) {
			return _customApiUrl.trim();
		}

		// Secara paksa menggunakan backend lokal (localhost/10.0.2.2) 
		// untuk menghindari error koneksi ke VPS karena internet sedang down.
		return developmentUrl;
	}

	/// Production URL (Domain with HTTPS)
	static String get productionUrl {
		// Production domain with HTTPS (RECOMMENDED)
		// Make sure your backend is configured to:
		// 1. Listen on port 443 (HTTPS) or use reverse proxy (Nginx)
		// 2. Have valid SSL certificate
		// 3. CORS enabled for mobile app
		return 'http://43.156.119.43';
		
		// Fallback options if HTTPS doesn't work:
		// return 'http://43.156.119.43';  // HTTP without SSL
		// return 'http://43.156.119.43:8000';  // HTTP with custom port
	}

	/// Staging URL (if you have a staging server)
	static String get stagingUrl {
		// Use same as production for now, or setup staging subdomain
		return 'http://43.156.119.43';
	}

	/// Development URL (local development)
	static String get developmentUrl {
		// Android emulator cannot access host localhost directly
		// Use 10.0.2.2 to access host machine's localhost
		if (Platform.isAndroid) {
			return 'http://10.0.2.2:8000';
		}

		// iOS simulator can use localhost
		if (Platform.isIOS) {
			return 'http://localhost:8000';
		}

		// For real devices on the same network, you should use:
		// --dart-define=API_BASE_URL=http://YOUR_LOCAL_IP:8000
		return 'http://127.0.0.1:8000';
	}

	/// Get current environment name
	static String get environment => _environment;

	/// Check if running in production
	static bool get isProduction => _environment == production;

	/// Check if running in development
	static bool get isDevelopment => _environment == dev;

	/// Check if running in staging
	static bool get isStaging => _environment == staging;

	/// API timeout durations
	static const Duration shortTimeout = Duration(seconds: 30);
	static const Duration mediumTimeout = Duration(seconds: 60);
	static const Duration longTimeout = Duration(seconds: 90);

	/// Debug mode
	static bool get isDebugMode {
		bool debugMode = false;
		assert(debugMode = true);
		return debugMode;
	}

	/// Print current configuration (for debugging)
	static void printConfig() {
		if (isDebugMode) {
			// ignore: avoid_print
			print('=== App Configuration ===');
			// ignore: avoid_print
			print('Environment: $environment');
			// ignore: avoid_print
			print('Base URL: $baseUrl');
			// ignore: avoid_print
			print('Platform: ${Platform.operatingSystem}');
			// ignore: avoid_print
			print('Debug Mode: $isDebugMode');
			// ignore: avoid_print
			print('========================');
		}
	}
}

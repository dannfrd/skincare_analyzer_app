# Skincare Analyzer App

Aplikasi Flutter untuk menganalisis produk skincare menggunakan OCR, AI (Google Gemini), dan RAG (Retrieval-Augmented Generation) dengan dataset ingredient terpercaya.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.11.1+
- Android Studio / Xcode
- Backend API running

### Installation

```bash
# Clone dan install dependencies
git clone <repository-url>
cd skincare_analyzer_app
flutter pub get

# Run aplikasi
flutter run
```

## 🏗️ Build & Run

Gunakan **build.bat** untuk semua kebutuhan build:

```bash
# Windows
build.bat
```

Menu tersedia:
1. **Development Build** - Debug APK untuk testing lokal
2. **Production Build** - Release APK untuk production
3. **Custom URL Build** - Build dengan backend URL custom
4. **Run Development** - Jalankan app mode development
5. **Run Production** - Jalankan app mode production
6. **Clean Project** - Bersihkan build cache

### Manual Build Commands

```bash
# Development
flutter build apk --debug --dart-define=ENV=dev

# Production
flutter build apk --release --dart-define=ENV=production

# Custom URL
flutter build apk --release --dart-define=API_BASE_URL=http://your-url:8000
```

## 🌐 Backend Configuration

### Production
- URL: `http://api.buildwithardan.my.id`
- Environment: `production`
- Protocol: HTTP

### Development
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://localhost:8000`
- Real Device: `http://YOUR_LOCAL_IP:8000`

Konfigurasi ada di: `lib/config/app_config.dart`

## 🤖 RAG Integration

Aplikasi ini menggunakan **RAG (Retrieval-Augmented Generation)** dengan **3 DATASET TERINTEGRASI** untuk analisis ingredient yang sangat akurat:

### 3 Dataset yang Digunakan:

1. **cosmetic_ingredients_train.csv** (1000+ ingredient)
   - Deskripsi lengkap ingredient
   - Fungsi dan cara kerja
   - Manfaat dan efek samping

2. **ingredients_category.csv** (500+ ingredient)
   - Kategori dan fungsi ingredient
   - Warning dan peringatan
   - Origin (Natural/Synthetic)
   - Charge type (Ionik/Non-ionik)

3. **Database BPOM Kosmetik Berbahaya**
   - Ingredient yang dilarang BPOM
   - Produk yang mengandung bahan berbahaya
   - Nomor surat public warning

### Cara Kerja Multi-Dataset RAG:

- **AI Model**: Google Gemini 2.5 Flash dengan fallback
- **Context-Aware**: AI mendapat konteks dari 3 dataset sekaligus
- **Fuzzy Matching**: Mencocokkan ingredient dengan threshold 84%
- **Merge Strategy**: Data dari 3 dataset digabung untuk context lengkap

Backend secara otomatis:
1. Extract ingredient dari OCR
2. Match dengan database MySQL
3. **Retrieve context dari 3 dataset CSV** (RAG multi-source)
4. Merge data dari semua sumber
5. Kirim ke Gemini AI dengan context lengkap
6. Return analisis yang grounded pada 3 sumber data

## 📦 Key Dependencies

- `http` & `dio` - HTTP client
- `image_picker` - Image selection
- `flutter_tesseract_ocr` - OCR
- `firebase_auth` - Authentication
- `google_sign_in` - Google auth
- `shared_preferences` - Local storage

## 🔧 Environment Variables

File `.env.example` tersedia sebagai template. Copy ke `.env` dan sesuaikan:

```env
ENV=production
API_BASE_URL=http://api.buildwithardan.my.id
```

## 📱 Output

APK hasil build ada di:
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

## 🐛 Troubleshooting

### Tidak bisa connect ke backend
1. Pastikan backend running
2. Cek koneksi internet
3. Untuk development, gunakan IP lokal yang benar
4. Untuk real device, gunakan `--dart-define=API_BASE_URL=http://YOUR_IP:8000`

### Build error
```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=ENV=production
```

## 📄 License

[Your License]

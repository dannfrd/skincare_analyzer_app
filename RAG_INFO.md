# RAG Integration Info

## Apa itu RAG?

**RAG (Retrieval-Augmented Generation)** adalah teknik AI yang menggabungkan:
- **Retrieval**: Mengambil informasi relevan dari dataset
- **Augmented**: Menambahkan konteks ke prompt AI
- **Generation**: AI menghasilkan response berdasarkan konteks

## Bagaimana RAG Bekerja di Aplikasi Ini?

### Backend (Otomatis)

```
User Input (OCR/Text)
    ↓
1. Text Cleaning & Tokenization
    ↓
2. Ingredient Matching (MySQL Database)
    ↓
3. RAG Context Retrieval (CSV Dataset)
    ├─ Exact Match
    └─ Fuzzy Match (84% threshold)
    ↓
4. Build Prompt with Context
    ├─ Database Context (MySQL)
    └─ Dataset Context (CSV)
    ↓
5. Google Gemini AI Analysis
    ├─ Model: gemini-2.5-flash
    ├─ Fallback: gemini-2.0-flash, gemini-1.5-flash
    └─ Context-Grounded Response
    ↓
6. Expert System Scoring
    ↓
Final Analysis Result → Flutter App
```

### Flutter App (Simple)

Flutter app **tidak perlu** implementasi RAG khusus. Cukup:

```dart
// 1. Kirim image atau text ke backend
final result = await ApiService.analyzeImage(imageFile);
// atau
final result = await ApiService.analyzeText(ingredientText);

// 2. Terima hasil analisis yang sudah ter-context
// Backend sudah melakukan RAG secara otomatis
```

## Dataset yang Digunakan

Backend menggunakan **3 dataset terintegrasi**:

### 1. cosmetic_ingredients_train.csv (1000+ ingredient)
   - **Ingredient name**: Nama ingredient
   - **Detailed description**: Deskripsi lengkap
   - **What it is**: Apa itu ingredient
   - **What it does**: Fungsi dan cara kerja
   - **Who should use/avoid**: Rekomendasi penggunaan

**Contoh**:
```csv
ingredient,description
Glycerin,"Glycerin is a humectant that helps skin retain moisture. It's been used for 50+ years..."
Niacinamide,"Niacinamide is vitamin B3 that helps brighten skin, reduce inflammation..."
```

### 2. ingredients_category.csv (500+ ingredient)
   - **Ingredient name**: Nama ingredient
   - **Function 1 & 2**: Fungsi utama dan sekunder
   - **Warning 1 & 2**: Peringatan penggunaan
   - **Origin**: Natural/Synthetic
   - **Charge**: Ionik/Non-ionik/Kationik/Anionik

**Contoh**:
```csv
ingredient_name,function1,function2,warning1,warning2,ingredient_origin,ingredient_charge
Glycerin,Humectant,Moisturizer,,,Natural,Non-ionik
Retinol,Anti-aging,Cell-Communicating,Irritant,Photosensitive,Synthetic,Non-ionik
```

### 3. Database Kosmetik Berbahaya BPOM
   - **Nama Produk**: Produk yang mengandung bahan berbahaya
   - **Kandungan Bahan Berbahaya**: Ingredient yang dilarang
   - **Nomor Surat Public Warning**: Nomor surat BPOM

**Contoh**:
```csv
No,Nama Produk,Kandungan Bahan Berbahaya/Dilarang,Nomor Surat Public Warning
1,Product X,Merkuri / raksa (Hg),HM.03.03.1.43.12.12.8256
2,Product Y,Hydroquinone (>2%),KH.00.01.432.6147
```

## Multi-Dataset RAG Strategy

RAG menggunakan **strategi merge** dari 3 dataset:

```
Ingredient: "Niacinamide"
    ↓
Retrieve from Dataset 1: ✅ Found
    → Description: "Vitamin B3 that brightens skin..."
    ↓
Retrieve from Dataset 2: ✅ Found
    → Function: "Brightening, Anti-inflammatory"
    → Warning: "None"
    → Origin: "Synthetic"
    ↓
Retrieve from Dataset 3: ❌ Not Found (Good! Not harmful)
    ↓
Merge All Data:
    {
      "name": "Niacinamide",
      "description": "Vitamin B3 that brightens...",
      "functions": "Brightening, Anti-inflammatory",
      "warnings": "",
      "origin": "Synthetic",
      "harmful": false,
      "sources": ["descriptions", "categories"]
    }
    ↓
Send to AI with Complete Context
```

### Contoh Ingredient Berbahaya:

```
Ingredient: "Mercury" / "Merkuri"
    ↓
Retrieve from Dataset 1: ❌ Not Found
    ↓
Retrieve from Dataset 2: ❌ Not Found
    ↓
Retrieve from Dataset 3: ✅ Found in BPOM
    → Harmful: TRUE
    → Warning: "BPOM: Bahan berbahaya/dilarang"
    → Found in products: ["Product X", "Product Y"]
    ↓
Merge All Data:
    {
      "name": "Merkuri / raksa (Hg)",
      "harmful": true,
      "bpom_warning": "BPOM: BAHAN BERBAHAYA/DILARANG",
      "sources": ["bpom_harmful"]
    }
    ↓
Send to AI with CRITICAL WARNING
```

## Keuntungan Multi-Dataset RAG

✅ **Sangat Akurat**: AI mendapat konteks dari 3 sumber terpercaya
✅ **Komprehensif**: Deskripsi + Kategori + Warning BPOM
✅ **Grounded**: Response berdasarkan data, bukan halusinasi
✅ **Safety First**: Deteksi otomatis ingredient berbahaya dari BPOM
✅ **Up-to-date**: Dataset bisa di-update tanpa retrain model
✅ **Transparent**: Bisa trace dari mana informasi berasal (sources)
✅ **Efficient**: Tidak perlu fine-tune model AI
✅ **Redundant**: Jika 1 dataset tidak punya data, masih ada 2 dataset lain

## Konfigurasi RAG (Backend)

Di backend `.env`:

```env
# Dataset paths (3 datasets)
RAG_DATASET_DESCRIPTIONS=data/dataset_scincare/cosmetic_ingredients_train.csv
RAG_DATASET_CATEGORIES=data/dataset_scincare/ingredients_category.csv
RAG_DATASET_BPOM=data/dataset_scincare/Database Kosmetik Mengandung Bahan Berbahaya - Direktorat Standardisasi Obat Tradisional, Suplemen Kesehatan dan Kosmetik.csv

# Fuzzy matching threshold (0.0 - 1.0)
RAG_FUZZY_THRESHOLD=0.84

# Max items to retrieve
RAG_MAX_CONTEXT_ITEMS=12
```

## Cara Kerja Fuzzy Matching

Contoh:
- User input: "Niacinamid" (typo)
- Dataset: "Niacinamide"
- Similarity: 91% (> 84% threshold)
- Result: ✅ Match!

## Response Format

Backend mengembalikan dengan data dari 3 dataset:

```json
{
  "input_text": "Water, Glycerin, Niacinamide, Mercury",
  "cleaned_tokens": ["water", "glycerin", "niacinamide", "mercury"],
  "matched_ingredients": [
    {
      "name": "Glycerin",
      "description": "Humectant that helps retain moisture...",
      "functions": "Humectant, Moisturizer",
      "origin": "Natural",
      "harmful": false,
      "sources": ["descriptions", "categories"]
    },
    {
      "name": "Niacinamide",
      "description": "Vitamin B3 that brightens skin...",
      "functions": "Brightening, Anti-inflammatory",
      "warnings": "",
      "origin": "Synthetic",
      "harmful": false,
      "sources": ["descriptions", "categories"]
    },
    {
      "name": "Mercury",
      "harmful": true,
      "bpom_warning": "BPOM: BAHAN BERBAHAYA/DILARANG",
      "sources": ["bpom_harmful"]
    }
  ],
  "ai_analysis": {
    "model_output": "⚠️ PERINGATAN: Produk mengandung Mercury yang DILARANG oleh BPOM...",
    "model_used": "gemini-2.5-flash",
    "rag_context_sources": ["descriptions", "categories", "bpom_harmful"]
  },
  "expert_analysis": {
    "overall_score": 20,
    "classification": "Dangerous"
  },
  "summary": "⚠️ BAHAYA: Mengandung bahan berbahaya Mercury...",
  "recommendation": "JANGAN GUNAKAN produk ini. Mengandung Mercury yang dilarang BPOM..."
}
```

## Troubleshooting

### RAG tidak bekerja?

Cek di backend:
1. **Semua 3 file dataset ada**:
   - `data/dataset_scincare/cosmetic_ingredients_train.csv`
   - `data/dataset_scincare/ingredients_category.csv`
   - `data/dataset_scincare/Database Kosmetik Mengandung Bahan Berbahaya...csv`
2. Environment variables benar (atau gunakan default path)
3. File CSV format valid (UTF-8)
4. Check logs: `python main.py` akan print error jika dataset gagal load

### AI response tidak akurat?

1. Cek threshold fuzzy matching (turunkan jika terlalu strict)
2. Tambah data ke dataset CSV
3. Cek Gemini API key valid
4. Review prompt di `modules/gemini_ai.py`

## Update Dataset

Untuk update dataset:

1. Edit file CSV di `backend/data/dataset_scincare/`
   - Tambah ingredient baru ke `cosmetic_ingredients_train.csv`
   - Tambah kategori baru ke `ingredients_category.csv`
   - Update data BPOM jika ada ingredient berbahaya baru
2. Restart backend (cache akan di-refresh otomatis)
3. Test dengan ingredient baru

**Keuntungan Multi-Dataset**:
- Jika ingredient tidak ada di dataset 1, masih bisa dapat info dari dataset 2 atau 3
- Data lebih lengkap karena merge dari 3 sumber
- BPOM warning otomatis terdeteksi

Tidak perlu:
- ❌ Retrain model
- ❌ Update Flutter app
- ❌ Rebuild APK

## Monitoring

Backend menyediakan endpoint monitoring:

```bash
# Health check
GET /health

# Metrics
GET /metrics/summary
GET /metrics/recent
```

## Kesimpulan

Multi-Dataset RAG membuat aplikasi ini:
- **Sangat akurat** (grounded pada 3 dataset terpercaya)
- **Sangat aman** (deteksi otomatis ingredient berbahaya BPOM)
- **Sangat lengkap** (deskripsi + kategori + warning)
- **Maintainable** (update dataset tanpa retrain)
- **Transparent** (bisa trace sumber info dari 3 dataset)
- **Efficient** (tidak perlu fine-tune model)
- **Redundant** (jika 1 dataset tidak ada data, masih ada 2 lainnya)

Flutter app tetap simple, semua kompleksitas Multi-Dataset RAG di-handle backend! 🚀

**Total Coverage**: 1000+ (descriptions) + 500+ (categories) + BPOM harmful = **1500+ ingredient dengan data lengkap!**

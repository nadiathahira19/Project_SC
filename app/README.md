# 🌿 EcoQuest - Smart Waste Management System

> **Ubah Sampah Menjadi Hadiah dengan Kekuatan AI**

![EcoQuest Banner](assets/images/logo.png)

EcoQuest adalah aplikasi mobile inovatif berbasis **Flutter** yang mengintegrasikan teknologi **Artificial Intelligence (AI)** dan **Geo-Location** untuk membangun kebiasaan daur ulang yang berkelanjutan. Aplikasi ini tidak hanya mencatat sampah, tapi memverifikasinya secara cerdas.

---

## 🌟 Fitur Unggulan & Teknologi

Aplikasi ini dibangun dengan logika yang kuat untuk mencegah kecurangan dan memaksimalkan pengalaman pengguna:

### 1. 🤖 AI-Powered Waste Recognition

Menggunakan model _Machine Learning_ yang di-hosting di **Hugging Face** untuk mengenali jenis sampah secara otomatis.

- **Alur:** Ambil gambar → Kirim ke server AI → Terima label (Botol, Kertas, Kaleng) → Validasi poin
- **Teknologi:** HTTP Request, Server-Sent Events (SSE)

### 2. 📍 Secure Geo-Fencing & QR Verification

Mencegah scan palsu di luar lokasi tong sampah.

- Pengguna **WAJIB** memindai QR Code di tong sampah fisik
- Jika pengguna bergerak > 30 meter dari lokasi saat sesi aktif, sesi otomatis dibatalkan

### 3. ⚡ Smart Burst Energy System (Anti-Spam)

Mencegah farming poin berlebihan.

- **Energi:** 5 kali scan
- **Cooldown:** 1 jam untuk pemulihan penuh
- **Lazy Reset:** Reset terjadi otomatis saat user mencoba scan setelah cooldown selesai

### 4. 🎁 Reward & Gamification

- Poin dinamis berdasarkan jenis sampah
- Streak harian
- Leaderboard real-time

---

## 🛠️ Tech Stack

| Komponen     | Teknologi                  |
| ------------ | -------------------------- |
| Frontend     | Flutter (Dart, Material 3) |
| Backend      | Firebase (Auth, Firestore) |
| AI Engine    | Hugging Face Spaces        |
| Storage      | Cloudinary                 |
| Maps         | Geolocator                 |
| Architecture | Feature-First              |

---

## 🚀 Cara Menjalankan Project

⚠️ **Catatan Penting**  
Repository ini adalah **monorepo**. Aplikasi Flutter berada di dalam folder **`/app`**.

### 1. Prasyarat

- Flutter SDK
- Android Studio / VS Code
- Emulator atau device Android

### 2. Clone Repository

```bash
git clone https://github.com/nadiathahira19/Project_SC.git
cd Project_SC/app
```

### 3. Konfigurasi Environment (.env)

Buat file `.env` di dalam folder **`app/`** :

```env
CLOUDINARY_CLOUD_NAME=nama_cloud_anda
CLOUDINARY_UPLOAD_PRESET=preset_anda
DEFAULT_AVATAR_URL=https://res.cloudinary.com/dm7eddntg/image/upload/v1760797982/dfaultProfil_ytmldx.jpg
```

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Generate Launcher Icon (Opsional)

```bash
dart run flutter_launcher_icons
```

### 6. Jalankan Aplikasi

```bash
flutter run
```

---

## 📂 Struktur Project (Flutter App)

```
app/
└── lib/
    ├── features/
    │   ├── authentication/
    │   ├── history/
    │   ├── home/
    │   ├── main/
    │   ├── notifications/
    │   ├── profile/
    │   ├── rewards/
    │   └── scan/
    ├── utils/
    └── main.dart
```

---

## 🔒 Security & Validation Rules

1. Poin hanya diberikan jika confidence AI memenuhi threshold
2. Sesi scan hangus jika user keluar aplikasi atau menjauh dari lokasi
3. Firebase Rules membatasi akses data antar pengguna

---

## 👥 Tim Pengembang

Project ini dikembangkan oleh **Kelompok GreenFlag**:

- M. Dimas Ardiansyah (220170176) – Project Manager
- Nadya Raudathul Sofa (220170170) – System Analyst
- Ragil Rachmad Gustillah (220170175) – UI/UX Designer
- Nadia Thahira (220170152) – Testing & Documentation
- Muhammad Iqbal (220170149) – Full-Stack Developer

---

© 2025 EcoQuest. All Rights Reserved.

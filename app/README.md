# 🌿 EcoQuest - Smart Waste Management System

> **Ubah Sampah Menjadi Hadiah dengan Kekuatan AI**

![EcoQuest Banner](assets/images/logo.png)

EcoQuest adalah aplikasi mobile inovatif berbasis **Flutter** yang mengintegrasikan teknologi **Artificial Intelligence (AI)** dan **Geo-Location** untuk membangun kebiasaan daur ulang yang berkelanjutan. Aplikasi ini tidak hanya mencatat sampah, tapi memverifikasinya secara cerdas.

---

## 🌟 Fitur Unggulan & Teknologi

Aplikasi ini dibangun dengan logika yang kuat untuk mencegah kecurangan dan memaksimalkan pengalaman pengguna:

### 1. 🤖 AI-Powered Waste Recognition

Menggunakan model _Machine Learning_ yang di-hosting di **Hugging Face** untuk mengenali jenis sampah secara otomatis.

- **Cara Kerja:** Gambar diunggah -> Diproses oleh Server AI -> Mengembalikan label (Botol, Kertas, Kaleng) -> Validasi Poin.
- **Teknologi:** HTTP Request, Server-Sent Events (SSE) untuk real-time feedback.

### 2. 📍 Secure Geo-Fencing & QR Verification

Mencegah pengguna melakukan scan palsu di rumah.

- **Logika:** Pengguna **WAJIB** memindai QR Code di tong sampah fisik terlebih dahulu.
- **Validasi Jarak:** Sistem memantau GPS pengguna. Jika pengguna bergerak menjauh (> 30 meter) dari lokasi tong sampah saat sesi aktif, sesi otomatis dibatalkan.

### 3. ⚡ Smart Burst Energy System (Anti-Spam)

Mencegah _farming_ poin berlebihan dengan sistem energi pintar.

- **Mekanisme:** Pengguna memiliki **5 Energi** (Kuota Scan).
- **Cooldown:** Setelah energi habis, pengguna harus menunggu **1 Jam** untuk pemulihan penuh (Full Recovery).
- **Lazy Reset:** Logika reset dilakukan secara otomatis saat pengguna mencoba scan kembali setelah waktu cooldown berakhir.

### 4. 🎁 Reward & Gamification

- **Poin Dinamis:** Nilai poin berbeda berdasarkan jenis sampah (Contoh: Kaca > Plastik).
- **Streak System:** Bonus poin tambahan bagi pengguna yang konsisten melakukan scan setiap hari.
- **Leaderboard:** Kompetisi real-time antar pengguna.

---

## 🛠️ Tech Stack

| Komponen         | Teknologi           | Keterangan                       |
| :--------------- | :------------------ | :------------------------------- |
| **Frontend**     | Flutter (Dart)      | UI Modern dengan Material 3      |
| **Backend**      | Firebase            | Firestore (DB), Auth (Login)     |
| **AI Engine**    | Hugging Face Spaces | Image Classification API         |
| **Storage**      | Cloudinary          | Penyimpanan bukti foto scan      |
| **Maps**         | Geolocator          | Verifikasi radius lokasi         |
| **Architecture** | Feature-First       | Struktur folder modular & bersih |

---

## 🚀 Cara Menjalankan Project

Ikuti langkah ini untuk menjalankan aplikasi di lingkungan lokal Anda:

### 1. Prasyarat

- Flutter SDK Terinstal
- Android Studio / VS Code
- Device Android (Fisik atau Emulator)

### 2. Clone Repository

```bash
git clone [https://github.com/nadiathahira19/Project_SC.git](https://github.com/nadiathahira19/Project_SC.git)
cd Project_SC

```

### 3. Konfigurasi Environment (.env)

Buat file bernama `.env` di root folder proyek (sejajar dengan `pubspec.yaml`). Isi dengan kredensial API Anda:

```env
# Cloudinary Config (Untuk Upload Gambar)
CLOUDINARY_CLOUD_NAME=nama_cloud_anda
CLOUDINARY_UPLOAD_PRESET=preset_anda

# Default Assets
DEFAULT_AVATAR_URL=[https://res.cloudinary.com/dm7eddntg/image/upload/v1760797982/dfaultProfil_ytmldx.jpg](https://res.cloudinary.com/dm7eddntg/image/upload/v1760797982/dfaultProfil_ytmldx.jpg)

```

### 4. Install Dependencies

```bash
flutter pub get

```

### 5. Generate Launcher Icon (Opsional)

Jika ingin memperbarui ikon aplikasi:

```bash
dart run flutter_launcher_icons

```

### 6. Jalankan Aplikasi

```bash
flutter run

```

---

## 📂 Struktur Project

Kami menggunakan pendekatan **Feature-First** agar kode mudah dikelola dan dikembangkan:

```
lib/
├── features/
│   ├── authentication/  # Login, Register, Splash Screen
│   ├── history/         # Riwayat Aktivitas & Poin
│   ├── home/            # Dashboard Utama & Leaderboard
│   ├── main/            # Navigasi Utama (Bottom Navbar)
│   ├── notifications/   # Layar Notifikasi (masih Dummy)
│   ├── profile/         # Manajemen Profil Pengguna
│   ├── rewards/         # Katalog & Penukaran Hadiah
│   └── scan/            # Kamera, AI Processing, Upload Logic
├── utils/               # Konstanta Warna, Tema, Helper Global
└── main.dart            # Entry Point Aplikasi

```

---

## 🔒 Security & Validation Rules

1. **Validasi Server-Side:** Poin hanya bertambah jika AI memberikan _confidence score_ yang tinggi terhadap gambar.
2. **Session Timeout:** Sesi scan di tong sampah akan hangus otomatis jika aplikasi ditutup atau pengguna menjauh.
3. **Firebase Rules:** Database dikunci agar pengguna hanya bisa mengedit data profil mereka sendiri, tidak bisa memanipulasi poin user lain.

---

## 👥 Tim Pengembang

Project ini dikembangkan dengan ❤️ oleh kelompok GreenFlag:

- **M.Dimas Ardiansyah (220170176)** - _Project Manager_
- **Nadya Raudathul Sofa (220170170)** - _System Analyst_
- **Ragil Rachmad Gustillah (220170175)** - _UI/UX Designer_
- **Nadia Thahira (220170152)** - _Quality Assurance & Doc_
- **Muhammad Iqbal (220170149)** - _Full-Stack Developer_

---

© 2025 EcoQuest. All Rights Reserved.

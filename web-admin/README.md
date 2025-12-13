# Eco Quest Admin Panel

Eco Quest Admin Panel adalah aplikasi dashboard administratif yang
dibangun menggunakan **Next.js (App Router)** dengan integrasi
**Firebase Authentication**, **Firestore Database**, dan **TailwindCSS**.
Sistem ini digunakan untuk mengelola akun admin, memverifikasi akses
berbasis peran, dan mengatur data operasional Eco Quest.

## Teknologi yang Digunakan

- Next.js (App Router)
- Firebase Authentication
- Firestore Database
- TailwindCSS
- Lucide Icons
- Vercel

## Fitur Utama

### 1. Autentikasi Admin (`/login`)

Menggunakan Firebase Authentication untuk login aman dan validasi akses.

### 2. Manajemen Admin (`/admins`)

Khusus super admin: - Membuat akun admin menggunakan Secondary Firebase
App (super admin tetap login selama proses). - Melihat daftar admin dan
super admin. - Menghapus role admin dari Firestore.

### 3. Dashboard Utama (`/`)

Halaman utama setelah login yang menyesuaikan akses berdasarkan role
pengguna.

## Instalasi

### 1. Clone Repository

```bash
git clone <repo-url>
cd eco-quest-admin
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Konfigurasi Firebase

Tambahkan konfigurasi Firebase pada file:

    /src/lib/firebase.js

Contoh konfigurasi:

```js
export const firebaseConfig = {
  apiKey: '...',
  authDomain: '...',
  projectId: '...',
  storageBucket: '...',
  messagingSenderId: '...',
  appId: '...',
}
```

Gunakan file `.env.local` untuk menyimpan credential:

    NEXT_PUBLIC_FIREBASE_API_KEY=...
    NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
    NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
    NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
    NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
    NEXT_PUBLIC_FIREBASE_APP_ID=...

## Menjalankan Aplikasi

```bash
npm run dev
```

Akses melalui:

    http://localhost:3000

## Sistem Role

### super_admin

- Akses penuh
- Dapat membuat dan menghapus admin

### admin

- Akses terbatas\
- Tidak dapat mengakses halaman manajemen admin

Validasi role dilakukan melalui Firestore dan Firebase Rules.

## Alur Penambahan Admin

1.  Super admin membuka halaman `/admins`.\
2.  Mengisi data admin baru.\
3.  Sistem membuat akun menggunakan Secondary Firebase App.\
4.  Role admin baru disimpan ke Firestore.\
5.  Super admin tetap login.\
6.  Admin baru dapat langsung menggunakan akun.

## Penghapusan Admin

### 1. Penghapusan Role Admin (melalui Web Admin)

- Menghapus role dari Firestore
- Akun tetap ada di Firebase Authentication
- Pengguna kehilangan akses admin

### 2. Penghapusan Akun Sepenuhnya

Dilakukan melalui Firebase Console atau Firebase Admin SDK.\
Tidak tersedia di Web Admin demi keamanan.

## Deployment

Aplikasi ini telah dideploy menggunakan Vercel.

**URL Production:**\
https://admin-ecoquest.vercel.app

## Lisensi

Dokumentasi dan aplikasi dapat disesuaikan untuk kebutuhan internal Eco
Quest.

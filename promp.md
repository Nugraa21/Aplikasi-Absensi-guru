Project: Absensi Guru (Flutter + SQLite)

Tujuan:
Buat aplikasi Flutter/Dart untuk absensi guru berbasis selfie + GPS. Gunakan dependency yang diberikan:
- camera: ^0.11.0+2
- geolocator: ^13.0.1
- permission_handler: ^11.3.1
- path_provider: ^2.1.5
- sqflite: ^2.4.0
- sqflite_common_ffi: ^2.3.2 (untuk Windows)
- image_picker: ^1.1.2
- intl: ^0.19.0

Role & Hak Akses:
1. super_admin
  - semua hak (CRUD users, reset password, set lokasi pusat & radius, export rekap)
2. admin
  - melihat daftar absen `pending`, validasi (approve/reject), komentar validasi
3. user (guru)
  - absen masuk & pulang (maks 2 record per hari: `check_in` & `check_out`)
  - melihat riwayat absennya

Rules / Business Logic:
- Absen hanya berhasil apabila:
  1. selfie diambil (foto tersimpan lokal path)
  2. lokasi GPS diperoleh dan jarak ke titik pusat <= 1000 meter (default)
- Setelah guru absen, status = `pending`. Admin harus mengubah status jadi `validated` agar dianggap sah.
- Reset absen: per hari — setiap pergantian tanggal, guru bisa absen lagi.
- PNS/ASN entry: jika user adalah PNS/ASN, simpan `nip`, `npwp`, `jenis` = 'pns'. Untuk guru non-PNS, simpan `id_non_nip` atau `keterangan`.
- Rekap bulanan: export data 30 hari terakhir ke CSV (bisa dibuka di Excel). Sertakan statistik: jumlah hadir, izin, absen tidak hadir.
- Lokasi pusat default: `lat = -7.797068`, `lng = 110.370529`, `maxDistance = 1000` meter. Super admin bisa ubah.

Database (SQLite) — skema awal:
Tabel `users`
- id INTEGER PRIMARY KEY AUTOINCREMENT
- username TEXT UNIQUE
- password TEXT (simpan hash sederhana atau plaintext sementara; beri note untuk ganti ke hash)
- name TEXT
- role TEXT CHECK(role IN ('super_admin','admin','guru'))
- type TEXT CHECK(type IN ('pns','non_pns')) DEFAULT 'non_pns'
- nip TEXT NULL
- npwp TEXT NULL
- created_at TEXT
- updated_at TEXT

Tabel `attendance`
- id INTEGER PRIMARY KEY AUTOINCREMENT
- user_id INTEGER REFERENCES users(id)
- date TEXT (yyyy-MM-dd)  -- tanggal absen (local date)
- type TEXT CHECK(type IN ('check_in','check_out'))
- time TEXT (HH:mm:ss)
- photo_path TEXT
- latitude REAL
- longitude REAL
- distance_m REAL
- status TEXT CHECK(status IN ('pending','validated','rejected')) DEFAULT 'pending'
- admin_comment TEXT
- validated_by INTEGER NULL
- created_at TEXT
- updated_at TEXT

Tabel `settings`
- id INTEGER PRIMARY KEY AUTOINCREMENT
- key TEXT UNIQUE
- value TEXT

Contoh initial setting entries:
- ('center_lat','-7.797068')
- ('center_lng','110.370529')
- ('max_distance_m','1000')

File structure (saran)
- lib/
  - main.dart
  - services/
    - db_helper.dart
    - auth_service.dart
    - attendance_service.dart
    - location_service.dart
    - export_service.dart
  - models/
    - user.dart
    - attendance.dart
  - screens/
    - login_page.dart
    - admin/
      - pending_list.dart
      - validate_screen.dart
    - super_admin/
      - manage_users.dart
      - settings_page.dart
    - guru/
      - attendance_form.dart
      - history_page.dart
    - common/
      - dashboard.dart
      - profile_page.dart
  - widgets/
    - permission_request.dart
    - photo_preview.dart

UI / Flow singkat:
- Login -> redirect by role to dashboard.
- Guru Dashboard -> Tombol "Absen Masuk" / "Absen Pulang" (disabled jika sudah absen hari ini untuk jenis itu). Tekan -> open camera (pakai camera atau image_picker) -> ambil selfie -> ambil lokasi -> hitung jarak -> simpan ke DB dengan status `pending`.
- Admin Dashboard -> list attendance status `pending` -> buka detail -> lihat foto + lokasi map (bisa hanya tampil lat/lng) -> tombol Approve / Reject + comment -> ubah status.
- Super Admin -> manage users (create/edit/reset password), settings lokasi & radius, export rekap 30 hari jadi CSV.

Fungsional non-fungsional:
- Handle permission kamera & lokasi (permission_handler).
- Simpan foto ke app directory (path_provider) dan simpan path di DB.
- Gunakan `intl` untuk format waktu/tanggal.
- Untuk export Excel: buat CSV di /storage/emulated/0/Download/ atau app dir (gunakan path_provider) dengan header: tanggal, nama, nip, type, waktu, status, jarak, photo_path.
- Tambahkan validasi UI & error handling.

Acceptance Criteria (yang harus bisa dilakukan):
1. Guru bisa login & absen (selfie + lokasi) => record dibuat dengan status pending.
2. Jarak dihitung benar (haversine), dan disimpan di DB.
3. Admin bisa melihat list pending & validate (approve/reject).
4. Super Admin bisa edit center lat/lng & maxDistance.
5. Rekap 30 hari bisa diexport ke CSV & file tersedia di storage.
6. SQLite DB bekerja di Android/Windows (sqlite_common_ffi untuk Windows).
7. Kode DBHelper dengan contoh CRUD untuk users, attendance dan settings.
8. Terdapat dokumentasi singkat untuk tiap file/service (komentar di atas fungsi).

Tambahan teknis & snippet yang diharapkan:
- Sediakan `DBHelper.initDB()` yang membuat tabel di atas.
- Sediakan contoh function `bool isWithinRadius(lat, lng)` yang baca center dari settings dan hitung jarak.
- Sediakan contoh `AttendanceService.createAttendance(userId, type, photoPath, lat, lng)` yang otomatis set date dan time.
- Sediakan contoh export: `ExportService.exportAttendanceToCsv(startDate, endDate, path)`.

Note keamanan:
- Untuk produksi, jangan simpan password plaintext. Gunakan hashing (bcrypt). Untuk sekarang cukup simpan plaintext sebagai POC dengan comment.

Deliverables:
- Kode lengkap (minimal: DBHelper, model, attendance flow, admin validate flow).
- README singkat cara run di Android & Windows.
- Contoh seed data: 1 super_admin (username: super, password: admin123), 1 admin (admin/admin123), 2 guru.


```
```
## Prompt task-specific (untuk minta kode bagian demi bagian)

Jika ingin minta implementasi per bagian, pakai prompt ini contoh:

DBHelper + schema

Buat file lib/services/db_helper.dart untuk Flutter. Fungsinya: initDB, create tables (users, attendance, settings), seed initial settings & seed akun super/admin. Sertakan method CRUD: addUser, getUserByUsername, updateUser, deleteUser, addAttendance, getPendingAttendances, updateAttendanceStatus, getAttendanceByUserAndDate, getAttendanceRange. Beri komentar di setiap fungsi.


Attendance form (guru)

Buat screen lib/screens/guru/attendance_form.dart: ambil permission, buka kamera (camera/image_picker), ambil lokasi (geolocator), hitung jarak (haversine), tampil preview foto + distance, tombol Submit yang panggil AttendanceService.createAttendance(...). Jika lokasi > maxDistance, tampil peringatan tapi tetap izinkan submit (admin bisa reject).


Admin validate screen

Buat screen lib/screens/admin/pending_list.dart yang ambil list pending dari DB, setiap item bisa dibuka detail (lihat foto, lokasi, jarak, waktu), admin bisa Approve atau Reject + optional comment. Update DB accordingly and record validated_by.


Export rekap

Buat service lib/services/export_service.dart dengan function exportAttendanceCsv(startDate, endDate). Simpan file CSV di Downloads (or app dir) dan return path file.
```ssl
Contoh SQL create table (copy-paste)
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE,
  password TEXT,
  name TEXT,
  role TEXT,
  type TEXT,
  nip TEXT,
  npwp TEXT,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE attendance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  date TEXT,
  type TEXT,
  time TEXT,
  photo_path TEXT,
  latitude REAL,
  longitude REAL,
  distance_m REAL,
  status TEXT,
  admin_comment TEXT,
  validated_by INTEGER,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT UNIQUE,
  value TEXT
);
```
Tips implementasi cepat (best-practice/cheats)

Gunakan permission_handler untuk cek & request permission camera & location di awal form.

Untuk foto di Android/Desktop: gunakan image_picker bila ingin lebih simple (front camera) atau camera untuk kontrol penuh.

Hitung jarak pakai rumus Haversine (ada snippet banyak online — bisa kubuat juga).

Untuk export Excel: pakai CSV (package csv atau manual) agar gampang dibuka di Excel tanpa dependency tambahan.

Jangan lupa timezone/local date saat membuat field date supaya reset per 24 jam sesuai jam lokal.
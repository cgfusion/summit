# 📖 MANUAL PENGGUNA KESELURUHAN SISTEM DARE TO CHANGE (D2C)
**Sekolah Menengah Kebangsaan Sungai Damit, Tamparuli, Sabah**
*Sistem Pengurusan Kehadiran, Sahsiah, Merit, Disiplin & Kaunseling Digital*

---

> 📌 **TEMA PROGRAM D2C**: *"Hadir Hari Ini, Menang Esok Hari"*  
> ⚡ **TAGLINE**: *"Saya Hadir, Saya Kekal, Saya Berjaya!"*  
> 🏆 **MOTTO SEKOLAH**: *"ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs"*

---

## 🛠️ Ringkasan Ciri-Ciri & Modul Keseluruhan Sistem:

### 1. 🌐 Laman Utama Public & Landing Page (`https://d2csummit.online/`)
- **1.1 Pusat Perhatian (Spotlight D2C)**:
  - **Rekabentuk High-Tech**: Menggunakan tema warna *Deep Space Navy* & *Cosmic Violet* dengan kad *Glassmorphism* futuristik.
  - **Indikator Uptime Status**: Memaparkan status hijau `🟢 TAMPARULI • D2C SYSTEM ONLINE` di header utama.
  - **Sasaran Program**: Dilaksanakan secara menyeluruh untuk murid **Tingkatan 1, 2, 3, 4 & 5 (Sesi Pagi & Sesi Petang)**.
  - **Motto & Tagline**: Menonjolkan slogan utama sekolah *"ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs"* dan *"Saya Hadir, Saya Kekal, Saya Berjaya!"*.
- **1.2 Model 3 Aras Intervensi D2C**:
  - **Aras 1 (Universal)**: Imbasan rekod harian, cabaran kelas, pemantauan masa rehat, dan merit sahsiah untuk semua murid.
  - **Aras 2 (Bersasar)**: Check-in mentor UBK/PRS, pelan 5 hari *"Saya Kembali Hari Ini"*, dan makluman peribadi penjaga bagi murid lewat/berulang.
  - **Aras 3 (Intensif)**: Program Ziarah Cakna ke rumah, perjumpaan khas Pengetua/PK HEM, serta pelan pemulihan UBK & Disiplin bagi kes berisiko tinggi.
- **1.3 Pautan Akses Portal (Launchpad)**:
  - **Peti Pautan Pintar**: Memaparkan 3 pautan khas ke Portal Guru (`/#/sign-in`), Portal Ibu Bapa (`/#/parent`), dan Portal Murid (`/#/student`).

---

### 2. 🔑 Log Masuk & Kawalan Akses Staf (Auth & RBAC)
- **2.1 Log Masuk Staf**:
  - **E-mel & Kata Laluan**: Guru dan pentadbir sekolah log masuk melalui kawalan keselamatan Supabase Auth.
- **2.2 Kawalan Hak Akses (Role-Based Access Control - RBAC)**:
  - **Peranan Admin (Pentadbir)**: Akses penuh ke semua modul, tetapan sistem, pengurusan akaun guru, dan laporan.
  - **Peranan Disiplin (Guru Disiplin)**: Akses khas ke Modul Disiplin SSDOP, pendaftaran kes, dan penerbitan Pengumuman Disiplin.
  - **Peranan Kaunselor (Guru UBK)**: Akses khas ke Modul Kaunseling UBK, rekod sesi, Peti Suara Murid, dan penerbitan Pengumuman Kaunseling.
  - **Peranan Guru Kelas / Subjek**: Akses ke imbasan QR harian, penandaan manual kelas, dan paparan merit murid.

---

### 3. 📷 Modul Imbasan QR & Kehadiran Harian
- **3.1 Imbasan Kad QR Name Tag Murid**:
  - **Pencegahan Impersonasi**: Murid diimbas menggunakan Kod QR unik pada Kad Name Tag murid (bukan No. IC) untuk mengelakkan penipuan kehadiran.
  - **Nisbah Masa Sesi**: Masa cutoff automatik diselaraskan mengikut Sesi Pagi (T3, T4, T5) dan Sesi Petang (T1, T2) serta hari persekolahan.
  - **Derivasi Status**: Imbasan sebelum cutoff dikira *Hadir*, imbasan selepas cutoff dikira *Lewat*.
- **3.2 Kemaskini Manual & Kemaskini Pukal**:
  - **Kemaskini Pukal**: Guru boleh menandakan kelas dengan *Default Hadir* dan hanya mendaftarkan murid yang *Tidak Hadir*, *Cuti Sakit (MC)*, atau *Urusan Rasmi*.
- **3.3 Pendaftaran & Gantian Kad QR**:
  - **Kemudahan Guru**: Mana-mana guru boleh mendaftarkan atau menggantikan Kad QR murid yang hilang/rosak secara terus.

---

### 4. 🏆 Modul Mata Merit & Pengiktirafan Sahsiah
- **4.1 Sistem 4 Mata Merit Harian D2C**:
  - **Step 01 (Hadir Ke Sekolah)**: +1 Mata Merit apabila hadir pada hari persekolahan.
  - **Step 02 (Tepat Masa)**: +1 Mata Merit apabila berada di kelas pada waktu ditetapkan.
  - **Step 03 (Kembali Selepas Rehat)**: +1 Mata Merit apabila masuk kelas selepas waktu rehat tanpa berkeliaran.
  - **Step 04 (Kekal Tamat Sesi)**: +1 Mata Merit apabila mengikuti PdP sehingga tamat sesi persekolahan.
- **4.2 Mata Merit Tambahan & Pengecualian**:
  - **Bonus Sahsiah**: Guru boleh menambah mata bonus bagi aktiviti khas sekolah.
- **4.3 Leaderboard & Sijil Pengiktirafan**:
  - **Carta Kedudukan**: Memaparkan kedudukan murid & kelas tertinggi mengikut kriteria mingguan/bulanan.
  - **6 Kategori Anugerah**: Pengiktirafan automatik bagi kehadiran penuh dan peningkatan sahsiah.

---

### 5. 📊 Modul Papan Pemuka Analytics (Dashboard)
- **5.1 Kad Statistik Utama (Present Breakdown Alignment)**:
  - **Penyelarasan Kad Hadir**: Memaparkan jumlah keseluruhan (*328 Total Present: 320 Hadir • 7 MC • 1 Rasmi*).
  - **Kad Stat Lengkap**: Hadir (Green), Tidak Hadir (Red), Lewat (Amber), dan Cuti/Rasmi (Blue).
- **5.2 Graf Analytics & Visualisasi**:
  - **Graf Trend Kehadiran**: Graf garis mingguan/bulanan peratusan sekolah.
  - **Taburan Masa Imbasan**: Taburan waktu ketibaan murid di sekolah.
  - **Heatmap Kehadiran**: Visual perbandingan kehadiran mengikut hari persekolahan.
  - **Kedudukan Kelas**: Menampilkan 5 Kelas Terbaik & Toggle 5 Kelas Perlu Perhatian.
- **5.3 Penyusunan Kad Boleh Ubah (Drag & Drop / Button Fallback)**:
  - **Drag to Reorder**: Guru boleh menyusun semula posisi kad statistik mengikut keutamaan.

---

### 6. ⚖️ Modul Disiplin & Kaunseling (SSDOP / UBK - `/#/discipline-counseling`)
- **6.1 Tab 1: Kes Disiplin SSDOP**:
  - **Pendaftaran Kes**: Mengikut Kes Ringan, Sederhana, dan Berat.
  - **✍️ Special Announcement (Discipline)**: Borang pengumuman khas Guru Disiplin (Coklat/Emas) untuk menerbitkan pengumuman terus ke Portal Murid dan menyalin teks format WhatsApp PIBG.
- **6.2 Tab 2: Sesi Kaunseling UBK**:
  - **Rekod Sesi Kaunseling**: Pendaftaran Kaunseling Individu, Kelompok, Kerjaya, dan Sahsiah.
  - **✍️ Special Announcement (Kaunseling UBK)**: Borang pengumuman khas Guru UBK (Ungu) untuk menerbitkan pengumuman terus ke Portal Murid dan menyalin teks format WhatsApp PIBG.
- **6.3 Tab 3: Peti Suara Murid (Teacher Inbox)**:
  - **Inbox Suara Murid**: Tempat Guru Kaunselor & Guru Disiplin membaca hantaran murid.
  - **Perlindungan Identiti (Anonymous)**: Bagi aduan buli/keselamatan yang dihantar secara rahsia, nama & kelas murid dilindungi sebagai `SULIT / RAHSIA (ANONYMOUS)`.
  - **Maklum Balas Guru**: Guru boleh mengemaskini status dan menulis nota respon yang dibaca oleh murid di portal mereka.

---

### 7. 📈 Modul Laporan & Eksport WhatsApp
- **7.1 Laporan Trend KPI D2C**:
  - **Laporan KPI**: Kadar Kehadiran, Murid Berisiko (At-Risk), Ketidakhadiran Berulang, Chronic Latecomers (lewat ≥3 kali), dan Pecahan Jenis Cuti.
- **7.2 Penjana Laporan WhatsApp PIBG (WhatsApp Report Generator)**:
  - **Format Mesra WhatsApp**: Menjanakan teks laporan kehadiran mengikut Sesi Pagi dan Sesi Petang.
  - **Butang Salin 1-Klik**: Memudahkan guru menyalin laporan terus ke kumpulan WhatsApp PIBG / Sekolah.

---

### 8. 👨‍👩‍👧‍👦 Portal Ibu Bapa (Parent Portal - `/#/parent`)
- **8.1 Carian No. IC Penjaga (MyKad Lookup)**:
  - **Tanpa Log Masuk Rumit**: Ibu bapa hanya perlu memasukkan No. IC / MyKad Penjaga yang berdaftar.
- **8.2 Sokongan Berbilang Anak (Multi-Sibling Tab Bar)**:
  - **Tab Berbilang Anak**: Paparan automatik tab untuk setiap anak jika penjaga mempunyai lebih daripada seorang anak di SMK Sungai Damit.
- **8.3 Paparan Rekod Anak**:
  - **Statistik Real-Time**: Peratus kehadiran %, hari hadir/tidak hadir, dan jumlah mata merit anak.

---

### 9. 🎓 Portal Murid & Suara Murid (`/#/student`)
- **9.1 Log Masuk Selamat Kad QR Name Tag**:
  - **Imbasan Kamera Kad QR**: Murid mengimbas Kod QR pada kad nama fizikal mereka atau memasukkan 8-aksara kod token.
- **9.2 Tab 1: 📢 Pengumuman (BAHARU)**:
  - **Paparan Pengumuman Rasmi**: Memaparkan Pengumuman Disiplin (Coklat/Emas) dan Pengumuman Kaunseling UBK (Ungu) yang diterbitkan oleh guru secara langsung (Live Sync).
- **9.3 Tab 2: 📈 Kemajuan Saya**:
  - **Rekod Kehadiran 30 Hari**: Cip status harian 30 hari terkini, jumlah mata merit, dan kadar peratusan.
- **9.4 Tab 3: 📣 Suara Murid (Peti Cadangan & Aduan Rahsia)**:
  - **4 Kategori Hantaran**: (1) Cadangan Sekolah, (2) Maklum Balas Pembelajaran, (3) Aduan Buli & Keselamatan, (4) Permohonan Kaunseling UBK.
  - **Pilihan Hantar Secara Rahsia (Anonymous)**: Murid boleh menyembunyikan nama & kelas bagi aduan buli demi keselamatan.
  - **Penjejak Status Respon**: Murid menyemak status hantaran (Baru, Dalam Tindakan, Selesai) dan membaca maklum balas guru.
- **9.5 Tab 4: 🌟 Inspirasi & Pengumuman**:
  - **Kata-kata Semangat**: Slogan motivasi sahsiah & info kejayaan program D2C.

---

### 10. ⚙️ Tetapan Sistem & Pengurusan Akaun (Settings)
- **10.1 Tetapan Tempoh Program & Merit**: Tetapan tarikh mula/tamat D2C & kawalan rutin merit.
- **10.2 Tetapan Masa Masuk (Cutoff Times)**: Tetapan waktu cutoff Sesi Pagi & Sesi Petang mengikut hari persekolahan.
- **10.3 Pengurusan Akaun Guru & Staf**: Penambahan e-mel guru dan penentuan peranan (Admin, Disiplin, Kaunselor, Teacher).

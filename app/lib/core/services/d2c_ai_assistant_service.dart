import 'dart:convert';
import 'package:http/http.dart' as http;

class D2CAiChatMessage {
  D2CAiChatMessage({
    required this.sender, // 'user' or 'ai'
    required this.text,
    required this.timestamp,
  });

  final String sender;
  final String text;
  final DateTime timestamp;
}

class D2CAiAssistantService {
  D2CAiAssistantService({this.apiKey});

  final String? apiKey;

  static const String _d2cSystemPrompt = '''
Anda adalah Pembantu AI Rasmi D2C (Dare to Change) bagi Sekolah Menengah Kebangsaan Sungai Damit, Tamparuli, Sabah.
Motto Sekolah: "ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs"
Tagline Program: "Saya Hadir, Saya Kekal, Saya Berjaya!"
Tema D2C: "Hadir Hari Ini, Menang Esok Hari"

Tugas Utama Anda:
1. Membantu Pengetua, Guru-Guru, Guru Kaunselor (UBK), Guru Disiplin, Ibu Bapa, dan Murid memahami sistem D2C.
2. Menerangkan 4 Rutin Merit Harian (+1 Hadir, +1 Tepat Masa, +1 Kembali Rehat, +1 Kekal Tamat Sesi).
3. Menerangkan 3 Aras Intervensi D2C (Aras 1 Universal T1-T5, Aras 2 Bersasar Mentor UBK/PRS, Aras 3 Intensif Ziarah Cakna & Pengetua).
4. Menerangkan Waktu Cutoff Sesi Pagi (Tingkatan 3, 4, 5) dan Sesi Petang (Tingkatan 1, 2).
5. Menerangkan panduan Portal Ibu Bapa (Carian No. IC Penjaga), Portal Murid (Imbas QR Name Tag & Suara Murid Rahsia/Anonymous), dan Ruang Disiplin & Kaunseling.

Sentiasa jawab dengan sopan, mesra, bersemangat, profesional, dan dalam Bahasa Melayu yang jelas dengan penggunaan emoji yang sesuai.
''';

  Future<String> askAi(String userPrompt, List<D2CAiChatMessage> chatHistory) async {
    // If Gemini API Key is available, try Gemini API call
    if (apiKey != null && apiKey!.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final contents = [
          {
            'role': 'user',
            'parts': [
              {'text': _d2cSystemPrompt}
            ]
          },
          ...chatHistory.take(6).map((m) => {
                'role': m.sender == 'user' ? 'user' : 'model',
                'parts': [
                  {'text': m.text}
                ]
              }),
          {
            'role': 'user',
            'parts': [
              {'text': userPrompt}
            ]
          }
        ];

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'contents': contents}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final reply = parts[0]['text'] as String?;
              if (reply != null && reply.isNotEmpty) {
                return reply.trim();
              }
            }
          }
        }
      } catch (_) {
        // Fallback to local intelligent knowledge engine
      }
    }

    // Intelligent D2C Knowledge Engine (Offline / Standalone Fallback)
    return _generateSmartLocalResponse(userPrompt);
  }

  String _generateSmartLocalResponse(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('tingkatan') ||
        lower.contains('terlibat') ||
        lower.contains('sasaran') ||
        lower.contains('kelas') ||
        lower.contains('siapa') ||
        lower.contains('sesi')) {
      return '''
🏫 **Tingkatan & Kumpulan Terlibat dalam Program D2C (SMK Sungai Damit)**:

Program **Dare to Change (D2C)** melibatkan **SEMUA murid dari Tingkatan 1 hingga Tingkatan 5**:

- ☀️ **Sesi Pagi (Tingkatan 3, 4, dan 5)**:
  - Waktu Sesi: Sebelum 7:00 AM hingga 1:00 PM.
  - Penandaan Kehadiran oleh Guru Tingkatan pada 7:30 AM.

- 🌙 **Sesi Petang (Tingkatan 1 dan 2)**:
  - Waktu Sesi: Sebelum 1:00 PM hingga 6:00 PM.
  - Penandaan Kehadiran oleh Guru Tingkatan pada 1:30 PM.

Semua murid (Tingkatan 1-5) mengumpul sehingga **4 Mata Merit Harian** secara automatik setiap hari! 🌟''';
    }

    if (lower.contains('maksud d2c') ||
        lower.contains('apa itu d2c') ||
        lower.contains('definisi d2c') ||
        lower.contains('objektif d2c') ||
        lower.contains('matlamat d2c')) {
      return '''
🚀 **Maksud & Matlamat Program Dare to Change (D2C)**:

D2C ialah program transformasi kehadiran digital dan sahsiah murid di **SMK Sungai Damit, Tamparuli, Sabah** di bawah tema *"Hadir Hari Ini, Menang Esok Hari"* dan slogan *"Saya Hadir, Saya Kekal, Saya Berjaya!"*.

**Matlamat Utama D2C**:
1. 📈 Meningkatkan peratus kehadiran murid sekolah ke sasaran **95%+**.
2. ⏱️ Mengurangkan kes murid lewat dan ponteng kelas.
3. 🏆 Memberikan pengiktirafan harian & mingguan melalui **4 Mata Merit Harian**.
4. 🛡️ Melaksanakan **3 Aras Intervensi** (Universal, UBK/PRS, Ziarah Cakna).''';
    }

    if (lower.contains('slogan') || lower.contains('motto') || lower.contains('tagline') || lower.contains('tema')) {
      return '''
🌟 **Motto & Tagline Rasmi D2C SMK Sungai Damit**:

- 🏫 **Motto Sekolah**: *"ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs"*
- ⚡ **Tema Utama D2C**: *"Hadir Hari Ini, Menang Esok Hari"*
- 🎯 **Tagline Murid**: *"Saya Hadir, Saya Kekal, Saya Berjaya!"*''';
    }

    if (lower.contains('merit') || lower.contains('mata') || lower.contains('markah')) {
      return '''
🏆 **Sistem 4 Mata Merit Harian D2C (SMK Sungai Damit)**:

Setiap murid mengumpul sehingga **4 Mata Merit** setiap hari:
1. ☀️ **Step 01 (+1 Mata)**: Hadir Ke Sekolah pada hari persekolahan.
2. ⏰ **Step 02 (+1 Mata)**: Tepat Masa berada di dalam kelas mengikut sesi.
3. 🔔 **Step 03 (+1 Mata)**: Kembali Ke Kelas Selepas Waktu Rehat tanpa berkeliaran.
4. 🏁 **Step 04 (+1 Mata)**: Kekal Mengikuti PdP sehingga Tamat Sesi Persekolahan.

Mata merit dikumpul secara automatik untuk **Merit Individu** dan **Merit Kelas**! 🌟''';
    }

    if (lower.contains('aras') || lower.contains('intervensi') || lower.contains('tahap')) {
      return '''
🛡️ **3 Aras Intervensi D2C**:

1. 🔵 **Aras 1 (Universal)**: Untuk seluruh murid (Tingkatan 1 hingga 5). Merangkumi imbasan QR harian, cabaran kelas, pemantauan masa rehat, dan pengiktirafan mingguan.
2. 🟡 **Aras 2 (Bersasar)**: Untuk murid lewat berulang atau berisiko. Merangkumi check-in mentor UBK/PRS, pelan 5 hari "Saya Kembali Hari Ini", dan makluman peribadi kepada penjaga.
3. 🔴 **Aras 3 (Intensif)**: Bagi kes berisiko tinggi. Merangkumi Program Ziarah Cakna ke rumah, perjumpaan khas Pengetua/PK HEM bersama penjaga, serta pelan pemulihan UBK & Disiplin.''';
    }

    if (lower.contains('suara murid') || lower.contains('aduan') || lower.contains('buli') || lower.contains('rahsia') || lower.contains('sulit')) {
      return '''
📣 **Portal Murid — Suara Murid & Aduan Rahsia**:

1. Log masuk ke Portal Murid di `/#/student` menggunakan **Imbasan Kod QR Name Tag** anda.
2. Buka **Tab 3: Suara Murid**.
3. Pilih kategori hantaran:
   - 💡 Cadangan Sekolah
   - 📖 Makluman Pembelajaran
   - 🛡️ Aduan Buli & Keselamatan
   - 💚 Sesi Kaunseling UBK
4. **Pilihan Hantar Secara Rahsia (Anonymous)**: Tandakan kotak *Sulit / Rahsia* untuk menyembunyikan nama & kelas anda demi keselamatan.
5. Guru Kaunselor & Guru Disiplin akan menerima dan memberikan maklum balas rasmi di portal anda! 🔒''';
    }

    if (lower.contains('ibu bapa') || lower.contains('parent') || lower.contains('penjaga') || lower.contains('ic')) {
      return '''
👨‍👩‍👧‍👦 **Portal Ibu Bapa (Parent Portal)**:

1. Layari pautan **`https://d2csummit.online/#/parent`**.
2. Masukkan **No. IC / MyKad Penjaga** yang berdaftar.
3. **Sokongan Multi-Sibling**: Jika anda mempunyai lebih daripada seorang anak di SMK Sungai Damit, sistem akan memaparkan tab untuk setiap anak secara automatik!
4. Anda boleh menyemak peratus kehadiran %, jumlah hari hadir/tidak hadir, status real-time hari ini, dan mata merit anak. 📈''';
    }

    if (lower.contains('pengumuman') || lower.contains('disiplin') || lower.contains('kaunseling') || lower.contains('ubk')) {
      return '''
📢 **Modul Pengumuman Disiplin & UBK (Portal Guru & Murid)**:

- **Bagi Guru**: Di ruang **Disiplin & Kaunseling** (`/#/discipline-counseling`), Guru Disiplin dan Guru UBK mempunyai borang **Special Announcement** untuk menerbitkan pesanan rasmi (dengan atau tanpa lampiran murid) dan menyalin teks WhatsApp PIBG.
- **Bagi Murid**: Pengumuman rasmi daripada guru akan dipaparkan secara **Live Sync** di **Tab 1: 📢 Pengumuman** dalam Portal Murid (`/#/student`)! ⚡''';
    }

    if (lower.contains('sudut info') || lower.contains('hebahan') || lower.contains('makluman')) {
      return '''
ℹ️ **Sudut Info Disiplin & Kaunseling (D2C)**:

Sudut Info dipaparkan secara langsung pada Halaman Utama (Landing Page) & Portal Murid.
- Guru Disiplin & Guru Kaunselor (UBK) boleh memasukkan pengumuman, jadual program, dan tips sahsiah di tab **Sudut Info** (`/#/discipline-counseling`).
- Tempoh paparan boleh dijadualkan mengikut masa mula dan masa tamat yang ditetapkan oleh guru!''';
    }

    if (lower.contains('jadual') || lower.contains('tarikh') || lower.contains('pelancaran') || lower.contains('penilaian')) {
      return '''
📅 **Jadual Pelaksanaan D2C 2026**:

- 🚀 **1 Ogos 2026**: Pelancaran Program D2C di seluruh sekolah (Tingkatan 1 hingga 5).
- 🔄 **Sepanjang Program**: Pemantauan harian, intervensi mentor UBK/PRS, dan pengiktirafan mingguan/bulanan.
- 🏆 **31 Oktober 2026**: Penilaian Akhir & Penutupan Fasa 1 Program D2C.''';
    }

    if (lower.contains('pengetua') || lower.contains('jawatankuasa') || lower.contains('hem') || lower.contains('guru')) {
      return '''
🏛️ **Jawatankuasa Induk Program D2C SMK Sungai Damit**:

- **Pengerusi**: Pn. Fauziah Binti Mahrop (Pengetua)
- **Naib Pengerusi I**: En. Norzalizan bin Bahari (PK HEM)
- **Naib Pengerusi II**: Pn. Lucy Gansoi (PK Pentadbiran)
- **Naib Pengerusi III**: Pn. Roslinah @ Winda Binti Majimin (PK Kokurikulum)
- **Naib Pengerusi IV**: Pn. Jarisah Gondikit (PK Petang)
- **Setiausaha**: Pn. Emily Subin (Guru Bimbingan & Kaunseling)''';
    }

    return '''
🤖 **Maklumat Program D2C (SMK Sungai Damit)**:

Mengenai pertanyaan anda (*"$prompt"*):

Program **Dare to Change (D2C)** merangkumi seluruh warga sekolah (Tingkatan 1 hingga 5).

Berikut ialah jawapan ringkas bagi topik berkaitan:
- 🏫 **Tingkatan Terlibat**: Semua murid Tingkatan 1, 2, 3, 4 & 5 (Sesi Pagi: T3-T5, Sesi Petang: T1-T2).
- 🏆 **4 Mata Merit**: (+1 Hadir, +1 Tepat Masa, +1 Kembali Rehat, +1 Tamat Sesi).
- 🛡️ **3 Aras Intervensi**: Aras 1 (Universal), Aras 2 (Mentor UBK/PRS), Aras 3 (Ziarah Cakna Pengetua).
- 👨‍👩‍👧‍👦 **Portal Ibu Bapa**: Semakan kehadiran anak guna No. IC Penjaga di `/#/parent`.
- 📣 **Suara Murid Rahsia**: Aduan buli & cadangan rahsia di `/#/student`.

*Sila taip soalan anda atau pilih butang cadangan di bawah!* ⚡''';
  }
}

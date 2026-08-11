import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SchoolLandingScreen extends StatefulWidget {
  const SchoolLandingScreen({super.key});

  @override
  State<SchoolLandingScreen> createState() => _SchoolLandingScreenState();
}

class _SchoolLandingScreenState extends State<SchoolLandingScreen> {
  final _scrollController = ScrollController();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  final _aboutKey = GlobalKey();
  final _levelsKey = GlobalKey();
  final _meritKey = GlobalKey();
  final _committeeKey = GlobalKey();
  final _portalsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/crest.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 32),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SMK SUNGAI DAMIT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'TAMPARULI, SABAH',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (MediaQuery.of(context).size.width > 900) ...[
            TextButton(
              onPressed: () => _scrollToSection(_aboutKey),
              child: const Text('Mengenai D2C'),
            ),
            TextButton(
              onPressed: () => _scrollToSection(_levelsKey),
              child: const Text('3 Aras Intervensi'),
            ),
            TextButton(
              onPressed: () => _scrollToSection(_meritKey),
              child: const Text('Sistem Merit'),
            ),
            TextButton(
              onPressed: () => _scrollToSection(_committeeKey),
              child: const Text('Jawatankuasa'),
            ),
            const SizedBox(width: 12),
          ],
          PopupMenuButton<String>(
            tooltip: 'Portal Akses',
            onSelected: (route) => context.go(route),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_open, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Portal Akses', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '/sign-in',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Portal Guru / Pentadbir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: '/parent',
                child: Row(
                  children: [
                    Icon(Icons.family_restroom, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Portal Ibu Bapa (Semakan IC)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: '/student',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.purple),
                    SizedBox(width: 10),
                    Text('Portal Murid (Kad QR & Suara Murid)'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // HERO SECTION - CENTER OF ATTENTION (D2C SPOTLIGHT)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), Colors.indigo.shade900]
                      : [Colors.blue.shade900, Colors.indigo.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade400,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'PROGRAM INTERVENSI KEHADIRAN IMPAK TINGGI 2026',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'DARE TO CHANGE (D2C)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '"Hadir Hari Ini, Menang Esok Hari"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Saya Hadir, Saya Kekal, Saya Berjaya!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Sasaran: Seluruh Warga Sekolah — Tingkatan 1, 2, 3, 4 & 5 (SMK Sungai Damit)',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _scrollToSection(_aboutKey),
                            icon: const Icon(Icons.explore),
                            label: const Text('Terokai Program D2C'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade400,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _scrollToSection(_portalsKey),
                            icon: const Icon(Icons.devices),
                            label: const Text('Portal Akses Sistem'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.amber.shade200,
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // SECTION 1: MENGENAI D2C & STATS
            Container(
              key: _aboutKey,
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Text(
                        'MENGENAI PROGRAM DARE TO CHANGE (D2C)',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 4, color: Colors.amber.shade600),
                      const SizedBox(height: 24),
                      Text(
                        'Program Dare to Change (D2C) merupakan inisiatif menyeluruh Unit Bimbingan & Kaunseling (UBK) dengan kerjasama Jawatankuasa HEM dan Pentadbiran SMK Sungai Damit. Program ini bukan sekadar kempen kesedaran, malah sistem tindakan harian menyeluruh yang menghubungkan data kehadiran real-time, intervensi mentor, sokongan Pembimbing Rakan Sebaya (PRS), penglibatan ibu bapa, serta pengiktirafan merit sahsiah murid.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 36),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          _StatBox(title: 'Tingkatan Terlibat', value: 'T1 - T5', subtitle: 'Seluruh Murid'),
                          _StatBox(title: 'Kehadiran Digital', value: '100%', subtitle: 'Real-Time Check-In'),
                          _StatBox(title: 'Mata Merit Harian', value: '4 Mata', subtitle: 'Maksimum Sehari'),
                          _StatBox(title: 'Aras Intervensi', value: '3 Aras', subtitle: 'Universal hingga Intensif'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(),

            // SECTION 2: 3 ARAS INTERVENSI D2C
            Container(
              key: _levelsKey,
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Text(
                        '3 ARAS INTERVENSI DARE TO CHANGE',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 4, color: Colors.amber.shade600),
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _LevelCard(
                              color: Colors.blue,
                              level: 'ARAS 1: UNIVERSAL',
                              target: 'Semua Murid (T1 - T5)',
                              description: 'Rekod harian, 4 mata merit sehari, cabaran kelas, pemantauan transisi masa rehat, dan pengiktirafan mingguan/bulanan.',
                              icon: Icons.public,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LevelCard(
                              color: Colors.amber.shade800,
                              level: 'ARAS 2: BERSASAR',
                              target: 'Murid Berulang / Lewat',
                              description: 'Check-in mentor UBK/PRS, sasaran kecil, pelan 5 hari "Saya Kembali Hari Ini", dan makluman peribadi kepada penjaga.',
                              icon: Icons.track_changes,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LevelCard(
                              color: Colors.red,
                              level: 'ARAS 3: INTENSIF',
                              target: 'Kes Berisiko Tinggi',
                              description: 'Program Ziarah Cakna ke rumah, perjumpaan khas penjaga dengan Pengetua/HEM, serta pelan pemulihan UBK & Disiplin.',
                              icon: Icons.warning_amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // SECTION 3: SISTEM MATA MERIT HARIAN
            Container(
              key: _meritKey,
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Text(
                        'RUTIN & SISTEM MATA MERIT D2C',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 4, color: Colors.amber.shade600),
                      const SizedBox(height: 12),
                      const Text(
                        'Setiap murid mengumpul sehingga 4 mata merit setiap hari yang dijumlahkan sebagai Merit Individu dan Merit Kelas:',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: const [
                          _MeritItem(title: 'Hadir Ke Sekolah', points: '+1 Mata', desc: 'Hadir pada hari persekolahan'),
                          _MeritItem(title: 'Tepat Masa', points: '+1 Mata', desc: 'Berada di kelas pada masa ditetapkan'),
                          _MeritItem(title: 'Kembali Selepas Rehat', points: '+1 Mata', desc: 'Masuk kelas selepas rehat tanpa berkeliaran'),
                          _MeritItem(title: 'Kekal Tamat Sesi', points: '+1 Mata', desc: 'Mengikuti sesi hingga waktu tamat'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(),

            // SECTION 4: JAWATANKUASA INDUK
            Container(
              key: _committeeKey,
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Text(
                        'JAWATANKUASA INDUK PROGRAM D2C',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 4, color: Colors.amber.shade600),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: const [
                          _LeaderCard(role: 'Pengerusi', name: 'Pn. Fauziah Binti Mahrop', title: 'Pengetua SMK Sungai Damit'),
                          _LeaderCard(role: 'Naib Pengerusi I', name: 'En. Norzalizan bin Bahari', title: 'PK Hal Ehwal Murid'),
                          _LeaderCard(role: 'Naib Pengerusi II', name: 'Pn. Lucy Gansoi', title: 'PK Pentadbiran'),
                          _LeaderCard(role: 'Naib Pengerusi III', name: 'Pn. Roslinah @ Winda Binti Majimin', title: 'PK Kokurikulum'),
                          _LeaderCard(role: 'Naib Pengerusi IV', name: 'Pn. Jarisah Gondikit', title: 'PK Petang'),
                          _LeaderCard(role: 'Setiausaha', name: 'Pn. Emily Subin', title: 'Guru Bimbingan & Kaunseling'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // SECTION 5: PORTAL AKSES SISTEM (SUBTLE SECTION)
            Container(
              key: _portalsKey,
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Text(
                        'PAUTAN AKSES PORTAL D2C',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 4, color: Colors.amber.shade600),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _PortalCard(
                              icon: Icons.admin_panel_settings,
                              color: Colors.blue,
                              title: 'Portal Guru & Pentadbir',
                              subtitle: 'Log masuk pengurusan kehadiran, merit & disiplin sekolah.',
                              buttonText: 'Log Masuk Guru',
                              onTap: () => context.go('/sign-in'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PortalCard(
                              icon: Icons.family_restroom,
                              color: Colors.green,
                              title: 'Portal Ibu Bapa',
                              subtitle: 'Semakan kehadiran real-time anak menggunakan No. IC Penjaga.',
                              buttonText: 'Semakan Ibu Bapa',
                              onTap: () => context.go('/parent'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PortalCard(
                              icon: Icons.qr_code_scanner,
                              color: Colors.purple,
                              title: 'Portal Murid',
                              subtitle: 'Imbas QR Name Tag, semak merit & hantar Suara Murid.',
                              buttonText: 'Portal Murid',
                              onTap: () => context.go('/student'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FOOTER
            Container(
              width: double.infinity,
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    'SEKOLAH MENENGAH KEBANGSAAN SUNGAI DAMIT',
                    style: TextStyle(color: Colors.amber.shade300, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Peti Surat 232, 89257 Tamparuli, Sabah',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs',
                    style: TextStyle(color: Colors.amber.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '© 2026 SMK Sungai Damit. D2C Summit System.',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.color,
    required this.level,
    required this.target,
    required this.description,
    required this.icon,
  });

  final Color color;
  final String level;
  final String target;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
            const SizedBox(height: 12),
            Text(level, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            const SizedBox(height: 4),
            Text(target, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _MeritItem extends StatelessWidget {
  const _MeritItem({required this.title, required this.points, required this.desc});

  final String title;
  final String points;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              Chip(
                backgroundColor: Colors.amber.shade200,
                label: Text(points, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({required this.role, required this.name, required this.title});

  final String role;
  final String name;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(name.isNotEmpty ? name[0] : 'G', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 16),
              label: Text(buttonText),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                foregroundColor: color,
                side: BorderSide(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

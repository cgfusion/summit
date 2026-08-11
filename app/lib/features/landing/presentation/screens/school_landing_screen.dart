import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SchoolLandingScreen extends StatefulWidget {
  const SchoolLandingScreen({super.key});

  @override
  State<SchoolLandingScreen> createState() => _SchoolLandingScreenState();
}

class _SchoolLandingScreenState extends State<SchoolLandingScreen> {
  final _scrollController = ScrollController();

  final _aboutKey = GlobalKey();
  final _levelsKey = GlobalKey();
  final _meritKey = GlobalKey();
  final _committeeKey = GlobalKey();
  final _portalsKey = GlobalKey();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgDark = isDark ? const Color(0xFF090D16) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // MAIN SCROLLABLE CONTENT
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 80), // Top padding for floating glass bar

                // HERO BANNER - HIGH TECH D2C SPOTLIGHT
                _TechHeroBanner(
                  onExplore: () => _scrollToSection(_aboutKey),
                  onOpenPortals: () => _scrollToSection(_portalsKey),
                ),

                // SECTION 1: MENGENAI D2C & HIGH-TECH METRICS
                _TechAboutSection(key: _aboutKey),

                // SECTION 2: 3 ARAS INTERVENSI D2C
                _TechLevelsSection(key: _levelsKey),

                // SECTION 3: RUTIN & SISTEM MATA MERIT HARIAN
                _TechMeritSection(key: _meritKey),

                // SECTION 4: JAWATANKUASA INDUK
                _TechLeadershipSection(key: _committeeKey),

                // SECTION 5: PORTAL LAUNCHPAD SECTION
                _TechPortalLaunchpadSection(key: _portalsKey),

                // FUTURISTIC FOOTER
                const _TechFooter(),
              ],
            ),
          ),

          // FLOATING GLASS NAVBAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _FloatingGlassHeader(
              onNavAbout: () => _scrollToSection(_aboutKey),
              onNavLevels: () => _scrollToSection(_levelsKey),
              onNavMerit: () => _scrollToSection(_meritKey),
              onNavCommittee: () => _scrollToSection(_committeeKey),
              onNavPortals: () => _scrollToSection(_portalsKey),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FLOATING GLASS HEADER
// ---------------------------------------------------------------------------
class _FloatingGlassHeader extends StatelessWidget {
  const _FloatingGlassHeader({
    required this.onNavAbout,
    required this.onNavLevels,
    required this.onNavMerit,
    required this.onNavCommittee,
    required this.onNavPortals,
  });

  final VoidCallback onNavAbout;
  final VoidCallback onNavLevels;
  final VoidCallback onNavMerit;
  final VoidCallback onNavCommittee;
  final VoidCallback onNavPortals;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.8),
            border: const Border(bottom: BorderSide(color: Color(0x1F38BDF8))),
          ),
          child: Row(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.3), blurRadius: 10),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/crest.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => const Icon(Icons.school, size: 28, color: Color(0xFF38BDF8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SMK SUNGAI DAMIT',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white, letterSpacing: 0.5),
                      ),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text(
                            'TAMPARULI • D2C SYSTEM ONLINE',
                            style: TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (MediaQuery.of(context).size.width > 920) ...[
                _NavTextButton(label: 'Mengenai D2C', onTap: onNavAbout),
                _NavTextButton(label: '3 Aras Intervensi', onTap: onNavLevels),
                _NavTextButton(label: 'Sistem Merit', onTap: onNavMerit),
                _NavTextButton(label: 'Jawatankuasa', onTap: onNavCommittee),
                const SizedBox(width: 12),
              ],
              PopupMenuButton<String>(
                tooltip: 'Portal Akses',
                onSelected: (route) => context.go(route),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                ),
                color: const Color(0xFF0F172A),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF4F46E5)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 16, color: Color(0xFFFDE047)),
                      SizedBox(width: 6),
                      Text('PORTAL AKSES', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  _buildMenuItem('/sign-in', Icons.admin_panel_settings, 'Portal Guru & Pentadbir', 'Akses Pengurusan Sekolah', Colors.blue),
                  _buildMenuItem('/parent', Icons.family_restroom, 'Portal Ibu Bapa', 'Semakan IC Real-Time', Colors.green),
                  _buildMenuItem('/student', Icons.qr_code_scanner, 'Portal Murid', 'Kad QR & Suara Murid', Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String route, IconData icon, String title, String subtitle, MaterialColor color) {
    return PopupMenuItem<String>(
      value: route,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.shade900.withValues(alpha: 0.4), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color.shade300),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavTextButton extends StatelessWidget {
  const _NavTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HIGH TECH HERO BANNER
// ---------------------------------------------------------------------------
class _TechHeroBanner extends StatelessWidget {
  const _TechHeroBanner({required this.onExplore, required this.onOpenPortals});

  final VoidCallback onExplore;
  final VoidCallback onOpenPortals;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF090D16)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // GLOWING BADGE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.3), blurRadius: 16),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFFDE047), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'HIGH-IMPACT DIGITAL SAHSIAH & ATTENDANCE SYSTEM 2026',
                      style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // GRADIENT HEADLINE
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFF38BDF8), Color(0xFFFDE047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'DARE TO CHANGE (D2C)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // THEME SLOGAN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x22FDE047),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x66FDE047)),
                ),
                child: const Text(
                  '"Hadir Hari Ini, Menang Esok Hari"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Saya Hadir, Saya Kekal, Saya Berjaya!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.5),
              ),
              const SizedBox(height: 28),

              // TARGET CARD BADGE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups, color: Color(0xFF38BDF8), size: 20),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Sasaran: Seluruh Warga Sekolah — Tingkatan 1, 2, 3, 4 & 5 (SMK Sungai Damit)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ACTION BUTTONS
              Wrap(
                spacing: 20,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onExplore,
                    icon: const Icon(Icons.rocket_launch, size: 18),
                    label: const Text('TEROKAI SISTEM D2C'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                      elevation: 8,
                      shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenPortals,
                    icon: const Icon(Icons.hub, size: 18),
                    label: const Text('PORTAL AKSES D2C'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // MOTTO PILL
              Text(
                'ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFDE047).withValues(alpha: 0.9),
                  fontSize: 12,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HIGH TECH ABOUT SECTION & METRICS
// ---------------------------------------------------------------------------
class _TechAboutSection extends StatelessWidget {
  const _TechAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B),
        border: Border(top: BorderSide(color: Color(0x1F38BDF8)), bottom: BorderSide(color: Color(0x1F38BDF8))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const _TechSectionTitle(
                tag: 'OVERVIEW',
                title: 'MENGENAI PROGRAM DARE TO CHANGE (D2C)',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'Program Dare to Change (D2C) dirancang sebagai program menyeluruh bagi semua murid SMK Sungai Damit. Program ini bukan sekadar kempen kesedaran, tetapi satu sistem tindakan harian yang menghubungkan data kehadiran real-time, intervensi mentor, sokongan Pembimbing Rakan Sebaya (PRS), penglibatan penjaga, serta ganjaran berasaskan usaha dan peningkatan sahsiah murid.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15, height: 1.7),
                ),
              ),
              const SizedBox(height: 40),

              // METRICS GRID
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: const [
                  _TechMetricCard(icon: Icons.school, title: 'Tingkatan Terlibat', value: 'T1 - T5', subtitle: 'Seluruh Murid', color: Color(0xFF38BDF8)),
                  _TechMetricCard(icon: Icons.qr_code_scanner, title: 'Kehadiran Digital', value: '100%', subtitle: 'Real-Time Scan', color: Color(0xFF10B981)),
                  _TechMetricCard(icon: Icons.military_tech, title: 'Mata Merit Harian', value: '4 Mata', subtitle: 'Maksimum Sehari', color: Color(0xFFFDE047)),
                  _TechMetricCard(icon: Icons.layers, title: 'Aras Intervensi', value: '3 Aras', subtitle: 'Universal -> Intensif', color: Color(0xFFA855F7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechMetricCard extends StatelessWidget {
  const _TechMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 ARAS INTERVENSI SECTION
// ---------------------------------------------------------------------------
class _TechLevelsSection extends StatelessWidget {
  const _TechLevelsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const _TechSectionTitle(
                tag: 'INTERVENTION MODEL',
                title: '3 ARAS INTERVENSI DARE TO CHANGE',
              ),
              const SizedBox(height: 36),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    child: _TechLevelCard(
                      color: Color(0xFF38BDF8),
                      level: 'ARAS 1: UNIVERSAL',
                      target: 'Semua Murid (T1 - T5)',
                      description: 'Rekod harian, 4 mata merit sehari, cabaran kelas, pemantauan transisi masa rehat, dan pengiktirafan mingguan/bulanan.',
                      icon: Icons.public,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _TechLevelCard(
                      color: Color(0xFFF59E0B),
                      level: 'ARAS 2: BERSASAR',
                      target: 'Murid Berulang / Lewat',
                      description: 'Check-in mentor UBK/PRS, sasaran kecil, pelan 5 hari "Saya Kembali Hari Ini", dan makluman peribadi kepada penjaga.',
                      icon: Icons.track_changes,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _TechLevelCard(
                      color: Color(0xFFEF4444),
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
    );
  }
}

class _TechLevelCard extends StatelessWidget {
  const _TechLevelCard({
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), radius: 24, child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 16),
          Text(level, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(target, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 10),
          Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade300, height: 1.5)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MERIT ROUTINE SECTION
// ---------------------------------------------------------------------------
class _TechMeritSection extends StatelessWidget {
  const _TechMeritSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B),
        border: Border(top: BorderSide(color: Color(0x1F38BDF8))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const _TechSectionTitle(
                tag: 'DAILY MERIT SYSTEM',
                title: 'RUTIN & SISTEM MATA MERIT D2C',
              ),
              const SizedBox(height: 12),
              const Text(
                'Setiap murid mengumpul sehingga 4 mata merit setiap hari yang dijumlahkan sebagai Merit Individu dan Merit Kelas:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: const [
                  _TechMeritTile(step: '01', title: 'Hadir Ke Sekolah', points: '+1 MATA', desc: 'Hadir pada hari persekolahan'),
                  _TechMeritTile(step: '02', title: 'Tepat Masa', points: '+1 MATA', desc: 'Berada di kelas pada masa ditetapkan'),
                  _TechMeritTile(step: '03', title: 'Kembali Selepas Rehat', points: '+1 MATA', desc: 'Masuk kelas selepas rehat tanpa berkeliaran'),
                  _TechMeritTile(step: '04', title: 'Kekal Tamat Sesi', points: '+1 MATA', desc: 'Mengikuti sesi hingga waktu tamat'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechMeritTile extends StatelessWidget {
  const _TechMeritTile({required this.step, required this.title, required this.points, required this.desc});

  final String step;
  final String title;
  final String points;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STEP $step', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0x33FDE047), borderRadius: BorderRadius.circular(10)),
                child: Text(points, style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LEADERSHIP SECTION
// ---------------------------------------------------------------------------
class _TechLeadershipSection extends StatelessWidget {
  const _TechLeadershipSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const _TechSectionTitle(
                tag: 'LEADERSHIP',
                title: 'JAWATANKUASA INDUK PROGRAM D2C',
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  _TechLeaderTile(role: 'Pengerusi', name: 'Pn. Fauziah Binti Mahrop', title: 'Pengetua SMK Sungai Damit'),
                  _TechLeaderTile(role: 'Naib Pengerusi I', name: 'En. Norzalizan bin Bahari', title: 'PK Hal Ehwal Murid'),
                  _TechLeaderTile(role: 'Naib Pengerusi II', name: 'Pn. Lucy Gansoi', title: 'PK Pentadbiran'),
                  _TechLeaderTile(role: 'Naib Pengerusi III', name: 'Pn. Roslinah @ Winda Binti Majimin', title: 'PK Kokurikulum'),
                  _TechLeaderTile(role: 'Naib Pengerusi IV', name: 'Pn. Jarisah Gondikit', title: 'PK Petang'),
                  _TechLeaderTile(role: 'Setiausaha', name: 'Pn. Emily Subin', title: 'Guru Bimbingan & Kaunseling'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechLeaderTile extends StatelessWidget {
  const _TechLeaderTile({required this.role, required this.name, required this.title});

  final String role;
  final String name;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
            child: Text(name.isNotEmpty ? name[0] : 'G', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: const TextStyle(fontSize: 11, color: Color(0xFFFDE047), fontWeight: FontWeight.bold)),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PORTAL LAUNCHPAD SECTION
// ---------------------------------------------------------------------------
class _TechPortalLaunchpadSection extends StatelessWidget {
  const _TechPortalLaunchpadSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B),
        border: Border(top: BorderSide(color: Color(0x1F38BDF8))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const _TechSectionTitle(
                tag: 'PORTAL LAUNCHPAD',
                title: 'PAUTAN AKSES PORTAL D2C',
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: _TechLaunchpadCard(
                      icon: Icons.admin_panel_settings,
                      color: const Color(0xFF38BDF8),
                      title: 'Portal Guru & Pentadbir',
                      subtitle: 'Log masuk pengurusan kehadiran, merit & disiplin sekolah.',
                      buttonText: 'LOG MASUK GURU',
                      onTap: () => context.go('/sign-in'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TechLaunchpadCard(
                      icon: Icons.family_restroom,
                      color: const Color(0xFF10B981),
                      title: 'Portal Ibu Bapa',
                      subtitle: 'Semakan kehadiran real-time anak menggunakan No. IC Penjaga.',
                      buttonText: 'SEMAKAN IBU BAPA',
                      onTap: () => context.go('/parent'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TechLaunchpadCard(
                      icon: Icons.qr_code_scanner,
                      color: const Color(0xFFA855F7),
                      title: 'Portal Murid',
                      subtitle: 'Imbas QR Name Tag, semak merit & hantar Suara Murid.',
                      buttonText: 'PORTAL MURID',
                      onTap: () => context.go('/student'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechLaunchpadCard extends StatelessWidget {
  const _TechLaunchpadCard({
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), radius: 24, child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400, height: 1.4)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 16),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: color,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FUTURISTIC FOOTER
// ---------------------------------------------------------------------------
class _TechFooter extends StatelessWidget {
  const _TechFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF050811),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text(
            'SEKOLAH MENENGAH KEBANGSAAN SUNGAI DAMIT',
            style: TextStyle(color: Colors.amber.shade300, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          const Text(
            'Peti Surat 232, 89257 Tamparuli, Sabah',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text(
            'ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs',
            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          const Text(
            '© 2026 SMK Sungai Damit • D2C Summit Cloud System v2.6.4',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// Helper: Tech Section Header Title
class _TechSectionTitle extends StatelessWidget {
  const _TechSectionTitle({required this.tag, required this.title});

  final String tag;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          tag,
          style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2.0),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Container(width: 60, height: 3, color: const Color(0xFFFDE047)),
      ],
    );
  }
}

import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _navy = Color(0xFF0F172A);
const _navyDeep = Color(0xFF090D16);
const _panel = Color(0xFF0B132B);
const _violet = Color(0xFF1E1B4B);
const _cyan = Color(0xFF38BDF8);
const _amber = Color(0xFFFDE047);
const _green = Color(0xFF10B981);
const _purple = Color(0xFFA855F7);
const _orange = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

/// Below this width, multi-column infographic layouts (timeline, intervention
/// flow, merit stepper, portal launchpad) collapse to a single connected
/// vertical column instead of squeezing horizontally.
const double _wideBreakpoint = 900;

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
    final bgDark = isDark ? _navyDeep : _navy;

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

                // PROGRAM TIMELINE INFOGRAPHIC
                const _TechTimelineSection(),

                // SECTION 1: MENGENAI D2C & HIGH-TECH METRICS
                _TechAboutSection(key: _aboutKey),

                // SECTION 2: 3 ARAS INTERVENSI D2C (escalation flow)
                _TechLevelsSection(key: _levelsKey),

                // SECTION 3: RUTIN & SISTEM MATA MERIT HARIAN (connected stepper + donut)
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
            color: _navy.withValues(alpha: 0.8),
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
                      border: Border.all(color: _cyan, width: 1.5),
                      boxShadow: [BoxShadow(color: _cyan.withValues(alpha: 0.3), blurRadius: 10)],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/crest.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => const Icon(Icons.school, size: 28, color: _cyan),
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
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text(
                            'TAMPARULI • D2C SYSTEM ONLINE',
                            style: TextStyle(fontSize: 10, color: _cyan, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
                  side: const BorderSide(color: _cyan, width: 1.5),
                ),
                color: _navy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF4F46E5)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 16, color: _amber),
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
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
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
        gradient: LinearGradient(colors: [_navy, _violet, _navyDeep], begin: Alignment.topCenter, end: Alignment.bottomCenter),
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
                  border: Border.all(color: _cyan.withValues(alpha: 0.5)),
                  boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.3), blurRadius: 16)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: _amber, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'HIGH-IMPACT DIGITAL SAHSIAH & ATTENDANCE SYSTEM 2026',
                      style: TextStyle(color: _cyan, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // GRADIENT HEADLINE
              ShaderMask(
                shaderCallback: (bounds) =>
                    const LinearGradient(colors: [Colors.white, _cyan, _amber], begin: Alignment.topLeft, end: Alignment.bottomRight)
                        .createShader(bounds),
                child: const Text(
                  'DARE TO CHANGE (D2C)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2.0, height: 1.1),
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
                  style: TextStyle(color: _amber, fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
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
                    Icon(Icons.groups, color: _cyan, size: 20),
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
                      backgroundColor: _cyan,
                      foregroundColor: _navy,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                      elevation: 8,
                      shadowColor: _cyan.withValues(alpha: 0.5),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenPortals,
                    icon: const Icon(Icons.hub, size: 18),
                    label: const Text('PORTAL AKSES D2C'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _cyan, width: 1.5),
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
                style: TextStyle(color: _amber.withValues(alpha: 0.9), fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROGRAM TIMELINE INFOGRAPHIC (new)
// ---------------------------------------------------------------------------
class _TimelineStop {
  const _TimelineStop({required this.icon, required this.color, required this.label, required this.dateLabel, required this.desc});

  final IconData icon;
  final Color color;
  final String label;
  final String dateLabel;
  final String desc;
}

class _TechTimelineSection extends StatelessWidget {
  const _TechTimelineSection();

  static const _stops = [
    _TimelineStop(
      icon: Icons.flag_circle,
      color: _cyan,
      label: 'PELANCARAN',
      dateLabel: '1 Ogos 2026',
      desc: 'Program D2C bermula di seluruh sekolah, Tingkatan 1 hingga 5.',
    ),
    _TimelineStop(
      icon: Icons.autorenew,
      color: _amber,
      label: 'SUSULAN BERTERUSAN',
      dateLabel: 'Sepanjang Program',
      desc: 'Pemantauan harian, mentor UBK/PRS, dan pengiktirafan mingguan/bulanan.',
    ),
    _TimelineStop(
      icon: Icons.emoji_events,
      color: _green,
      label: 'PENILAIAN AKHIR',
      dateLabel: '31 Oktober 2026',
      desc: 'Penutupan fasa 1 program dan penilaian pencapaian keseluruhan.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _navyDeep,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const _TechSectionTitle(tag: 'TIMELINE PROGRAM', title: 'JADUAL PELAKSANAAN D2C 2026'),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= _wideBreakpoint) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < _stops.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 26),
                              child: SizedBox(
                                width: 48,
                                child: Container(height: 2, color: _cyan.withValues(alpha: 0.35)),
                              ),
                            ),
                          Expanded(child: _TimelineNode(stop: _stops[i])),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < _stops.length; i++) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: SizedBox(height: 28, child: VerticalDivider(color: _cyan.withValues(alpha: 0.35), thickness: 2)),
                          ),
                        _TimelineNodeMobile(stop: _stops[i]),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.stop});

  final _TimelineStop stop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: stop.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: stop.color, width: 2),
            boxShadow: [BoxShadow(color: stop.color.withValues(alpha: 0.3), blurRadius: 12)],
          ),
          child: Icon(stop.icon, color: stop.color, size: 24),
        ),
        const SizedBox(height: 14),
        Text(stop.label, textAlign: TextAlign.center, style: TextStyle(color: stop.color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(stop.dateLabel, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Text(stop.desc, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5, height: 1.4)),
      ],
    );
  }
}

class _TimelineNodeMobile extends StatelessWidget {
  const _TimelineNodeMobile({required this.stop});

  final _TimelineStop stop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: stop.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: stop.color, width: 2),
          ),
          child: Icon(stop.icon, color: stop.color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.label, style: TextStyle(color: stop.color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(stop.dateLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(stop.desc, style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
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
        color: _panel,
        border: Border(top: BorderSide(color: Color(0x1F38BDF8)), bottom: BorderSide(color: Color(0x1F38BDF8))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const _TechSectionTitle(tag: 'OVERVIEW', title: 'MENGENAI PROGRAM DARE TO CHANGE (D2C)'),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: _navy.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                child: const Text(
                  'Program Dare to Change (D2C) dirancang sebagai program menyeluruh bagi semua murid SMK Sungai Damit. Program ini bukan sekadar kempen kesedaran, tetapi satu sistem tindakan harian yang menghubungkan data kehadiran real-time, intervensi mentor, sokongan Pembimbing Rakan Sebaya (PRS), penglibatan penjaga, serta ganjaran berasaskan usaha dan peningkatan sahsiah murid.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15, height: 1.7),
                ),
              ),
              const SizedBox(height: 40),

              // METRICS GRID — each with a decorative progress ring behind the icon
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: const [
                  _TechMetricCard(icon: Icons.school, title: 'Tingkatan Terlibat', value: 'T1 - T5', subtitle: 'Seluruh Murid', color: _cyan, ringValue: 1.0),
                  _TechMetricCard(icon: Icons.qr_code_scanner, title: 'Kehadiran Digital', value: '100%', subtitle: 'Real-Time Scan', color: _green, ringValue: 1.0),
                  _TechMetricCard(icon: Icons.military_tech, title: 'Mata Merit Harian', value: '4 Mata', subtitle: 'Maksimum Sehari', color: _amber, ringValue: 0.8),
                  _TechMetricCard(icon: Icons.layers, title: 'Aras Intervensi', value: '3 Aras', subtitle: 'Universal -> Intensif', color: _purple, ringValue: 0.6),
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
    required this.ringValue,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  /// Decorative fill (0-1) for the ring behind the icon — illustrative, not live data.
  final double ringValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12)],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: ringValue,
                    strokeWidth: 3,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                CircleAvatar(radius: 20, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 20)),
              ],
            ),
          ),
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
// 3 ARAS INTERVENSI SECTION — connected escalation flow
// ---------------------------------------------------------------------------
class _TechLevelsSection extends StatelessWidget {
  const _TechLevelsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = const [
      _TechLevelCard(
        color: _cyan,
        level: 'ARAS 1: UNIVERSAL',
        target: 'Semua Murid (T1 - T5)',
        description: 'Rekod harian, 4 mata merit sehari, cabaran kelas, pemantauan transisi masa rehat, dan pengiktirafan mingguan/bulanan.',
        icon: Icons.public,
      ),
      _TechLevelCard(
        color: _orange,
        level: 'ARAS 2: BERSASAR',
        target: 'Murid Berulang / Lewat',
        description: 'Check-in mentor UBK/PRS, sasaran kecil, pelan 5 hari "Saya Kembali Hari Ini", dan makluman peribadi kepada penjaga.',
        icon: Icons.track_changes,
      ),
      _TechLevelCard(
        color: _red,
        level: 'ARAS 3: INTENSIF',
        target: 'Kes Berisiko Tinggi',
        description: 'Program Ziarah Cakna ke rumah, perjumpaan khas penjaga dengan Pengetua/HEM, serta pelan pemulihan UBK & Disiplin.',
        icon: Icons.warning_amber,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(color: _navy),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const _TechSectionTitle(tag: 'INTERVENTION MODEL', title: '3 ARAS INTERVENSI DARE TO CHANGE'),
              const SizedBox(height: 8),
              Text(
                'Semakin tinggi keperluan murid, semakin bersasar sokongan yang diberikan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= _wideBreakpoint) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i < cards.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.3), size: 26),
                            ),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Icon(Icons.arrow_downward_rounded, color: Colors.white.withValues(alpha: 0.3), size: 24),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechLevelCard extends StatelessWidget {
  const _TechLevelCard({required this.color, required this.level, required this.target, required this.description, required this.icon});

  final Color color;
  final String level;
  final String target;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 16)],
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
// MERIT ROUTINE SECTION — connected stepper + composition donut
// ---------------------------------------------------------------------------
class _MeritStep {
  const _MeritStep({required this.step, required this.title, required this.desc, required this.color});

  final String step;
  final String title;
  final String desc;
  final Color color;
}

class _TechMeritSection extends StatelessWidget {
  const _TechMeritSection({super.key});

  static const _steps = [
    _MeritStep(step: '01', title: 'Hadir Ke Sekolah', desc: 'Hadir pada hari persekolahan', color: _cyan),
    _MeritStep(step: '02', title: 'Tepat Masa', desc: 'Berada di kelas pada masa ditetapkan', color: _amber),
    _MeritStep(step: '03', title: 'Kembali Selepas Rehat', desc: 'Masuk kelas selepas rehat tanpa berkeliaran', color: _green),
    _MeritStep(step: '04', title: 'Kekal Tamat Sesi', desc: 'Mengikuti sesi hingga waktu tamat', color: _purple),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(color: _panel, border: Border(top: BorderSide(color: Color(0x1F38BDF8)))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const _TechSectionTitle(tag: 'DAILY MERIT SYSTEM', title: 'RUTIN & SISTEM MATA MERIT D2C'),
              const SizedBox(height: 12),
              const Text(
                'Setiap murid mengumpul sehingga 4 mata merit setiap hari yang dijumlahkan sebagai Merit Individu dan Merit Kelas:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= _wideBreakpoint;
                  final stepper = isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _steps.length; i++) ...[
                              Expanded(child: _MeritStepTile(step: _steps[i])),
                              if (i < _steps.length - 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 22),
                                  child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.25), size: 20),
                                ),
                            ],
                          ],
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < _steps.length; i++) ...[
                              _MeritStepTile(step: _steps[i]),
                              if (i < _steps.length - 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Icon(Icons.arrow_downward_rounded, color: Colors.white.withValues(alpha: 0.25), size: 20),
                                ),
                            ],
                          ],
                        );

                  if (!isWide) {
                    return Column(children: [stepper, const SizedBox(height: 40), const _MeritDonut()]);
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: stepper),
                        const SizedBox(width: 32),
                        const SizedBox(width: 240, child: _MeritDonut()),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeritStepTile extends StatelessWidget {
  const _MeritStepTile({required this.step});

  final _MeritStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(16), border: Border.all(color: step.color.withValues(alpha: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: step.color.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: step.color)),
                child: Text(step.step, style: TextStyle(color: step.color, fontWeight: FontWeight.w900, fontSize: 10)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: step.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('+1 MATA', style: TextStyle(color: step.color, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          const SizedBox(height: 4),
          Text(step.desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, height: 1.4)),
        ],
      ),
    );
  }
}

/// Illustrative donut showing the 4 equal-weighted merit components — static
/// branding content, not live student data (this page is public/unauthenticated).
class _MeritDonut extends StatelessWidget {
  const _MeritDonut();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              sections: [
                for (final step in _TechMeritSection._steps)
                  PieChartSectionData(
                    value: 1,
                    color: step.color,
                    radius: 26,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Column(
          children: const [
            Text('4', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
            Text('MATA / HARI', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final step in _TechMeritSection._steps)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: step.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Rutin ${step.step}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
          ],
        ),
      ],
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
      decoration: const BoxDecoration(color: _navy),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const _TechSectionTitle(tag: 'LEADERSHIP', title: 'JAWATANKUASA INDUK PROGRAM D2C'),
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
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
            child: Text(name.isNotEmpty ? name[0] : 'G', style: const TextStyle(fontWeight: FontWeight.bold, color: _cyan)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: const TextStyle(fontSize: 11, color: _amber, fontWeight: FontWeight.bold)),
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
    final cards = [
      _TechLaunchpadCard(
        icon: Icons.admin_panel_settings,
        color: _cyan,
        title: 'Portal Guru & Pentadbir',
        subtitle: 'Log masuk pengurusan kehadiran, merit & disiplin sekolah.',
        buttonText: 'LOG MASUK GURU',
        onTap: () => context.go('/sign-in'),
      ),
      _TechLaunchpadCard(
        icon: Icons.family_restroom,
        color: _green,
        title: 'Portal Ibu Bapa',
        subtitle: 'Semakan kehadiran real-time anak menggunakan No. IC Penjaga.',
        buttonText: 'SEMAKAN IBU BAPA',
        onTap: () => context.go('/parent'),
      ),
      _TechLaunchpadCard(
        icon: Icons.qr_code_scanner,
        color: _purple,
        title: 'Portal Murid',
        subtitle: 'Imbas QR Name Tag, semak merit & hantar Suara Murid.',
        buttonText: 'PORTAL MURID',
        onTap: () => context.go('/student'),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(color: _panel, border: Border(top: BorderSide(color: Color(0x1F38BDF8)))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const _TechSectionTitle(tag: 'PORTAL LAUNCHPAD', title: 'PAUTAN AKSES PORTAL D2C'),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= _wideBreakpoint) {
                    return Row(
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i < cards.length - 1) const SizedBox(width: 16),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1) const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechLaunchpadCard extends StatelessWidget {
  const _TechLaunchpadCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.buttonText, required this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16)],
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
          const Text('Peti Surat 232, 89257 Tamparuli, Sabah', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          const Text(
            'ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs',
            style: TextStyle(color: _cyan, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          const Text('© 2026 SMK Sungai Damit • D2C Summit Cloud System v2.6.4', style: TextStyle(color: Colors.white38, fontSize: 11)),
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
        Text(tag, style: const TextStyle(color: _cyan, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2.0)),
        const SizedBox(height: 4),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(width: 60, height: 3, color: _amber),
      ],
    );
  }
}

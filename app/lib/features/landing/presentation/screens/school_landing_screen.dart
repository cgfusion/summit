import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/d2c_ai_assistant_dialog.dart';
import 'package:app/features/discipline_counseling/presentation/providers/discipline_counseling_providers.dart';

class SchoolLandingScreen extends StatefulWidget {
  const SchoolLandingScreen({super.key});

  @override
  State<SchoolLandingScreen> createState() => _SchoolLandingScreenState();
}

class _SchoolLandingScreenState extends State<SchoolLandingScreen> {
  final _scrollController = ScrollController();

  final _aboutKey = GlobalKey();
  final _timelineKey = GlobalKey();
  final _levelsKey = GlobalKey();
  final _meritKey = GlobalKey();
  final _committeeKey = GlobalKey();
  final _portalsKey = GlobalKey();
  final _sudutInfoKey = GlobalKey();

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
    final bgDark = isDark ? const Color(0xFF060913) : const Color(0xFF0B1222);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // MAIN SCROLLABLE CONTENT
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 72), // Top padding for floating navbar

                // 1. HERO SPOTLIGHT WITH SCHOOL BACKGROUND & SUDUT INFO CARD
                _CyberHeroSpotlight(
                  sudutInfoKey: _sudutInfoKey,
                  onExplore: () => _scrollToSection(_aboutKey),
                  onOpenPortals: () => _scrollToSection(_portalsKey),
                  onViewSudutInfo: () => _scrollToSection(_portalsKey),
                ),

                // 2. SECTION: TIMELINE PROGRAM (JADUAL PELAKSANAAN D2C 2026)
                _CyberTimelineSection(key: _timelineKey),

                // 3. SECTION: OVERVIEW (MENGENAI PROGRAM DARE TO CHANGE & 4 METRICS)
                _CyberOverviewSection(key: _aboutKey),

                // 4. SECTION: 3 ARAS INTERVENSI D2C
                _CyberLevelsSection(key: _levelsKey),

                // 5. SECTION: RUTIN & SISTEM MATA MERIT HARIAN
                _CyberMeritSection(key: _meritKey),

                // 6. SECTION: JAWATANKUASA INDUK
                _CyberLeadershipSection(key: _committeeKey),

                // 7. SECTION: PORTAL LAUNCHPAD SECTION
                _CyberPortalLaunchpadSection(key: _portalsKey),

                // FUTURISTIC FOOTER
                const _CyberFooter(),
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
              onNavTimeline: () => _scrollToSection(_timelineKey),
              onNavLevels: () => _scrollToSection(_levelsKey),
              onNavMerit: () => _scrollToSection(_meritKey),
              onNavCommittee: () => _scrollToSection(_committeeKey),
              onNavPortals: () => _scrollToSection(_portalsKey),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => D2CAiAssistantDialog.show(context),
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.black),
        label: const Text(
          'PEMBANTU AI',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 0.8, fontSize: 12),
        ),
        backgroundColor: const Color(0xFF38BDF8),
        elevation: 8,
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
    required this.onNavTimeline,
    required this.onNavLevels,
    required this.onNavMerit,
    required this.onNavCommittee,
    required this.onNavPortals,
  });

  final VoidCallback onNavAbout;
  final VoidCallback onNavTimeline;
  final VoidCallback onNavLevels;
  final VoidCallback onNavMerit;
  final VoidCallback onNavCommittee;
  final VoidCallback onNavPortals;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF090F1E).withValues(alpha: 0.85),
            border: const Border(bottom: BorderSide(color: Color(0x2B38BDF8))),
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
                        BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), blurRadius: 12),
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
              if (MediaQuery.of(context).size.width > 960) ...[
                _NavTextButton(label: 'Jadual Timeline', onTap: onNavTimeline),
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
// 1. CYBER HERO SPOTLIGHT & SUDUT INFO CARD (100% MATCH DESIGN)
// ---------------------------------------------------------------------------
class _CyberHeroSpotlight extends ConsumerStatefulWidget {
  const _CyberHeroSpotlight({
    required this.sudutInfoKey,
    required this.onExplore,
    required this.onOpenPortals,
    required this.onViewSudutInfo,
  });

  final GlobalKey sudutInfoKey;
  final VoidCallback onExplore;
  final VoidCallback onOpenPortals;
  final VoidCallback onViewSudutInfo;

  @override
  ConsumerState<_CyberHeroSpotlight> createState() => _CyberHeroSpotlightState();
}

class _CyberHeroSpotlightState extends ConsumerState<_CyberHeroSpotlight> {
  int _activeInfoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 980;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF080D1A),
        image: DecorationImage(
          image: AssetImage('assets/images/school_front.jpg'),
          fit: BoxFit.cover,
          opacity: 0.28,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.35), blurRadius: 18),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'PORTAL RASMI HAL EHWAL MURID & SAHSIAH',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildHeroLeftText(context)),
                    const SizedBox(width: 40),
                    Expanded(flex: 5, child: _buildSudutInfoCard(context)),
                  ],
                )
              else ...[
                _buildHeroLeftText(context),
                const SizedBox(height: 48),
                _buildSudutInfoCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroLeftText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'DARE TO ',
                style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              TextSpan(
                text: 'CHANGE ',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              TextSpan(
                text: '(D2C)',
                style: TextStyle(color: Color(0xFFFDE047), fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x22FDE047),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x88FDE047), width: 1.2),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFDE047).withValues(alpha: 0.15), blurRadius: 12),
            ],
          ),
          child: const Text(
            '"Hadir Hari Ini, Menang Esok Hari"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFDE047),
              fontSize: 20,
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
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x3338BDF8)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.groups, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Sasaran: Seluruh Warga Sekolah – Tingkatan 1, 2, 3, 4 & 5 (SMK Sungai Damit)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: widget.onExplore,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 10,
                shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('TEROKAI SISTEM D2C', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: widget.onOpenPortals,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apps, size: 18, color: Color(0xFF38BDF8)),
                  SizedBox(width: 8),
                  Text('PORTAL AKSES D2C', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: Color(0xFF38BDF8)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'ONE TEAM ONE DREAM, TERUS MARA MENAWAN 7SUMMITs',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFFDE047).withValues(alpha: 0.95),
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSudutInfoCard(BuildContext context) {
    final activePostsAsync = ref.watch(activeSudutInfoPostsProvider(null));

    return Container(
      key: widget.sudutInfoKey,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF091225).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF0284C7), width: 1.8),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.25), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 18),
              SizedBox(width: 8),
              Text(
                'SUDUT INFO',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.campaign, size: 38, color: Color(0xFF38BDF8)),
          ),
          const SizedBox(height: 16),
          activePostsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return Column(
                  children: const [
                    Text(
                      'Makluman & Info Terkini',
                      style: TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Dikendalikan oleh\nUnit Disiplin & Kaunseling',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Dapatkan makluman, hebahan penting, tips sahsiah dan kaunseling terus di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                    ),
                  ],
                );
              }

              final safeIndex = _activeInfoIndex % posts.length;
              final currentPost = posts[safeIndex];

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentPost.category.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentPost.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pengendali: ${currentPost.managedBy}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  if (currentPost.imageUrl != null && currentPost.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: currentPost.imageUrl!.startsWith('assets/')
                            ? Image.asset(currentPost.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover)
                            : Image.network(
                                currentPost.imageUrl!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    currentPost.content,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                  ),
                  if (posts.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF38BDF8)),
                          onPressed: () {
                            setState(() {
                              _activeInfoIndex = ((_activeInfoIndex - 1 + posts.length) % posts.length).toInt();
                            });
                          },
                        ),
                        Text(
                          '${safeIndex + 1} / ${posts.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF38BDF8)),
                          onPressed: () {
                            setState(() {
                              _activeInfoIndex = ((_activeInfoIndex + 1) % posts.length).toInt();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, st) => const Text('Makluman Sudut Info', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: widget.onViewSudutInfo,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF0B172E),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lihat Semua Makluman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 14, color: Color(0xFF38BDF8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. TIMELINE PROGRAM SECTION (JADUAL PELAKSANAAN D2C 2026)
// ---------------------------------------------------------------------------
class _CyberTimelineSection extends StatelessWidget {
  const _CyberTimelineSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF080D1A),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1224),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.1), blurRadius: 20),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'TIMELINE PROGRAM',
                  style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2.0),
                ),
                const SizedBox(height: 6),
                const Text(
                  'JADUAL PELAKSANAAN D2C 2026',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Container(width: 80, height: 3, color: const Color(0xFFFDE047)),
                const SizedBox(height: 40),

                // 3 TIMELINE NODES
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child: _TimelineNodeCard(
                              icon: Icons.play_arrow_rounded,
                              iconColor: Color(0xFF38BDF8),
                              title: 'PELANCARAN',
                              date: '1 Ogos 2026',
                              desc: 'Program D2C bermula di seluruh sekolah, Tingkatan 1 hingga 5.',
                            ),
                          ),
                          _TimelineConnectorLine(),
                          Expanded(
                            child: _TimelineNodeCard(
                              icon: Icons.refresh_rounded,
                              iconColor: Color(0xFFFDE047),
                              title: 'SUSULAN BERTERUSAN',
                              date: 'Sepanjang Program',
                              desc: 'Pemantauan harian, mentor UBK/PRS, dan pengiktirafan mingguan/bulanan.',
                            ),
                          ),
                          _TimelineConnectorLine(),
                          Expanded(
                            child: _TimelineNodeCard(
                              icon: Icons.emoji_events_rounded,
                              iconColor: Color(0xFF10B981),
                              title: 'PENILAIAN AKHIR',
                              date: '31 Oktober 2026',
                              desc: 'Penutupan fasa 1 program dan penilaian pencapaian keseluruhan.',
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: const [
                        _TimelineNodeCard(
                          icon: Icons.play_arrow_rounded,
                          iconColor: Color(0xFF38BDF8),
                          title: 'PELANCARAN',
                          date: '1 Ogos 2026',
                          desc: 'Program D2C bermula di seluruh sekolah, Tingkatan 1 hingga 5.',
                        ),
                        SizedBox(height: 20),
                        _TimelineNodeCard(
                          icon: Icons.refresh_rounded,
                          iconColor: Color(0xFFFDE047),
                          title: 'SUSULAN BERTERUSAN',
                          date: 'Sepanjang Program',
                          desc: 'Pemantauan harian, mentor UBK/PRS, dan pengiktirafan mingguan/bulanan.',
                        ),
                        SizedBox(height: 20),
                        _TimelineNodeCard(
                          icon: Icons.emoji_events_rounded,
                          iconColor: Color(0xFF10B981),
                          title: 'PENILAIAN AKHIR',
                          date: '31 Oktober 2026',
                          desc: 'Penutupan fasa 1 program dan penilaian pencapaian keseluruhan.',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineConnectorLine extends StatelessWidget {
  const _TimelineConnectorLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle)),
          Container(width: 24, height: 2, color: const Color(0x6638BDF8)),
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle)),
        ],
      ),
    );
  }
}

class _TimelineNodeCard extends StatelessWidget {
  const _TimelineNodeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.desc,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String date;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF091225),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: iconColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: iconColor.withValues(alpha: 0.12), blurRadius: 14),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.6)),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: iconColor, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade300, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. OVERVIEW SECTION (MENGENAI PROGRAM DARE TO CHANGE & 4 METRICS)
// ---------------------------------------------------------------------------
class _CyberOverviewSection extends StatelessWidget {
  const _CyberOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF060913),
        border: Border(top: BorderSide(color: Color(0x1F38BDF8)), bottom: BorderSide(color: Color(0x1F38BDF8))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // OVERVIEW CONTAINER WITH TARGET RETICLE ICON
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1224),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TARGET ICON ON LEFT
                    if (MediaQuery.of(context).size.width > 680) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.track_changes, size: 48, color: Color(0xFF38BDF8)),
                      ),
                      const SizedBox(width: 24),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'OVERVIEW',
                            style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2.0),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'MENGENAI PROGRAM DARE TO CHANGE (D2C)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Container(width: 60, height: 3, color: const Color(0xFFFDE047)),
                          const SizedBox(height: 20),
                          const Text(
                            'Program Dare to Change (D2C) dirancang sebagai program menyeluruh bagi semua murid SMK Sungai Damit. Program ini bukan sekadar kempen kesedaran, tetapi satu sistem tindakan harian yang menghubungkan data kehadiran real-time, intervensi mentor, sokongan Pembimbing Rakan Sebaya (PRS), penglibatan penjaga, serta ganjaran berasaskan usaha dan peningkatan sahsiah murid.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // 4 METRIC CARDS (100% MATCH TO MOCKUP)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  _CyberMetricCard(
                    icon: Icons.school_rounded,
                    value: 'T1 - T5',
                    title: 'Tingkatan Terlibat',
                    subtitle: 'Seluruh Murid',
                    color: Color(0xFF38BDF8),
                  ),
                  _CyberMetricCard(
                    icon: Icons.qr_code_scanner_rounded,
                    value: '100%',
                    title: 'Kehadiran Digital',
                    subtitle: 'Real-Time Scan',
                    color: Color(0xFF10B981),
                  ),
                  _CyberMetricCard(
                    icon: Icons.emoji_events_rounded,
                    value: '4 Mata',
                    title: 'Mata Merit Harian',
                    subtitle: 'Maksimum Sehari',
                    color: Color(0xFFFDE047),
                  ),
                  _CyberMetricCard(
                    icon: Icons.layers_rounded,
                    value: '3 Aras',
                    title: 'Aras Intervensi',
                    subtitle: 'Universal → Intensif',
                    color: Color(0xFFA855F7),
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

class _CyberMetricCard extends StatelessWidget {
  const _CyberMetricCard({
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF091225),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          const SizedBox(height: 2),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. 3 ARAS INTERVENSI D2C
// ---------------------------------------------------------------------------
class _CyberLevelsSection extends StatelessWidget {
  const _CyberLevelsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(color: Color(0xFF080D1A)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const _CyberSectionTitle(
                tag: 'INTERVENTION MODEL',
                title: '3 ARAS INTERVENSI DARE TO CHANGE',
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(
                          child: _CyberLevelCard(
                            color: Color(0xFF38BDF8),
                            level: 'ARAS 1: UNIVERSAL',
                            target: 'Semua Murid (T1 - T5)',
                            description: 'Rekod harian, 4 mata merit sehari, cabaran kelas, pemantauan transisi masa rehat, dan pengiktirafan mingguan/bulanan.',
                            icon: Icons.public_rounded,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _CyberLevelCard(
                            color: Color(0xFFF59E0B),
                            level: 'ARAS 2: BERSASAR',
                            target: 'Murid Berulang / Lewat',
                            description: 'Check-in mentor UBK/PRS, sasaran kecil, pelan 5 hari "Saya Kembali Hari Ini", dan makluman peribadi kepada penjaga.',
                            icon: Icons.track_changes_rounded,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _CyberLevelCard(
                            color: Color(0xFFEF4444),
                            level: 'ARAS 3: INTENSIF',
                            target: 'Kes Berisiko Tinggi',
                            description: 'Program Ziarah Cakna ke rumah, perjumpaan khas penjaga dengan Pengetua/HEM, serta pelan pemulihan UBK & Disiplin.',
                            icon: Icons.warning_amber_rounded,
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: const [
                      _CyberLevelCard(
                        color: Color(0xFF38BDF8),
                        level: 'ARAS 1: UNIVERSAL',
                        target: 'Semua Murid (T1 - T5)',
                        description: 'Rekod harian, 4 mata merit sehari, cabaran kelas, pemantauan transisi masa rehat, dan pengiktirafan mingguan/bulanan.',
                        icon: Icons.public_rounded,
                      ),
                      SizedBox(height: 16),
                      _CyberLevelCard(
                        color: Color(0xFFF59E0B),
                        level: 'ARAS 2: BERSASAR',
                        target: 'Murid Berulang / Lewat',
                        description: 'Check-in mentor UBK/PRS, sasaran kecil, pelan 5 hari "Saya Kembali Hari Ini", dan makluman peribadi kepada penjaga.',
                        icon: Icons.track_changes_rounded,
                      ),
                      SizedBox(height: 16),
                      _CyberLevelCard(
                        color: Color(0xFFEF4444),
                        level: 'ARAS 3: INTENSIF',
                        target: 'Kes Berisiko Tinggi',
                        description: 'Program Ziarah Cakna ke rumah, perjumpaan khas penjaga dengan Pengetua/HEM, serta pelan pemulihan UBK & Disiplin.',
                        icon: Icons.warning_amber_rounded,
                      ),
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

class _CyberLevelCard extends StatelessWidget {
  const _CyberLevelCard({
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
        color: const Color(0xFF0A1224),
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
// 5. RUTIN & SISTEM MATA MERIT HARIAN
// ---------------------------------------------------------------------------
class _CyberMeritSection extends StatelessWidget {
  const _CyberMeritSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF060913),
        border: Border(top: BorderSide(color: Color(0x1F38BDF8))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const _CyberSectionTitle(
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
                  _CyberMeritTile(step: '01', title: 'Hadir Ke Sekolah', points: '+1 MATA', desc: 'Hadir pada hari persekolahan'),
                  _CyberMeritTile(step: '02', title: 'Tepat Masa', points: '+1 MATA', desc: 'Berada di kelas pada masa ditetapkan'),
                  _CyberMeritTile(step: '03', title: 'Kembali Selepas Rehat', points: '+1 MATA', desc: 'Masuk kelas selepas rehat tanpa berkeliaran'),
                  _CyberMeritTile(step: '04', title: 'Kekal Tamat Sesi', points: '+1 MATA', desc: 'Mengikuti sesi hingga waktu tamat'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyberMeritTile extends StatelessWidget {
  const _CyberMeritTile({required this.step, required this.title, required this.points, required this.desc});

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
        color: const Color(0xFF091225),
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
// 6. JAWATANKUASA INDUK
// ---------------------------------------------------------------------------
class _CyberLeadershipSection extends StatelessWidget {
  const _CyberLeadershipSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(color: Color(0xFF080D1A)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const _CyberSectionTitle(
                tag: 'LEADERSHIP',
                title: 'JAWATANKUASA INDUK PROGRAM D2C',
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  _CyberLeaderTile(role: 'Pengerusi', name: 'Pn. Fauziah Binti Mahrop', title: 'Pengetua SMK Sungai Damit'),
                  _CyberLeaderTile(role: 'Naib Pengerusi I', name: 'En. Norzalizan bin Bahari', title: 'PK Hal Ehwal Murid'),
                  _CyberLeaderTile(role: 'Naib Pengerusi II', name: 'Pn. Lucy Gansoi', title: 'PK Pentadbiran'),
                  _CyberLeaderTile(role: 'Naib Pengerusi III', name: 'Pn. Roslinah @ Winda Binti Majimin', title: 'PK Kokurikulum'),
                  _CyberLeaderTile(role: 'Naib Pengerusi IV', name: 'Pn. Jarisah Gondikit', title: 'PK Petang'),
                  _CyberLeaderTile(role: 'Setiausaha', name: 'Pn. Emily Subin', title: 'Guru Bimbingan & Kaunseling'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyberLeaderTile extends StatelessWidget {
  const _CyberLeaderTile({required this.role, required this.name, required this.title});

  final String role;
  final String name;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1224),
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
// 7. PORTAL LAUNCHPAD SECTION
// ---------------------------------------------------------------------------
class _CyberPortalLaunchpadSection extends StatelessWidget {
  const _CyberPortalLaunchpadSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        color: Color(0xFF060913),
        border: Border(top: BorderSide(color: Color(0x1F38BDF8))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const _CyberSectionTitle(
                tag: 'PORTAL LAUNCHPAD',
                title: 'PAUTAN AKSES PORTAL D2C',
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      children: [
                        Expanded(
                          child: _CyberLaunchpadCard(
                            icon: Icons.admin_panel_settings_rounded,
                            color: const Color(0xFF38BDF8),
                            title: 'Portal Guru & Pentadbir',
                            subtitle: 'Log masuk pengurusan kehadiran, merit & disiplin sekolah.',
                            buttonText: 'LOG MASUK GURU',
                            onTap: () => context.go('/sign-in'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CyberLaunchpadCard(
                            icon: Icons.family_restroom_rounded,
                            color: const Color(0xFF10B981),
                            title: 'Portal Ibu Bapa',
                            subtitle: 'Semakan kehadiran real-time anak menggunakan No. IC Penjaga.',
                            buttonText: 'SEMAKAN IBU BAPA',
                            onTap: () => context.go('/parent'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CyberLaunchpadCard(
                            icon: Icons.qr_code_scanner_rounded,
                            color: const Color(0xFFA855F7),
                            title: 'Portal Murid',
                            subtitle: 'Imbas QR Name Tag, semak merit & hantar Suara Murid.',
                            buttonText: 'PORTAL MURID',
                            onTap: () => context.go('/student'),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _CyberLaunchpadCard(
                        icon: Icons.admin_panel_settings_rounded,
                        color: const Color(0xFF38BDF8),
                        title: 'Portal Guru & Pentadbir',
                        subtitle: 'Log masuk pengurusan kehadiran, merit & disiplin sekolah.',
                        buttonText: 'LOG MASUK GURU',
                        onTap: () => context.go('/sign-in'),
                      ),
                      const SizedBox(height: 16),
                      _CyberLaunchpadCard(
                        icon: Icons.family_restroom_rounded,
                        color: const Color(0xFF10B981),
                        title: 'Portal Ibu Bapa',
                        subtitle: 'Semakan kehadiran real-time anak menggunakan No. IC Penjaga.',
                        buttonText: 'SEMAKAN IBU BAPA',
                        onTap: () => context.go('/parent'),
                      ),
                      const SizedBox(height: 16),
                      _CyberLaunchpadCard(
                        icon: Icons.qr_code_scanner_rounded,
                        color: const Color(0xFFA855F7),
                        title: 'Portal Murid',
                        subtitle: 'Imbas QR Name Tag, semak merit & hantar Suara Murid.',
                        buttonText: 'PORTAL MURID',
                        onTap: () => context.go('/student'),
                      ),
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

class _CyberLaunchpadCard extends StatelessWidget {
  const _CyberLaunchpadCard({
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
        color: const Color(0xFF091225),
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
class _CyberFooter extends StatelessWidget {
  const _CyberFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF04060C),
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

// Helper: Cyber Section Header Title
class _CyberSectionTitle extends StatelessWidget {
  const _CyberSectionTitle({required this.tag, required this.title});

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

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../utils/formatters.dart';
import '../profile/help_center_page.dart';
import '../profile/status_pengajuan_page.dart';
import 'pengajuan_screen.dart';

class BerandaWarga extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const BerandaWarga({super.key, this.onNavigateTab});

  @override
  State<BerandaWarga> createState() => _BerandaWargaState();
}

class _BerandaWargaState extends State<BerandaWarga> {
  String _userName = 'Warga';
  bool _isLoading = true;
  List<dynamic> _banners = [];
  Map<String, dynamic> _dashboardData = {};
  int _currentBannerIndex = 0;
  final PageController _pageController = PageController();
  Timer? _bannerTimer;

  // Fallback banners jika belum ada koneksi / data API kosong
  final List<Map<String, String>> _defaultBanners = [
    {
      'judul': 'Retribusi Sampah Kudus',
      'deskripsi': 'Wujudkan Kudus Asri & Bersih dengan tertib retribusi',
      'color_1': '0xFF1B5E20',
      'color_2': '0xFF2E7D32',
      'icon': 'recycling',
    },
    {
      'judul': 'Pilah Sampah dari Rumah',
      'deskripsi': 'Pisahkan sampah organik dan anorganik demi lingkungan sehat',
      'color_1': '0xFF0D47A1',
      'color_2': '0xFF1976D2',
      'icon': 'delete_sweep',
    },
    {
      'judul': 'Pembayaran Digital & Transparan',
      'deskripsi': 'Bayar retribusi kini lebih mudah melalui QRIS & Petugas Lapangan',
      'color_1': '0xFF4A148C',
      'color_2': '0xFF7B1FA2',
      'icon': 'qr_code_scanner',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('nama');
    if (name != null && name.isNotEmpty) {
      if (mounted) setState(() => _userName = name);
    }
    await Future.wait([_fetchBanners(), _fetchDashboard()]);
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    final count = _banners.isNotEmpty ? _banners.length : _defaultBanners.length;
    if (count > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          int nextPage = _currentBannerIndex + 1;
          if (nextPage >= count) {
            nextPage = 0;
          }
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _fetchBanners() async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/banners');
      final response = await http.get(url, headers: ApiClient.headers).timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          if (mounted) {
            setState(() {
              _banners = data['data'];
            });
          }
        }
      }
    } catch (_) {
      // Menggunakan default fallback banners
    }
  }

  Future<void> _fetchDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${ApiClient.baseUrl}/warga/dashboard');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _dashboardData = data['data'] ?? {};
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sisaTagihan = _dashboardData['sisa_tagihan'] as List<dynamic>? ?? [];
    final totalSisa = _dashboardData['total_sisa_tagihan'] ?? 0;
    final profil = _dashboardData['profil'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_fetchBanners(), _fetchDashboard()]);
            _startBannerTimer();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header / Profile Bar
                _buildTopProfileBar(),
                const SizedBox(height: 18),

                // Hero Banner Slideshow
                _buildBannerSlider(),
                const SizedBox(height: 22),

                // Quick Access Grid
                const Text(
                  'Menu Cepat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickAccessGrid(),
                const SizedBox(height: 24),

                // Ringkasan Tagihan Section
                _buildTagihanSummaryCard(profil, sisaTagihan, totalSisa),
                const SizedBox(height: 24),

                // Informasi & Tips Kudus Bersih
                _buildWasteTipsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopProfileBar() {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'W';

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(2); // Pindah ke tab Profil
            }
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.green.shade700,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Datang,',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF059669)),
            tooltip: 'Segarkan',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadInitialData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSlider() {
    final hasApiBanners = _banners.isNotEmpty;
    final count = hasApiBanners ? _banners.length : _defaultBanners.length;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemCount: count,
            itemBuilder: (context, index) {
              if (hasApiBanners) {
                final banner = _banners[index];
                return _buildApiBannerCard(banner);
              } else {
                final banner = _defaultBanners[index];
                return _buildFallbackBannerCard(banner);
              }
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBannerIndex == index ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
                    ? const Color(0xFF059669)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiBannerCard(Map<String, dynamic> banner) {
    final imageUrl = banner['gambar_url'] ?? '';
    final judul = banner['judul'] ?? '';
    final deskripsi = banner['deskripsi'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.green.shade700,
                  child: const Center(
                    child: Icon(Icons.recycling, size: 60, color: Colors.white70),
                  ),
                ),
              )
            else
              Container(color: Colors.green.shade700),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),

            // Content Text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (deskripsi.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      deskripsi,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBannerCard(Map<String, String> banner) {
    final color1 = Color(int.parse(banner['color_1'] ?? '0xFF1B5E20'));
    final color2 = Color(int.parse(banner['color_2'] ?? '0xFF2E7D32'));

    IconData icon = Icons.recycling;
    if (banner['icon'] == 'delete_sweep') icon = Icons.delete_sweep;
    if (banner['icon'] == 'qr_code_scanner') icon = Icons.qr_code_scanner;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color1.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 110,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PKPLH KUDUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  banner['judul'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  banner['deskripsi'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: [
        _buildQuickMenuItem(
          icon: Icons.receipt_long_rounded,
          label: 'Retribusi',
          color: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
          onTap: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(1); // Pindah ke Tab Retribusi
            }
          },
        ),
        _buildQuickMenuItem(
          icon: Icons.app_registration_rounded,
          label: 'Pengajuan',
          color: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PengajuanScreen()),
            );
            if (result == true) {
              _fetchDashboard();
            }
          },
        ),
        _buildQuickMenuItem(
          icon: Icons.fact_check_rounded,
          label: 'Status',
          color: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF3C7),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StatusPengajuanPage()),
            );
          },
        ),
        _buildQuickMenuItem(
          icon: Icons.support_agent_rounded,
          label: 'Bantuan',
          color: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpCenterPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTagihanSummaryCard(
    dynamic profil,
    List<dynamic> sisaTagihan,
    dynamic totalSisa,
  ) {
    if (_isLoading) {
      return Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Jika belum terdaftar
    if (profil == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Belum Terdaftar Retribusi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Daftarkan rumah atau usaha Anda untuk mulai berlangganan.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PengajuanScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Daftar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // Jika sudah lunas
    if (sisaTagihan.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Semua Tagihan Lunas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Terima kasih telah tertib membayar retribusi sampah.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Jika ada tagihan belum lunas
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF2F2), Color(0xFFFFF1F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${sisaTagihan.length} Tagihan Tertunda',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.formatRupiah(totalSisa),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Segera lakukan pembayaran bulan ini',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (widget.onNavigateTab != null) {
                widget.onNavigateTab!(1); // Buka Tab Retribusi
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Bayar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFF059669), size: 20),
              SizedBox(width: 8),
              Text(
                'Edukasi & Informasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipRow('🗑️', 'Pilah Sampah', 'Pisahkan sampah organik sisa makanan & anorganik plastik.'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildTipRow('⏰', 'Jadwal Petugas', 'Letakkan sampah di depan rumah sebelum jam 07.00 pagi.'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildTipRow('📞', 'Layanan Pengaduan', 'Hubungi call center PKPLH jika ada tumpukan sampah liar.'),
        ],
      ),
    );
  }

  Widget _buildTipRow(String emoji, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

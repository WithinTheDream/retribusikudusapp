import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_tagihan_warga_page.dart';
import 'pengajuan_screen.dart';
import '../../core/api_client.dart';
import '../../utils/formatters.dart';

class DashboardWarga extends StatefulWidget {
  const DashboardWarga({super.key});

  @override
  State<DashboardWarga> createState() => _DashboardWargaState();
}

class _DashboardWargaState extends State<DashboardWarga> {
  bool isLoading = true;
  Map<String, dynamic> dashboardData = {};

  final List<String> _namaBulan = [
    '',
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
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
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          dashboardData = data['data'] ?? {};
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data tagihan retribusi')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  String _getBulanText(dynamic bulan) {
    if (bulan == null) return '';
    int b = int.tryParse(bulan.toString()) ?? 0;
    if (b >= 1 && b <= 12) return _namaBulan[b];
    return bulan.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Menu Retribusi', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
      );
    }

    final sisaTagihan = (dashboardData['sisa_tagihan'] as List<dynamic>?) ?? [];
    final riwayat = (dashboardData['riwayat_pembayaran'] as List<dynamic>?) ?? [];
    final profil = dashboardData['profil'];

    // State jika user belum terdaftar
    if (profil == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: AppBar(
          title: const Text('Retribusi Warga', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          backgroundColor: Colors.white,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF059669)),
              tooltip: 'Perbarui',
              onPressed: () {
                setState(() => isLoading = true);
                fetchDashboard();
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: fetchDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            children: [
              const SizedBox(height: 30),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Icon(Icons.assignment_ind_outlined, size: 70, color: Color(0xFF059669)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Terdaftar Sebagai Wajib Retribusi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Untuk dapat mengecek tagihan dan membayar retribusi sampah, silakan ajukan pendaftaran objek retribusi rumah atau usaha Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PengajuanScreen()),
                  );
                  if (result == true) {
                    setState(() => isLoading = true);
                    fetchDashboard();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_task),
                label: const Text(
                  'Ajukan Retribusi Sekarang',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Retribusi Saya',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            Text(
              '${profil['nama_lengkap'] ?? 'Warga'} • ${profil['desa']?['desa'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF059669)),
            tooltip: 'Perbarui',
            onPressed: () {
              setState(() => isLoading = true);
              fetchDashboard();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. Kartu Pembayaran Bulan Ini (Menggantikan Total Sisa Tagihan)
            _buildMonthlyPaymentCard(sisaTagihan, riwayat),
            const SizedBox(height: 24),

            // 2. Bagian Tagihan Belum Lunas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tagihan Belum Lunas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                if (sisaTagihan.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sisaTagihan.length} Tagihan',
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _buildUnpaidList(sisaTagihan),
            const SizedBox(height: 24),

            // 3. Bagian Riwayat Pembayaran
            const Text(
              'Riwayat Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            _buildHistoryList(riwayat),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Kartu Utama: Pembayaran Bulan Ini
  Widget _buildMonthlyPaymentCard(List<dynamic> sisaTagihan, List<dynamic> riwayat) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final currentMonthName = _namaBulan[currentMonth];

    // Cek apakah tagihan bulan ini ada di list belum bayar
    dynamic currentMonthBill;
    try {
      currentMonthBill = sisaTagihan.firstWhere(
        (item) =>
            (int.tryParse(item['bulan'].toString()) == currentMonth) &&
            (int.tryParse(item['tahun'].toString()) == currentYear),
      );
    } catch (_) {
      currentMonthBill = null;
    }

    // Cek apakah tagihan bulan ini ada di list lunas
    dynamic currentMonthPaid;
    if (currentMonthBill == null) {
      try {
        currentMonthPaid = riwayat.firstWhere(
          (item) =>
              (int.tryParse(item['bulan'].toString()) == currentMonth) &&
              (int.tryParse(item['tahun'].toString()) == currentYear),
        );
      } catch (_) {
        currentMonthPaid = null;
      }
    }

    // Kasus 1: Ada tagihan bulan ini dan belum bayar
    if (currentMonthBill != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tagihan Bulan Ini',
                        style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF87171),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Belum Bayar',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentMonthName $currentYear',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.formatRupiah(currentMonthBill['nominal'] ?? 0),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailTagihanWargaPage(tagihan: currentMonthBill),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Bayar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Kasus 2: Tagihan bulan ini sudah lunas
    if (currentMonthPaid != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF047857), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tagihan $currentMonthName $currentYear Lunas',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nominal: ${AppFormatters.formatRupiah(currentMonthPaid['nominal'] ?? 0)}',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Kasus 3: Jika ada sisa tagihan bulan lain tapi bukan bulan ini
    if (sisaTagihan.isNotEmpty) {
      final oldest = sisaTagihan.first;
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Terdapat Tagihan Tertunda',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sisaTagihan.length} tagihan belum diselesaikan',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTagihanWargaPage(tagihan: oldest),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // Kasus 4: Bersih (tidak ada tagihan)
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFF059669), size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bebas Tagihan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tidak ada tagihan tertunggak untuk periode $currentMonthName $currentYear.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidList(List<dynamic> sisaTagihan) {
    if (sisaTagihan.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 12),
            Text('Semua tagihan Anda lunas!', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sisaTagihan.length,
      itemBuilder: (context, index) {
        final tag = sisaTagihan[index];
        final bulanName = _getBulanText(tag['bulan']);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: Color(0xFFDC2626), size: 24),
            ),
            title: Text(
              'Tagihan $bulanName ${tag['tahun'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'No: ${tag['nomor_tagihan'] ?? '-'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppFormatters.formatRupiah(tag['nominal'] ?? 0),
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailTagihanWargaPage(tagihan: tag),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(List<dynamic> riwayat) {
    if (riwayat.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'Belum ada riwayat pembayaran yang tercatat.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: riwayat.length,
      itemBuilder: (context, index) {
        final tag = riwayat[index];
        final bulanName = _getBulanText(tag['bulan']);
        final pembayaran = tag['pembayaran'];
        final metode = pembayaran?['metode_pembayaran'] ?? 'Tunai';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24),
            ),
            title: Text(
              'Pembayaran $bulanName ${tag['tahun'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      metode.toString().toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.formatRupiah(tag['nominal'] ?? 0),
                    style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Text(
                'LUNAS',
                style: TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

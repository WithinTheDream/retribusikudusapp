import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_tagihan_warga_page.dart';
import 'pengajuan_screen.dart';
import 'detail_tps_warga_page.dart';
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
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
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
          const SnackBar(
            content: Text('Gagal mengambil data tagihan retribusi'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
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
          title: const Text(
            'Menu Retribusi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    final sisaTagihan = (dashboardData['sisa_tagihan'] as List<dynamic>?) ?? [];
    final riwayat =
        (dashboardData['riwayat_pembayaran'] as List<dynamic>?) ?? [];
    final profil = dashboardData['profil'];
    final infoTps = dashboardData['info_tps'] as Map<String, dynamic>?;
    final riwayatPengambilan =
        (dashboardData['riwayat_pengambilan'] as List<dynamic>?) ?? [];
    final wargaQrCode = dashboardData['warga_qr_code']?.toString();
    final rumahDiambilHariIni = dashboardData['rumah_diambil_hari_ini'] == true;
    final pengambilanRumahHariIni =
        dashboardData['pengambilan_rumah_hari_ini'] as Map<String, dynamic>?;

    // State jika user belum terdaftar
    if (profil == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: AppBar(
          title: const Text(
            'Retribusi Warga',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
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
                  child: const Icon(
                    Icons.assignment_ind_outlined,
                    size: 70,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Terdaftar Sebagai Wajib Retribusi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Untuk dapat mengecek tagihan dan membayar retribusi sampah, silakan ajukan pendaftaran objek retribusi rumah atau usaha Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PengajuanScreen(),
                    ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '${profil['nama_lengkap'] ?? 'Warga'} • ${profil['desa']?['desa'] ?? ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.normal,
              ),
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
            // 0. Status Pengambilan Sampah Rumah Hari Ini (Banner Prioritas)
            if (rumahDiambilHariIni && pengambilanRumahHariIni != null) ...[
              _buildRumahCollectedTodayBanner(pengambilanRumahHariIni),
              const SizedBox(height: 16),
            ] else if (infoTps != null) ...[
              _buildWaitingCollectionBanner(infoTps),
              const SizedBox(height: 16),
            ],

            // 1. Kartu QR Code Stiker Tempat Sampah Warga
            if (wargaQrCode != null) ...[
              _buildQrCodeCard(wargaQrCode, profil),
              const SizedBox(height: 16),
            ],

            // 2. Kartu Pembayaran Bulan Ini
            _buildMonthlyPaymentCard(sisaTagihan, riwayat),
            const SizedBox(height: 24),

            // 3. Bagian Tagihan Belum Lunas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tagihan Belum Lunas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (sisaTagihan.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sisaTagihan.length} Tagihan',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _buildUnpaidList(sisaTagihan),
            const SizedBox(height: 24),

            // 4. Bagian Riwayat Pembayaran
            const Text(
              'Riwayat Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            _buildHistoryList(riwayat),
            const SizedBox(height: 24),

            // 5. Info TPS Penampungan Sampah
            if (infoTps != null) ...[
              _buildTpsInfoCard(infoTps, profil, riwayatPengambilan),
              const SizedBox(height: 24),
            ],

            // 6. Riwayat Pengambilan Sampah (khusus rumah ini)
            if (riwayatPengambilan.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Pengambilan Sampah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${riwayatPengambilan.length} Log',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildPengambilanList(riwayatPengambilan),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // Kartu Utama: Pembayaran Bulan Ini
  Widget _buildMonthlyPaymentCard(
    List<dynamic> sisaTagihan,
    List<dynamic> riwayat,
  ) {
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
              color: const Color(0xFF059669).withValues(alpha: 0.25),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tagihan Bulan Ini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF87171),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Belum Bayar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatters.formatRupiah(
                          currentMonthBill['nominal'] ?? 0,
                        ),
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
                    onPressed: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailTagihanWargaPage(tagihan: currentMonthBill),
                        ),
                      );
                      if (res == true) {
                        fetchDashboard();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Bayar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
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
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tagihan $currentMonthName $currentYear Lunas',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nominal: ${AppFormatters.formatRupiah(currentMonthPaid['nominal'] ?? 0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sisaTagihan.length} tagihan belum diselesaikan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailTagihanWargaPage(tagihan: oldest),
                  ),
                );
                if (res == true) {
                  fetchDashboard();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Bayar Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tidak ada tagihan tertunggak untuk periode $currentMonthName $currentYear.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                  ),
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
            Icon(
              Icons.check_circle_outline,
              color: Color(0xFF10B981),
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Semua tagihan Anda lunas!',
              style: TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
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
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            title: Text(
              'Tagihan $bulanName ${tag['tahun'] ?? ''}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
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
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            onTap: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailTagihanWargaPage(tagihan: tag),
                ),
              );
              if (res == true) {
                fetchDashboard();
              }
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 24,
              ),
            ),
            title: Text(
              'Pembayaran $bulanName ${tag['tahun'] ?? ''}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      metode.toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.formatRupiah(tag['nominal'] ?? 0),
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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

  // Banner: Sampah Rumah Sudah Diambil Hari Ini
  Widget _buildRumahCollectedTodayBanner(Map<String, dynamic> pengambilan) {
    final jam = pengambilan['jam_ambil']?.toString() ?? '-';
    final volume = pengambilan['volume_sampah']?.toString() ?? '-';
    final petugas = pengambilan['nama_petugas']?.toString() ?? 'Petugas PKPLH';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ Sampah Sudah Diambil Hari Ini!',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Jam $jam oleh $petugas',
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 12,
                  ),
                ),
                if (volume.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Volume: $volume',
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Banner: Menunggu Pengambilan
  Widget _buildWaitingCollectionBanner(Map<String, dynamic> infoTps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⏳ Menunggu Pengambilan Sampah',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sampah Anda belum diambil hari ini. TPS: ${infoTps['nama_tps'] ?? '-'}',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kartu QR Code Stiker Tempat Sampah Warga
  Widget _buildQrCodeCard(String qrCode, dynamic profil) {
    final nama = profil?['nama_lengkap']?.toString() ?? 'Warga';
    final kode = profil?['kode']?.toString() ?? '';

    return InkWell(
      onTap: () => _showQrDialog(qrCode, nama, kode),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // QR Preview (dari API)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=80x80&data=${Uri.encodeComponent(qrCode)}',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.qr_code_2, size: 40, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR Stiker Tempat Sampah Anda',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    qrCode,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cetak & tempel di tong sampah / dinding rumah',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.fullscreen_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(String qrCode, String nama, String kode) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QR Stiker Tempat Sampah',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nama,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(qrCode)}',
                  width: 220,
                  height: 220,
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(child: Icon(Icons.qr_code_2, size: 120, color: Color(0xFF94A3B8))),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                qrCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                  fontFamily: 'monospace',
                ),
              ),
              if (kode.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Kode Wajib Retribusi: $kode',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Cetak dan tempel stiker ini di tong sampah atau dinding rumah Anda agar petugas dapat men-scan saat pengambilan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kartu Info TPS Penampungan Sampah
  Widget _buildTpsInfoCard(
    Map<String, dynamic> tps,
    dynamic profil,
    List<dynamic> riwayat,
  ) {
    final isSelesaiHariIni = tps['sudah_diambil_hari_ini'] == true;
    final jarakKm = tps['jarak_km'];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailTpsWargaPage(
              infoTps: tps,
              riwayatPengambilan: riwayat,
              profilWarga: profil,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TPS Penampungan Sampah Anda',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        tps['nama_tps']?.toString() ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tps['kode_tps']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Live Status Banner Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelesaiHariIni
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFFEF3C7).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelesaiHariIni ? Colors.white38 : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelesaiHariIni
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSelesaiHariIni
                        ? 'Status Hari Ini: Sampah Sudah Diangkut'
                        : 'Status Hari Ini: Menunggu Rute Pengangkutan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tps['alamat']?.toString() ?? 'Alamat tidak tersedia',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (jarakKm != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.navigation_outlined,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Jarak ke TPS: $jarakKm km',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'Lihat Peta & Riwayat Lengkap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Daftar Riwayat Pengambilan Sampah
  Widget _buildPengambilanList(List<dynamic> riwayat) {
    return Column(
      children: [
        ...riwayat.take(5).map<Widget>((item) {
          final tanggal = item['tanggal_ambil']?.toString() ?? '-';
          final jam = item['jam_ambil']?.toString() ?? '';
          final status = item['status']?.toString() ?? 'selesai';
          final volume = item['volume_sampah']?.toString() ?? '-';
          final catatan = item['catatan']?.toString() ?? '';
          final petugas = item['nama_petugas']?.toString() ?? 'Petugas PKPLH';
          final foto = item['foto_bukti']?.toString();
          final tipeLokasi = item['tipe_lokasi']?.toString() ?? '';
          final isRumahPelanggan = tipeLokasi == 'Rumah Pelanggan';

          final isSelesai = status == 'selesai';
          final statusColor = isSelesai
              ? const Color(0xFF059669)
              : status == 'proses'
              ? const Color(0xFFD97706)
              : status == 'terlewat'
              ? const Color(0xFFDC2626)
              : const Color(0xFF6366F1);

          String formattedDate = tanggal;
          try {
            final dt = DateTime.parse(tanggal);
            final bulanList = [
              '',
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'Mei',
              'Jun',
              'Jul',
              'Ags',
              'Sep',
              'Okt',
              'Nov',
              'Des',
            ];
            formattedDate = '${dt.day} ${bulanList[dt.month]} ${dt.year}';
          } catch (_) {}

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelesai
                        ? Icons.check_circle_outline
                        : status == 'proses'
                        ? Icons.timelapse
                        : status == 'terlewat'
                        ? Icons.cancel_outlined
                        : Icons.schedule,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (jam.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              jam.length >= 5 ? jam.substring(0, 5) : jam,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (tipeLokasi.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isRumahPelanggan
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isRumahPelanggan ? '🏠 Rumah' : '🏭 TPS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isRumahPelanggan
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        volume,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                      if (catatan.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          catatan,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            petugas,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          if (foto != null && foto.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.photo_camera_outlined,
                              size: 12,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'Ada Foto',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isSelesai
                        ? 'Selesai'
                        : status == 'proses'
                        ? 'Proses'
                        : status == 'terlewat'
                        ? 'Terlewat'
                        : 'Terjadwal',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

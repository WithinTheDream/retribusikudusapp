import 'package:flutter/material.dart';
import '../../utils/formatters.dart';

class DetailTagihanWargaPage extends StatelessWidget {
  final Map<String, dynamic> tagihan;

  const DetailTagihanWargaPage({super.key, required this.tagihan});

  static const List<String> _namaBulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _getNamaBulan(dynamic bulan) {
    if (bulan == null) return '';
    int b = int.tryParse(bulan.toString()) ?? 0;
    if (b >= 1 && b <= 12) return _namaBulan[b];
    return bulan.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isLunas = tagihan['status'] == 'lunas';
    final nominal = tagihan['nominal'] ?? 0;
    final bulanStr = _getNamaBulan(tagihan['bulan']);
    final tahunStr = tagihan['tahun']?.toString() ?? '';
    final nomorTagihan = tagihan['nomor_tagihan'] ?? 'INV-${tagihan['id']}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Tagihan Retribusi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Modern Header Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLunas
                      ? const [Color(0xFF059669), Color(0xFF047857)]
                      : const [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isLunas ? const Color(0xFF059669) : const Color(0xFFDC2626)).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLunas ? '✓ PEMBAYARAN LUNAS' : '⏳ MENUNGGU PEMBAYARAN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Total Tagihan Retribusi', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.formatRupiah(nominal),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Periode: $bulanStr $tahunStr',
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Info Detail Tagihan
            Container(
              padding: const EdgeInsets.all(18),
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
                      Icon(Icons.receipt_outlined, color: Color(0xFF059669), size: 20),
                      SizedBox(width: 8),
                      Text('Informasi Tagihan', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _buildRow('Nomor Tagihan', nomorTagihan, isBold: true),
                  _buildRow('Bulan / Tahun', '$bulanStr $tahunStr'),
                  _buildRow('Nominal Tarif', AppFormatters.formatRupiah(nominal)),
                  _buildRow('Status', isLunas ? 'Lunas ✓' : 'Belum Dibayar', valueColor: isLunas ? const Color(0xFF059669) : const Color(0xFFDC2626), isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Pembayaran QRIS jika belum bayar
            if (!isLunas) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.qr_code_2_rounded, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 8),
                        Text('Bayar Instan via QRIS', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.qr_code_2, size: 160, color: Color(0xFF1E293B)),
                          SizedBox(height: 8),
                          Text('NMID: ID1020030040050', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Petunjuk Pembayaran:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                          SizedBox(height: 4),
                          Text(
                            '1. Simpan tangkapan layar (screenshot) kode QR di atas.\n'
                            '2. Buka aplikasi Mobile Banking atau E-Wallet Anda.\n'
                            '3. Pilih menu Scan QR / QRIS, lalu unggah gambar QR.\n'
                            '4. Pembayaran akan terverifikasi secara otomatis.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.person_pin_circle_outlined, color: Color(0xFF059669), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anda juga dapat membayar secara langsung kepada Petugas Penarik Retribusi di wilayah Anda.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF065F46), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

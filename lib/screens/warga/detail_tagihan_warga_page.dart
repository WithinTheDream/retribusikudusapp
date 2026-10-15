import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../utils/formatters.dart';

class DetailTagihanWargaPage extends StatefulWidget {
  final Map<String, dynamic> tagihan;

  const DetailTagihanWargaPage({super.key, required this.tagihan});

  @override
  State<DetailTagihanWargaPage> createState() => _DetailTagihanWargaPageState();
}

class _DetailTagihanWargaPageState extends State<DetailTagihanWargaPage> {
  late bool _isLunas;
  bool _isLoadingMidtrans = false;
  bool _hasPaid = false;
  String? _currentOrderId;

  static const List<String> _namaBulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _isLunas = widget.tagihan['status'] == 'lunas';
  }

  String _getNamaBulan(dynamic bulan) {
    if (bulan == null) return '';
    int b = int.tryParse(bulan.toString()) ?? 0;
    if (b >= 1 && b <= 12) return _namaBulan[b];
    return bulan.toString();
  }

  Future<void> _bayarDenganMidtrans() async {
    setState(() => _isLoadingMidtrans = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${ApiClient.baseUrl}/warga/pembayaran/midtrans/snap-token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'tagihan_id': widget.tagihan['id'],
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final redirectUrl = data['redirect_url']?.toString();
        _currentOrderId = data['order_id']?.toString();

        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          final uri = Uri.parse(redirectUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }

        if (mounted) {
          _showDialogKonfirmasiMidtrans(redirectUrl);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Gagal membuat transaksi Midtrans'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan koneksi Midtrans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMidtrans = false);
      }
    }
  }

  void _showDialogKonfirmasiMidtrans(String? redirectUrl) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payment, color: Color(0xFF0284C7), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembayaran Midtrans Aktif',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Mode Sandbox / Demo',
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Halaman pembayaran Midtrans telah dibuka di browser. Silakan selesaikan pembayaran (QRIS / GoPay / VA), lalu klik tombol konfirmasi di bawah.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _konfirmasiPembayaranSelesai(simulate: false);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Cek Status Pembayaran (Midtrans)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              if (redirectUrl != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(redirectUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Buka Ulang Halaman Midtrans'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _konfirmasiPembayaranSelesai(simulate: true);
                },
                icon: const Icon(Icons.bolt, size: 18, color: Color(0xFF059669)),
                label: const Text(
                  'Simulasi Bayar Berhasil (Demo PKL)',
                  style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _konfirmasiPembayaranSelesai({bool simulate = false}) async {
    setState(() => _isLoadingMidtrans = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${ApiClient.baseUrl}/warga/pembayaran/midtrans/finish');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'tagihan_id': widget.tagihan['id'],
          'order_id': _currentOrderId,
          'metode_pembayaran': 'midtrans_qris',
          'simulate': simulate,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _isLunas = true;
          _hasPaid = true;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: Color(0xFF059669), size: 28),
                  SizedBox(width: 8),
                  Text('Pembayaran Berhasil!'),
                ],
              ),
              content: const Text(
                'Terima kasih, pembayaran retribusi sampah Anda melalui Midtrans telah terverifikasi secara resmi.',
                style: TextStyle(height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(c);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Konfirmasi belum diterima.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal konfirmasi status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMidtrans = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nominal = widget.tagihan['nominal'] ?? 0;
    final bulanStr = _getNamaBulan(widget.tagihan['bulan']);
    final tahunStr = widget.tagihan['tahun']?.toString() ?? '';
    final nomorTagihan = widget.tagihan['nomor_tagihan'] ?? 'INV-${widget.tagihan['id']}';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Did pop handled by system
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasPaid),
          ),
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
              // 1. Header Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLunas
                        ? const [Color(0xFF059669), Color(0xFF047857)]
                        : const [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_isLunas ? const Color(0xFF059669) : const Color(0xFFDC2626)).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isLunas ? '✓ PEMBAYARAN LUNAS' : '⏳ MENUNGGU PEMBAYARAN',
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
                    _buildRow(
                      'Status',
                      _isLunas ? 'Lunas ✓' : 'Belum Dibayar',
                      valueColor: _isLunas ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Opsi Pembayaran Midtrans (Jika belum lunas)
              if (!_isLunas) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.flash_on_rounded, color: Color(0xFF2563EB), size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Bayar Instan Online',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: const Text(
                              'Midtrans Demo',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dukung pembayaran via QRIS, GoPay, ShopeePay, serta Virtual Account BCA, BNI, BRI, Mandiri.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoadingMidtrans ? null : _bayarDenganMidtrans,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: _isLoadingMidtrans
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.payment, size: 20),
                                    SizedBox(width: 8),
                                    Text('BAYAR DENGAN MIDTRANS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Terkoneksi langsung ke Midtrans Snap Sandbox',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Alternatif Pembayaran Tunai ke Petugas
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
                          'Anda juga dapat membayar secara langsung secara tunai kepada Petugas Penarik Retribusi di wilayah Anda.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF065F46), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Card Bukti Pembayaran Berhasil
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Pembayaran Telah Terverifikasi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tagihan ini sudah lunas dicatat oleh sistem Dinas PKPLH Kudus.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, _hasPaid),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Kembali ke Dashboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

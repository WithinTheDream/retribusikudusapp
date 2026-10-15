import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import 'catat_pengambilan_page.dart';

class ScanTpsPage extends StatefulWidget {
  const ScanTpsPage({super.key});

  @override
  State<ScanTpsPage> createState() => _ScanTpsPageState();
}

class _ScanTpsPageState extends State<ScanTpsPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _isTorchOn = false;

  // Daftar warga/pelanggan Kudus untuk simulasi scanner (Demo Mode / Emulator)
  final List<Map<String, String>> _demoWargaList = [
    {
      'qr': 'QR-WR-001',
      'nama': 'Adam (WR-001)',
      'kode': 'WR-001',
    },
    {
      'qr': 'QR-WR-2026080003',
      'nama': 'awdaw (WR-2026080003)',
      'kode': 'WR-2026080003',
    },
    {
      'qr': 'QR-WR-2026080007',
      'nama': 'Adam - Karangbener, Bae',
      'kode': 'WR-2026080007',
    },
    {
      'qr': 'QR-WR-2026090008',
      'nama': 'Bluu - JL. Ngembal Rejo',
      'kode': 'WR-2026090008',
    },
    {
      'qr': 'QR-WR-202609-0009',
      'nama': 'Lamine Hanif - Jl. Gamon No.1',
      'kode': 'WR-202609-0009',
    },
    {
      'qr': 'QR-WR-202610-0010',
      'nama': 'vvvvv (WR-202610-0010)',
      'kode': 'WR-202610-0010',
    },
    {
      'qr': 'QR-WR-202610-0011',
      'nama': 'Bagus Setiawan',
      'kode': 'WR-202610-0011',
    },
  ];

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    _processQrCode(code.trim());
  }

  Future<void> _processQrCode(String qrCode) async {
    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Gunakan endpoint scan-qr baru yang mendukung warga & TPS
      final url = Uri.parse('${ApiClient.baseUrl}/petugas/scan-qr');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'qr_code': qrCode}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        final target = resData['target']?.toString() ?? 'tps';

        if (target == 'warga') {
          // QR milik stiker tempat sampah / tong sampah warga
          final wargaData = resData['data']?['warga'] as Map<String, dynamic>?;
          final tpsData = resData['data']?['tps'] as Map<String, dynamic>?;

          if (wargaData != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CatatPengambilanPage(
                  tps: tpsData ?? {},
                  warga: wargaData,
                  scannedQr: qrCode,
                ),
              ),
            );

            if (!mounted) return;
            if (result == true) {
              Navigator.pop(context, true);
            } else {
              setState(() => _isProcessing = false);
            }
            return;
          }
        } else {
          // Fallback: QR milik TPS penampungan
          final tpsData = resData['data']?['tps'] as Map<String, dynamic>?;

          if (tpsData != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CatatPengambilanPage(
                  tps: tpsData,
                  scannedQr: qrCode,
                ),
              ),
            );

            if (!mounted) return;
            if (result == true) {
              Navigator.pop(context, true);
            } else {
              setState(() => _isProcessing = false);
            }
            return;
          }
        }
      }

      final errorRes = json.decode(response.body);
      final errorMsg = errorRes['message'] ??
          'QR Code tidak dikenali sebagai stiker tempat sampah warga / TPS Kudus.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan verifikasi: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showDemoQrSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text(
                    'Simulasi Scan QR Stiker Warga (Demo)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Pilih salah satu warga/pelanggan untuk mensimulasikan pemindaian QR stiker di tong sampah / dinding rumah:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _demoWargaList.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final warga = _demoWargaList[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.home_outlined,
                        color: Color(0xFF059669),
                      ),
                    ),
                    title: Text(
                      warga['nama']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${warga['kode']} • ${warga['qr']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _processQrCode(warga['qr']!);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan QR Stiker Tempat Sampah Warga',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            tooltip: 'Senter',
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
              _scannerController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            tooltip: 'Ganti Kamera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Kamera Pemindai QR
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // Custom Overlay Target Kotak Pemindai
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF10B981),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 3),
                          left: BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 3),
                          right: BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 3),
                          left: BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 3),
                          right: BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Teks Instruksi di atas kotak
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Arahkan kamera ke stiker QR Code di tong sampah atau dinding rumah pelanggan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Loading Indicator saat memverifikasi
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF10B981)),
                    SizedBox(height: 16),
                    Text(
                      'Memverifikasi QR Tempat Sampah...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bagian Bawah: Tombol Simulasi Mode Demo / Input Manual
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _showDemoQrSelector,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.touch_app_outlined),
                  label: const Text(
                    'PILIH SIMULASI QR WARGA (DEMO)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan tombol di atas jika testing di Emulator atau tanpa QR stiker fisik',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DetailTagihanWargaPage extends StatelessWidget {
  final Map<String, dynamic> tagihan;

  const DetailTagihanWargaPage({super.key, required this.tagihan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tagihan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Total Tagihan', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${tagihan['nominal']}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text('Bulan: ${tagihan['bulan']} | Tahun: ${tagihan['tahun']}'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tagihan['status'] == 'belum_bayar' ? Colors.orange.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tagihan['status'] == 'belum_bayar' ? 'Belum Dibayar' : 'Lunas',
                        style: TextStyle(
                          color: tagihan['status'] == 'belum_bayar' ? Colors.orange.shade800 : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (tagihan['status'] == 'belum_bayar') ...[
              const Text(
                'Cara Pembayaran (QRIS)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Simulasi QR Code QRIS
                      Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.qr_code_2, size: 150, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '1. Screenshot atau simpan gambar QR ini.\n'
                        '2. Buka aplikasi M-Banking atau E-Wallet Anda.\n'
                        '3. Pilih menu Scan QR / QRIS.\n'
                        '4. Upload gambar screenshot ini dari Galeri.',
                        style: TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('QR Code berhasil disimpan ke Galeri! (Simulasi)')),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Simpan QR Code'),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  final List<Map<String, String>> faqs = const [
    {
      'q': 'Bagaimana cara mendaftar objek retribusi baru?',
      'a':
          'Masuk ke akun Warga Anda, buka tab "Retribusi", lalu tekan tombol "Ajukan Retribusi Sekarang". Lengkapi data NIK, alamat tempat tinggal/usaha, titik koordinat, dan unggah foto KTP. Pengajuan Anda akan diverifikasi oleh petugas kami.',
    },
    {
      'q': 'Kapan jatuh tempo pembayaran retribusi setiap bulannya?',
      'a':
          'Pembayaran retribusi sampah jatuh tempo pada tanggal 20 setiap bulannya. Tagihan baru akan otomatis terbit pada awal bulan.',
    },
    {
      'q': 'Bagaimana cara membayar kepada petugas lapangan?',
      'a':
          'Ketika petugas penarik retribusi mendatangi lokasi Anda, petugas akan memeriksa data tagihan melalui aplikasi petugas. Anda dapat membayar secara tunai dan meminta bukti pembayaran langsung dari petugas.',
    },
    {
      'q': 'Apakah saya bisa membayar tagihan secara online dengan QRIS?',
      'a':
          'Ya, buka menu "Retribusi" pada akun Warga, pilih salah satu tagihan yang belum lunas untuk melihat detail tagihan dan kode QRIS. Anda dapat memindai atau menyimpan gambar QRIS tersebut untuk dibayar melalui M-Banking atau E-Wallet pilihan Anda.',
    },
    {
      'q':
          'Apa yang harus dilakukan jika data tagihan atau pengajuan tidak sesuai?',
      'a':
          'Jika terdapat ketidaksesuaian nominal, alamat, atau status retribusi, Anda dapat menghubungi Help Center melalui kontak WhatsApp resmi Dinas PKPLH Kabupaten Kudus di bawah ini.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pusat Bantuan & FAQ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 3,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green.shade700,
                      child: const Icon(
                        Icons.support_agent,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Layanan Bantuan Retribusi Kudus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dinas Perumahan, Kawasan Permukiman dan Lingkungan Hidup (PKPLH) Kabupaten Kudus',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Kontak Kami
            const Text(
              'Hubungi Kami',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.phone, color: Colors.green),
                    ),
                    title: const Text('Call Center & WhatsApp'),
                    subtitle: const Text('+62 812-3456-7890 (Pengaduan)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Membuka kontak WhatsApp Layanan Pengaduan Kudus...',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.email, color: Colors.blue),
                    ),
                    title: const Text('Email Resmi'),
                    subtitle: const Text('pkplh@kuduskab.go.id'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membuka aplikasi Email pengaduan...'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E0),
                      child: Icon(Icons.location_on, color: Colors.orange),
                    ),
                    title: const Text('Alamat Kantor'),
                    subtitle: const Text(
                      'Jl. Sunan Muria No. 1, Kabupaten Kudus, Jawa Tengah',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF3E5F5),
                      child: Icon(Icons.access_time, color: Colors.purple),
                    ),
                    title: const Text('Jam Operasional Layanan'),
                    subtitle: const Text('Senin - Jumat: 08:00 - 15:30 WIB'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pertanyaan yang Sering Diajukan (FAQ)
            const Text(
              'Pertanyaan yang Sering Diajukan (FAQ)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...faqs.map(
              (faq) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  title: Text(
                    faq['q']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq['a']!,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          height: 1.5,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  final List<Map<String, String>> faqs = const [
    {
      'q': 'Bagaimana cara mendaftar objek retribusi baru?',
      'a':
          'Buka beranda Warga, pilih menu "Pengajuan", lalu lengkapi data NIK, alamat tempat tinggal/usaha, titik koordinat Google Maps, dan unggah foto KTP. Pengajuan Anda akan segera diverifikasi oleh tim Dinas PKPLH Kudus.',
    },
    {
      'q': 'Bagaimana cara menyalin titik koordinat dari Google Maps?',
      'a':
          'Buka aplikasi Google Maps, tekan dan tahan (Drop Pin) pada titik lokasi rumah/tempat usaha Anda. Di bagian atas atau detail pin akan muncul angka koordinat (contoh: -6.804825, 110.840660). Tekan angka tersebut untuk menyalin, lalu tempel di formulir pengajuan.',
    },
    {
      'q': 'Kapan jatuh tempo pembayaran retribusi setiap bulannya?',
      'a':
          'Pembayaran retribusi sampah jatuh tempo pada tanggal 20 setiap bulannya. Tagihan baru akan otomatis terbit pada awal bulan berjalan.',
    },
    {
      'q': 'Bagaimana cara membayar retribusi secara tunai?',
      'a':
          'Petugas penarik retribusi resmi di wilayah kecamatan Anda akan mendatangi lokasi sesuai titik koordinat. Anda dapat membayar tunai dan petugas akan langsung mengonfirmasi pembayaran melalui aplikasi.',
    },
    {
      'q': 'Apakah saya bisa membayar tagihan secara online dengan QRIS?',
      'a':
          'Ya, buka menu "Retribusi", tekan tagihan yang belum dibayar untuk melihat kode QRIS. Simpan atau tangkap layar (screenshot) kode QR tersebut, lalu bayar melalui aplikasi M-Banking atau E-Wallet pilihan Anda.',
    },
    {
      'q': 'Apa yang harus dilakukan jika data tagihan atau pengajuan tidak sesuai?',
      'a':
          'Jika terdapat ketidaksesuaian nominal, alamat, atau status retribusi, silakan hubungi Customer Service kami melalui WhatsApp resmi Dinas PKPLH Kudus di bawah ini.',
    },
  ];

  Future<void> _launchUrlHelper(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka tautan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pusat Bantuan & FAQ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Layanan Bantuan Retribusi Kudus',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dinas Perumahan, Kawasan Permukiman dan Lingkungan Hidup (PKPLH) Kabupaten Kudus',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFFD1FAE5), height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kontak Kami Section
            const Text(
              'Hubungi Layanan Pengaduan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDCFCE7),
                      child: Icon(Icons.chat, color: Color(0xFF16A34A), size: 20),
                    ),
                    title: const Text('WhatsApp Customer Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('+62 812-3456-7890 (Respon Cepat)', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                    onTap: () => _launchUrlHelper(context, 'https://wa.me/6281234567890?text=Halo%20Admin%20Layanan%20Retribusi%20Kudus,%20saya%20ingin%20bertanya'),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.email_outlined, color: Color(0xFF2563EB), size: 20),
                    ),
                    title: const Text('Email Pengaduan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('pkplh@kuduskab.go.id', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                    onTap: () => _launchUrlHelper(context, 'mailto:pkplh@kuduskab.go.id?subject=Pengaduan%20Retribusi%20Kudus'),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEF3C7),
                      child: Icon(Icons.location_on_outlined, color: Color(0xFFD97706), size: 20),
                    ),
                    title: const Text('Kantor Dinas PKPLH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('Jl. Sunan Muria No. 1, Kabupaten Kudus', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                    onTap: () => _launchUrlHelper(context, 'https://www.google.com/maps/search/?api=1&query=Dinas+PKPLH+Kabupaten+Kudus'),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFF3E8FF),
                      child: Icon(Icons.access_time_rounded, color: Color(0xFF9333EA), size: 20),
                    ),
                    title: Text('Jam Operasional Pelayanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('Senin – Jumat: 08:00 – 15:30 WIB', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Section
            const Text(
              'Pertanyaan yang Sering Diajukan (FAQ)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            ...faqs.map(
              (faq) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: Color(0xFF059669), size: 18),
                  ),
                  title: Text(
                    faq['q']!,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF1E293B)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq['a']!,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

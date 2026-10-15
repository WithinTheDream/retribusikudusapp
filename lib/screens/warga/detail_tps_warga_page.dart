import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailTpsWargaPage extends StatefulWidget {
  final Map<String, dynamic> infoTps;
  final List<dynamic> riwayatPengambilan;
  final Map<String, dynamic>? profilWarga;

  const DetailTpsWargaPage({
    super.key,
    required this.infoTps,
    required this.riwayatPengambilan,
    this.profilWarga,
  });

  @override
  State<DetailTpsWargaPage> createState() => _DetailTpsWargaPageState();
}

class _DetailTpsWargaPageState extends State<DetailTpsWargaPage> {
  final MapController _mapController = MapController();

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: const Text('Gagal memuat foto bukti'),
                ),
              ),
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
                    child: Center(
                      child: Icon(Icons.qr_code_2,
                          size: 120, color: Color(0xFF94A3B8)),
                    ),
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
                  'Kode WR: $kode',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Tempelkan stiker ini di tong sampah atau dinding pagar rumah Anda untuk dipindai petugas pengangkut sampah.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  height: 1.4,
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

  Widget _buildWargaQrCard(Map<String, dynamic> profil) {
    final qrCode = profil['qr_code']?.toString() ??
        (profil['kode'] != null ? 'QR-${profil['kode']}' : 'QR-WR-KUDUS');
    final nama = profil['nama_lengkap']?.toString() ?? 'Warga';
    final kode = profil['kode']?.toString() ?? '';

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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=80x80&data=${Uri.encodeComponent(qrCode)}',
                width: 65,
                height: 65,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 65,
                  height: 65,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.qr_code_2,
                      size: 36, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR Stiker Tong Sampah Rumah',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    qrCode,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Tap untuk perbesar atau cetak stiker',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
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

  @override
  Widget build(BuildContext context) {
    final tps = widget.infoTps;
    final isSelesaiHariIni = tps['sudah_diambil_hari_ini'] == true;
    final logHariIni = tps['pengambilan_hari_ini'];

    final tpsLat = double.tryParse(tps['latitude']?.toString() ?? '');
    final tpsLng = double.tryParse(tps['longitude']?.toString() ?? '');

    final wargaLat =
        double.tryParse(tps['warga_latitude']?.toString() ?? '') ??
        double.tryParse(widget.profilWarga?['latitude']?.toString() ?? '');
    final wargaLng =
        double.tryParse(tps['warga_longitude']?.toString() ?? '') ??
        double.tryParse(widget.profilWarga?['longitude']?.toString() ?? '');

    final jarakKm = tps['jarak_km'];

    // Titik tengah peta
    final centerMap = tpsLat != null && tpsLng != null
        ? LatLng(tpsLat, tpsLng)
        : const LatLng(-6.8085, 110.8420);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Detail TPS & Pengambilan Sampah',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Kartu Stiker QR Tempat Sampah Warga
            if (widget.profilWarga != null) ...[
              _buildWargaQrCard(widget.profilWarga!),
              const SizedBox(height: 16),
            ],

            // 1. Live Status Banner Hari Ini
            _buildLiveStatusBanner(isSelesaiHariIni, logHariIni),
            const SizedBox(height: 20),

            // 2. Kartu Profil TPS Penampungan
            _buildTpsDetailCard(tps, jarakKm, tpsLat, tpsLng),
            const SizedBox(height: 20),

            // 3. Mini Peta Lokasi Rumah & TPS
            if (tpsLat != null && tpsLng != null) ...[
              _buildMapSection(
                centerMap,
                tpsLat,
                tpsLng,
                wargaLat,
                wargaLng,
                jarakKm,
                tps['nama_tps'] ?? 'TPS',
              ),
              const SizedBox(height: 24),
            ],

            // 4. Riwayat Timeline Pengambilan Sampah
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
                    '${widget.riwayatPengambilan.length} Pengambilan',
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRiwayatTimeline(widget.riwayatPengambilan),
            const SizedBox(height: 24),

            // 5. Kartu Bantuan / Pengaduan Sampah
            _buildHelpCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusBanner(
    bool isSelesaiHariIni,
    dynamic logHariIni,
  ) {
    if (isSelesaiHariIni && logHariIni != null) {
      final jam = logHariIni['jam_ambil']?.toString() ?? '-';
      final volume = logHariIni['volume_sampah']?.toString() ?? '-';
      final petugas = logHariIni['nama_petugas']?.toString() ?? 'Petugas PKPLH';
      final catatan = logHariIni['catatan']?.toString() ?? '';
      final foto = logHariIni['foto_bukti']?.toString();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS PENGAMBILAN HARI INI',
                        style: TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Sampah Telah Diangkut Petugas',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    jam.length >= 5 ? jam.substring(0, 5) : jam,
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFA7F3D0)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 15, color: Color(0xFF047857)),
                const SizedBox(width: 6),
                Text(
                  'Volume: $volume',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.person_outline,
                    size: 15, color: Color(0xFF047857)),
                const SizedBox(width: 4),
                Text(
                  petugas,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (catatan.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '"$catatan"',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF047857),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (foto != null && foto.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _showImageDialog(foto),
                child: Row(
                  children: [
                    const Icon(Icons.photo_camera_back,
                        size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    const Text(
                      'Lihat Foto Bukti Pengambilan Lapangan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // State Belum Diambil Hari Ini
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timelapse_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS HARI INI: MENUNGGU JADWAL',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Menunggu Rute Pengangkutan Petugas',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Petugas kebersihan PKPLH Kudus sedang menjalankan rute pengangkutan harian di wilayah TPS Anda.',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTpsDetailCard(
    Map<String, dynamic> tps,
    dynamic jarakKm,
    double? tpsLat,
    double? tpsLng,
  ) {
    return Container(
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
            blurRadius: 10,
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
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tps['kode_tps'] ?? 'TPS',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      tps['nama_tps'] ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (jarakKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$jarakKm km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tps['alamat'] ?? 'Alamat tidak tersedia',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.map_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'Wilayah: Desa ${tps['desa'] ?? '-'}, Kec. ${tps['kecamatan'] ?? '-'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if ((tps['kapasitas'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Kapasitas: ${tps['kapasitas']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapSection(
    LatLng center,
    double tpsLat,
    double tpsLng,
    double? wargaLat,
    double? wargaLng,
    dynamic jarakKm,
    String namaTps,
  ) {
    final markers = <Marker>[
      // Marker TPS
      Marker(
        point: LatLng(tpsLat, tpsLng),
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    ];

    // Marker Warga (jika ada koordinat rumah warga)
    if (wargaLat != null && wargaLng != null) {
      markers.add(
        Marker(
          point: LatLng(wargaLat, wargaLng),
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Peta Lokasi TPS & Rumah',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (jarakKm != null)
                      Text(
                        'Estimasi Jarak: $jarakKm km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _openGoogleMaps(tpsLat, tpsLng),
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Rute Maps'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13.5,
                  minZoom: 10.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.retribusikudus.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatTimeline(List<dynamic> riwayat) {
    if (riwayat.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'Belum ada catatan riwayat pengambilan sampah di TPS ini.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: riwayat.map<Widget>((item) {
        final tanggal = item['tanggal_ambil']?.toString() ?? '-';
        final jam = item['jam_ambil']?.toString() ?? '';
        final volume = item['volume_sampah']?.toString() ?? '-';
        final catatan = item['catatan']?.toString() ?? '';
        final petugas = item['nama_petugas']?.toString() ?? 'Petugas PKPLH';
        final foto = item['foto_bukti']?.toString();
        final tipeLokasi = item['tipe_lokasi']?.toString() ?? '';
        final isRumahPelanggan = tipeLokasi == 'Rumah Pelanggan';

        String formattedDate = tanggal;
        try {
          final dt = DateTime.parse(tanggal);
          final bulanList = [
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
          formattedDate = '${dt.day} ${bulanList[dt.month]} ${dt.year}';
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF059669),
                  size: 20,
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
                            '• ${jam.length >= 5 ? jam.substring(0, 5) : jam} WIB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (tipeLokasi.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                      'Volume: $volume',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                    if (catatan.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '"$catatan"',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
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
                          'Petugas: $petugas',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (foto != null && foto.isNotEmpty)
                InkWell(
                  onTap: () => _showImageDialog(foto),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image_not_supported,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sampah Belum Diangkut?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hubungi call center Dinas PKPLH Kabupaten Kudus untuk bantuan pengangkutan.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

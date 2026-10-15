import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import 'catat_pengambilan_page.dart';
import 'scan_tps_page.dart';

class RuteTpsPage extends StatefulWidget {
  const RuteTpsPage({super.key});

  @override
  State<RuteTpsPage> createState() => _RuteTpsPageState();
}

class _RuteTpsPageState extends State<RuteTpsPage> {
  final MapController _mapController = MapController();
  final LatLng _centerKudus = const LatLng(-6.8085, 110.8420);

  bool _isLoading = true;
  bool _isMapView = false; // Toggle between list view and map view
  List<dynamic> _tpsList = [];
  List<dynamic> _filteredTpsList = [];
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Belum Diambil', 'Sudah Selesai'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTpsList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTpsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiClient.baseUrl}/petugas/tps');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        final list = (resData['data'] as List<dynamic>?) ?? [];

        if (!mounted) return;
        setState(() {
          _tpsList = list;
          _isLoading = false;
          _applyFilters();
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data rute TPS')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _applyFilters() {
    List<dynamic> list = List.from(_tpsList);

    if (_selectedFilter == 'Belum Diambil') {
      list = list.where((item) => item['sudah_diambil_hari_ini'] != true).toList();
    } else if (_selectedFilter == 'Sudah Selesai') {
      list = list.where((item) => item['sudah_diambil_hari_ini'] == true).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((item) {
        final nama = (item['nama_tps'] ?? '').toString().toLowerCase();
        final kode = (item['kode_tps'] ?? '').toString().toLowerCase();
        final kec = (item['nama_kecamatan'] ?? '').toString().toLowerCase();
        final desa = (item['nama_desa'] ?? '').toString().toLowerCase();
        return nama.contains(q) || kode.contains(q) || kec.contains(q) || desa.contains(q);
      }).toList();
    }

    setState(() {
      _filteredTpsList = list;
    });
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
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

  void _showTpsDetail(Map<String, dynamic> tps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) {
          final isSelesai = tps['sudah_diambil_hari_ini'] == true;
          final lastLog = tps['pengambilan_terakhir'];
          final lat = double.tryParse(tps['latitude']?.toString() ?? '');
          final lng = double.tryParse(tps['longitude']?.toString() ?? '');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ListView(
              controller: scrollCtrl,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelesai
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSelesai
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: isSelesai
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tps['kode_tps'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            tps['nama_tps'] ?? '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isSelesai
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelesai
                                    ? const Color(0xFFA7F3D0)
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Text(
                              isSelesai
                                  ? 'SELESAI DIAMBIL HARI INI'
                                  : 'BELUM DIAMBIL HARI INI',
                              style: TextStyle(
                                color: isSelesai
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB45309),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Alamat',
                  tps['alamat'] ?? '-',
                ),
                _buildInfoRow(
                  Icons.map_outlined,
                  'Wilayah',
                  'Desa ${tps['nama_desa'] ?? '-'}, Kec. ${tps['nama_kecamatan'] ?? '-'}',
                ),
                _buildInfoRow(
                  Icons.inventory_2_outlined,
                  'Kapasitas',
                  tps['kapasitas'] ?? '-',
                ),
                _buildInfoRow(
                  Icons.group_outlined,
                  'Warga Terdaftar',
                  '${tps['total_warga'] ?? 0} Objek Wajib Retribusi',
                ),
                _buildInfoRow(
                  Icons.qr_code_2,
                  'Kode QR Stiker',
                  tps['qr_code'] ?? '-',
                ),

                if (lastLog != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catatan Pengambilan Terakhir Hari Ini:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jam: ${lastLog['jam_ambil'] ?? '-'} • Volume: ${lastLog['volume_sampah'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        if ((lastLog['catatan'] ?? '').toString().isNotEmpty)
                          Text(
                            '"${lastLog['catatan']}"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    if (lat != null && lng != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openGoogleMaps(lat, lng),
                          icon: const Icon(Icons.directions),
                          label: const Text('Rute Maps'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF0F766E)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (lat != null && lng != null) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CatatPengambilanPage(
                                tps: tps,
                              ),
                            ),
                          );
                          if (res == true) fetchTpsList();
                        },
                        icon: const Icon(Icons.edit_note_rounded),
                        label: Text(
                          isSelesai ? 'Perbarui Catatan' : 'Catat Pengambilan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalTps = _tpsList.length;
    final selesaiTps =
        _tpsList.where((item) => item['sudah_diambil_hari_ini'] == true).length;
    final belumTps = totalTps - selesaiTps;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Rute & Pengambilan TPS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          // Toggle View Peta vs List
          IconButton(
            icon: Icon(
              _isMapView ? Icons.format_list_bulleted : Icons.map_outlined,
              color: const Color(0xFF059669),
            ),
            tooltip: _isMapView ? 'Lihat Daftar' : 'Lihat Peta Rute',
            onPressed: () {
              setState(() => _isMapView = !_isMapView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF059669)),
            tooltip: 'Segarkan Data',
            onPressed: () {
              setState(() => _isLoading = true);
              fetchTpsList();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          : Column(
              children: [
                // 1. Ringkasan Status Harian Petugas
                _buildSummaryHeader(totalTps, selesaiTps, belumTps),

                // 2. Bar Filter & Search
                _buildFilterBar(),

                // 3. Body: Peta atau Daftar Rute
                Expanded(
                  child: _isMapView ? _buildMapView() : _buildListView(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScanTpsPage(),
            ),
          );
          if (res == true) {
            setState(() => _isLoading = true);
            fetchTpsList();
          }
        },
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text(
          'SCAN QR TPS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(int total, int selesai, int belum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _buildStatCard(
            'Total TPS',
            total.toString(),
            const Color(0xFF0F766E),
            const Color(0xFFCCFBF1),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Selesai',
            selesai.toString(),
            const Color(0xFF059669),
            const Color(0xFFECFDF5),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Belum',
            belum.toString(),
            const Color(0xFFD97706),
            const Color(0xFFFEF3C7),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          // Search box
          SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _searchQuery = val;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Cari nama TPS, desa, kecamatan...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _applyFilters();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Filter chips
          Row(
            children: ['Semua', 'Belum Diambil', 'Sudah Selesai'].map((f) {
              final isSel = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(f),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : const Color(0xFF475569),
                  ),
                  selected: isSel,
                  selectedColor: const Color(0xFF059669),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = f;
                      _applyFilters();
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_filteredTpsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada TPS yang sesuai filter',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchTpsList,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _filteredTpsList.length,
        itemBuilder: (context, index) {
          final tps = _filteredTpsList[index];
          final isSelesai = tps['sudah_diambil_hari_ini'] == true;
          final lastLog = tps['pengambilan_terakhir'];
          final lat = double.tryParse(tps['latitude']?.toString() ?? '');
          final lng = double.tryParse(tps['longitude']?.toString() ?? '');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelesai
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _showTpsDetail(tps),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelesai
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isSelesai
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            color: isSelesai
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tps['nama_tps'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${tps['kode_tps']} • Desa ${tps['nama_desa'] ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
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
                            color: isSelesai
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelesai
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Text(
                            isSelesai ? 'SELESAI' : 'BELUM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelesai
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tps['alamat'] ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.group_outlined,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tps['total_warga'] ?? 0} Warga terhubung',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (lastLog != null) ...[
                          const Spacer(),
                          Text(
                            'Diambil ${lastLog['jam_ambil'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tombol Aksi Cepat
                    Row(
                      children: [
                        if (lat != null && lng != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openGoogleMaps(lat, lng),
                              icon: const Icon(Icons.directions, size: 16),
                              label: const Text(
                                'Rute Maps',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F766E),
                                side: const BorderSide(color: Color(0xFF0F766E)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        if (lat != null && lng != null) const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CatatPengambilanPage(
                                    tps: tps,
                                  ),
                                ),
                              );
                              if (res == true) fetchTpsList();
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: Text(
                              isSelesai ? 'Edit Catatan' : 'Catat Ambil',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelesai
                                  ? const Color(0xFF0F766E)
                                  : const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView() {
    final markers = <Marker>[];

    for (var tps in _filteredTpsList) {
      final lat = double.tryParse(tps['latitude']?.toString() ?? '');
      final lng = double.tryParse(tps['longitude']?.toString() ?? '');
      final isSelesai = tps['sudah_diambil_hari_ini'] == true;

      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => _showTpsDetail(tps),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isSelesai
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isSelesai ? Icons.check : Icons.delete,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centerKudus,
            initialZoom: 12.5,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.retribusikudus.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        // Legend Peta di pojok kiri atas
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 12, color: Color(0xFF059669)),
                    SizedBox(width: 6),
                    Text(
                      'Selesai Diambil',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 12, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Text(
                      'Belum Diambil',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Tombol Reset Kamera Peta ke Kudus
        Positioned(
          bottom: 90,
          right: 12,
          child: FloatingActionButton.small(
            onPressed: () {
              _mapController.move(_centerKudus, 12.5);
            },
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF059669),
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}


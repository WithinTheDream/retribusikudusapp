import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../utils/formatters.dart';
import 'detail_tagihan_petugas_page.dart';

class DashboardPetugas extends StatefulWidget {
  const DashboardPetugas({super.key});

  @override
  State<DashboardPetugas> createState() => _DashboardPetugasState();
}

class _DashboardPetugasState extends State<DashboardPetugas> {
  bool isLoading = true;
  bool hasAssignment = true;
  String kecamatanName = '';
  List<dynamic> tagihans = [];
  List<dynamic> filteredTagihans = [];

  String searchQuery = '';
  String selectedDesa = 'Semua Desa';
  List<String> availableDesas = ['Semua Desa'];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTagihan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTagihan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiClient.baseUrl}/petugas/tagihan');
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

        final rawList = (data['data'] as List<dynamic>?) ?? [];
        final assignmentStatus = data['has_assignment'] ?? true;
        final wilayahData = data['wilayah'];
        final kec = wilayahData?['nama_kecamatan'] ?? 'Kudus';

        // Extract daftar desa unik dari list tagihan
        final Set<String> desaSet = {'Semua Desa'};
        for (var item in rawList) {
          final desaName = item['wajib_retribusi']?['desa']?['desa'];
          if (desaName != null && desaName.toString().isNotEmpty) {
            desaSet.add(desaName.toString());
          }
        }

        setState(() {
          hasAssignment = assignmentStatus;
          kecamatanName = kec;
          tagihans = rawList;
          availableDesas = desaSet.toList();
          if (!availableDesas.contains(selectedDesa)) {
            selectedDesa = 'Semua Desa';
          }
          _applyFilters();
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data tagihan')),
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

  void _applyFilters() {
    List<dynamic> result = List.from(tagihans);

    // 1. Filter Desa
    if (selectedDesa != 'Semua Desa') {
      result = result.where((item) {
        final desa = item['wajib_retribusi']?['desa']?['desa']?.toString() ?? '';
        return desa == selectedDesa;
      }).toList();
    }

    // 2. Search Query (Nama, NIK, No Tagihan, Alamat)
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((item) {
        final wr = item['wajib_retribusi'] ?? {};
        final nama = (wr['nama_lengkap'] ?? '').toString().toLowerCase();
        final nik = (wr['nik'] ?? '').toString().toLowerCase();
        final alamat = (wr['alamat'] ?? '').toString().toLowerCase();
        final noTagihan = (item['nomor_tagihan'] ?? '').toString().toLowerCase();

        return nama.contains(q) || nik.contains(q) || alamat.contains(q) || noTagihan.contains(q);
      }).toList();
    }

    setState(() {
      filteredTagihans = result;
    });
  }

  // Mengelompokkan tagihan berdasarkan nama Desa
  Map<String, List<dynamic>> _groupTagihanByDesa() {
    final Map<String, List<dynamic>> grouped = {};
    for (var item in filteredTagihans) {
      final desaName = item['wajib_retribusi']?['desa']?['desa']?.toString() ?? 'Lainnya';
      if (!grouped.containsKey(desaName)) {
        grouped[desaName] = [];
      }
      grouped[desaName]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tagihan Wilayah',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            if (kecamatanName.isNotEmpty)
              Text(
                'Kecamatan $kecamatanName',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF059669)),
            tooltip: 'Segarkan',
            onPressed: () {
              setState(() => isLoading = true);
              fetchTagihan();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : !hasAssignment
              ? _buildNoAssignmentState()
              : tagihans.isEmpty
                  ? _buildAllPaidState()
                  : Column(
                      children: [
                        // Header Filter & Search Box
                        _buildFilterAndSearchSection(),

                        // Body List Tagihan Grouped by Desa
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: fetchTagihan,
                            child: filteredTagihans.isEmpty
                                ? _buildEmptySearchResult()
                                : _buildGroupedTagihanList(),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildFilterAndSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          // Banner Wilayah Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF059669), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tagihan untuk Wilayah: Kec. $kecamatanName',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredTagihans.length} Tagihan',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
              searchQuery = val;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Cari nama warga, NIK, alamat...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _searchController.clear();
                        searchQuery = '';
                        _applyFilters();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF059669)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Dropdown Filter Desa
          Row(
            children: [
              const Icon(Icons.filter_list, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              const Text(
                'Filter Desa:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDesa,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF059669)),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                      items: availableDesas.map((desa) {
                        return DropdownMenuItem<String>(
                          value: desa,
                          child: Text(desa),
                        );
                      }).toList(),
                      onChanged: (newDesa) {
                        if (newDesa != null) {
                          selectedDesa = newDesa;
                          _applyFilters();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTagihanList() {
    final grouped = _groupTagihanByDesa();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: grouped.keys.length,
      itemBuilder: (context, groupIndex) {
        final desaName = grouped.keys.elementAt(groupIndex);
        final listForDesa = grouped[desaName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Nama Desa
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 10.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Desa $desaName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${listForDesa.length} Wajib Retribusi)',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Item Tagihan di Desa Tersebut
            ...listForDesa.map((tagihan) => _buildTagihanCard(tagihan)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildTagihanCard(dynamic tagihan) {
    final wr = tagihan['wajib_retribusi'] ?? {};
    final nama = wr['nama_lengkap'] ?? 'Tanpa Nama';
    final alamat = wr['alamat'] ?? '-';
    final rw = wr['rw'] ?? '';
    final rt = wr['rt'] ?? '';
    final nominal = tagihan['nominal'] ?? 0;
    final bulan = tagihan['bulan'] ?? '';
    final tahun = tagihan['tahun'] ?? '';

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
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Belum Bayar',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.home_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$alamat ${rt.isNotEmpty ? "RT $rt " : ""}${rw.isNotEmpty ? "RW $rw" : ""}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periode $bulan/$tahun',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      AppFormatters.formatRupiah(nominal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailTagihanPetugasPage(tagihan: tagihan),
                      ),
                    );
                    if (result == true) {
                      setState(() => isLoading = true);
                      fetchTagihan();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Detail & Bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchResult() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off_rounded, size: 54, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'Tidak Ada Tagihan yang Cocok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci pencarian atau filter desa.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPaidState() {
    return RefreshIndicator(
      onRefresh: fetchTagihan,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Banner info wilayah
              if (kecamatanName.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF059669), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Wilayah Penugasan: Kec. $kecamatanName',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                ),
                child: const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Semua Tagihan Lunas!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tidak ada tagihan yang tertunggak di wilayah penugasan Anda saat ini.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => isLoading = true);
                  fetchTagihan();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Perbarui Data Tagihan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoAssignmentState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_late_outlined, size: 64, color: Color(0xFFD97706)),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Penugasan Wilayah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Akun Anda belum dikaitkan dengan Kecamatan atau Desa oleh Admin Dinas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => isLoading = true);
                fetchTagihan();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Cek Ulang Penugasan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

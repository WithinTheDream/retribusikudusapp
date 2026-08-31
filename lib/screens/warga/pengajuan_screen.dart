import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key});

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  final _nikController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _noHpController = TextEditingController();
  final _namaUsahaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _koordinatController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _ktpImageFile;
  bool _isLoading = false;
  bool _isLoadingMaster = true;

  // Master Data State
  List<dynamic> _jenisRetribusis = [];
  List<dynamic> _kecamatans = [];
  List<dynamic> _desas = [];

  int? _selectedJenisRetribusiId;
  int? _selectedKecamatanId;
  int? _selectedDesaId;

  @override
  void initState() {
    super.initState();
    _loadUserInitialData();
    _fetchMasterData();
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaLengkapController.dispose();
    _noHpController.dispose();
    _namaUsahaController.dispose();
    _alamatController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _koordinatController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final nama = prefs.getString('nama');
    if (nama != null && nama.isNotEmpty) {
      setState(() {
        _namaLengkapController.text = nama;
      });
    }
  }

  Future<void> _fetchMasterData() async {
    try {
      final resJenis = await http.get(
        Uri.parse('${ApiClient.baseUrl}/master/jenis-retribusi'),
        headers: ApiClient.headers,
      );
      final resKec = await http.get(
        Uri.parse('${ApiClient.baseUrl}/master/kecamatan'),
        headers: ApiClient.headers,
      );

      if (resJenis.statusCode == 200 && resKec.statusCode == 200) {
        final dataJenis = json.decode(resJenis.body)['data'] ?? [];
        final dataKec = json.decode(resKec.body)['data'] ?? [];

        if (mounted) {
          setState(() {
            _jenisRetribusis = dataJenis;
            _kecamatans = dataKec;
            _isLoadingMaster = false;
          });
        }
      } else {
        _setFallbackMasterData();
      }
    } catch (_) {
      _setFallbackMasterData();
    }
  }

  void _setFallbackMasterData() {
    if (!mounted) return;
    setState(() {
      _isLoadingMaster = false;
      if (_jenisRetribusis.isEmpty) {
        _jenisRetribusis = [
          {'id': 1, 'nama': 'Rumah Tinggal'},
          {'id': 2, 'nama': 'Komersial / Usaha'},
          {'id': 3, 'nama': 'Instansi / Industri'},
        ];
      }
      if (_kecamatans.isEmpty) {
        _kecamatans = [
          {'id': 1, 'kecamatan': 'Kota Kudus'},
          {'id': 2, 'kecamatan': 'Jati'},
          {'id': 3, 'kecamatan': 'Bae'},
          {'id': 4, 'kecamatan': 'Gebog'},
          {'id': 5, 'kecamatan': 'Kaliwungu'},
          {'id': 6, 'kecamatan': 'Dawe'},
          {'id': 7, 'kecamatan': 'Mejobo'},
          {'id': 8, 'kecamatan': 'Jekulo'},
          {'id': 9, 'kecamatan': 'Undaan'},
        ];
      }
    });
  }

  Future<void> _fetchDesa(int kecamatanId) async {
    setState(() {
      _desas = [];
      _selectedDesaId = null;
    });

    try {
      final resDesa = await http.get(
        Uri.parse('${ApiClient.baseUrl}/master/desa/$kecamatanId'),
        headers: ApiClient.headers,
      );
      if (resDesa.statusCode == 200) {
        final data = json.decode(resDesa.body)['data'] ?? [];
        if (mounted) {
          setState(() => _desas = data);
        }
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _ktpImageFile = picked);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto KTP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.camera_alt, color: Color(0xFF0284C7)),
                ),
                title: const Text('Buka Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.photo_library, color: Color(0xFF16A34A)),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pasteCoordinateFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _koordinatController.text = data.text!.trim();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Koordinat berhasil ditempel dari clipboard!'),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard kosong.')),
      );
    }
  }

  Future<void> _submitPengajuan() async {
    // 1. Validasi Form
    if (_nikController.text.trim().length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIK harus terdiri dari tepat 16 digit!')),
      );
      return;
    }

    if (_namaLengkapController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Lengkap Pemohon wajib diisi!')),
      );
      return;
    }

    if (_selectedJenisRetribusiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih Jenis Retribusi!')),
      );
      return;
    }

    if (_selectedKecamatanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih Kecamatan!')),
      );
      return;
    }

    if (_selectedDesaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih Desa / Kelurahan!')),
      );
      return;
    }

    if (_alamatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat jalan/lokasi wajib diisi!')),
      );
      return;
    }

    if (_rtController.text.trim().isEmpty || _rwController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RT dan RW wajib diisi!')),
      );
      return;
    }

    if (_noHpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor WhatsApp / HP wajib diisi!')),
      );
      return;
    }

    // 2. Validasi & Parsing Single Coordinate Input
    final rawCoord = _koordinatController.text.trim();
    if (rawCoord.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titik koordinat Latitude & Longitude wajib diisi untuk penugasan petugas!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<String> parts = [];
    if (rawCoord.contains(',')) {
      parts = rawCoord.split(',');
    } else if (rawCoord.contains(' ')) {
      parts = rawCoord.split(RegExp(r'\s+'));
    }

    if (parts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format koordinat tidak valid. Contoh format: -6.804825, 110.840660'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final latStr = parts[0].trim();
    final longStr = parts[1].trim();
    final latVal = double.tryParse(latStr);
    final longVal = double.tryParse(longStr);

    if (latVal == null || longVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nilai Latitude dan Longitude harus berupa angka desimal valid!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_ktpImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan upload foto KTP terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${ApiClient.baseUrl}/warga/pengajuan');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields['nik'] = _nikController.text.trim();
      request.fields['nama_lengkap'] = _namaLengkapController.text.trim();
      request.fields['nama_usaha'] = _namaUsahaController.text.trim();
      request.fields['jenis_retribusi_id'] = _selectedJenisRetribusiId.toString();
      request.fields['kecamatan_id'] = _selectedKecamatanId.toString();
      request.fields['desa_id'] = _selectedDesaId.toString();
      request.fields['alamat'] = _alamatController.text.trim();
      request.fields['rt'] = _rtController.text.trim();
      request.fields['rw'] = _rwController.text.trim();
      request.fields['lat'] = latVal.toString();
      request.fields['lokasi_long'] = longVal.toString();
      request.fields['koordinat'] = rawCoord;
      request.fields['no_hp'] = _noHpController.text.trim();

      // Unggah Dokumen KTP
      if (kIsWeb) {
        final bytes = await _ktpImageFile!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'dokumen[KTP]',
            bytes,
            filename: _ktpImageFile!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'dokumen[KTP]',
            _ktpImageFile!.path,
            filename: _ktpImageFile!.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (!mounted) return;

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Pengajuan berhasil dikirim! Menunggu verifikasi.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        Navigator.pop(context, true);
      } else {
        String msg = data['message'] ?? 'Gagal memproses pengajuan';
        if (data['errors'] != null) {
          final errMap = data['errors'] as Map<String, dynamic>;
          msg += ': ${errMap.values.map((e) => e.toString()).join(", ")}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan jaringan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStepHeader({required String step, required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Icon(icon, color: const Color(0xFF059669), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669), letterSpacing: 0.5),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pendaftaran Objek Retribusi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _isLoadingMaster
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Info
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Lengkapi formulir di bawah ini untuk pendaftaran wajib retribusi sampah resmi Kabupaten Kudus.',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STEP 1: IDENTITAS PEMOHON
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepHeader(step: 'Langkah 1', title: 'Data Identitas Pemohon', icon: Icons.person_outline),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        TextField(
                          controller: _nikController,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Induk Kependudukan (NIK)*',
                            hintText: '16 digit sesuai KTP',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _namaLengkapController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap Pemohon*',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _noHpController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor WhatsApp / HP Aktif*',
                            hintText: 'Contoh: 08123456789',
                            prefixIcon: Icon(Icons.phone_android),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STEP 2: KATEGORI OBJEK RETRIBUSI
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepHeader(step: 'Langkah 2', title: 'Kategori Objek Retribusi', icon: Icons.category_outlined),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedJenisRetribusiId,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Jenis Objek Retribusi*',
                            prefixIcon: Icon(Icons.home_work_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                          items: _jenisRetribusis.map<DropdownMenuItem<int>>((item) {
                            return DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text(item['nama'] ?? '-', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedJenisRetribusiId = val),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _namaUsahaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Toko / Usaha (Opsional)',
                            hintText: 'Isi jika objek berupa tempat usaha/kios',
                            prefixIcon: Icon(Icons.storefront_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STEP 3: ALAMAT & TITIK KOORDINAT LOKASI
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepHeader(step: 'Langkah 3', title: 'Alamat & Titik Koordinat', icon: Icons.location_on_outlined),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedKecamatanId,
                          decoration: const InputDecoration(
                            labelText: 'Kecamatan*',
                            prefixIcon: Icon(Icons.map_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                          items: _kecamatans.map<DropdownMenuItem<int>>((item) {
                            return DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text(item['kecamatan'] ?? '-', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedKecamatanId = val);
                              _fetchDesa(val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedDesaId,
                          decoration: const InputDecoration(
                            labelText: 'Desa / Kelurahan*',
                            prefixIcon: Icon(Icons.holiday_village_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                          items: _desas.map<DropdownMenuItem<int>>((item) {
                            return DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text(item['desa'] ?? '-', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: _desas.isEmpty ? null : (val) => setState(() => _selectedDesaId = val),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _alamatController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Lengkap / Nama Jalan*',
                            hintText: 'Contoh: Jl. Diponegoro No. 45',
                            prefixIcon: Icon(Icons.home_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rtController,
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                decoration: const InputDecoration(
                                  labelText: 'RT*',
                                  hintText: '001',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _rwController,
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                decoration: const InputDecoration(
                                  labelText: 'RW*',
                                  hintText: '005',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SINGLE COMBINED COORDINATE INPUT
                        TextField(
                          controller: _koordinatController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'Titik Koordinat Maps (Wajib)*',
                            hintText: 'Contoh: -6.804825, 110.840660',
                            prefixIcon: const Icon(Icons.pin_drop, color: Color(0xFFDC2626)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.content_paste, color: Color(0xFF2563EB)),
                              tooltip: 'Tempel dari Clipboard',
                              onPressed: _pasteCoordinateFromClipboard,
                            ),
                            helperText: 'Cukup salin & tempel titik koordinat dari Google Maps',
                            helperMaxLines: 2,
                            helperStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STEP 4: FOTO DOKUMEN KTP
                  _buildCardWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepHeader(step: 'Langkah 4', title: 'Upload Dokumen KTP', icon: Icons.upload_file),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        if (_ktpImageFile == null)
                          InkWell(
                            onTap: _showImageSourceDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                              ),
                              child: Column(
                                children: const [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Color(0xFFE2E8F0),
                                    child: Icon(Icons.add_a_photo_outlined, color: Color(0xFF475569), size: 26),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Pilih / Ambil Foto KTP',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Format JPG/PNG, pastikan teks KTP terbaca jelas',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: kIsWeb
                                      ? Image.network(_ktpImageFile!.path, height: 180, width: double.infinity, fit: BoxFit.cover)
                                      : Image.file(File(_ktpImageFile!.path), height: 180, width: double.infinity, fit: BoxFit.cover),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Foto KTP siap diunggah',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _showImageSourceDialog,
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Ganti', style: TextStyle(fontSize: 12)),
                                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF059669)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // SUBMIT BUTTON
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitPengajuan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'KIRIM PENGAJUAN SEKARANG',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

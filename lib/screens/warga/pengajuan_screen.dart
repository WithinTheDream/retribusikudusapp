import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final _latController = TextEditingController();
  final _longController = TextEditingController();

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
      // Fallback data umum jika API master sedang tidak merespons
      if (_jenisRetribusis.isEmpty) {
        _jenisRetribusis = [
          {'id': 1, 'nama': 'Rumah Tangga'},
          {'id': 2, 'nama': 'Komersial / Usaha'},
          {'id': 3, 'nama': 'Instansi / Industri'},
        ];
      }
    });
  }

  void _onKecamatanChanged(int? kecamatanId) {
    setState(() {
      _selectedKecamatanId = kecamatanId;
      _selectedDesaId = null;
      _desas = [];
    });

    if (kecamatanId == null) return;

    // Cari daftar desa dari data kecamatan yang sudah dimuat
    final selectedKec = _kecamatans.firstWhere(
      (k) => k['id'] == kecamatanId,
      orElse: () => null,
    );

    if (selectedKec != null &&
        selectedKec['desas'] != null &&
        (selectedKec['desas'] as List).isNotEmpty) {
      setState(() {
        _desas = selectedKec['desas'];
      });
    } else {
      // Fetch desa by kecamatan jika belum tersarang di data kecamatan
      _fetchDesaByKecamatan(kecamatanId);
    }
  }

  Future<void> _fetchDesaByKecamatan(int kecamatanId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiClient.baseUrl}/master/desa/$kecamatanId'),
        headers: ApiClient.headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'] ?? [];
        if (mounted) {
          setState(() {
            _desas = data;
          });
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
        setState(() {
          _ktpImageFile = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
      }
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
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto KTP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Pilih dari Galeri'),
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

  Future<void> _submitPengajuan() async {
    // Validasi Form
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silakan pilih Kecamatan!')));
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

    if (_rtController.text.trim().isEmpty ||
        _rwController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('RT dan RW wajib diisi!')));
      return;
    }

    if (_latController.text.trim().isEmpty ||
        _longController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Titik koordinat Latitude dan Longitude wajib diisi untuk navigasi petugas!',
          ),
        ),
      );
      return;
    }

    if (double.tryParse(_latController.text.trim()) == null ||
        double.tryParse(_longController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Format Latitude dan Longitude harus berupa angka desimal (Contoh: -6.8048, 110.8405)!',
          ),
        ),
      );
      return;
    }

    if (_ktpImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan upload foto KTP terlebih dahulu!'),
        ),
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

      // Field wajib sesuai validasi backend Laravel
      request.fields['nik'] = _nikController.text.trim();
      request.fields['nama_lengkap'] = _namaLengkapController.text.trim();
      request.fields['nama_usaha'] = _namaUsahaController.text.trim();
      request.fields['jenis_retribusi_id'] = _selectedJenisRetribusiId
          .toString();
      request.fields['kecamatan_id'] = _selectedKecamatanId.toString();
      request.fields['desa_id'] = _selectedDesaId.toString();
      request.fields['alamat'] = _alamatController.text.trim();
      request.fields['rt'] = _rtController.text.trim();
      request.fields['rw'] = _rwController.text.trim();
      request.fields['lat'] = _latController.text.trim();
      request.fields['lokasi_long'] = _longController.text.trim();
      request.fields['no_hp'] = _noHpController.text.trim();

      // Unggah Dokumen KTP dengan key dokumen[KTP] sesuai controller backend
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

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  'Pengajuan berhasil dikirim! Menunggu verifikasi.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Kembali dan refresh dashboard
      } else {
        // Tampilkan pesan error validasi yang detail jika ada
        String errorMsg = data['message'] ?? 'Gagal mengirim pengajuan.';
        if (data['errors'] != null && data['errors'] is Map) {
          final errorsMap = data['errors'] as Map;
          final errorList = errorsMap.values
              .map((e) => e is List ? e.first : e.toString())
              .toList();
          errorMsg = errorList.join('\n');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Retribusi')),
      body: _isLoadingMaster
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data wilayah & retribusi...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD 1: IDENTITAS PEMOHON
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Identitas Pemohon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nikController,
                            maxLength: 16,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'NIK KTP * (16 Digit)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _namaLengkapController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap Pemohon *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noHpController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Nomor WhatsApp / HP',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 2: JENIS RETRIBUSI & USAHA
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '2. Jenis Objek Retribusi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedJenisRetribusiId,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Jenis Retribusi *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _jenisRetribusis.map<DropdownMenuItem<int>>((
                              item,
                            ) {
                              return DropdownMenuItem<int>(
                                value: item['id'],
                                child: Text(
                                  item['nama'] ?? 'Jenis #${item['id']}',
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedJenisRetribusiId = val;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _namaUsahaController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Usaha / Toko (Opsional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.storefront),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 3: LOKASI & WILAYAH
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '3. Alamat & Wilayah Penagihan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Dropdown Kecamatan
                          DropdownButtonFormField<int>(
                            initialValue: _selectedKecamatanId,
                            decoration: const InputDecoration(
                              labelText: 'Kecamatan *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            items: _kecamatans.map<DropdownMenuItem<int>>((
                              item,
                            ) {
                              return DropdownMenuItem<int>(
                                value: item['id'],
                                child: Text(
                                  item['kecamatan'] ??
                                      'Kecamatan #${item['id']}',
                                ),
                              );
                            }).toList(),
                            onChanged: _onKecamatanChanged,
                          ),
                          const SizedBox(height: 12),

                          // Dropdown Desa
                          DropdownButtonFormField<int>(
                            key: ValueKey(_selectedKecamatanId),
                            initialValue: _selectedDesaId,
                            decoration: const InputDecoration(
                              labelText: 'Desa / Kelurahan *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.holiday_village),
                            ),
                            items: _desas.map<DropdownMenuItem<int>>((item) {
                              return DropdownMenuItem<int>(
                                value: item['id'],
                                child: Text(
                                  item['desa'] ?? 'Desa #${item['id']}',
                                ),
                              );
                            }).toList(),
                            onChanged: _selectedKecamatanId == null
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedDesaId = val;
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _alamatController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Alamat Lengkap / Jalan *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.home),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _rtController,
                                  maxLength: 3,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'RT * (cth: 01)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _rwController,
                                  maxLength: 3,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'RW * (cth: 02)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _latController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Latitude (Wajib)*',
                                    hintText: 'Contoh: -6.8048',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _longController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Longitude (Wajib)*',
                                    hintText: 'Contoh: 110.8405',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 4: FOTO DOKUMEN KTP
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '4. Upload Berkas Dokumen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Foto KTP Pemohon *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_ktpImageFile == null)
                            OutlinedButton.icon(
                              onPressed: _showImageSourceDialog,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text(
                                'Ambil Foto KTP (Kamera / Galeri)',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(color: Colors.green.shade700),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? Image.network(
                                            _ktpImageFile!.path,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_ktpImageFile!.path),
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _ktpImageFile!.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _showImageSourceDialog,
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Ganti'),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => setState(
                                          () => _ktpImageFile = null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SUBMIT BUTTON
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitPengajuan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'KIRIM PENGAJUAN RETRIBUSI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key});

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  final _nikController = TextEditingController();
  final _namaUsahaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();
  final _nibController = TextEditingController(); // Simulasi file
  final _npwpController = TextEditingController(); // Simulasi file
  bool _isLoading = false;
  String _ktpFileName = '';

  void _submitPengajuan() async {
    if (_nikController.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NIK harus 16 digit!')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse('${ApiClient.baseUrl}/warga/pengajuan');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nik': _nikController.text,
          'nama_lengkap': _namaUsahaController.text.isNotEmpty ? _namaUsahaController.text : 'Warga',
          'alamat': _alamatController.text,
          'nama_usaha': _namaUsahaController.text,
          'lat': _latController.text,
          'lokasi_long': _longController.text,
          // ktp_file akan ditangani dengan Multipart jika pakai FilePicker asli, ini versi simulasi JSON
        }),
      );

      final data = json.decode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali dan refresh
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal mengirim pengajuan')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Retribusi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Isi Form Pengajuan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _nikController, 
              maxLength: 16,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'NIK KTP * (16 Digit)')
            ),
            const SizedBox(height: 12),
            TextField(controller: _alamatController, maxLines: 3, decoration: const InputDecoration(labelText: 'Alamat Lengkap *')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _latController, decoration: const InputDecoration(labelText: 'Latitude'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _longController, decoration: const InputDecoration(labelText: 'Longitude'))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _namaUsahaController, decoration: const InputDecoration(labelText: 'Nama Usaha (Opsional)')),
            const SizedBox(height: 16),
            
            // KTP Upload Button Simulation
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _ktpFileName = 'ktp_${_nikController.text}.jpg';
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File KTP berhasil dipilih')));
              }, 
              icon: const Icon(Icons.upload_file), 
              label: Text(_ktpFileName.isEmpty ? 'Upload Foto KTP *' : 'KTP: $_ktpFileName')
            ),

            const SizedBox(height: 12),
            TextField(controller: _nibController, decoration: const InputDecoration(labelText: 'Dokumen NIB (Opsional)')),
            const SizedBox(height: 12),
            TextField(controller: _npwpController, decoration: const InputDecoration(labelText: 'Dokumen NPWP (Opsional)')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitPengajuan,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('KIRIM PENGAJUAN', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

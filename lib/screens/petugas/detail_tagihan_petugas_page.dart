import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class DetailTagihanPetugasPage extends StatefulWidget {
  final Map<String, dynamic> tagihan;

  const DetailTagihanPetugasPage({super.key, required this.tagihan});

  @override
  State<DetailTagihanPetugasPage> createState() => _DetailTagihanPetugasPageState();
}

class _DetailTagihanPetugasPageState extends State<DetailTagihanPetugasPage> {
  bool isProcessing = false;

  Future<void> _prosesPembayaranTunai() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiClient.baseUrl}/petugas/pembayaran/tunai');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'tagihan_id': widget.tagihan['id'],
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran Tunai Berhasil!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali ke dashboard dengan membawa status 'true'
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Gagal memproses pembayaran'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wajibRetribusi = widget.tagihan['wajib_retribusi'] ?? {};
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tagihan Warga'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Wajib Retribusi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('Nama: ${wajibRetribusi['nama_lengkap'] ?? '-'}'),
                    Text('NIK: ${wajibRetribusi['nik'] ?? '-'}'),
                    Text('No HP: ${wajibRetribusi['no_hp'] ?? '-'}'),
                    const SizedBox(height: 8),
                    Text('Alamat: ${wajibRetribusi['alamat']} RT ${wajibRetribusi['rt']} / RW ${wajibRetribusi['rw']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Total Tagihan', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${widget.tagihan['nominal']}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text('Bulan: ${widget.tagihan['bulan']} | Tahun: ${widget.tagihan['tahun']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isProcessing ? null : _prosesPembayaranTunai,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Terima Pembayaran Tunai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

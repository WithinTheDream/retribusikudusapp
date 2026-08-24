import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

class RekapSetoranPage extends StatefulWidget {
  @override
  _RekapSetoranPageState createState() => _RekapSetoranPageState();
}

class _RekapSetoranPageState extends State<RekapSetoranPage> {
  bool isLoading = true;
  bool isSubmitting = false;
  Map<String, dynamic> rekapData = {};

  @override
  void initState() {
    super.initState();
    fetchRekap();
  }

  Future<void> fetchRekap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiClient.baseUrl}/petugas/setoran/rekap');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          rekapData = data['data'];
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data rekap')),
        );
      }
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> submitSetoran() async {
    if (isSubmitting) return;
    setState(() { isSubmitting = true; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final url = Uri.parse('${ApiClient.baseUrl}/petugas/setoran/submit');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setoran Berhasil Dikirim')),
        );
        Navigator.pop(context); // Kembali
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal mengirim setoran')),
        );
        setState(() { isSubmitting = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
      setState(() { isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rekap Setoran')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : rekapData.isEmpty || rekapData['jumlah_transaksi'] == 0
              ? Center(child: Text('Tidak ada setoran hari ini.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text('Total Uang Tunai Hari Ini', style: TextStyle(fontSize: 16)),
                              SizedBox(height: 10),
                              Text(
                                'Rp ${rekapData['total_uang']}',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              SizedBox(height: 10),
                              Text('${rekapData['jumlah_transaksi']} Transaksi'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isSubmitting ? null : submitSetoran,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isSubmitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Submit Setoran ke Bendahara', style: TextStyle(fontSize: 18)),
                      )
                    ],
                  ),
                ),
    );
  }
}

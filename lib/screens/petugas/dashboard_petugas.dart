import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_tagihan_petugas_page.dart';
import '../../core/api_client.dart';

class DashboardPetugas extends StatefulWidget {
  @override
  _DashboardPetugasState createState() => _DashboardPetugasState();
}

class _DashboardPetugasState extends State<DashboardPetugas> {
  List<dynamic> tagihans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTagihan();
  }

  Future<void> fetchTagihan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // Asumsi token disimpan di shared_preferences

      final url = Uri.parse('${ApiClient.baseUrl}/petugas/tagihan');
      
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
          tagihans = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data tagihan')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Petugas'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : tagihans.isEmpty
              ? Center(child: Text('Tidak ada tagihan yang belum lunas di wilayah Anda.'))
              : ListView.builder(
                  itemCount: tagihans.length,
                  itemBuilder: (context, index) {
                    final tagihan = tagihans[index];
                    final wajibRetribusi = tagihan['wajib_retribusi'];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(wajibRetribusi['nama_lengkap'] ?? 'Unknown'),
                        subtitle: Text('Bulan: ${tagihan['bulan']} | Tahun: ${tagihan['tahun']} \nNominal: Rp ${tagihan['nominal']}'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DetailTagihanPetugasPage(tagihan: tagihan)),
                            );
                            if (result == true) {
                              fetchTagihan(); // Refresh data jika berhasil bayar
                            }
                          },
                          child: Text('Detail'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

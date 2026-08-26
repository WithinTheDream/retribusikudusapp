import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifTagihan = true;
  bool _notifStatus = true;
  String _nama = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nama = prefs.getString('nama') ?? 'Pengguna';
      _role = prefs.getString('role') ?? 'User';
      _notifTagihan = prefs.getBool('notif_tagihan') ?? true;
      _notifStatus = prefs.getBool('notif_status') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ubah Kata Sandi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oldPasswordController,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Saat Ini',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureOld ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setModalState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Baru',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setModalState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi Baru',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setModalState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (oldPasswordController.text.isEmpty ||
                      newPasswordController.text.isEmpty ||
                      confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Semua kolom wajib diisi!')),
                    );
                    return;
                  }
                  if (newPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kata sandi baru minimal 6 karakter!'),
                      ),
                    );
                    return;
                  }
                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Konfirmasi kata sandi baru tidak cocok!',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kata sandi berhasil diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  'SIMPAN KATA SANDI BARU',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kebijakan Privasi'),
        content: const SingleChildScrollView(
          child: Text(
            'Aplikasi Retribusi Sampah Kudus menghargai dan melindungi data pribadi Anda.\n\n'
            '1. Penggunaan Data: Data NIK, KTP, dan alamat hanya digunakan untuk kepentingan validasi objek retribusi resmi Pemerintah Kabupaten Kudus.\n\n'
            '2. Keamanan Transaksi: Riwayat pembayaran dan nominal tercatat secara transparan dan aman pada server Dinas PKPLH Kudus.\n\n'
            '3. Hak Pengguna: Pengguna dapat mengajukan pembaruan data melalui menu Pusat Bantuan atau kantor dinas terkait.',
            style: TextStyle(height: 1.5, fontSize: 13.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Akun Info
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.green.shade100,
                    child: Icon(Icons.person, color: Colors.green.shade800),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Peran: ${_role.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Keamanan Akun
          const Text(
            'Keamanan Akun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.green),
                  title: const Text('Ubah Kata Sandi'),
                  subtitle: const Text(
                    'Ganti password akun Anda secara berkala',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notifikasi
          const Text(
            'Preferensi Notifikasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.blue,
                  ),
                  title: const Text('Pengingat Tagihan Bulanan'),
                  subtitle: const Text(
                    'Terima pengingat saat tagihan retribusi baru terbit',
                  ),
                  value: _notifTagihan,
                  activeThumbColor: Colors.green,
                  onChanged: (val) {
                    setState(() => _notifTagihan = val);
                    _savePreference('notif_tagihan', val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text('Pembaruan Status Pengajuan'),
                  subtitle: const Text(
                    'Notifikasi ketika status pengajuan berubah',
                  ),
                  value: _notifStatus,
                  activeThumbColor: Colors.green,
                  onChanged: (val) {
                    setState(() => _notifStatus = val);
                    _savePreference('notif_status', val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Informasi & Kebijakan
          const Text(
            'Tentang Aplikasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.purple,
                  ),
                  title: const Text('Kebijakan Privasi & Ketentuan'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showPrivacyPolicyDialog,
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.teal),
                  title: Text('Versi Aplikasi'),
                  subtitle: Text('1.0.0 (PKL Edition Kudus)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

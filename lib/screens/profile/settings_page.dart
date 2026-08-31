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
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ubah Kata Sandi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oldPasswordController,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Saat Ini',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setModalState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Baru',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setModalState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi Baru',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      const SnackBar(content: Text('Kata sandi baru minimal 6 karakter!')),
                    );
                    return;
                  }
                  if (newPasswordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Konfirmasi kata sandi baru tidak cocok!')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Kata sandi berhasil diperbarui!'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
                child: const Text('SIMPAN KATA SANDI BARU', style: TextStyle(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kebijakan Privasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const SingleChildScrollView(
          child: Text(
            'Aplikasi Retribusi Sampah Kudus menghargai dan melindungi data pribadi Anda.\n\n'
            '1. Penggunaan Data: Data NIK, KTP, dan titik koordinat hanya digunakan untuk validasi objek retribusi resmi Dinas PKPLH Kabupaten Kudus.\n\n'
            '2. Keamanan Transaksi: Riwayat pembayaran dan nominal tercatat secara transparan dan aman pada server Dinas PKPLH Kudus.\n\n'
            '3. Hak Pengguna: Pengguna dapat mengajukan pembaruan data melalui menu Pusat Bantuan atau kantor dinas terkait.',
            style: TextStyle(height: 1.5, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Akun Info Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFECFDF5),
                  child: const Icon(Icons.person, color: Color(0xFF059669), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nama,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Peran: ${_role.toUpperCase()}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Keamanan Akun
          const Text('Keamanan Akun', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFECFDF5),
                child: Icon(Icons.lock_outline, color: Color(0xFF059669), size: 20),
              ),
              title: const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: const Text('Ganti password akun Anda secara berkala', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
              onTap: _showChangePasswordDialog,
            ),
          ),
          const SizedBox(height: 20),

          // Notifikasi
          const Text('Preferensi Notifikasi', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.notifications_active_outlined, color: Color(0xFF2563EB), size: 20),
                  ),
                  title: const Text('Pengingat Tagihan Bulanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Pemberitahuan saat tagihan retribusi baru terbit', style: TextStyle(fontSize: 12)),
                  value: _notifTagihan,
                  activeThumbColor: const Color(0xFF059669),
                  onChanged: (val) {
                    setState(() => _notifTagihan = val);
                    _savePreference('notif_tagihan', val);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  secondary: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(Icons.assignment_turned_in_outlined, color: Color(0xFFD97706), size: 20),
                  ),
                  title: const Text('Pembaruan Status Pengajuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Pemberitahuan ketika status pengajuan berubah', style: TextStyle(fontSize: 12)),
                  value: _notifStatus,
                  activeThumbColor: const Color(0xFF059669),
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
          const Text('Tentang Aplikasi', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E8FF),
                    child: Icon(Icons.privacy_tip_outlined, color: Color(0xFF9333EA), size: 20),
                  ),
                  title: const Text('Kebijakan Privasi & Ketentuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                  onTap: _showPrivacyPolicyDialog,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 20),
                  ),
                  title: Text('Versi Aplikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text('v1.1.0 • Dinas PKPLH Kabupaten Kudus', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

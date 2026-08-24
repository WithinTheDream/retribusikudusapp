import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'retribusi_offline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabel untuk menyimpan data pembayaran yang belum tersinkronisasi
        await db.execute('''
          CREATE TABLE pembayaran_pending (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tagihan_id INTEGER NOT NULL,
            tanggal_bayar TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insertPembayaranPending(int tagihanId, String tanggalBayar) async {
    final db = await database;
    return await db.insert('pembayaran_pending', {
      'tagihan_id': tagihanId,
      'tanggal_bayar': tanggalBayar,
      'is_synced': 0
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPembayaran() async {
    final db = await database;
    return await db.query('pembayaran_pending', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<int> markAsSynced(int id) async {
    final db = await database;
    return await db.update('pembayaran_pending', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

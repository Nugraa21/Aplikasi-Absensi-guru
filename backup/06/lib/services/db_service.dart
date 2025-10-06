import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  // --- Get user by ID ---
  static Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await getDB();
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  static Database? _db;

  static Future<Database> getDB() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'absensi.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          nip TEXT,
          jabatan TEXT,
          kelas TEXT,
          email TEXT UNIQUE,
          password TEXT,
          photo TEXT,
          isAdmin INTEGER DEFAULT 0,
          isApproved INTEGER DEFAULT 0
        )
      ''');
        await db.execute('''
        CREATE TABLE attendance(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          date TEXT,
          time TEXT,
          location TEXT,
          photo TEXT,
          approved INTEGER DEFAULT 0
        )
      ''');
        await db.execute('''
        CREATE TABLE settings(
          id INTEGER PRIMARY KEY,
          keyName TEXT UNIQUE,
          value TEXT
        )
      ''');
        // default radius setting (meters)
        await db.insert('settings', {
          'id': 1,
          'keyName': 'attendance_radius',
          'value': '1000',
        });
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          try {
            await db.execute(
              'ALTER TABLE users ADD COLUMN isApproved INTEGER DEFAULT 0',
            );
          } catch (_) {}
        }
      },
    );
    return _db!;
  }

  // --- Users ---
  static Future<int> registerUser({
    required String name,
    required String nip,
    required String jabatan,
    required String kelas,
    required String email,
    required String password,
    int isAdmin = 0,
    int isApproved = 0,
  }) async {
    final db = await getDB();
    return await db.insert('users', {
      'name': name,
      'nip': nip,
      'jabatan': jabatan,
      'kelas': kelas,
      'email': email,
      'password': password,
      'photo': '',
      'isAdmin': isAdmin,
      'isApproved': isApproved,
    });
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final db = await getDB();
    final res = await db.query(
      'users',
      where: 'email=? AND password=?',
      whereArgs: [email, password],
    );
    return res.isNotEmpty ? res.first : null;
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await getDB();
    return await db.query('users', orderBy: 'isAdmin DESC, name ASC');
  }

  static Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final db = await getDB();
    return await db.query('users', where: 'isApproved=0', orderBy: 'name ASC');
  }

  static Future<int> approveUser(int id) async {
    final db = await getDB();
    return await db.update(
      'users',
      {'isApproved': 1},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<int> denyUser(int id) async {
    final db = await getDB();
    await db.delete('attendance', where: 'userId=?', whereArgs: [id]);
    return await db.delete('users', where: 'id=?', whereArgs: [id]);
  }

  static Future<int> updateProfile(
    int userId,
    String name,
    String nip,
    String jabatan,
    String kelas,
    String photo,
  ) async {
    final db = await getDB();
    return await db.update(
      'users',
      {
        'name': name,
        'nip': nip,
        'jabatan': jabatan,
        'kelas': kelas,
        'photo': photo,
      },
      where: 'id=?',
      whereArgs: [userId],
    );
  }

  // --- Attendance ---
  static Future<int> saveAttendance(
    int userId,
    String date,
    String time,
    String location,
    String photoPath,
  ) async {
    final db = await getDB();
    return await db.insert('attendance', {
      'userId': userId,
      'date': date,
      'time': time,
      'location': location,
      'photo': photoPath,
      'approved': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getAttendance(int userId) async {
    final db = await getDB();
    return await db.query(
      'attendance',
      where: 'userId=?',
      whereArgs: [userId],
      orderBy: 'date DESC, time DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final db = await getDB();
    return await db.query('attendance', orderBy: 'date DESC, time DESC');
  }

  static Future<int> approveAttendance(int id) async {
    final db = await getDB();
    return await db.update(
      'attendance',
      {'approved': 1},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<int> denyAttendance(int id) async {
    final db = await getDB();
    return await db.delete('attendance', where: 'id=?', whereArgs: [id]);
  }

  // --- Settings ---
  static Future<String> getSetting(String key) async {
    final db = await getDB();
    final res = await db.query(
      'settings',
      where: 'keyName=?',
      whereArgs: [key],
    );
    return res.isNotEmpty ? res.first['value'] as String : '';
  }

  static Future<int> setSetting(String key, String value) async {
    final db = await getDB();
    final exists = await db.query(
      'settings',
      where: 'keyName=?',
      whereArgs: [key],
    );
    if (exists.isNotEmpty) {
      return await db.update(
        'settings',
        {'value': value},
        where: 'keyName=?',
        whereArgs: [key],
      );
    } else {
      return await db.insert('settings', {'keyName': key, 'value': value});
    }
  }
}

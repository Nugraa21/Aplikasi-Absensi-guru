// lib/services/db_service.dart
// Database service using SQLite for user management, attendance, settings, and requests. Handles CRUD operations.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DBService {
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
      version: 4,
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
          type TEXT DEFAULT 'masuk',
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
        await db.execute('''
        CREATE TABLE requests(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          date TEXT,
          time TEXT,
          reason TEXT,
          type TEXT,
          approved INTEGER DEFAULT 0
        )
      ''');
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
        if (oldV < 3) {
          try {
            await db.execute(
              "ALTER TABLE attendance ADD COLUMN type TEXT DEFAULT 'masuk'",
            );
          } catch (_) {}
        }
        if (oldV < 4) {
          try {
            await db.execute('''
            CREATE TABLE requests(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              date TEXT,
              time TEXT,
              reason TEXT,
              type TEXT,
              approved INTEGER DEFAULT 0
            )
            ''');
          } catch (_) {}
        }
      },
    );
    return _db!;
  }

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
    await db.delete('requests', where: 'userId=?', whereArgs: [id]);
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

  static Future<int> saveAttendance(
    int userId,
    String date,
    String time,
    String location,
    String photoPath,
    String type,
  ) async {
    final db = await getDB();
    return await db.insert('attendance', {
      'userId': userId,
      'date': date,
      'time': time,
      'location': location,
      'photo': photoPath,
      'type': type,
      'approved': 0,
    });
  }

  static Future<int> updateAttendanceTime(int id, String newTime) async {
    final db = await getDB();
    return await db.update(
      'attendance',
      {'time': newTime},
      where: 'id=?',
      whereArgs: [id],
    );
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

  static Future<int> saveRequest(
    int userId,
    String date,
    String time,
    String reason,
    String type,
  ) async {
    final db = await getDB();
    return await db.insert('requests', {
      'userId': userId,
      'date': date,
      'time': time,
      'reason': reason,
      'type': type,
      'approved': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getRequests({int? userId}) async {
    final db = await getDB();
    if (userId != null) {
      return await db.query(
        'requests',
        where: 'userId=?',
        whereArgs: [userId],
        orderBy: 'date DESC, time DESC',
      );
    } else {
      return await db.query('requests', orderBy: 'date DESC, time DESC');
    }
  }

  static Future<int> approveRequest(int id) async {
    final db = await getDB();
    return await db.update(
      'requests',
      {'approved': 1},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<int> denyRequest(int id) async {
    final db = await getDB();
    return await db.delete('requests', where: 'id=?', whereArgs: [id]);
  }

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

  static Future<bool> hasTodayAttendance(int userId) async {
    final db = await getDB();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await db.query(
      'attendance',
      where: 'userId = ? AND date = ? AND approved = 1',
      whereArgs: [userId, today],
    );
    return res.isNotEmpty;
  }

  static Future<int> getTodayAttendanceCount() async {
    final db = await getDB();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await db.query(
      'attendance',
      where: 'date = ? AND approved = 1',
      whereArgs: [today],
    );
    return res.length;
  }
}

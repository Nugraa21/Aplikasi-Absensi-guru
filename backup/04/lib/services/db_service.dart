import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static Database? _db;

  static Future<Database> getDB() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'absensi.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          nip TEXT,
          email TEXT UNIQUE,
          password TEXT,
          photo TEXT,
          isAdmin INTEGER DEFAULT 0
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
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // ensure attendance has approved column
          try {
            await db.execute(
              'ALTER TABLE attendance ADD COLUMN approved INTEGER DEFAULT 0',
            );
          } catch (_) {}
        }
      },
    );
    return _db!;
  }

  // Users
  static Future<int> registerUser(
    String name,
    String nip,
    String email,
    String password, {
    int isAdmin = 0,
  }) async {
    final db = await getDB();
    return await db.insert('users', {
      'name': name,
      'nip': nip,
      'email': email,
      'password': password,
      'photo': '',
      'isAdmin': isAdmin,
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

  static Future<int> updateProfile(
    int userId,
    String name,
    String nip,
    String photo,
  ) async {
    final db = await getDB();
    return await db.update(
      'users',
      {'name': name, 'nip': nip, 'photo': photo},
      where: 'id=?',
      whereArgs: [userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await getDB();
    return await db.query('users', orderBy: 'isAdmin DESC, name ASC');
  }

  static Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await getDB();
    final res = await db.query('users', where: 'id=?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> deleteUser(int id) async {
    final db = await getDB();
    await db.delete('attendance', where: 'userId=?', whereArgs: [id]);
    return await db.delete('users', where: 'id=?', whereArgs: [id]);
  }

  // Attendance
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

  static Future<int> deleteAttendance(int id) async {
    final db = await getDB();
    return await db.delete('attendance', where: 'id=?', whereArgs: [id]);
  }
}

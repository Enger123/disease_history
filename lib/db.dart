import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'sections.dart';

typedef Rec = Map<String, dynamic>;

class Db {
  static Database? _db;
  static Future<Database> get db async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'med_history.db');
    return openDatabase(path, version: 1, onCreate: (d, _) async {
      await d.execute('CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT, email TEXT UNIQUE, salt TEXT, hash TEXT)');
      for (final s in sections) {
        final cols = s.fields.map((f) => '${f.key} TEXT').join(',');
        await d.execute('CREATE TABLE ${s.table}(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, $cols)');
      }
      await d.execute('CREATE TABLE attachments(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'user_id INTEGER, tbl TEXT, record_id INTEGER, name TEXT, path TEXT)');
    });
  }

  // ---------- users ----------
  static Future<Rec?> userById(int id) async {
    final r = await (await db).query('users', where: 'id=?', whereArgs: [id]);
    return r.isEmpty ? null : r.first;
  }

  static Future<Rec?> userByEmail(String email) async {
    final r = await (await db).query('users', where: 'email=?', whereArgs: [email]);
    return r.isEmpty ? null : r.first;
  }

  static Future<int> addUser(Rec u) async => (await db).insert('users', u);

  // ---------- records ----------
  /// Пошук робимо в Dart, бо SQLite LIKE не ігнорує регістр для кирилиці.
  static Future<List<Rec>> list(Section s, int uid, {String q = ''}) async {
    final all = await (await db).query(s.table, where: 'user_id=?', whereArgs: [uid], orderBy: 'date DESC');
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return all;
    return all.where((r) => s.fields.any((f) => '${r[f.key] ?? ''}'.toLowerCase().contains(t))).toList();
  }

  static Future<int> insert(Section s, int uid, Rec data) async =>
      (await db).insert(s.table, {...data, 'user_id': uid});

  static Future<void> update(Section s, int id, Rec data) async =>
      (await db).update(s.table, data, where: 'id=?', whereArgs: [id]);

  static Future<void> delete(Section s, int id) async {
    for (final a in await attachments(s.table, id)) {
      await deleteAttachment(a['id'] as int);
    }
    await (await db).delete(s.table, where: 'id=?', whereArgs: [id]);
  }

  // ---------- attachments ----------
  static Future<List<Rec>> attachments(String tbl, int recordId) async => (await db)
      .query('attachments', where: 'tbl=? AND record_id=?', whereArgs: [tbl, recordId]);

  /// Копіюємо файл у внутрішню папку застосунку, щоб він не пропав.
  static Future<void> addAttachment(int uid, String tbl, int recordId, String name, String src) async {
    final dir = Directory(join((await getApplicationDocumentsDirectory()).path, 'attachments'));
    await dir.create(recursive: true);
    final dest = join(dir.path, '${DateTime.now().microsecondsSinceEpoch}_$name');
    await File(src).copy(dest);
    await (await db).insert('attachments',
        {'user_id': uid, 'tbl': tbl, 'record_id': recordId, 'name': name, 'path': dest});
  }

  static Future<void> deleteAttachment(int id) async {
    final d = await db;
    final r = await d.query('attachments', where: 'id=?', whereArgs: [id]);
    if (r.isNotEmpty) {
      final f = File(r.first['path'] as String);
      if (await f.exists()) await f.delete();
    }
    await d.delete('attachments', where: 'id=?', whereArgs: [id]);
  }

  // ---------- видалення акаунта ----------
  static Future<void> deleteUser(int uid) async {
    final d = await db;
    for (final a in await d.query('attachments', where: 'user_id=?', whereArgs: [uid])) {
      await deleteAttachment(a['id'] as int);
    }
    for (final s in sections) {
      await d.delete(s.table, where: 'user_id=?', whereArgs: [uid]);
    }
    await d.delete('users', where: 'id=?', whereArgs: [uid]);
  }
}

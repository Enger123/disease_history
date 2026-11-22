import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db.dart';

class Auth {
  static int? userId;
  static String name = '', email = '';

  static String _hash(String pass, String salt) => sha256.convert(utf8.encode('$salt$pass')).toString();

  static Future<void> _start(Rec u) async {
    userId = u['id'] as int;
    name = u['name'] as String;
    email = u['email'] as String;
    (await SharedPreferences.getInstance()).setInt('uid', userId!);
  }

  /// Відновлення сесії після перезапуску.
  static Future<void> restore() async {
    final id = (await SharedPreferences.getInstance()).getInt('uid');
    if (id == null) return;
    final u = await Db.userById(id);
    if (u != null) await _start(u);
  }

  /// Повертає текст помилки або null, якщо успішно.
  static Future<String?> register(String n, String e, String pass) async {
    e = e.trim().toLowerCase();
    if (await Db.userByEmail(e) != null) return 'Користувач з таким email вже існує';
    final salt = base64Url.encode(List.generate(16, (_) => Random.secure().nextInt(256)));
    final id = await Db.addUser({'name': n.trim(), 'email': e, 'salt': salt, 'hash': _hash(pass, salt)});
    await _start((await Db.userById(id))!);
    return null;
  }

  static Future<String?> login(String e, String pass) async {
    final u = await Db.userByEmail(e.trim().toLowerCase());
    if (u == null || u['hash'] != _hash(pass, u['salt'] as String)) return 'Невірний email або пароль';
    await _start(u);
    return null;
  }

  static Future<void> logout() async {
    userId = null;
    (await SharedPreferences.getInstance()).remove('uid');
  }

  static Future<String?> deleteAccount(String pass) async {
    final u = await Db.userById(userId!);
    if (u == null || u['hash'] != _hash(pass, u['salt'] as String)) return 'Невірний пароль';
    await Db.deleteUser(userId!);
    await logout();
    return null;
  }
}

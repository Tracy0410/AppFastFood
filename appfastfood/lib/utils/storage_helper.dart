import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static const String _token = 'token';
  static const String _userid = 'user_id';
  static const String _fullname = 'fullname';
  static const String _avatar = 'Image';
  static const String _role = 'role';


  static Future<void> init() async {
    await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_token, token);
  }

  static Future<void> saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userid, id);
  }

  static Future<void> saveFullname(String fullname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fullname, fullname);
  }

  static Future<void> saveImage(String? image) async {
    final prefs = await SharedPreferences.getInstance();
    if (image != null && image != "null" && image.isNotEmpty) {
      await prefs.setString(_avatar, image);
    } else {
      await prefs.remove(_avatar);
    }
  }
    static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_role, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_role);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_token);
  }

  static Future<String?> getFullname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fullname) ?? "Khách hàng";
  }

  static Future<String?> getAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatar);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userid);
  }

  static Future<void> ClearLoginToLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

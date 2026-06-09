import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use this when running Flutter on Chrome/Windows desktop
  static const String baseUrl = 'http://localhost:8000/api/v1';

  // Use this instead when running on Android emulator
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // ─── Get saved token ──────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // ─── Headers ──────────────────────────────────────────────────
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static const Map<String, String> publicHeaders = {
    'Content-Type': 'application/json',
  };

  // ─── AUTH ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: publicHeaders,
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveTokens(data['access'], data['refresh']);
    }
    return {'status': response.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: publicHeaders,
      body: jsonEncode(userData),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      await saveTokens(data['access'], data['refresh']);
    }
    return {'status': response.statusCode, 'data': data};
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString('refresh_token');
    final headers = await authHeaders();
    await http.post(
      Uri.parse('$baseUrl/auth/logout/'),
      headers: headers,
      body: jsonEncode({'refresh': refresh}),
    );
    await clearTokens();
  }

  static Future<Map<String, dynamic>> getMe() async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me/'),
      headers: headers,
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  // ─── COMPLAINTS ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getComplaints(
      {Map<String, String>? filters}) async {
    final headers = await authHeaders();
    var uri = Uri.parse('$baseUrl/complaints/');
    if (filters != null) {
      uri = uri.replace(queryParameters: filters);
    }
    final response = await http.get(uri, headers: headers);
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> submitComplaint(
      Map<String, dynamic> data) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/complaints/'),
      headers: headers,
      body: jsonEncode(data),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getComplaintDetail(String id) async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/complaints/$id/'),
      headers: headers,
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> trackComplaint(String code) async {
    final response = await http.get(
      Uri.parse('$baseUrl/complaints/track/?code=$code'),
      headers: publicHeaders,
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> upvoteComplaint(String id) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/complaints/$id/upvote/'),
      headers: headers,
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> addComment(
      String id, String content) async {
    final headers = await authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/complaints/$id/comment/'),
      headers: headers,
      body: jsonEncode({'content': content}),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/complaints/stats/'),
      headers: headers,
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getNotifications() async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/'),
      headers: headers,
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    final headers = await authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count/'),
      headers: headers,
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<void> markAllRead() async {
    final headers = await authHeaders();
    await http.post(
      Uri.parse('$baseUrl/notifications/mark-all-read/'),
      headers: headers,
    );
  }
}
// lib/services/community_service.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:optionxi/Main_Pages/Community/dm_community_model.dart';

class CommunityService {
  static String _baseUrl = dotenv.env['COMMUNITY_API_LINK']!; // ← change this

  static String get discourseBaseUrl {
    final url = dotenv.env['DISCOURSE_URL'] ?? '';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // ─── Token helper ───────────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static void _assertOk(http.Response res, String context) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('[$context] HTTP ${res.statusCode}: ${res.body}');
    }
  }

  // ─── Auth sync ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> syncUser() async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/sync'),
      headers: await _headers(),
    );
    _assertOk(res, 'syncUser');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Categories ─────────────────────────────────────────────────────────────
  static Future<List<Category>> getCategories() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/categories'),
      headers: await _headers(),
    );
    _assertOk(res, 'getCategories');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['categories'] as List)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ─── Topics ─────────────────────────────────────────────────────────────────
  static Future<List<Topic>> getTopics({int page = 0, int? categoryId}) async {
    final params = {'page': '$page'};
    if (categoryId != null) params['category_id'] = '$categoryId';
    final uri = Uri.parse('$_baseUrl/topics').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res, 'getTopics');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['topics'] as List)
        .map((t) => Topic.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  static Future<TopicDetail> getTopicDetail(int topicId, {int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/topics/$topicId')
        .replace(queryParameters: {'page': '$page'});
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res, 'getTopicDetail');
    return TopicDetail.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> createTopic({
    required String title,
    required String raw,
    int? categoryId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/topics'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'raw': raw,
        if (categoryId != null) 'category_id': categoryId,
      }),
    );
    _assertOk(res, 'createTopic');
  }

  // ─── Posts ──────────────────────────────────────────────────────────────────
  static Future<void> createPost({
    required int topicId,
    required String raw,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/posts'),
      headers: await _headers(),
      body: jsonEncode({'topic_id': topicId, 'raw': raw}),
    );
    _assertOk(res, 'createPost');
  }

  static Future<void> updatePost({
    required int postId,
    required String raw,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: await _headers(),
      body: jsonEncode({'post_id': postId, 'raw': raw}),
    );
    _assertOk(res, 'updatePost');
  }

  static Future<void> deletePost(int postId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: await _headers(),
    );
    _assertOk(res, 'deletePost');
  }

  // ─── Reactions ──────────────────────────────────────────────────────────────
  static Future<void> likePost(int postId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/like'),
      headers: await _headers(),
    );
    _assertOk(res, 'likePost');
  }

  static Future<void> unlikePost(int postId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/posts/$postId/like'),
      headers: await _headers(),
    );
    _assertOk(res, 'unlikePost');
  }

  // ─── Search ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> search(String query) async {
    final uri =
        Uri.parse('$_baseUrl/search').replace(queryParameters: {'q': query});
    final res = await http.get(uri, headers: await _headers());
    _assertOk(res, 'search');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Profile ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/profile'),
      headers: await _headers(),
    );
    _assertOk(res, 'getProfile');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Notifications ───────────────────────────────────────────────────────────
  static Future<List<dynamic>> getNotifications() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/notifications'),
      headers: await _headers(),
    );
    _assertOk(res, 'getNotifications');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['notifications'] as List? ?? [];
  }
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _productionBaseUrl = 'http://159.75.201.229:3001/api';
  static const String _customBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }

    if (kReleaseMode || kProfileMode) {
      return _productionBaseUrl;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001/api';
    }

    return 'http://localhost:3001/api';
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static String? _token;

  static void setToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  static String? getToken() => _token;

  // ----- Auth -----

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final resp = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return resp.data;
  }

  static Future<Map<String, dynamic>> sendRegisterCode(String email) async {
    final resp = await _dio.post(
      '/auth/register/send-code',
      data: {'email': email},
    );
    return resp.data;
  }

  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String code,
  ) async {
    final resp = await _dio.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'code': code},
    );
    return resp.data;
  }

  static Future<Map<String, dynamic>> sendResetPasswordCode(
    String email,
  ) async {
    final resp = await _dio.post(
      '/auth/reset-password/send-code',
      data: {'email': email},
    );
    return resp.data;
  }

  static Future<Map<String, dynamic>> verifyResetPasswordCode(
    String email,
    String code,
  ) async {
    final resp = await _dio.post(
      '/auth/reset-password/verify-code',
      data: {'email': email, 'code': code},
    );
    return resp.data;
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final resp = await _dio.post(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'new_password': newPassword},
    );
    return resp.data;
  }

  static Future<void> logout() async {
    await _dio.post('/auth/logout');
    setToken(null);
  }

  // ----- User Cities -----

  static Future<List<dynamic>> getCities() async {
    final resp = await _dio.get('/user/cities');
    return resp.data['data'] ?? [];
  }

  static Future<List<dynamic>> addCity(Map<String, String> city) async {
    final resp = await _dio.post('/user/cities', data: city);
    return resp.data['data'] ?? [];
  }

  static Future<List<dynamic>> deleteCity(String id) async {
    final resp = await _dio.delete('/user/cities/$id');
    return resp.data['data'] ?? [];
  }

  // ----- User Settings -----

  static Future<Map<String, dynamic>> getSettings() async {
    final resp = await _dio.get('/user/settings');
    return resp.data['data'] ?? {};
  }

  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _dio.post('/user/settings', data: settings);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final resp = await _dio.get('/user/profile');
    return resp.data['data'] ?? {};
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? userAvatar,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) {
      data['name'] = name;
    }
    if (userAvatar != null) {
      data['user_avatar'] = userAvatar;
    }
    final resp = await _dio.put('/user/profile', data: data);
    return resp.data['data'] ?? {};
  }

  static Future<Map<String, dynamic>> getAvatarUploadCredentials() async {
    final resp = await _dio.get('/user/avatar/sts');
    return resp.data['data'] ?? {};
  }

  // ----- Weather -----

  static Future<Map<String, dynamic>> geoLookup(String location) async {
    final resp = await _dio.get(
      '/weather/geo/lookup',
      queryParameters: {'location': location},
    );
    return resp.data;
  }

  static Future<Map<String, dynamic>> geoTop({
    int number = 20,
    String range = 'cn',
  }) async {
    final resp = await _dio.get(
      '/weather/geo/top',
      queryParameters: {'number': number, 'range': range},
    );
    return resp.data;
  }

  static Future<Map<String, dynamic>> weatherNow(
    String location, {
    String lang = 'en',
  }) async {
    final resp = await _dio.get(
      '/weather/now',
      queryParameters: {'location': location, 'lang': lang},
    );
    return resp.data;
  }

  static Future<Map<String, dynamic>> weather24h(
    String location, {
    String lang = 'en',
  }) async {
    final resp = await _dio.get(
      '/weather/24h',
      queryParameters: {'location': location, 'lang': lang},
    );
    return resp.data;
  }

  static Future<Map<String, dynamic>> weather7d(
    String location, {
    String lang = 'en',
  }) async {
    final resp = await _dio.get(
      '/weather/7d',
      queryParameters: {'location': location, 'lang': lang},
    );
    return resp.data;
  }
}

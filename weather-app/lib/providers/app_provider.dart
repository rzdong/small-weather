import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AppProvider with ChangeNotifier {
  static const Duration _nowCacheTtl = Duration(minutes: 30);
  static const Duration _hourlyCacheTtl = Duration(hours: 1);
  static const Duration _dailyCacheTtl = Duration(hours: 6);
  static const String _weatherCachePrefix = 'weather_cache';

  bool _isDarkMode = false;
  String _language = 'en';
  double _lightAngle = -3 * pi / 4;
  double _shadowIntensity = 1.0;

  // Auth state
  bool _isLoggedIn = false;
  String _userId = '';
  String _userName = '';
  String _userEmail = '';
  String _userAvatar = '';

  // Weather state
  Map<String, dynamic> _currentWeather = {};
  List<dynamic> _hourlyForecast = [];
  List<dynamic> _dailyForecast = [];
  String _dailyForecastCityId = '';
  List<dynamic> _userCities = [];
  List<dynamic> _searchResults = [];
  String _selectedCityId = '';
  String _selectedCityName = '';
  bool _isLoading = false;
  bool _isForecastLoading = false;
  bool _isSearching = false;
  String? _lastSyncTime;
  DateTime? _weatherCachedAt;

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  double get lightAngle => _lightAngle;
  double get shadowIntensity => _shadowIntensity;
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userAvatar => _userAvatar;
  Map<String, dynamic> get currentWeather => _currentWeather;
  List<dynamic> get hourlyForecast => _hourlyForecast;
  List<dynamic> get dailyForecast => _dailyForecast;
  List<dynamic> get userCities => _userCities;
  List<dynamic> get searchResults => _searchResults;
  String get selectedCityId => _selectedCityId;
  String get selectedCityName => _selectedCityName;
  bool get isLoading => _isLoading;
  bool get isForecastLoading => _isForecastLoading;
  bool get isSearching => _isSearching;
  String? get lastSyncTime => _lastSyncTime;

  AppProvider() {
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _language = prefs.getString('language') ?? 'en';
    _lightAngle = prefs.getDouble('lightAngle') ?? (-3 * pi / 4);
    _shadowIntensity = prefs.getDouble('shadowIntensity') ?? 1.0;
    _restoreLocalUserProfile(prefs);
    final hasLocalCityState = _restoreLocalCityState(prefs);

    if (hasLocalCityState) {
      final cacheState = await _loadWeatherFromCache();
      if (cacheState.isStale) {
        fetchWeather(forceRefresh: true);
      }
    }

    final token = prefs.getString('auth_token');
    if (token != null) {
      _isLoggedIn = true;
      final restored = await _restoreAuthenticatedSession(token, prefs);
      if (!restored) {
        await _clearAuthState(prefs);
        if (!hasLocalCityState) {
          await initLocation();
        }
      }
    } else if (!hasLocalCityState) {
      await initLocation();
    }

    notifyListeners();
  }

  void _restoreLocalUserProfile(SharedPreferences prefs) {
    _userId = prefs.getString('user_id') ?? _userId;
    _userName = prefs.getString('user_name') ?? _userName;
    _userEmail = prefs.getString('user_email') ?? _userEmail;
    _userAvatar = prefs.getString('user_avatar') ?? _userAvatar;
  }

  bool _restoreLocalCityState(SharedPreferences prefs) {
    final rawCities = prefs.getString('cached_cities');
    if (rawCities != null && rawCities.isNotEmpty) {
      try {
        final decoded = json.decode(rawCities);
        if (decoded is List) {
          _userCities = decoded
              .whereType<Map>()
              .map(
                (city) => city.map(
                  (key, value) =>
                      MapEntry(key.toString(), value?.toString() ?? ''),
                ),
              )
              .toList();
        }
      } catch (_) {}
    }

    _selectedCityId = prefs.getString('selected_city_id') ?? _selectedCityId;
    _selectedCityName =
        prefs.getString('selected_city_name') ?? _selectedCityName;

    if (_selectedCityId.isNotEmpty && _selectedCityName.isNotEmpty) {
      notifyListeners();
      return true;
    }

    if (_userCities.isNotEmpty) {
      _selectedCityId = _userCities.first['id']?.toString() ?? '';
      _selectedCityName = _userCities.first['name']?.toString() ?? '';
      notifyListeners();
      return _selectedCityId.isNotEmpty;
    }

    return false;
  }

  Future<void> _persistCityState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_cities', json.encode(_userCities));
    await prefs.setString('selected_city_id', _selectedCityId);
    await prefs.setString('selected_city_name', _selectedCityName);
  }

  /// Try to get the user's GPS location and auto-detect city.
  /// If location fails or permissions are denied, default to Chongqing.
  Future<void> initLocation() async {
    Position? position;
    try {
      position = await LocationService.getCurrentPosition();
      debugPrint('initLocation currentPosition: $position');
    } catch (e) {
      debugPrint('getCurrentPosition error: $e');
    }

    if (position != null) {
      try {
        final locStr =
            '${position.longitude.toStringAsFixed(2)},${position.latitude.toStringAsFixed(2)}';
        debugPrint('initLocation query (coords): $locStr');

        final geoData = await ApiService.geoLookup(locStr);
        final locations = geoData['location'] as List<dynamic>?;

        if (locations != null && locations.isNotEmpty) {
          final city = locations[0];
          _selectedCityId = city['id'] ?? '';
          _selectedCityName = city['name'] ?? '';

          _userCities = [
            {
              'id': _selectedCityId,
              'name': _selectedCityName,
              'lat': city['lat'] ?? '',
              'lon': city['lon'] ?? '',
            },
          ];
          notifyListeners();
          final cacheState = await _loadWeatherFromCache();
          if (!cacheState.loaded) {
            await fetchWeather(forceRefresh: true);
          } else if (cacheState.isStale) {
            fetchWeather(forceRefresh: true);
          }
          return;
        }
      } catch (e) {
        debugPrint('geoLookup during initLocation error: $e');
      }
    }

    // Default Fallback: Chongqing
    debugPrint('initLocation: Falling back to Chongqing (Default)');
    _selectedCityId = '101040100'; // Chongqing ID
    _selectedCityName = '重庆';
    _userCities = [
      {
        'id': _selectedCityId,
        'name': _selectedCityName,
        'lat': '29.56',
        'lon': '106.55',
      },
    ];
    notifyListeners();
    final cacheState = await _loadWeatherFromCache();
    if (!cacheState.loaded) {
      await fetchWeather(forceRefresh: true);
    } else if (cacheState.isStale) {
      fetchWeather(forceRefresh: true);
    }
  }

  // ---- Settings ----

  void toggleDarkMode(bool value) async {
    _isDarkMode = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
    _syncSettings();
    notifyListeners();
  }

  void setLanguage(String value) async {
    _language = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('language', value);
    _syncSettings();
    notifyListeners();
  }

  void setLightAngle(double angle) async {
    _lightAngle = angle;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('lightAngle', angle);
    _syncSettings();
    notifyListeners();
  }

  void setShadowIntensity(double val) async {
    _shadowIntensity = val;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('shadowIntensity', val);
    _syncSettings();
    notifyListeners();
  }

  Future<void> _syncSettings() async {
    if (!_isLoggedIn) return;
    try {
      await ApiService.updateSettings({
        'language': _language,
        'is_dark_mode': _isDarkMode,
        'light_angle': _lightAngle,
        'shadow_intensity': _shadowIntensity,
      });
    } catch (e) {
      debugPrint('Sync settings error: $e');
    }
  }

  // ---- Auth ----

  Future<bool> login(String email, String password) async {
    final localCities = _citiesSnapshotForSync();
    try {
      final result = await ApiService.login(email, password);
      if (result['success'] == true) {
        await _applyAuthData(result['data']);
        await _syncSettings();
        await _syncLocalCitiesAfterAuth(localCities);
        await fetchCities();
        await fetchProfile();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  Future<String?> sendRegisterCode(String email) async {
    try {
      final result = await ApiService.sendRegisterCode(email);
      return result['message']?.toString() ?? 'Verification code sent';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          'Failed to send verification code';
    } catch (e) {
      debugPrint('Send register code error: $e');
      return 'Failed to send verification code';
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String code,
  }) async {
    final localCities = _citiesSnapshotForSync();
    try {
      final result = await ApiService.register(email, password, code);
      if (result['success'] == true) {
        await _applyAuthData(result['data']);
        await _syncSettings();
        await _syncLocalCitiesAfterAuth(localCities);
        await fetchCities();
        await fetchProfile();
        notifyListeners();
        return null;
      }
      return result['message']?.toString() ?? 'Registration failed';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? 'Registration failed';
    } catch (e) {
      debugPrint('Register error: $e');
      return 'Registration failed';
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await _clearAuthState(prefs);
    notifyListeners();
  }

  Future<String?> sendResetPasswordCode(String email) async {
    try {
      final result = await ApiService.sendResetPasswordCode(email);
      return result['message']?.toString() ?? 'Verification code sent';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          'Failed to send verification code';
    } catch (e) {
      debugPrint('Send reset password code error: $e');
      return 'Failed to send verification code';
    }
  }

  Future<String?> verifyResetPasswordCode(String email, String code) async {
    try {
      final result = await ApiService.verifyResetPasswordCode(email, code);
      return result['success'] == true
          ? null
          : result['message']?.toString() ?? 'Invalid verification code';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          'Invalid verification code';
    } catch (e) {
      debugPrint('Verify reset password code error: $e');
      return 'Invalid verification code';
    }
  }

  Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final result = await ApiService.resetPassword(email, code, newPassword);
      return result['success'] == true
          ? null
          : result['message']?.toString() ?? 'Failed to reset password';
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          'Failed to reset password';
    } catch (e) {
      debugPrint('Reset password error: $e');
      return 'Failed to reset password';
    }
  }

  Future<void> fetchProfile() async {
    if (!_isLoggedIn) {
      return;
    }
    try {
      final profile = await ApiService.getProfile();
      _userId = profile['id']?.toString() ?? _userId;
      _userName = profile['name']?.toString() ?? _userName;
      _userEmail = profile['email']?.toString() ?? _userEmail;
      _userAvatar = profile['user_avatar']?.toString() ?? _userAvatar;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _userId);
      await prefs.setString('user_name', _userName);
      await prefs.setString('user_email', _userEmail);
      await prefs.setString('user_avatar', _userAvatar);
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
  }

  Future<String?> updateProfileName(String name) async {
    try {
      final profile = await ApiService.updateProfile(name: name);
      _userId = profile['id']?.toString() ?? _userId;
      _userName = profile['name']?.toString() ?? name;
      _userEmail = profile['email']?.toString() ?? _userEmail;
      _userAvatar = profile['user_avatar']?.toString() ?? _userAvatar;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _userId);
      await prefs.setString('user_name', _userName);
      await prefs.setString('user_email', _userEmail);
      await prefs.setString('user_avatar', _userAvatar);
      notifyListeners();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          'Failed to save profile';
    } catch (e) {
      debugPrint('Update profile error: $e');
      return 'Failed to save profile';
    }
  }

  Future<String?> updateProfileAvatar(String avatarUrl) async {
    try {
      final profile = await ApiService.updateProfile(userAvatar: avatarUrl);
      _userId = profile['id']?.toString() ?? _userId;
      _userName = profile['name']?.toString() ?? _userName;
      _userEmail = profile['email']?.toString() ?? _userEmail;
      _userAvatar = profile['user_avatar']?.toString() ?? avatarUrl;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _userId);
      await prefs.setString('user_name', _userName);
      await prefs.setString('user_email', _userEmail);
      await prefs.setString('user_avatar', _userAvatar);
      notifyListeners();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ??
          'Failed to update avatar';
    } catch (e) {
      debugPrint('Update avatar error: $e');
      return 'Failed to update avatar';
    }
  }

  // ---- Cities ----

  Future<void> fetchCities() async {
    try {
      _userCities = await ApiService.getCities();
      if (_userCities.isNotEmpty && _selectedCityId.isEmpty) {
        _selectedCityId = _userCities[0]['id'] ?? '';
        _selectedCityName = _userCities[0]['name'] ?? '';
        fetchWeather();
      }
      await _persistCityState();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch cities error: $e');
    }
  }

  Future<void> addCity(Map<String, String> city) async {
    try {
      _userCities = await ApiService.addCity(city);
      await _persistCityState();
      notifyListeners();
    } catch (e) {
      debugPrint('Add city error: $e');
    }
  }

  Future<void> deleteCity(String id) async {
    try {
      if (_isLoggedIn) {
        _userCities = await ApiService.deleteCity(id);
      } else {
        _userCities.removeWhere((c) => c['id'].toString() == id);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('local_cities', json.encode(_userCities));
      }

      if (_selectedCityId == id) {
        if (_userCities.isNotEmpty) {
          _selectedCityId = _userCities[0]['id'].toString();
          _selectedCityName = _userCities[0]['name'].toString();
          fetchWeather();
        } else {
          _selectedCityId = '';
          _selectedCityName = '';
        }
      }
      await _persistCityState();
      notifyListeners();
    } catch (e) {
      debugPrint('Delete city error: $e');
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  void selectCity(String id, String name) async {
    _selectedCityId = id;
    _selectedCityName = name;
    _currentWeather = {};
    _hourlyForecast = [];
    _dailyForecast = [];
    _dailyForecastCityId = '';
    _lastSyncTime = null;
    await _persistCityState();
    notifyListeners();
    _loadCityWeather();
  }

  Future<void> _loadCityWeather() async {
    final cacheState = await _loadWeatherFromCache();
    if (!cacheState.loaded) {
      await fetchWeather(forceRefresh: true);
      return;
    }

    if (cacheState.isStale) {
      fetchWeather(forceRefresh: true);
    }
  }

  // City Search
  Future<void> searchCity(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final data = await ApiService.geoLookup(query);
      _searchResults = data['location'] ?? [];
    } catch (e) {
      debugPrint('Search city error: $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  Future<void> addAndSelectCity(Map<String, dynamic> city) async {
    final cityId = city['id']?.toString() ?? '';
    final cityName = city['name'] ?? '';

    // Check if already in the list
    bool exists = _userCities.any((c) => c['id'].toString() == cityId);
    if (!exists) {
      if (!_isLoggedIn) {
        _userCities.add(city);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('local_cities', json.encode(_userCities));
        await _persistCityState();
      } else {
        _userCities = await ApiService.addCity({
          'id': cityId,
          'name': cityName,
          'lat': city['lat']?.toString() ?? '',
          'lon': city['lon']?.toString() ?? '',
        });
        await _persistCityState();
      }
    }

    selectCity(cityId, cityName);
  }

  // ---- Weather ----

  Future<_WeatherLoadState> _loadWeatherFromCache() async {
    if (_selectedCityId.isEmpty) {
      return const _WeatherLoadState(loaded: false, isStale: false);
    }

    final prefs = await SharedPreferences.getInstance();
    final nowEntry = _readCacheEntry(
      prefs,
      cityId: _selectedCityId,
      type: 'now',
      ttl: _nowCacheTtl,
    );
    final hourlyEntry = _readCacheEntry(
      prefs,
      cityId: _selectedCityId,
      type: 'hourly',
      ttl: _hourlyCacheTtl,
    );

    final nowData = nowEntry?.data;
    final hourlyData = hourlyEntry?.data;
    if (nowData == null && hourlyData == null) {
      return const _WeatherLoadState(loaded: false, isStale: false);
    }

    _currentWeather = nowData ?? {};
    _hourlyForecast = (hourlyData?['hourly'] as List?)?.toList() ?? [];
    _weatherCachedAt = _latestOf(nowEntry?.cachedAt, hourlyEntry?.cachedAt);
    _lastSyncTime = _formatSyncTime(_weatherCachedAt);
    notifyListeners();
    return _WeatherLoadState(
      loaded: true,
      isStale:
          !(nowEntry?.isFresh ?? false) || !(hourlyEntry?.isFresh ?? false),
    );
  }

  Future<_WeatherLoadState> _loadDailyForecastFromCache() async {
    if (_selectedCityId.isEmpty) {
      return const _WeatherLoadState(loaded: false, isStale: false);
    }

    final prefs = await SharedPreferences.getInstance();
    final dailyEntry = _readCacheEntry(
      prefs,
      cityId: _selectedCityId,
      type: 'daily',
      ttl: _dailyCacheTtl,
    );
    if (dailyEntry?.data == null) {
      return const _WeatherLoadState(loaded: false, isStale: false);
    }

    _dailyForecast = (dailyEntry!.data['daily'] as List?)?.toList() ?? [];
    _dailyForecastCityId = _selectedCityId;
    notifyListeners();
    return _WeatherLoadState(loaded: true, isStale: !dailyEntry.isFresh);
  }

  Future<void> fetchWeather({bool forceRefresh = false}) async {
    if (_selectedCityId.isEmpty) return;
    final targetCityId = _selectedCityId;
    if (!forceRefresh) {
      final cacheState = await _loadWeatherFromCache();
      if (cacheState.loaded && !cacheState.isStale) {
        return;
      }
    }
    _isLoading = true;
    notifyListeners();

    final lang = _language == 'zh' ? 'zh' : 'en';

    try {
      final results = await Future.wait([
        ApiService.weatherNow(targetCityId, lang: lang),
        ApiService.weather24h(targetCityId, lang: lang),
      ]);

      final fetchedNow = Map<String, dynamic>.from(results[0]);
      final fetchedHourly = (results[1]['hourly'] as List?)?.toList() ?? [];
      final cachedAt = DateTime.now();
      await _writeCacheEntry(
        cityId: targetCityId,
        type: 'now',
        data: fetchedNow,
      );
      await _writeCacheEntry(
        cityId: targetCityId,
        type: 'hourly',
        data: {'hourly': fetchedHourly},
      );

      if (_selectedCityId == targetCityId) {
        _currentWeather = fetchedNow;
        _hourlyForecast = fetchedHourly;
        _weatherCachedAt = cachedAt;
        _lastSyncTime = _formatSyncTime(_weatherCachedAt);
      }

      if (_dailyForecastCityId != targetCityId) {
        _dailyForecast = [];
        _dailyForecastCityId = '';
      }
    } catch (e) {
      debugPrint('Fetch weather error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDailyForecast({bool force = false}) async {
    if (_selectedCityId.isEmpty) return;
    final targetCityId = _selectedCityId;
    if (!force) {
      final cacheState = await _loadDailyForecastFromCache();
      if (cacheState.loaded && !cacheState.isStale) {
        return;
      }
    }

    _isForecastLoading = true;
    notifyListeners();

    final lang = _language == 'zh' ? 'zh' : 'en';

    try {
      final result = await ApiService.weather7d(targetCityId, lang: lang);
      final fetchedDaily = (result['daily'] as List?)?.toList() ?? [];
      await _writeCacheEntry(
        cityId: targetCityId,
        type: 'daily',
        data: {'daily': fetchedDaily},
      );

      if (_selectedCityId == targetCityId) {
        _dailyForecast = fetchedDaily;
        _dailyForecastCityId = targetCityId;
      }
    } catch (e) {
      debugPrint('Fetch 7d weather error: $e');
    }

    _isForecastLoading = false;
    notifyListeners();
  }

  Future<void> _applyAuthData(Map<String, dynamic> data) async {
    final token = data['token']?.toString();
    _isLoggedIn = true;
    _userId = data['user_id']?.toString() ?? _userId;
    _userName = data['name']?.toString() ?? '';
    _userEmail = data['email']?.toString() ?? '';
    _userAvatar = data['user_avatar']?.toString() ?? _userAvatar;
    ApiService.setToken(token);

    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    }
    await prefs.setString('user_id', _userId);
    await prefs.setString('user_name', _userName);
    await prefs.setString('user_email', _userEmail);
    await prefs.setString('user_avatar', _userAvatar);
  }

  List<Map<String, String>> _citiesSnapshotForSync() {
    final snapshot = <Map<String, String>>[];
    for (final rawCity in _userCities) {
      if (rawCity is! Map) {
        continue;
      }

      final cityId = rawCity['id']?.toString() ?? '';
      final cityName = rawCity['name']?.toString() ?? '';
      if (cityId.isEmpty || cityName.isEmpty) {
        continue;
      }

      snapshot.add({
        'id': cityId,
        'name': cityName,
        'lat': rawCity['lat']?.toString() ?? '',
        'lon': rawCity['lon']?.toString() ?? '',
      });
    }
    return snapshot;
  }

  Future<void> _syncLocalCitiesAfterAuth(
    List<Map<String, String>> localCities,
  ) async {
    if (!_isLoggedIn || localCities.isEmpty) {
      return;
    }

    for (final city in localCities) {
      try {
        await ApiService.addCity(city);
      } catch (e) {
        debugPrint('Sync city after auth error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_cities');
  }

  Future<bool> _restoreAuthenticatedSession(
    String token,
    SharedPreferences prefs,
  ) async {
    try {
      ApiService.setToken(token);
      final profile = await ApiService.getProfile();
      final settings = await ApiService.getSettings();
      final cities = await ApiService.getCities();

      _isLoggedIn = true;
      _userId = profile['id']?.toString() ?? prefs.getString('user_id') ?? '';
      _userName =
          profile['name']?.toString() ?? prefs.getString('user_name') ?? '';
      _userEmail =
          profile['email']?.toString() ?? prefs.getString('user_email') ?? '';
      _userAvatar =
          profile['user_avatar']?.toString() ??
          prefs.getString('user_avatar') ??
          '';
      _userCities = cities;

      if (settings.isNotEmpty) {
        _language = settings['language'] ?? _language;
        _isDarkMode = settings['is_dark_mode'] ?? _isDarkMode;
        _lightAngle = settings['light_angle']?.toDouble() ?? _lightAngle;
        _shadowIntensity =
            settings['shadow_intensity']?.toDouble() ?? _shadowIntensity;
      }

      await prefs.setString('user_id', _userId);
      await prefs.setString('user_name', _userName);
      await prefs.setString('user_email', _userEmail);
      await prefs.setString('user_avatar', _userAvatar);
      await prefs.setString('language', _language);
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setDouble('lightAngle', _lightAngle);
      await prefs.setDouble('shadowIntensity', _shadowIntensity);

      if (_userCities.isNotEmpty) {
        final hasSelectedCity = _userCities.any(
          (city) => city['id']?.toString() == _selectedCityId,
        );
        if (!hasSelectedCity) {
          _selectedCityId = _userCities[0]['id']?.toString() ?? '';
          _selectedCityName = _userCities[0]['name']?.toString() ?? '';
        } else {
          _selectedCityName =
              _userCities
                  .firstWhere(
                    (city) => city['id']?.toString() == _selectedCityId,
                    orElse: () => _userCities[0],
                  )['name']
                  ?.toString() ??
              _selectedCityName;
        }
        await _persistCityState();
        final cacheState = await _loadWeatherFromCache();
        if (!cacheState.loaded) {
          await fetchWeather(forceRefresh: true);
        } else if (cacheState.isStale) {
          fetchWeather(forceRefresh: true);
        }
      } else {
        _selectedCityId = '';
        _selectedCityName = '';
      }

      return true;
    } on DioException catch (e) {
      debugPrint('Restore authenticated session error: $e');
      return false;
    } catch (e) {
      debugPrint('Restore authenticated session error: $e');
      return false;
    }
  }

  Future<void> _clearAuthState(SharedPreferences prefs) async {
    _isLoggedIn = false;
    _userId = '';
    _userName = '';
    _userEmail = '';
    _userAvatar = '';
    _userCities = [];
    _selectedCityId = '';
    _selectedCityName = '';
    _weatherCachedAt = null;
    ApiService.setToken(null);
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_avatar');
  }

  _WeatherCacheEntry? _readCacheEntry(
    SharedPreferences prefs, {
    required String cityId,
    required String type,
    required Duration ttl,
  }) {
    final raw = prefs.getString(_weatherCacheKey(cityId, type));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(
        decoded['cached_at']?.toString() ?? '',
      );
      final data = decoded['data'];
      if (cachedAt == null || data is! Map<String, dynamic>) {
        return null;
      }

      return _WeatherCacheEntry(
        data: data,
        cachedAt: cachedAt,
        isFresh: DateTime.now().difference(cachedAt) <= ttl,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCacheEntry({
    required String cityId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _weatherCacheKey(cityId, type),
      json.encode({
        'cached_at': DateTime.now().toIso8601String(),
        'data': data,
      }),
    );
  }

  String _weatherCacheKey(String cityId, String type) {
    return '${_weatherCachePrefix}_${cityId}_$type';
  }

  DateTime? _latestOf(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  String? _formatSyncTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}

class _WeatherCacheEntry {
  const _WeatherCacheEntry({
    required this.data,
    required this.cachedAt,
    required this.isFresh,
  });

  final Map<String, dynamic> data;
  final DateTime cachedAt;
  final bool isFresh;
}

class _WeatherLoadState {
  const _WeatherLoadState({required this.loaded, required this.isStale});

  final bool loaded;
  final bool isStale;
}

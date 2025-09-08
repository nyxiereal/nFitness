import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EfitnessService {
  static const _baseUrl = 'https://api-frontend2.efitness.com.pl/api';
<<<<<<< HEAD
  static const _appInfoUrl =
      'https://raw.githubusercontent.com/nyxiereal/nFitness/master/appinfo.json';

  static Map<String, dynamic>? _cachedAppInfo;
  static bool _isFetchingAppInfo = false;
=======
  static const _appInfoUrl = 'https://raw.githubusercontent.com/nyxiereal/nFitness/main/appinfo.json';
  
  static Map<String, dynamic>? _cachedAppInfo;
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80

  Future<Map<String, dynamic>> _getAppInfo() async {
    if (_cachedAppInfo != null) {
      return _cachedAppInfo!;
    }

<<<<<<< HEAD
    // Prevent multiple simultaneous requests
    if (_isFetchingAppInfo) {
      // Wait for the ongoing request to complete
      while (_isFetchingAppInfo) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      if (_cachedAppInfo != null) {
        return _cachedAppInfo!;
      }
    }

=======
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('cached_appinfo');
    final cacheTime = prefs.getInt('appinfo_cache_time');
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Check if cache is valid (less than 24 hours old)
    if (cachedJson != null && cacheTime != null) {
      final ageInHours = (currentTime - cacheTime) / (1000 * 60 * 60);
      if (ageInHours < 24) {
        _cachedAppInfo = jsonDecode(cachedJson);
        if (kDebugMode) {
<<<<<<< HEAD
          print(
            '📱 Using cached app info (age: ${ageInHours.toStringAsFixed(1)}h)',
          );
=======
          print('📱 Using cached app info (age: ${ageInHours.toStringAsFixed(1)}h)');
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
        }
        return _cachedAppInfo!;
      }
    }

<<<<<<< HEAD
    _isFetchingAppInfo = true;

    // Fetch new app info
    try {
      if (kDebugMode) {
        print('📱 Fetching app info from Codeberg...');
      }
      final response = await http.get(Uri.parse(_appInfoUrl));

      if (response.statusCode == 200) {
        final appInfo = jsonDecode(response.body);

        // Save new data to cache
        await prefs.setString('cached_appinfo', response.body);
        await prefs.setInt('appinfo_cache_time', currentTime);

=======
    // Fetch new app info
    try {
      if (kDebugMode) {
        print('📱 Fetching app info from GitHub...');
      }
      final response = await http.get(Uri.parse(_appInfoUrl));
      
      if (response.statusCode == 200) {
        final appInfo = jsonDecode(response.body);
        
        // Save new data to cache
        await prefs.setString('cached_appinfo', response.body);
        await prefs.setInt('appinfo_cache_time', currentTime);
        
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
        _cachedAppInfo = appInfo;
        if (kDebugMode) {
          print('✅ App info fetched and cached successfully');
        }
        return appInfo;
      } else {
        throw Exception('Failed to fetch app info: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch app info: $e');
      }
<<<<<<< HEAD

=======
      
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
      // If GitHub is down, but cached data is available, use it
      if (cachedJson != null) {
        _cachedAppInfo = jsonDecode(cachedJson);
        if (kDebugMode) {
          print('⚠️ Using expired cached app info as fallback');
        }
        return _cachedAppInfo!;
      }
<<<<<<< HEAD

=======
      
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
      // In case github is not reachable or no cache is available, return hardcoded values that work on 8/08/2025
      // This should not happen, but better be safe than sorry
      return {
        'okhttp-version': '4.9.2',
        'efitness-version': '3.3.18',
        'superadmin-username': 'superAdmin',
<<<<<<< HEAD
        'superadmin-password': 'Da8nLy?Db>k>AQ*D',
      };
    } finally {
      _isFetchingAppInfo = false;
=======
        'superadmin-password': 'Da8nLy?Db>k>AQ*D'
      };
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
    }
  }

  void _logRequest(
    String method,
    String url,
    Map<String, String> headers, [
    String? body,
  ]) {
    if (kDebugMode) {
      print('🌐 [$method] $url');
      print('📋 Headers: $headers');
      if (body != null) {
        print('📦 Body: $body');
      }
    }
  }

  void _logResponse(String method, String url, int statusCode, String body) {
    if (kDebugMode) {
      print('✅ [$method] $url - Status: $statusCode');
      if (statusCode >= 200 && statusCode < 300) {
        print(
          '📄 Response: ${body.length > 500 ? '${body.substring(0, 500)}...' : body}',
        );
      } else {
        print('❌ Error Response: $body');
      }
    }
  }

  void _logError(String method, String url, dynamic error) {
    if (kDebugMode) {
      print('💥 [$method] $url - Error: $error');
    }
  }

  Future<Map<String, String>> _buildHeaders({
    bool requiresApiToken = true,
    bool requiresMemberToken = false,
    String? customClientRequestId,
    bool includeContentType = false,
  }) async {
    final appInfo = await _getAppInfo();
    final okhttpVersion = appInfo['okhttp-version'] ?? '4.9.2';
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';
<<<<<<< HEAD

=======
    
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
    final headers = <String, String>{
      'Accept': 'application/json',
      'login-source': '2',
      'Accept-Language': 'en-GB',
      'Request-Starttime': DateTime.now().millisecondsSinceEpoch.toString(),
      'Accept-Encoding': 'gzip',
      'User-Agent': 'okhttp/$okhttpVersion',
    };

    if (customClientRequestId != null) {
      headers['Client-Request-Id'] = customClientRequestId;
    } else {
      headers['Client-Request-Id'] = 'eFitness/$eFitnessVersion';
    }

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (requiresApiToken) {
      final apiToken = await getApiAccessToken();
      if (apiToken != null) {
        headers['api-access-token'] = apiToken;
      }
    }

    if (requiresMemberToken) {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken != null) {
        headers['member-token'] = 'Bearer $accessToken';
      }
    }

    return headers;
  }

  Future<T?> _makeRequest<T>({
    required String method,
    required String url,
    bool requiresApiToken = true,
    bool requiresMemberToken = false,
    bool refreshTokenIfNeeded = false,
    String? customClientRequestId,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? parser,
    T Function(List<dynamic>)? listParser,
    bool returnBool = false,
  }) async {
    if (refreshTokenIfNeeded && !await this.refreshTokenIfNeeded()) {
<<<<<<< HEAD
      // Try automatic re-login if token refresh fails
      if (!await attemptAutoRelogin()) {
        if (kDebugMode) {
          print('❌ Token refresh and auto re-login failed');
        }
        return returnBool ? false as T : null;
      }
=======
      if (kDebugMode) {
        print('❌ Token refresh failed for request');
      }
      return returnBool ? false as T : null;
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
    }

    final headers = await _buildHeaders(
      requiresApiToken: requiresApiToken,
      requiresMemberToken: requiresMemberToken,
      customClientRequestId: customClientRequestId,
      includeContentType: body != null,
    );

    final requestBody = body != null ? jsonEncode(body) : null;
    _logRequest(method, url, headers, requestBody);

    try {
      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: requestBody,
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      _logResponse(method, url, response.statusCode, response.body);

      if (response.statusCode == 200) {
        if (returnBool) {
          return true as T;
        }

        final data = jsonDecode(response.body);

        if (parser != null) {
          return parser(data);
        } else if (listParser != null) {
          final results = data['results'] as List<dynamic>? ?? [];
          return listParser(results);
        } else {
          return data as T;
        }
      } else if (response.statusCode == 400 && method == 'POST') {
        return jsonDecode(response.body) as T;
      } else if (response.statusCode == 404) {
        return null;
      }
    } catch (e) {
      _logError(method, url, e);
    }

    return returnBool ? false as T : null;
  }

<<<<<<< HEAD
  Future<bool> attemptAutoRelogin() async {
    if (kDebugMode) {
      print('🔄 Attempting automatic re-login...');
    }
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('savedEmail');
    final password = prefs.getString('savedPassword');
    final clubJson = prefs.getString('selectedClub');

    if (email == null || password == null || clubJson == null) {
      if (kDebugMode) {
        print('❌ Missing saved credentials for auto re-login');
      }
      return false;
    }

    final club = Map<String, dynamic>.from(jsonDecode(clubJson));
    final clubId = club['clubId'] as int;

    final loginData = await loginMember(
      clubId: clubId,
      email: email,
      password: password,
    );

    if (loginData == null) {
      if (kDebugMode) {
        print('❌ Auto re-login failed');
      }
      return false;
    }

    await prefs.setString('accessToken', loginData['accessToken']);
    await prefs.setString('refreshToken', loginData['refreshToken']);
    await prefs.setInt('expiresIn', loginData['expiresIn']);
    await prefs.setString('user_id', loginData['user_id'].toString());
    await prefs.setInt(
      'loginTime',
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    if (kDebugMode) {
      print('✅ Auto re-login successful');
    }
    return true;
  }

=======
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
  Future<bool> refreshTokenIfNeeded() async {
    if (kDebugMode) {
      print('🔄 Checking if token refresh is needed...');
    }
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt('loginTime');
    final expiresIn = prefs.getInt('expiresIn');
    final refreshToken = prefs.getString('refreshToken');
    final clubJson = prefs.getString('selectedClub');

    if (kDebugMode) {
      print('⏰ Login time: $loginTime, Expires in: $expiresIn');
    }

    if (loginTime == null ||
        expiresIn == null ||
        refreshToken == null ||
        clubJson == null) {
      if (kDebugMode) {
        print('❌ Missing token data - refresh not possible');
      }
      return false;
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tokenExpireTime = loginTime + expiresIn;

    if (kDebugMode) {
      print('⏰ Current time: $currentTime, Token expires: $tokenExpireTime');
    }

    if (currentTime + 300 >= tokenExpireTime) {
      if (kDebugMode) {
        print('🔄 Token expires soon - refreshing...');
      }
      final club = Map<String, dynamic>.from(jsonDecode(clubJson));
      final clubId = club['clubId'] as int;

      return await _refreshMemberToken(clubId, refreshToken);
    }

    if (kDebugMode) {
      print('✅ Token is still valid');
    }
    return true;
  }

  Future<bool> _refreshMemberToken(int clubId, String refreshToken) async {
    if (kDebugMode) {
      print('🔄 Refreshing member token for club $clubId...');
    }
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    if (userId == null) {
      if (kDebugMode) {
        print('❌ Missing user ID for token refresh');
      }
      return false;
    }

    final result = await _makeRequest<Map<String, dynamic>>(
      method: 'POST',
      url: '$_baseUrl/clubs/$clubId/token/member/refresh',
      requiresMemberToken: true,
      customClientRequestId: 'eFitness/$eFitnessVersion/$userId',
      body: {'refreshToken': refreshToken},
    );

    if (result != null) {
      await prefs.setString('accessToken', result['accessToken']);
      await prefs.setString('refreshToken', result['refreshToken']);
      await prefs.setInt('expiresIn', result['expiresIn']);
      await prefs.setInt(
        'loginTime',
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      if (kDebugMode) {
        print('✅ Token refreshed successfully');
      }
      return true;
    }

    if (kDebugMode) {
      print('❌ Token refresh failed');
    }
    return false;
  }

  Future<String?> getApiAccessToken() async {
    if (kDebugMode) {
      print('🔑 Getting API access token...');
    }
    final prefs = await SharedPreferences.getInstance();
    final cachedToken = prefs.getString('apiAccessToken');
    if (cachedToken != null) {
      if (kDebugMode) {
        print('✅ Using cached API token');
      }
      return cachedToken;
    }

    if (kDebugMode) {
      print('🔑 Requesting new API access token...');
    }

    final appInfo = await _getAppInfo();
    final superAdminLogin = appInfo['superadmin-username'] ?? 'superAdmin';
<<<<<<< HEAD
    final superAdminPassword =
        appInfo['superadmin-password'] ?? 'Da8nLy?Db>k>AQ*D';
=======
    final superAdminPassword = appInfo['superadmin-password'] ?? 'Da8nLy?Db>k>AQ*D';
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80

    final result = await _makeRequest<Map<String, dynamic>>(
      method: 'POST',
      url: '$_baseUrl/token/api-access',
      requiresApiToken: false,
      body: {'login': superAdminLogin, 'password': superAdminPassword},
    );

    if (result != null) {
      final token = result['apiAccessToken'];
      if (token != null) {
        await prefs.setString('apiAccessToken', token);
        if (kDebugMode) {
          print('✅ API access token obtained and cached');
        }
        return token;
      }
    }

    if (kDebugMode) {
      print('❌ Failed to get API access token');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getClubs() async {
    if (kDebugMode) {
      print('🏢 Fetching clubs list...');
    }

    return await _makeRequest<List<Map<String, dynamic>>>(
          method: 'GET',
          url: '$_baseUrl/clubs?MobileClubNameOrCity=',
          listParser: (results) {
            if (kDebugMode) {
              print('✅ Fetched ${results.length} clubs');
            }
            return results.map((e) => Map<String, dynamic>.from(e)).toList();
          },
        ) ??
        [];
  }

  Future<Map<String, dynamic>?> loginMember({
    required int clubId,
    required String email,
    required String password,
  }) async {
    if (kDebugMode) {
      print('🔐 Logging in member for club $clubId...');
    }

    return await _makeRequest<Map<String, dynamic>>(
      method: 'POST',
      url: '$_baseUrl/clubs/$clubId/token/member',
      body: {'login': email, 'password': password, 'loginSource': 2},
      parser: (data) {
        if (kDebugMode) {
          print('✅ Member login successful');
        }
        return {
          'accessToken': data['accessToken'],
          'refreshToken': data['refreshToken'],
          'user_id': data['id'],
          'expiresIn': data['expiresIn'],
        };
      },
    );
  }

  Future<Map<String, dynamic>?> getClubMembers(int clubId) async {
    if (kDebugMode) {
      print('👥 Fetching club members for club $clubId...');
    }

    return await _makeRequest<Map<String, dynamic>>(
      method: 'GET',
      url: '$_baseUrl/clubs/$clubId/inside-members/summary',
      requiresMemberToken: true,
      refreshTokenIfNeeded: true,
      parser: (data) {
        if (kDebugMode) {
          print('✅ Club members data fetched successfully');
        }
        return data;
      },
    );
  }

  Future<List<Map<String, dynamic>>> getInstructors(int clubId) async {
    if (kDebugMode) {
      print('👨‍🏫 Fetching instructors for club $clubId...');
    }

    return await _makeRequest<List<Map<String, dynamic>>>(
          method: 'GET',
          url: '$_baseUrl/clubs/$clubId/schedules/instructors',
          listParser: (results) {
            if (kDebugMode) {
              print('✅ Fetched ${results.length} instructors');
            }
            return results.map((e) => Map<String, dynamic>.from(e)).toList();
          },
        ) ??
        [];
  }

  Future<Map<String, dynamic>?> getMembershipInfo(int clubId) async {
    if (kDebugMode) {
      print('🎫 Fetching membership info for club $clubId...');
    }

    return await _makeRequest<Map<String, dynamic>>(
      method: 'GET',
      url: '$_baseUrl/clubs/$clubId/members/memberships',
      requiresMemberToken: true,
      refreshTokenIfNeeded: true,
      parser: (data) {
        final results = data['results'] as List<dynamic>? ?? [];
        if (kDebugMode) {
          print('✅ Membership info fetched successfully');
        }
        return results.isNotEmpty
            ? Map<String, dynamic>.from(results.first)
            : <String, dynamic>{};
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory({
    required int clubId,
    required String dateFrom,
    required String dateTo,
    int limit = 1000,
  }) async {
    if (kDebugMode) {
      print('📅 Fetching attendance history for club $clubId...');
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<List<Map<String, dynamic>>>(
          method: 'GET',
          url:
              '$_baseUrl/clubs/$clubId/members/class-reservations?dateFrom=$dateFrom&dateTo=$dateTo&limit=$limit',
          requiresMemberToken: true,
          refreshTokenIfNeeded: true,
          customClientRequestId: userId != null
              ? 'eFitness/$eFitnessVersion/$userId'
              : null,
          listParser: (results) {
            if (kDebugMode) {
              print('✅ Fetched ${results.length} attendance records');
            }
            return results.map((e) => Map<String, dynamic>.from(e)).toList();
          },
        ) ??
        [];
  }

  Future<Map<String, dynamic>?> generateQrCode(int clubId) async {
    if (kDebugMode) {
      print('🔲 Generating QR code for club $clubId...');
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<Map<String, dynamic>>(
      method: 'POST',
      url: '$_baseUrl/clubs/$clubId/qr-codes/generate',
      requiresMemberToken: true,
      refreshTokenIfNeeded: true,
      customClientRequestId: userId != null
          ? 'eFitness/$eFitnessVersion/$userId'
          : null,
      parser: (data) {
        if (kDebugMode) {
          print('✅ QR code generated');
        }
        return data;
      },
    );
  }

  Future<List<Map<String, dynamic>>> getClasses({
    required int clubId,
    required String dateFrom,
    required String dateTo,
  }) async {
    if (kDebugMode) {
      print(
        '📅 Fetching classes for club $clubId from $dateFrom to $dateTo...',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<List<Map<String, dynamic>>>(
          method: 'GET',
          url:
              '$_baseUrl/clubs/$clubId/schedules/classes?dateFrom=$dateFrom&dateTo=$dateTo',
          requiresMemberToken: true,
          refreshTokenIfNeeded: true,
          customClientRequestId: userId != null
              ? 'eFitness/$eFitnessVersion/$userId'
              : null,
          listParser: (results) {
            if (kDebugMode) {
              print('✅ Fetched ${results.length} classes');
            }
            return results.map((e) => Map<String, dynamic>.from(e)).toList();
          },
        ) ??
        [];
  }

  Future<Map<String, dynamic>?> reserveClass({
    required int clubId,
    required int classId,
  }) async {
    if (kDebugMode) {
      print('📝 Reserving class $classId for club $clubId...');
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<Map<String, dynamic>>(
      method: 'POST',
      url: '$_baseUrl/clubs/$clubId/members/class-reservations',
      requiresMemberToken: true,
      refreshTokenIfNeeded: true,
      customClientRequestId: userId != null
          ? 'eFitness/$eFitnessVersion/$userId'
          : null,
      body: {'classId': classId},
      parser: (data) {
        if (kDebugMode) {
          print('✅ Class reservation successful');
        }
        return data;
      },
    );
  }

  Future<List<Map<String, dynamic>>?> getClassReservations({
    required int clubId,
    required int classId,
  }) async {
    if (kDebugMode) {
      print(
        '👥 Fetching class reservations for class $classId in club $clubId...',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<List<Map<String, dynamic>>>(
      method: 'GET',
      url:
          '$_baseUrl/clubs/$clubId/schedules/classes/$classId/class-reservations',
      requiresMemberToken: true,
      refreshTokenIfNeeded: true,
      customClientRequestId: userId != null
          ? 'eFitness/$eFitnessVersion/$userId'
          : null,
      listParser: (results) {
        if (kDebugMode) {
          print('✅ Fetched ${results.length} class reservations');
        }
        return results.map((e) => Map<String, dynamic>.from(e)).toList();
      },
    );
  }

  Future<bool> cancelClassReservation({
    required int clubId,
    required int classReservationId,
  }) async {
    if (kDebugMode) {
      print(
        '🗑️ Cancelling class reservation $classReservationId for club $clubId...',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<bool>(
          method: 'DELETE',
          url:
              '$_baseUrl/clubs/$clubId/members/class-reservations/$classReservationId',
          requiresMemberToken: true,
          refreshTokenIfNeeded: true,
          customClientRequestId: userId != null
              ? 'eFitness/$eFitnessVersion/$userId'
              : null,
          returnBool: true,
        ) ??
        false;
  }

  Future<List<Map<String, dynamic>>> getInstallments({
    required int clubId,
    required int membershipId,
  }) async {
    if (kDebugMode) {
      print(
        '💳 Fetching installments for membership $membershipId in club $clubId...',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<List<Map<String, dynamic>>>(
          method: 'GET',
          url:
              '$_baseUrl/clubs/$clubId/members/memberships/$membershipId/installments?0',
          requiresMemberToken: true,
          refreshTokenIfNeeded: true,
          customClientRequestId: userId != null
              ? 'eFitness/$eFitnessVersion/$userId'
              : null,
          listParser: (results) {
            if (kDebugMode) {
              print('✅ Fetched ${results.length} installments');
            }
            return results.map((e) => Map<String, dynamic>.from(e)).toList();
          },
        ) ??
        [];
  }

  Future<List<Map<String, dynamic>>> getMembershipDefinitions(
    int clubId,
  ) async {
    if (kDebugMode) {
      print('🛒 Fetching membership definitions for club $clubId...');
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<List<Map<String, dynamic>>>(
          method: 'GET',
          url: '$_baseUrl/clubs/$clubId/membership-definitions?visibility=2',
          requiresMemberToken: true,
          refreshTokenIfNeeded: true,
          customClientRequestId: userId != null
              ? 'eFitness/$eFitnessVersion/$userId'
              : null,
          listParser: (results) {
            if (kDebugMode) {
              print('✅ Fetched ${results.length} membership definitions');
            }
            return results.map((e) => Map<String, dynamic>.from(e)).toList();
          },
        ) ??
        [];
  }

  Future<Map<String, dynamic>?> payInstallments({
    required int clubId,
    required List<int> installmentIds,
  }) async {
    if (kDebugMode) {
      print('💳 Paying installments $installmentIds for club $clubId...');
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<Map<String, dynamic>>(
      method: 'POST',
      url: '$_baseUrl/clubs/$clubId/members/payments/credit-cards/transactions',
      requiresMemberToken: true,
      refreshTokenIfNeeded: true,
      customClientRequestId: userId != null
          ? 'eFitness/$eFitnessVersion/$userId'
          : null,
      body: {'installmentIds': installmentIds, 'chargeIds': []},
      parser: (data) {
        if (kDebugMode) {
          print('✅ Installment payment response: $data');
        }
        return data;
      },
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    required int clubId,
    int limit = 20,
    int offset = 0,
  }) async {
    if (kDebugMode) {
      print('🔔 Fetching notifications for club $clubId...');
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<List<Map<String, dynamic>>>(
          method: 'GET',
          url:
              '$_baseUrl/clubs/$clubId/members/notifications/push?Limit=$limit&Offset=$offset',
          requiresMemberToken: true,
          refreshTokenIfNeeded: true,
          customClientRequestId: userId != null
              ? 'eFitness/$eFitnessVersion/$userId'
              : null,
          listParser: (results) {
            if (kDebugMode) {
              print('✅ Fetched ${results.length} notifications');
            }
            return results.map((e) => Map<String, dynamic>.from(e)).toList();
          },
        ) ??
        [];
  }

  Future<Map<String, dynamic>?> getCreditCardInfo(int clubId) async {
    if (kDebugMode) {
      print('💳 Fetching credit card info for club $clubId...');
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<Map<String, dynamic>>(
      method: 'GET',
      url: '$_baseUrl/clubs/$clubId/members/payments/credit-cards',
      requiresMemberToken: true,
      refreshTokenIfNeeded: true,
      customClientRequestId: userId != null
          ? 'eFitness/$eFitnessVersion/$userId'
          : null,
      parser: (data) {
        if (kDebugMode) {
          print('✅ Credit card info fetched');
        }
        return data;
      },
    );
  }

  Future<Map<String, dynamic>?> getMemberProfile(int clubId) async {
    if (kDebugMode) {
      print('👤 Fetching member profile for club $clubId...');
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final appInfo = await _getAppInfo();
    final eFitnessVersion = appInfo['efitness-version'] ?? '3.3.18';

    return await _makeRequest<Map<String, dynamic>>(
      method: 'GET',
      url: '$_baseUrl/clubs/$clubId/members',
      requiresMemberToken: true,
      refreshTokenIfNeeded: true,
      customClientRequestId: userId != null
          ? 'eFitness/$eFitnessVersion/$userId'
          : null,
      parser: (data) {
        if (kDebugMode) {
          print('✅ Member profile fetched');
        }
        return data;
      },
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80

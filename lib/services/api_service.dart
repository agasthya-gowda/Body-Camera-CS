import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://116.73.243.111:8080";
  static const String _sessionPrefsKey = 'session_cookie';

  // Under the new AD/WAD-backed permissions, the server sometimes returns
  // error messages in Chinese (e.g. a role-restricted account hitting a
  // module it can't view) instead of English. Decoding every response
  // through here swaps any non-Latin message text for a generic English
  // fallback before it ever reaches a screen's UI.
  dynamic _decodeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['msg'] is String) {
      final msg = decoded['msg'] as String;
      if (RegExp(r'[^\x00-\x7F]').hasMatch(msg)) {
        final code = decoded['code'];
        decoded['msg'] = (code == 401 || code == 403)
            ? "You don't have permission to access this."
            : 'Request failed. Please try again or contact your administrator.';
      }
    }
    return decoded;
  }

  // Static (shared across all instances) because nearly every screen creates
  // its own `ApiService()` rather than reusing one shared instance - an
  // instance field here would mean each screen's requests carry no session
  // cookie at all except on the screen that actually called login().
  static String? _sessionCookie;

  // ---------------- SESSION PERSISTENCE ----------------
  // The server only cares that requests carry a still-valid PHPSESSID - it
  // doesn't matter whether that cookie came from a fresh login or one saved
  // from a previous app run. Saving it lets the app skip the login screen
  // after being fully closed and reopened, as long as the server session
  // (kept alive by the 20s heartbeat while the app was last running) hasn't
  // since expired.
  static Future<void> _persistSessionCookie() async {
    final prefs = await SharedPreferences.getInstance();
    if (_sessionCookie != null) {
      await prefs.setString(_sessionPrefsKey, _sessionCookie!);
    } else {
      await prefs.remove(_sessionPrefsKey);
    }
  }

  // Loads a previously saved cookie (if any) and confirms the server still
  // accepts it via the heartbeat endpoint. Returns true if the restored
  // session is valid, meaning the caller can skip straight to the dashboard.
  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_sessionPrefsKey);
    if (saved == null) return false;
    _sessionCookie = saved;
    final valid = await ApiService().sendHeartbeat();
    if (!valid) {
      _sessionCookie = null;
      await prefs.remove(_sessionPrefsKey);
    }
    return valid;
  }

  // ---------------- LOGIN ----------------
  // Since the vendor added AD/WAD-backed authentication, the login endpoint
  // now requires two extra things the old flow didn't need (reverse-engineered
  // directly from the vendor's own web dashboard bundle - chunk-common.js's
  // "param_up" helper - and confirmed end-to-end with a real session cookie):
  //   1. A per-session `token`, obtained from a GET call that also issues the
  //      PHPSESSID this login then authenticates.
  //   2. A `pe_signals` request signature: sort every field alphabetically as
  //      "key=value;", append md5("Pe2695jingyi"), URL-encode the result, then
  //      md5 that. The server rejects the request before ever checking the
  //      username/password if this doesn't match.
  // The inner credentials blob also now needs `raw_password` (the plaintext
  // password) alongside the old MD5 hash, since AD needs the real password to
  // bind against the directory server.
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Step 0: Fetch a fresh login token - this call's Set-Cookie is the
      // PHPSESSID the login POST below authenticates.
      final getResponse = await http.get(
        Uri.parse("$baseUrl/rest/index/login/get?key="),
      );
      final cookieHeader = getResponse.headers['set-cookie'];
      if (cookieHeader != null) {
        final match = RegExp(r'PHPSESSID=[^;]+').firstMatch(cookieHeader);
        if (match != null) _sessionCookie = match.group(0);
      }
      final basicInfo =
          jsonDecode(utf8.decode(base64Decode(getResponse.body)));
      final String token = basicInfo['data']?['page']?['token'] ?? '';

      // Step 1: MD5 hash the password (32-char lowercase)
      String md5Password = md5.convert(utf8.encode(password)).toString();

      // Step 2: Build the inner JSON, now including the plaintext password
      Map<String, String> innerJson = {
        "username": username,
        "password": md5Password,
        "raw_password": password,
        "key": "",
      };
      String loginInfo =
          base64Encode(utf8.encode(jsonEncode(innerJson)));

      // Step 3: Build the pe_signals signature exactly as the web login does.
      // captcha_code "29" and nocache "null" are the literal values the web
      // login itself sends whenever its (currently disabled) CAPTCHA isn't shown.
      const captchaCode = '29';
      const nocache = 'null';
      final signatureFields = <String, String>{
        'captcha_code': captchaCode,
        'login_info': loginInfo,
        'new_password': 'undefined',
        'nocache': nocache,
        'sso': 'undefined',
        'token': token,
        'withCredentials': 'true',
      };
      final sortedKeys = signatureFields.keys.toList()..sort();
      final buffer = StringBuffer();
      for (final key in sortedKeys) {
        buffer.write('$key=${signatureFields[key]};');
      }
      buffer.write(md5.convert(utf8.encode('Pe2695jingyi')).toString());
      final peSignals = md5
          .convert(utf8.encode(Uri.encodeComponent(buffer.toString())))
          .toString();

      final body = jsonEncode({
        'captcha_code': captchaCode,
        'login_info': loginInfo,
        'nocache': nocache,
        'token': token,
        'withCredentials': true,
        'pe_signals': peSignals,
      });

      // Step 4: Send request, reusing the session cookie captured in Step 0 -
      // this login call no longer returns a fresh cookie of its own.
      final response = await http.post(
        Uri.parse("$baseUrl/rest/index/login/login"),
        headers: _authHeaders(),
        body: body,
      );

      final data = _decodeJson(response.body);
      if (data['code'] == 200 && _sessionCookie != null) {
        await _persistSessionCookie();
      }
      return data;
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // LOGOUT
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/index/login/logout"),
        headers: _authHeaders(),
      );
      // Also clear the platform heartbeat (per doc: /rest/other/user/del_online, GET)
      await clearHeartbeat();
      _sessionCookie = null;
      await _persistSessionCookie();
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // CLEAN/CLEAR HEARTBEAT (call once on logout, per API doc)
  Future<void> clearHeartbeat() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rest/other/user/del_online"),
        headers: _authHeaders(),
      );
      final data = _decodeJson(response.body);
      if (data['code'] == 200) {
        print("Clear heartbeat succeeded: ${data['msg']}");
      } else {
        print("Clear heartbeat failed: ${data['msg']}");
      }
    } catch (e) {
      print("Clear heartbeat error: $e");
    }
  }

  // ---------------- HEARTBEAT (call every 20 seconds) ----------------
  Future<bool> sendHeartbeat() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rest/other/user/online"),
        headers: _authHeaders(),
      );
      final data = _decodeJson(response.body);
      if (data['code'] == 200) {
        return true;
      } else {
        print("Heartbeat failed: ${data['msg']}");
        return false;
      }
    } catch (e) {
      print("Heartbeat error: $e");
      return false;
    }
  }

  // ---------------- Helper: attach session cookie ----------------
  Map<String, String> _authHeaders() {
    Map<String, String> headers = {"Content-Type": "application/json"};
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  // ---------------- ONLINE DEVICE LIST ----------------
  // Per doc Section 6 "Online device status": POST /rest/other/unitjson/gdlist
  // Body: {"bh": "bh", "text": "dname"} -- both fields required with the doc's
  // literal fixed values (not real data, just constant strings the doc specifies).
  // Note: pe_signals omitted per vendor's confirmation (internal use only)
  Future<Map<String, dynamic>> getOnlineDevices() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/other/unitjson/gdlist"),
        headers: _authHeaders(),
        body: jsonEncode({"bh": "bh", "text": "dname"}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- DEVICE DETAIL INQUIRY (battery, storage, signal) ----------------
  // Per doc Section 5, item 22 "User info inquiry": POST /rest/gis/gismoni/get_devicedetail
  // Body: {"ids": ["<device_sn>", ...]}  -- array of device SN (did/hostbody values), NOT imei
  // Note: pe_signals omitted per vendor's confirmation (internal use only)
  // Corrected from an earlier version that incorrectly sent {imei, hostbody} -
  // that shape does not match the doc and would fail against the real server.
  Future<Map<String, dynamic>> getDeviceDetail(List<String> deviceIds) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/get_devicedetail"),
        headers: _authHeaders(),
        body: jsonEncode({"ids": deviceIds}),
      );
      final result = _decodeJson(response.body);
      return {
        "code": result['code'],
        "msg": result['msg'],
        "data": List<Map<String, dynamic>>.from(result['data'] ?? []),
      };
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e", "data": <Map<String, dynamic>>[]};
    }
  }

  // ---------------- START VIDEO CALL (per doc: Realtime Streaming APIs) ----------------
  // Success response: data is a List of stream info objects
  // Error response (code 400): data is an Object with error_hostbody, error_code, err_msg, success_data
  Future<Map<String, dynamic>> startVideoCall(List<String> hostbodyList) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/live/chrome/startLive"),
        headers: _authHeaders(),
        body: jsonEncode({"hostbody_arr": hostbodyList}),
      );
      final result = _decodeJson(response.body);

      if (result['code'] == 200) {
        // Success case: data is a List
        return {
          "code": 200,
          "msg": result['msg'],
          "streams": List<Map<String, dynamic>>.from(result['data'] ?? []),
          "failedDevices": <Map<String, dynamic>>[],
        };
      } else {
        // Error case: data is an Object with partial success info
        final errorData = result['data'] ?? {};
        final successList = List<Map<String, dynamic>>.from(errorData['success_data'] ?? []);
        final errorHostbodies = List<String>.from(errorData['error_hostbody'] ?? []);
        final errorMsgs = List<String>.from(errorData['err_msg'] ?? []);
        final errorCodes = List<dynamic>.from(errorData['error_code'] ?? []);
        List<Map<String, dynamic>> failedDevices = [];
        for (int i = 0; i < errorHostbodies.length; i++) {
          failedDevices.add({
            "hostbody": errorHostbodies[i],
            "err_msg": i < errorMsgs.length ? errorMsgs[i] : "Unknown error",
            "error_code": i < errorCodes.length ? errorCodes[i] : 0,
          });
        }
        return {
          "code": result['code'],
          "msg": result['msg'],
          "streams": successList,
          "failedDevices": failedDevices,
        };
      }
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e", "streams": [], "failedDevices": []};
    }
  }

  // ---------------- STOP VIDEO CALL ----------------
  Future<Map<String, dynamic>> stopVideoCall(List<String> hostbodyList) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/live/chrome/stopLive"),
        headers: _authHeaders(),
        body: jsonEncode({"hostbody_arr": hostbodyList}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- START AUDIO CALL ----------------
  // Same success/error response shape as Start Video Call
  Future<Map<String, dynamic>> startAudioCall(List<String> hostbodyList) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/live/chrome/startAudio"),
        headers: _authHeaders(),
        body: jsonEncode({"hostbody_arr": hostbodyList}),
      );
      final result = _decodeJson(response.body);

      if (result['code'] == 200) {
        return {
          "code": 200,
          "msg": result['msg'],
          "streams": List<Map<String, dynamic>>.from(result['data'] ?? []),
          "failedDevices": <Map<String, dynamic>>[],
        };
      } else {
        final errorData = result['data'] ?? {};
        final successList = List<Map<String, dynamic>>.from(errorData['success_data'] ?? []);
        final errorHostbodies = List<String>.from(errorData['error_hostbody'] ?? []);
        final errorMsgs = List<String>.from(errorData['err_msg'] ?? []);
        final errorCodes = List<dynamic>.from(errorData['error_code'] ?? []);
        List<Map<String, dynamic>> failedDevices = [];
        for (int i = 0; i < errorHostbodies.length; i++) {
          failedDevices.add({
            "hostbody": errorHostbodies[i],
            "err_msg": i < errorMsgs.length ? errorMsgs[i] : "Unknown error",
            "error_code": i < errorCodes.length ? errorCodes[i] : 0,
          });
        }
        return {
          "code": result['code'],
          "msg": result['msg'],
          "streams": successList,
          "failedDevices": failedDevices,
        };
      }
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e", "streams": [], "failedDevices": []};
    }
  }

  // ---------------- STOP AUDIO CALL ----------------
  Future<Map<String, dynamic>> stopAudioCall(List<String> hostbodyList, List<String> wsChannelIdList) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/live/chrome/stopAudio"),
        headers: _authHeaders(),
        body: jsonEncode({"hostbody_arr": hostbodyList, "wsChannelId_arr": wsChannelIdList}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- SEND COMMAND (mute/unmute, and later photo/video/restart) ----------------
  // Per doc: /rest/gis/gismoni/send_cmd - generic command endpoint, "type" determines action
  Future<Map<String, dynamic>> sendCommand(String imei, String type) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/send_cmd"),
        headers: _authHeaders(),
        body: jsonEncode({"imei": imei, "type": type}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- REGISTER NEW USER (multipart/form-data per doc) ----------------
  // Note: pe_signals omitted per vendor's confirmation - it's for internal use only
  Future<Map<String, dynamic>> registerUser({
    required String hostcode,
    required String realname,
    required String bh,
    required String type,
    String? mobile,
    String? tel,
    String? sort,
    String? note,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/rest/user/police/add"),
      );
      request.headers.addAll(_authHeaders());
      request.fields['hostcode'] = hostcode;
      request.fields['realname'] = realname;
      request.fields['bh'] = bh;
      request.fields['type'] = type;
      if (mobile != null) request.fields['mobile'] = mobile;
      if (tel != null) request.fields['tel'] = tel;
      if (sort != null) request.fields['sort'] = sort;
      if (note != null) request.fields['note'] = note;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- MODIFY USER (multipart/form-data per doc) ----------------
  // Note: pe_signals omitted per vendor's confirmation - it's for internal use only
  Future<Map<String, dynamic>> modifyUser({
    required String id,
    required String realname,
    required String bh,
    required String type,
    String? mobile,
    String? tel,
    String? sort,
    String? note,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/rest/user/police/saveedit"),
      );
      request.headers.addAll(_authHeaders());
      request.fields['id'] = id;
      request.fields['realname'] = realname;
      request.fields['bh'] = bh;
      request.fields['type'] = type;
      if (mobile != null) request.fields['mobile'] = mobile;
      if (tel != null) request.fields['tel'] = tel;
      if (sort != null) request.fields['sort'] = sort;
      if (note != null) request.fields['note'] = note;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- SEARCH USER (application/json per doc) ----------------
  // Response includes user_type dictionary - useful for populating type dropdown dynamically
  Future<Map<String, dynamic>> searchUsers({
    String? hostkey,
    String? bh,
    String? type,
    String? bind, // "0" = no limit, "1" = binding, "2" = no binding (per doc)
    int pageSize = 20,
    int curPage = 1,
  }) async {
    try {
      Map<String, dynamic> body = {
        "page_size": pageSize,
        "cur_page": curPage,
      };
      if (hostkey != null) body['hostkey'] = hostkey;
      if (bh != null) body['bh'] = bh;
      if (type != null) body['type'] = type;
      if (bind != null) body['bind'] = bind;

      final response = await http.post(
        Uri.parse("$baseUrl/rest/user/police/policelist"),
        headers: _authHeaders(),
        body: jsonEncode(body),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- DELETE USER (application/json per doc) ----------------
  // Note: pe_signals omitted per vendor's confirmation - it's for internal use only
  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/user/police/del"),
        headers: _authHeaders(),
        body: jsonEncode({"id": id}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- NEW MESSAGE (multipart/form-data, includes image file) ----------------
  Future<Map<String, dynamic>> createMessage({
    required String title,
    required String content,
    required List<int> imageBytes,
    required String imageFileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/rest/gis/gismessage/add"),
      );
      request.headers.addAll(_authHeaders());
      request.fields['title'] = title;
      request.fields['type'] = '0'; // Fixed value per doc
      request.fields['content'] = content;
      request.files.add(http.MultipartFile.fromBytes(
        'pic_mess',
        imageBytes,
        filename: imageFileName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- SEND MESSAGE (application/json) ----------------
  // Note: pe_signals omitted per vendor's confirmation
  Future<Map<String, dynamic>> sendMessage({
    required String messId,
    required List<String> deviceList,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismessagesend/send"),
        headers: _authHeaders(),
        body: jsonEncode({"mess_id": messId, "device": deviceList}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- MESSAGE SEARCH (application/json) ----------------
  Future<Map<String, dynamic>> searchMessages({
    String? keyword,
    int pageSize = 20,
    int curPage = 1,
  }) async {
    try {
      Map<String, dynamic> body = {
        "page_size": pageSize,
        "cur_page": curPage,
      };
      if (keyword != null) body['keyword'] = keyword;

      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismessage/messlist"),
        headers: _authHeaders(),
        body: jsonEncode(body),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- MODIFY MESSAGE (multipart/form-data, includes image file) ----------------
  // Note: pic_mess is marked Required in doc even for edit - matching literally.
  // TODO: Verify with real server if editing without re-uploading image is actually possible.
  Future<Map<String, dynamic>> modifyMessage({
    required String messId,
    required String title,
    required String content,
    required List<int> imageBytes,
    required String imageFileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/rest/gis/gismessage/saveEdit"),
      );
      request.headers.addAll(_authHeaders());
      request.fields['messid'] = messId;
      request.fields['title'] = title;
      request.fields['type'] = '0'; // Fixed value per doc
      request.fields['content'] = content;
      request.files.add(http.MultipartFile.fromBytes(
        'pic_mess',
        imageBytes,
        filename: imageFileName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- DELETE MESSAGE (application/json) ----------------
  Future<Map<String, dynamic>> deleteMessage(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismessage/del"),
        headers: _authHeaders(),
        body: jsonEncode({"id": id}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- SENT MESSAGE LIST (application/json) ----------------
  Future<Map<String, dynamic>> getSentMessageList({
    required String id,
    String? keyword,
    String? bh,
    String pageSize = "20",
    String curPage = "1",
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "page_size": pageSize,
        "cur_page": curPage,
      };
      if (keyword != null) body['keyword'] = keyword;
      if (bh != null) body['bh'] = bh;

      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismessagesendlist/messglist"),
        headers: _authHeaders(),
        body: jsonEncode(body),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- REAL-TIME LOCATION (GPS Tracking) ----------------
  // Per doc Section 7.2: POST /rest/gis/gismoni/get_point
  // Body: {"ids": ["T060039", ...]}  -- device SN (hostbody/did values, NOT imei)
  // Response data: [{id, lat, lng, name}]
  // Note: pe_signals omitted per vendor's confirmation (internal use only)
  Future<Map<String, dynamic>> getRealtimeLocation(List<String> deviceIds) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/get_point"),
        headers: _authHeaders(),
        body: jsonEncode({"ids": deviceIds}),
      );
      final result = _decodeJson(response.body);
      return {
        "code": result['code'],
        "msg": result['msg'],
        "data": List<Map<String, dynamic>>.from(result['data'] ?? []),
      };
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e", "data": <Map<String, dynamic>>[]};
    }
  }

  // ---------------- GPS HISTORY (Route Playback) ----------------
  // Per doc Section 7.1: POST /rest/gis/gishistory/history
  // Body: {"history_hostbody": "...", "start_in": "<unix_ts>", "end_in": "<unix_ts>"}
  // Response data: { measure: {walk, bike, car}, gpsarray: [{deviceid, id, lat, lng, islbs, gpstime, speed}] }
  // Note: pe_signals omitted per vendor's confirmation
  Future<Map<String, dynamic>> getGpsHistory({
    required String historyHostbody,
    required String startIn,
    required String endIn,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gishistory/history"),
        headers: _authHeaders(),
        body: jsonEncode({
          "history_hostbody": historyHostbody,
          "start_in": startIn,
          "end_in": endIn,
        }),
      );
      final result = _decodeJson(response.body);
      return {
        "code": result['code'],
        "msg": result['msg'],
        "data": result['data'] ?? {},
      };
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e", "data": {}};
    }
  }

  // ---------------- REMOTE KICKOFF (Photo / Video Trigger) ----------------
  // Per doc Section 5, item 20 "Remote kickoff": POST /rest/gis/gismoni/send_cmd
  // Same endpoint as mute/unmute (item 19), different "type" values:
  //   "takephoto"  -> triggers the device to capture a photo remotely
  //   "startvideo" -> triggers the device to start recording remotely
  // Note: pe_signals omitted per vendor's confirmation (internal use only)
  Future<Map<String, dynamic>> remoteKickoff(String imei, String type) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/send_cmd"),
        headers: _authHeaders(),
        body: jsonEncode({"imei": imei, "type": type}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- REMOTE RESTART ----------------
  // Per doc Section 5, item 21 "Remote restart": POST /rest/gis/gismoni/send_restart
  // Different endpoint from send_cmd - requires BOTH imei and hostbody
  // Note: pe_signals omitted per vendor's confirmation (internal use only)
  Future<Map<String, dynamic>> remoteRestart(String imei, String hostbody) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/send_restart"),
        headers: _authHeaders(),
        body: jsonEncode({"imei": imei, "hostbody": hostbody}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- ADD DEVICE ----------------
  // Per doc Section 6, item 23: POST /rest/device/device/add
  // Note: pe_signals omitted per vendor's confirmation (internal use only)
  Future<Map<String, dynamic>> addDevice({
    required String bh,
    required String hostbody,
    required String recorderType, // "0" = normal, "1" = live streaming
    required String typesn,       // device model ID
    String? productFirm,
    String? capacity,
    String? version,
  }) async {
    try {
      Map<String, dynamic> body = {
        "bh": bh,
        "hostbody": hostbody,
        "recorder_type": recorderType,
        "typesn": typesn,
      };
      if (productFirm != null) body['product_firm'] = productFirm;
      if (capacity != null) body['capacity'] = capacity;
      if (version != null) body['version'] = version;

      final response = await http.post(
        Uri.parse("$baseUrl/rest/device/device/add"),
        headers: _authHeaders(),
        body: jsonEncode(body),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- ALL DEVICE LIST ----------------
  // Per doc Section 6, item 25: POST /rest/device/device/devicelist
  // Note: pe_signals omitted per vendor's confirmation
  Future<Map<String, dynamic>> getAllDevices({
    String? hostkey,
    String? hostbody,
    String? bh,
    String? state, // "" = all, "0"-normal, "1"-fail, "2"-obsolete, "3"-stopped
    String? devicetype,
    int pageSize = 20,
    int curPage = 1,
  }) async {
    try {
      Map<String, dynamic> body = {
        "page_size": pageSize,
        "cur_page": curPage,
      };
      if (hostkey != null) body['hostkey'] = hostkey;
      if (hostbody != null) body['hostbody'] = hostbody;
      if (bh != null) body['bh'] = bh;
      if (state != null) body['state'] = state;
      if (devicetype != null) body['devicetype'] = devicetype;

      final response = await http.post(
        Uri.parse("$baseUrl/rest/device/device/devicelist"),
        headers: _authHeaders(),
        body: jsonEncode(body),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e", "data": {}};
    }
  }

  // ---------------- MODIFY DEVICE ----------------
  // Per doc Section 6, item 26: POST /rest/device/device/saveedit
  // Note: pe_signals omitted per vendor's confirmation
  Future<Map<String, dynamic>> modifyDevice({
    required String id,
    required String bh,
    required String recorderType,
    required String typesn,
    String? productFirm,
    String? capacity,
    String? version,
  }) async {
    try {
      Map<String, dynamic> body = {
        "id": id,
        "bh": bh,
        "recorder_type": recorderType,
        "typesn": typesn,
      };
      if (productFirm != null) body['product_firm'] = productFirm;
      if (capacity != null) body['capacity'] = capacity;
      if (version != null) body['version'] = version;

      final response = await http.post(
        Uri.parse("$baseUrl/rest/device/device/saveedit"),
        headers: _authHeaders(),
        body: jsonEncode(body),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- DELETE DEVICE ----------------
  // Per doc Section 6, item 27: POST /rest/device/device/del
  // Note: pe_signals omitted per vendor's confirmation
  Future<Map<String, dynamic>> deleteDevice(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/device/device/del"),
        headers: _authHeaders(),
        body: jsonEncode({"id": id}),
      );
      return _decodeJson(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  bool get isLoggedIn => _sessionCookie != null;
}
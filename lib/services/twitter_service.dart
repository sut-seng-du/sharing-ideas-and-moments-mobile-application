import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:twitter_api_v2/twitter_api_v2.dart' as v2;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_links/app_links.dart';
import '../models/message.dart';
import '../config/twitter_config.dart';

class TwitterService {
  static const _storage = FlutterSecureStorage();
  static final _appLinks = AppLinks();

  // In-memory completer that authenticate() waits on
  static Completer<String>? _pendingCompleter;

  // Persisted keys for the OAuth PKCE flow (survive app restarts)
  static const _oauthStateKey = 'twitter_pkce_state';
  static const _oauthVerifierKey = 'twitter_pkce_verifier';
  static const _tokenKey = 'twitter_oauth2_token';

  // Use the verified Client ID from the config
  static const String _clientId = TwitterConfig.clientId;
  static const String _callbackUrl = 'sim-app://callback';

  /// Call this ONCE in main() — checks initial link AND subscribes to the stream.
  static void initDeepLinkListener() {
    print('TwitterService: initDeepLinkListener started');
    // Handle app opened via deep link (Android restart case)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        print('TwitterService: Initial link received: $uri');
        _handleIncomingLink(uri);
      }
    });

    // Handle deep link while app is already running (foreground case)
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        print('TwitterService: Stream link received: $uri');
        _handleIncomingLink(uri);
      }
    });
  }

  static Future<void> _handleIncomingLink(Uri uri) async {
    final uriStr = uri.toString();
    if (!uriStr.startsWith(_callbackUrl)) return;

    final code = uri.queryParameters['code'];
    final returnedState = uri.queryParameters['state'];
    if (code == null || returnedState == null) return;

    // Read the persisted expected state
    final expectedState = await _storage.read(key: _oauthStateKey);
    final codeVerifier = await _storage.read(key: _oauthVerifierKey);

    print('TwitterService: Callback details: code=$code, state=$returnedState, expected=$expectedState');

    if (returnedState != expectedState || codeVerifier == null) {
      print('TwitterService: State mismatch or no verifier found.');
      return;
    }

    // Clean up persisted PKCE data
    await _storage.delete(key: _oauthStateKey);
    await _storage.delete(key: _oauthVerifierKey);

    // Either resolve in-memory completer OR exchange token directly
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      print('TwitterService: Completing in-memory authentication...');
      _pendingCompleter!.complete(code);
    } else {
      print('TwitterService: Authenticate() not active, exchanging token directly...');
      await _exchangeCodeForToken(code, codeVerifier);
    }
  }

  static Future<bool> isConnected() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return List.generate(length, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  static String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static Future<void> authenticate() async {
    final state = _generateRandomString(32);
    final codeVerifier = _generateRandomString(128);
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    // Save PKCE state to survive app restart
    await _storage.write(key: _oauthStateKey, value: state);
    await _storage.write(key: _oauthVerifierKey, value: codeVerifier);

    _pendingCompleter = Completer<String>();

    final authUrl = Uri.https('twitter.com', '/i/oauth2/authorize', {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _callbackUrl,
      'scope': 'tweet.read tweet.write users.read offline.access media.write',
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    print('TwitterService: Opening browser for auth...');
    if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
      _pendingCompleter = null;
      throw Exception('Could not launch authorization URL');
    }

    try {
      final code = await _pendingCompleter!.future.timeout(const Duration(minutes: 5));
      await _exchangeCodeForToken(code, codeVerifier);
    } on TimeoutException {
      // Check if token was already saved by the daemon listener
      await Future.delayed(const Duration(seconds: 2));
      if (!await isConnected()) {
        throw Exception('Authorization timed out.');
      }
    } finally {
      _pendingCompleter = null;
    }
  }

  static Future<void> _exchangeCodeForToken(String code, String codeVerifier) async {
    print('TwitterService: Exchanging code for Access Token...');
    final tokenUrl = Uri.https('api.twitter.com', '/2/oauth2/token');
    
    final response = await http.post(
      tokenUrl,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        // Some X implementations require Basic Auth for confidential clients
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:${TwitterConfig.clientSecret}'))}',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': _clientId, // Some still require it in body too
        'redirect_uri': _callbackUrl,
        'code_verifier': codeVerifier,
      },
    );

    print('TwitterService: Token status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: _tokenKey, value: data['access_token']);
      print('TwitterService: OAuth 2.0 Access Token stored successfully!');
    } else {
      print('TwitterService: Token error: ${response.body}');
      throw Exception('Failed to exchange token: ${response.body}');
    }
  }

  static Future<void> postMessage(Message message) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('Not authenticated with X');

    List<String>? mediaIds;
    if (message.imagePaths.isNotEmpty) {
      mediaIds = await _uploadMedia(message.imagePaths);
    }

    try {
      print('TwitterService: Manual Post to https://api.x.com/2/tweets');
      final response = await http.post(
        Uri.parse('https://api.x.com/2/tweets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-Client-Id': _clientId,
        },
        body: jsonEncode({
          'text': '${message.title}\n\n${message.content}',
          if (mediaIds != null && mediaIds.isNotEmpty)
            'media': {
              'media_ids': mediaIds,
            },
        }),
      );

      print('TwitterService: Post status: ${response.statusCode}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('TwitterService: Success! Tweet ID: ${data['data']['id']}');
      } else {
        print('TwitterService: X API Error: ${response.statusCode} - ${response.body}');
        throw Exception('X API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('TwitterService: Critical error during manual post: $e');
      rethrow;
    }
  }

  static Future<List<String>> _uploadMedia(List<String> paths) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) throw Exception('No OAuth 2.0 token found');

    List<String> mediaIds = [];
    try {
      for (final path in paths) {
        final file = File(path);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        final totalBytes = bytes.length;
        final mediaType = _getMediaType(path);

        print('TwitterService: V2 Media INIT - $path ($totalBytes bytes)');
        
        // 1. INITIALIZE
        final initResponse = await http.post(
          Uri.parse('https://api.x.com/2/media/upload/initialize'),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Client-Id': _clientId,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'total_bytes': totalBytes,
            'media_type': mediaType,
            'media_category': 'tweet_image',
          }),
        );

        if (initResponse.statusCode != 201 && initResponse.statusCode != 200) {
          throw Exception('Media INIT failed: ${initResponse.body}');
        }
        
        final dynamic initData = jsonDecode(initResponse.body);
        final String? mediaId = initData['data']?['id']?.toString() ??
                              initData['media_id_string'] ?? 
                              initData['data']?['media_id_string'] ?? 
                              initData['data']?['media_id']?.toString();
        
        if (mediaId == null) {
          throw Exception('Media ID was not found in INIT response: ${initResponse.body}');
        }

        // 2. APPEND
        print('TwitterService: V2 Media APPEND - $mediaId');
        // V2 Media upload uses the ID in the PATH only.
        final appendUrl = Uri.parse('https://api.x.com/2/media/upload/$mediaId/append');
        
        final appendRequest = http.MultipartRequest('POST', appendUrl);
        appendRequest.headers['Authorization'] = 'Bearer $token';
        appendRequest.headers['X-Client-Id'] = _clientId;
        
        appendRequest.fields['segment_index'] = '0';
        appendRequest.files.add(await http.MultipartFile.fromPath('media', path));

        final appendStreamed = await appendRequest.send();
        final appendResponse = await http.Response.fromStream(appendStreamed);

        if (appendResponse.statusCode != 204 && appendResponse.statusCode != 200) {
          throw Exception('Media APPEND failed: ${appendResponse.statusCode} - ${appendResponse.body}');
        }

        // 3. FINALIZE
        print('TwitterService: V2 Media FINALIZE - $mediaId');
        // V2 Media finalize also uses ID in the PATH only.
        final finalizeUrl = Uri.parse('https://api.x.com/2/media/upload/$mediaId/finalize');
        
        final finalizeResponse = await http.post(
          finalizeUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'X-Client-Id': _clientId,
          },
        );

        if (finalizeResponse.statusCode != 201 && finalizeResponse.statusCode != 200) {
          throw Exception('Media FINALIZE failed: ${finalizeResponse.body}');
        }

        mediaIds.add(mediaId);
        print('TwitterService: V2 Media Upload SUCCESS: $mediaId');
      }
    } catch (e) {
      print('TwitterService: V2 Media Upload Error: $e');
      rethrow;
    }
    return mediaIds;
  }

  static String _getMediaType(String path) {
    if (path.toLowerCase().endsWith('.png')) return 'image/png';
    if (path.toLowerCase().endsWith('.webp')) return 'image/webp';
    if (path.toLowerCase().endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    print('TwitterService: User logged out.');
  }
}

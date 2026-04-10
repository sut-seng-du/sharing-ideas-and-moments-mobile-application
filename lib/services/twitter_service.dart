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
import 'package:oauth1/oauth1.dart' as oauth1;
import '../models/message.dart';
import '../config/twitter_config.dart';

class TwitterService {
  static const _storage = FlutterSecureStorage();
  static final _appLinks = AppLinks();

  // In-memory completer that authenticate() waits on
  static Completer<String>? _pendingCompleter;

  // Persisted keys for the OAuth 1.0a flow
  static const _oauthTokenKey = 'twitter_oauth1_token';
  static const _oauthSecretKey = 'twitter_oauth1_token_secret';
  static const _tempSecretKey = 'twitter_temp_oauth_secret';

  // Credentials from the config
  static const String _consumerKey = TwitterConfig.consumerKey;
  static const String _consumerSecret = TwitterConfig.consumerSecret;
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

    final oauthToken = uri.queryParameters['oauth_token'];
    final oauthVerifier = uri.queryParameters['oauth_verifier'];
    
    if (oauthToken == null || oauthVerifier == null) {
      print('TwitterService: Missing token or verifier in callback');
      return;
    }

    print('TwitterService: Callback details: oauth_token=$oauthToken, oauth_verifier=$oauthVerifier');

    // Retrieve temporary secret to complete the exchange
    final tempSecret = await _storage.read(key: _tempSecretKey);
    if (tempSecret == null) {
      print('TwitterService: No temporary secret found for exchange.');
      return;
    }

    // Resolve in-memory completer OR exchange token directly
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      print('TwitterService: Completing in-memory authentication...');
      _pendingCompleter!.complete(oauthVerifier);
    } else {
      print('TwitterService: Authenticate() not active, exchanging token directly...');
      await _exchangeTokens(oauthToken, oauthVerifier, tempSecret);
    }
  }

  static Future<bool> isConnected() async {
    final token = await _storage.read(key: _oauthTokenKey);
    final secret = await _storage.read(key: _oauthSecretKey);
    return token != null && secret != null;
  }

  static Future<void> authenticate() async {
    print('TwitterService: Starting OAuth 1.0a flow...');
    
    final platform = oauth1.Platform(
      'https://api.twitter.com/oauth/request_token',
      'https://api.twitter.com/oauth/authorize',
      'https://api.twitter.com/oauth/access_token',
      oauth1.SignatureMethods.hmacSha1,
    );

    final clientCredentials = oauth1.ClientCredentials(_consumerKey, _consumerSecret);
    final auth = oauth1.Authorization(clientCredentials, platform);

    // 1. Get Request Token
    final result = await auth.requestTemporaryCredentials(_callbackUrl);
    final credentials = result.credentials;

    // Save temporary secret to survive app restart if necessary
    await _storage.write(key: _tempSecretKey, value: credentials.tokenSecret);

    _pendingCompleter = Completer<String>();

    final authUrl = Uri.parse(auth.getResourceOwnerAuthorizationURI(credentials.token));

    print('TwitterService: Opening browser for auth: $authUrl');
    if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
      _pendingCompleter = null;
      throw Exception('Could not launch authorization URL');
    }

    try {
      final oauthVerifier = await _pendingCompleter!.future.timeout(const Duration(minutes: 5));
      await _exchangeTokens(credentials.token, oauthVerifier, credentials.tokenSecret);
    } on TimeoutException {
      await Future.delayed(const Duration(seconds: 2));
      if (!await isConnected()) {
        throw Exception('Authorization timed out.');
      }
    } finally {
      _pendingCompleter = null;
    }
  }

  static Future<void> _exchangeTokens(String token, String verifier, String secret) async {
    print('TwitterService: Exchanging for User Access Tokens...');
    
    final platform = oauth1.Platform(
      'https://api.twitter.com/oauth/request_token',
      'https://api.twitter.com/oauth/authorize',
      'https://api.twitter.com/oauth/access_token',
      oauth1.SignatureMethods.hmacSha1,
    );

    final clientCredentials = oauth1.ClientCredentials(_consumerKey, _consumerSecret);
    final auth = oauth1.Authorization(clientCredentials, platform);
    
    final requestCredentials = oauth1.Credentials(token, secret);
    final finalResult = await auth.requestTokenCredentials(requestCredentials, verifier);
    final finalCredentials = finalResult.credentials;

    await _storage.write(key: _oauthTokenKey, value: finalCredentials.token);
    await _storage.write(key: _oauthSecretKey, value: finalCredentials.tokenSecret);
    await _storage.delete(key: _tempSecretKey);

    print('TwitterService: OAuth 1.0a Access Tokens stored successfully!');
  }

  static Future<void> postMessage(Message message) async {
    final token = await _storage.read(key: _oauthTokenKey);
    final secret = await _storage.read(key: _oauthSecretKey);
    if (token == null || secret == null) throw Exception('Not authenticated with X (1.0a required)');

    // Initialize the library with OAuth 1.0a credentials
    final twitter = v2.TwitterApi(
      bearerToken: '', // Not used for User-Context operations
      oauthTokens: v2.OAuthTokens(
        consumerKey: _consumerKey,
        consumerSecret: _consumerSecret,
        accessToken: token,
        accessTokenSecret: secret,
      ),
    );

    List<String>? mediaIds;
    if (message.imagePaths.isNotEmpty) {
      mediaIds = await _uploadMedia(twitter, message.imagePaths);
    }

    try {
      print('TwitterService: Posting Tweet via twitter_api_v2...');
      final response = await twitter.tweets.createTweet(
        text: '${message.title}\n\n${message.content}',
        media: mediaIds != null && mediaIds.isNotEmpty 
          ? v2.TweetMediaParam(mediaIds: mediaIds) 
          : null,
      );

      print('TwitterService: Success! Tweet ID: ${response.data.id}');
    } catch (e) {
      print('TwitterService: Critical error during tweet post: $e');
      rethrow;
    }
  }

  static Future<List<String>> _uploadMedia(v2.TwitterApi twitter, List<String> paths) async {
    List<String> mediaIds = [];
    try {
      for (final path in paths) {
        final file = File(path);
        if (!await file.exists()) continue;

        print('TwitterService: Uploading Media via legacy v1.1 pipeline - $path');
        
        final response = await twitter.media.uploadMedia(
          file: file,
        );
        
        final String mediaId = response.data.id.toString();
        mediaIds.add(mediaId);
        print('TwitterService: Media Upload SUCCESS: $mediaId');
      }
    } catch (e) {
      print('TwitterService: Media Upload Error: $e');
      rethrow;
    }
    return mediaIds;
  }

  static Future<void> logout() async {
    await _storage.delete(key: _oauthTokenKey);
    await _storage.delete(key: _oauthSecretKey);
    print('TwitterService: User logged out.');
  }
}

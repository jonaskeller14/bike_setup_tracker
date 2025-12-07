import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/servicecontrol/v2.dart';
import '../utils/data.dart';
import '../utils/file_import.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];
  static const String _fileName = 'bike_setup_tracker_data.json';

  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  String errorMessage = '';

  drive.DriveApi? _driveApi;
  final Map<String, dynamic> Function() getDataToUpload;
  final Function(Data) onDataDownloaded;

  DateTime? lastSync;
  Timer? _syncTimer;
  final Duration _syncMinTimeGap = const Duration(minutes: 5);
  final Duration _syncDebounceDuration = const Duration(seconds: 3);

  bool get isSignedIn => _currentUser != null;
  String? get displayName => _currentUser?.displayName;
  String? get email => _currentUser?.email;
  String? get photoUrl => _currentUser?.photoUrl;

  GoogleDriveService({
    required this.getDataToUpload,
    required this.onDataDownloaded,
  });

  Future<void> silentSetup() async {
    final GoogleSignIn signIn = GoogleSignIn.instance;

    try {
      await signIn.initialize(
        clientId: null,
        serverClientId: "473188600318-2fbh7usdhumouj41r55jm7r61nkunsag.apps.googleusercontent.com",
      );

      signIn.authenticationEvents
          .listen(_handleAuthenticationEvent)
          .onError(_handleAuthenticationError);
      
      await signIn.attemptLightweightAuthentication(); // Silent Sign in
      
    } catch (error) {
      errorMessage = "Google Sign In Setup Failed: $error";
    }
  }

  Future<void> _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    final GoogleSignInClientAuthorization? authorization = await user?.authorizationClient.authorizationForScopes(_scopes);
    
    _currentUser = user;
    _isAuthorized = authorization != null;
    errorMessage = '';

    await silentSync();
  }

  Future<void> _handleAuthenticationError(Object e) async {
    _currentUser = null;
    _isAuthorized = false;
    errorMessage =
        e is GoogleSignInException
            ? _errorMessageFromSignInException(e)
            : 'Unknown error: $e';
  }

  String _errorMessageFromSignInException(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled',
      GoogleSignInExceptionCode.interrupted => "Sign in interrupted",
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }

  Future<void> handleAuthorizeScopes() async {
    try {
      await _currentUser!.authorizationClient.authorizeScopes(_scopes);
      _isAuthorized = true;
      errorMessage = '';
    } on GoogleSignInException catch (e) {
      _isAuthorized = false;
      errorMessage = _errorMessageFromSignInException(e);
    }
  }

  Future<void> _initializeDriveApi() async {
    if (_currentUser == null) return;
    final Map<String, String>? headers = await _currentUser!.authorizationClient
        .authorizationHeaders(_scopes);

    if (headers == null) {
      throw Exception("Failed to obtain authorization headers.");
    }

    final client = AuthenticatedClient(http.Client(), headers);
    _driveApi = drive.DriveApi(client);
  }

  Future<void> interactiveSignIn() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      errorMessage = "Current Platform does not support Authentication";
      return;
    }

    try {
      _currentUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      errorMessage = "Sign in error: $e";
    } catch (e) {
      errorMessage = "Sign in error: $e";
    }
    if (_currentUser == null) return;
    
    _initializeDriveApi();
  }

  Future<void> interactiveSync() async {
    if (_currentUser == null) await interactiveSignIn();
    if (_currentUser == null) return;

    if (!_isAuthorized) await handleAuthorizeScopes();
    if (!_isAuthorized) return;

    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return;
    
    try {
      await download(); 
      await upload();
      lastSync = DateTime.now();
    } on DetailedApiRequestError catch (e) {
      if (e.status == 401) { // Catch the 401 (Token Rejected)
        debugPrint("401 Unauthorized: Access token is invalid or expired. Requesting re-authorization.");
        
        await clearToken();
        await handleAuthorizeScopes();

        if (!_isAuthorized) return;

        try {
          await download(); 
          await upload();
          lastSync = DateTime.now();
        } catch (e) {
          errorMessage = "ERROR handling 401 error: $e"; 
        }
      } else {
        errorMessage = 'API Error: ${e.message}';
      }
    } catch (e) {
      errorMessage = 'General Sync Error: $e';
    }
  }

  Future<void> silentSync() async {
    if (_currentUser == null) return;
    if (!_isAuthorized) return;

    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return;
    
    try {
      await download(); 
      await upload();
      lastSync = DateTime.now();
    } catch (e) {
      errorMessage = 'Silent Sync Error: $e';
    }
  }

  void scheduleSilentSync() {
    if (lastSync != null && DateTime.now().difference(lastSync!) < _syncMinTimeGap) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(_syncDebounceDuration, () async {
      await silentSync();
    });
  }

  Future<void> clearToken() async {
    try {
      final GoogleSignInClientAuthorization? authorization = await _currentUser?.authorizationClient.authorizationForScopes(_scopes);
      await _currentUser!.authorizationClient.clearAuthorizationToken(accessToken: authorization!.accessToken);
      debugPrint("Cleared Token.");
    } catch (e) {
      debugPrint("Could not clear token: $e");
    }
  }

  Future<void> upload() async {
    if (_driveApi == null) throw Exception("Drive API not initialized");
    final jsonString = jsonEncode(getDataToUpload());
    final List<int> fileBytes = utf8.encode(jsonString);
    final media = drive.Media(
      Stream.fromIterable([fileBytes]),
      fileBytes.length,
    );
    
    final fileId = await _getFileId(); // Check if file already exists in appDataFolder

    if (fileId != null) {
      final driveFile = drive.File(); // Metadata update if needed
      await _driveApi!.files.update(
        driveFile,
        fileId,
        uploadMedia: media,
      );
    } else {
      final driveFile = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder'];

      await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );
    }
  }

  Future<void> download() async {
    if (_driveApi == null) throw Exception("Drive API not initialized");

    final fileId = await _getFileId();
    if (fileId == null) return; // File doesn't exist yet

    final drive.Media media = await _driveApi!.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> dataStore = [];
    await for (final data in media.stream) {
      dataStore.addAll(data);
    }

    final jsonString = utf8.decode(dataStore);
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final Data remoteData = await FileImport.parseJson(jsonData: jsonData);
    onDataDownloaded(remoteData);
  }

  Future<String?> _getFileId() async {
    final fileList = await _driveApi!.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName' and trashed = false", 
      $fields: 'files(id)',
    );

    if (fileList.files?.isNotEmpty == true) {
      return fileList.files!.first.id;
    }
    return null;
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.disconnect();
    _currentUser = null;
    _driveApi = null;
  }
}

class AuthenticatedClient extends http.BaseClient {
  final http.Client _baseClient;
  final Map<String, String> _headers;

  AuthenticatedClient(this._baseClient, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _baseClient.send(request);
  }
}

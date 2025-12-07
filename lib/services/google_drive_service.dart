import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/servicecontrol/v2.dart';
import '../utils/data.dart';
import '../utils/file_import.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService extends ChangeNotifier { 
  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];
  static const String _fileName = 'bike_setup_tracker_data.json';

  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  String _errorMessage = '';
  bool _isSyncing = false;

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
  bool get isAuthorized => _isAuthorized;
  String get errorMessage => _errorMessage;
  bool get isSyncing => _isSyncing;

  GoogleDriveService({
    required this.getDataToUpload,
    required this.onDataDownloaded,
  });

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setIsSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

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
      _setErrorMessage("Google Sign In Setup Failed: $error");
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
    _errorMessage = '';

    notifyListeners();

    await silentSync();
  }

  Future<void> _handleAuthenticationError(Object e) async {
    _currentUser = null;
    _isAuthorized = false;
    _errorMessage =
        e is GoogleSignInException
            ? _errorMessageFromSignInException(e)
            : 'Unknown error: $e';
    notifyListeners(); // Notify UI of sign-out/error
  }

  String _errorMessageFromSignInException(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled by user',
      GoogleSignInExceptionCode.interrupted => "Sign in interrupted",
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }

  Future<void> handleAuthorizeScopes() async {
    if (_currentUser == null) return;

    try {
      await _currentUser!.authorizationClient.authorizeScopes(_scopes);
      _isAuthorized = true;
      _errorMessage = '';
      notifyListeners();
    } on GoogleSignInException catch (e) {
      _isAuthorized = false;
      _setErrorMessage(_errorMessageFromSignInException(e));
    }
  }

  Future<void> _initializeDriveApi() async {
    if (_currentUser == null) {
      _driveApi = null;
      return;
    }

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
      _setErrorMessage("Current Platform does not support Authentication");
      return;
    }
    
    _setErrorMessage('');

    try {
      _currentUser = await GoogleSignIn.instance.authenticate();
      if (_currentUser == null) return; // User cancelled
      await _initializeDriveApi(); // Initialize API immediately after sign-in
    } on GoogleSignInException catch (e) {
      _setErrorMessage("Sign in error: ${_errorMessageFromSignInException(e)}");
    } catch (e) {
      _setErrorMessage("Sign in error: $e");
    }
    notifyListeners(); // Update UI after sign-in attempt
  }

  Future<void> interactiveSync() async {
    _setIsSyncing(true);
    _setErrorMessage(''); 

    if (_currentUser == null) await interactiveSignIn();
    if (_currentUser == null) {
      _setIsSyncing(false);
      return;
    }

    if (!_isAuthorized) await handleAuthorizeScopes();
    if (!_isAuthorized) {
      _setIsSyncing(false);
      return;
    }

    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) {
      _setIsSyncing(false);
      _setErrorMessage("Drive API initialization failed.");
      return;
    }
    
    try {
      await download(); 
      await upload();
      lastSync = DateTime.now();
    } on DetailedApiRequestError catch (e) {
      if (e.status == 401) { // Catch the 401 (Token Rejected)
        debugPrint("401 Unauthorized: Access token is invalid or expired. Requesting re-authorization.");
        
        await clearToken();
        await handleAuthorizeScopes();

        if (!_isAuthorized) {
          _setIsSyncing(false);
          return;
        }

        try {
          await download(); 
          await upload();
          lastSync = DateTime.now();
        } catch (e) {
          _setErrorMessage("Error after re-authorization: $e");
        }
      } else {
        _setErrorMessage('API Error: ${e.message}');
      }
    } on SocketException {
      _setErrorMessage('No internet connection. Please connect to a network.');
    } catch (e) {
      _setErrorMessage('General Sync Error: $e');
    }
    
    _setIsSyncing(false);
    notifyListeners(); // Notify one last time for sync status update
  }

  Future<void> silentSync() async {
    if (_currentUser == null) return;
    if (!_isAuthorized) return;

    if (_driveApi == null) await _initializeDriveApi();
    if (_driveApi == null) return;
    
    // Silent sync only logs errors, doesn't overwrite general errorMessage
    try {
      await download(); 
      await upload();
      lastSync = DateTime.now();
      debugPrint("Silent Sync successful at $lastSync");
    } on DetailedApiRequestError catch (e) {
      debugPrint('Silent Sync API Error: Status ${e.status}, Message: ${e.message}');
    } on SocketException {
      debugPrint('Silent Sync failed: No internet connection.');
    } catch (e) {
      debugPrint('Silent Sync General Error: $e');
    }
  }

  void scheduleSilentSync() {
    if (lastSync != null && DateTime.now().difference(lastSync!) < _syncMinTimeGap) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(_syncDebounceDuration, () {
      debugPrint("Scheduled Silent Sync triggered");
      silentSync();
    });
  }

  Future<void> clearToken() async {
    try {
      final GoogleSignInClientAuthorization? authorization = await _currentUser?.authorizationClient.authorizationForScopes(_scopes);
      // Ensure authorization and accessToken are non-null before attempting clear
      if (authorization?.accessToken != null) {
        await _currentUser!.authorizationClient.clearAuthorizationToken(accessToken: authorization!.accessToken);
        debugPrint("Cleared Token.");
      }
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
    if (fileId == null) {
      debugPrint("Remote file does not exist. Skipping download.");
      return; 
    }

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
    _isAuthorized = false;
    _errorMessage = '';
    notifyListeners();
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

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'google_signin.dart';
import 'dart:typed_data' as typed_data;


class GoogleDriveService {

  // Instancia de GoogleSignInProvider para acceder a la sesión de Google
  final GoogleSignInProvider googleSignInProvider = GoogleSignInProvider();

  GoogleSignInAccount? get currentUser => googleSignInProvider.currentUser;

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive', // Permiso para el uso de la api de Google Drive
    ],
  );

  // Iniciar sesión con Google
  Future<void> signIn() async {
    await googleSignInProvider.signIn();
    if (currentUser != null) {
      debugPrint("Usuario autenticado: ${currentUser!.displayName}");
    } else {
      debugPrint("El inicio de sesión fue cancelado o fallido.");
    }
  }

  // Obtener el token de acceso para verificar si el usuario está autenticado
  Future<String?> getAccessToken() async {
    try {
      GoogleSignInAccount? user = currentUser ?? await googleSignIn.signInSilently();
      if (user == null) {
        user = await googleSignIn.signIn();
        if (user == null) {
          debugPrint("No se pudo iniciar sesión en Google");
          return null;
        }
      }

      final auth = await user.authentication;
      debugPrint("Token fresco obtenido");
      return auth.accessToken;
    } catch (e) {
      debugPrint("Error al obtener token: $e");
      return null;
    }
  }

  Future<String?> _refreshAccessToken() async {
    try {

      GoogleSignInAccount? user = currentUser ?? await googleSignIn.signInSilently();

      if (user == null) {
        user = await googleSignIn.signIn();
        if (user == null) {
          debugPrint("Usuario no autenticado.");
          return null;
        }
      }

      final googleAuth = await user.authentication;
      return googleAuth.accessToken;
    } catch (e) {
      debugPrint("Error al refrescar token: $e");
      return null;
    }
  }


  Future<void> uploadFile(File file, {String? folderId}) async {
    final String? accessToken = await getAccessToken();
    if (accessToken == null) {
      debugPrint("No se pudo obtener el token de acceso.");
      return;
    }

    final authClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken("Bearer", accessToken, DateTime.now().toUtc().add(const Duration(hours: 1))),
        "",
        [],
      ),
    );

    final driveApi = drive.DriveApi(authClient);
    final media = drive.Media(file.openRead(), file.lengthSync());

    final driveFile = drive.File()
      ..name = file.path.split('/').last
      ..parents = folderId != null ? [folderId] : null;

    try {
      final result = await driveApi.files.create(driveFile, uploadMedia: media);
      debugPrint("Archivo subido a Drive con ID: ${result.id}");
    } catch (e) {
      debugPrint("Error al subir archivo: $e");
    }
  }


  // Cerrar sesión
  Future<void> signOut() async {
    await googleSignInProvider.signOut();
    debugPrint("Sesión cerrada.");
  }

  // Listar archivos CSV
  Future<List<drive.File>> listCsvFiles() async {
    // Obtener el token de acceso
    final accessToken = await _refreshAccessToken();

    if (accessToken == null) {
      debugPrint("No se pudo obtener el token de acceso.");
      return [];
    }

    // Crear un cliente autenticado para interactuar con Google Drive
    final authClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken("Bearer", accessToken, DateTime.now().toUtc().add(Duration(hours: 1))),
        "",
        [],
      ),
    );

    // Crear instancia de la API de Google Drive
    final driveApi = drive.DriveApi(authClient);

    try {
      final fileList = await driveApi.files.list(
        q: "trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      return fileList.files ?? [];
    } catch (e) {
      debugPrint("Error al listar archivos: $e");
      return [];
    }
  }

  Future<typed_data.Uint8List?> getFileBytes(String fileId) async {
    try {
      final String? accessToken = await getAccessToken();
      if (accessToken == null) {
        debugPrint("No se pudo obtener el token de acceso.");
        return null;
      }

      final authClient = auth.authenticatedClient(
        http.Client(),
        auth.AccessCredentials(
          auth.AccessToken("Bearer", accessToken, DateTime.now().toUtc().add(Duration(hours: 1))),
          "",
          [],
        ),
      );

      final driveApi = drive.DriveApi(authClient);

      final drive.Media file = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> bytes = [];
      await file.stream.forEach((chunk) => bytes.addAll(chunk));

      return typed_data.Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint("Error al obtener los bytes del archivo: $e");
      return null;
    }
  }


  Future<String> getFileName(String fileId) async {
    final String? accessToken = await getAccessToken();
    if (accessToken == null) {
      debugPrint("No se pudo obtener el token de acceso.");
      return '';
    }

    final authClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken("Bearer", accessToken, DateTime.now().toUtc().add(const Duration(hours: 1))),
        "",
        [],
      ),
    );

    final driveApi = drive.DriveApi(authClient);

    try {
      final drive.File? file = await driveApi.files.get(fileId, $fields: 'name') as drive.File?;
      return file?.name ?? '';
    } catch (e) {
      debugPrint("Error al obtener el nombre del archivo: $e");
      return '';
    }
  }
}

import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/drive.file',
  ],
);

class GoogleSignInProvider {
  GoogleSignInAccount? _currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await googleSignIn.signIn();
      return _currentUser;
    } catch (e) {
      debugPrint("Error al iniciar sesión con Google: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      _currentUser = null;
      debugPrint("Sesión cerrada y credenciales eliminadas.");
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  GoogleSignInAccount? get currentUser => _currentUser;
}

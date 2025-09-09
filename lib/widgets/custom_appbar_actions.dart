import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/categorias_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/localFile_controller.dart';
import '../themes/theme_provider.dart';
import '../views/drive_restore_view.dart';
import '../views/drive_upload_view.dart';

class CustomAppBarActions extends StatelessWidget {
  final HomeController homeController;

  CustomAppBarActions({required this.homeController});

  @override
  Widget build(BuildContext context) {
    final LocalFileController _localFileController = LocalFileController();
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'subir_drive') {
          if (homeController.currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor, inicie sesión primero.')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DriveUploadView()),
          );
        } else if (value == 'restaurar_drive') {
          if (homeController.currentUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor, inicie sesión primero.')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DriveRestoreView()),
          );
        } else if (value == 'importar_archivo') {
          await _localFileController.importLocalZip(context);
        } else if (value == 'gestionar_categorias') {
          final categoriasController = CategoriasController();
          categoriasController.loadCategoriasAndNavigateToGestion(context);
        } else if (value == 'tema') {
          final themeProvider = context.read<ThemeProvider>();
          bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
          themeProvider.toggleTheme(!isDarkMode);
        } else if (value == 'login_logout') {
          if (homeController.currentUser == null) {
            await homeController.signIn();
          } else {
            await homeController.signOut();
          }
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              "Respaldo y Gestión de Datos",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          PopupMenuItem<String>(
            value: 'subir_drive',
            child: Row(
              children: const [
                Icon(Icons.cloud_upload),
                SizedBox(width: 8),
                Text("Guardar en Google Drive"),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'restaurar_drive',
            child: Row(
              children: const [
                Icon(Icons.cloud_download),
                SizedBox(width: 8),
                Text("Restaurar desde Google Drive"),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'importar_archivo',
            child: Row(
              children: const [
                Icon(Icons.file_upload),
                SizedBox(width: 8),
                Text("Importar desde archivo"),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              "Categorias",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          PopupMenuItem<String>(
            value: 'gestionar_categorias',
            child: Row(
              children: const [
                Icon(Icons.category),
                SizedBox(width: 8),
                Text("Gestionar Categorías"),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              "Personalización",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          PopupMenuItem<String>(
            value: 'tema',
            child: Row(
              children: const [
                Icon(Icons.color_lens),
                SizedBox(width: 8),
                Text("Cambiar tema"),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'login_logout',
            child: Row(
              children: [
                homeController.currentUser?.photoUrl != null
                    ? CircleAvatar(
                  backgroundImage: NetworkImage(homeController.currentUser!.photoUrl!),
                )
                    : const Icon(Icons.person_outline),
                const SizedBox(width: 8),
                Text(homeController.currentUser == null ? 'Iniciar sesión' : 'Cerrar sesión'),
              ],
            ),
          ),
        ];
      },
    );
  }
}

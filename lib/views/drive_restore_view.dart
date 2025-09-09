import 'package:flutter/material.dart';
import 'package:finanzas_app/controllers/drive_controller.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../controllers/home_controller.dart';
import '../services/google_drive.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_appbar_actions.dart';
import 'package:provider/provider.dart';

class DriveRestoreView extends StatefulWidget {
  const DriveRestoreView({super.key});

  @override
  DriveRestoreViewState createState() => DriveRestoreViewState();
}

class DriveRestoreViewState extends State<DriveRestoreView> {
  final DriveController _controller = DriveController();
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  bool _isLoading = false;
  String? _selectedFileId;
  List<drive.File> _csvFiles = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCsvFiles();
  }

  // Metodo para cargar la lista de archivos CSV
  Future<void> _loadCsvFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Resetear el mensaje de error
    });

    try {
      // Intentar iniciar sesión nuevamente si no hay usuario autenticado
      await _googleDriveService.signIn();

      if (_googleDriveService.currentUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Por favor, inicia sesión en Google Drive.';
        });
        return;
      }

      // Obtener los archivos CSV desde Google Drive
      List<drive.File> files = await _googleDriveService.listCsvFiles();

      if (files.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontraron archivos CSV en tu Google Drive.';
        });
      }

      setState(() {
        _csvFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar los archivos: $e';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
        builder: (context, homeController, child) {
          return Scaffold(
            appBar: CustomGradientAppBar(title: 'Restaurar datos',
              actions: [ CustomAppBarActions(homeController: homeController)],),

            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Si hay un error, mostrar mensaje
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  // Indicador de carga si está cargando
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                  // Mostrar lista de archivos CSV
                    Expanded(
                      child: ListView.builder(
                        itemCount: _csvFiles.length,
                        itemBuilder: (context, index) {
                          final file = _csvFiles[index];
                          return ListTile(
                            title: Text(
                              file.name ?? 'Sin nombre',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedFileId = file.id;
                              });
                            },
                            selected: _selectedFileId == file.id,
                            selectedTileColor: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedFileId == null || _isLoading
                            ? null
                            : () async {
                          setState(() {
                            _isLoading = true;
                          });

                          // Restaurar los datos desde el archivo seleccionado
                          bool isRestored = await _controller.restoreDataFromDrive(
                            context,
                            _selectedFileId!,
                          );

                          setState(() {
                            _isLoading = false;
                          });
                          if (!context.mounted) return;

                          if (isRestored) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Datos restaurados exitosamente')),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Error al restaurar los datos')),
                            );
                          }
                        },
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text(
                          'Restaurar datos desde Google Drive',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
    );
  }
}

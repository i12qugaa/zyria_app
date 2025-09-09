import 'package:flutter/material.dart';
import 'package:finanzas_app/controllers/drive_controller.dart';
import 'package:provider/provider.dart';
import '../controllers/home_controller.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_appbar_actions.dart';

class DriveUploadView extends StatefulWidget {
  const DriveUploadView({super.key});

  @override
  DriveUploadViewState createState() => DriveUploadViewState();
}

class DriveUploadViewState extends State<DriveUploadView> {
  final Map<String, bool> _selected = {
    'gasto': false,
    'ingreso': false,
    'ahorro': false,
    'activos': false,
    'deudas': false,
  };

  final DriveController _controller = DriveController();

  void _uploadSelectedData() {
    List<String> tiposSeleccionados = [];

    for (var tipo in _selected.keys) {
      if (_selected[tipo] == true) tiposSeleccionados.add(tipo);
    }

    if (tiposSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos una opción')),
      );
      return;
    }

    _controller.subirDatosDrive(context, tiposSeleccionados);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, homeController, child) {
        return Scaffold(
          appBar: CustomGradientAppBar(
            title: 'Guardar datos',
            actions: [CustomAppBarActions(homeController: homeController)],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '¿Qué desea subir?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: _selected.keys.map((tipo) {
                      return Card(
                        color: Colors.grey.shade100,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: CheckboxListTile(
                          title: Text(
                            tipo[0].toUpperCase() + tipo.substring(1),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          value: _selected[tipo],
                          activeColor: Colors.blueAccent,
                          onChanged: (bool? seleccionado) {
                            setState(() {
                              _selected[tipo] = seleccionado ?? false;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploadSelectedData,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text(
                        'Subir a Google Drive',
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
              ],
            ),
          ),
        );
      },
    );
  }
}

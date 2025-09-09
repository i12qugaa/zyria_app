import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/activos_controller.dart';
import '../controllers/ai_controller.dart';
import '../controllers/categorias_controller.dart';
import '../controllers/deudas_controller.dart';
import '../controllers/movimientos_controller.dart';
import '../controllers/home_controller.dart';
import '../main.dart';
import '../widgets/AiAssistantButton.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_appbar_actions.dart';
import 'aiChat_view.dart';
import '../widgets/chart.dart';
import '../widgets/card.dart';
import 'package:file_picker/file_picker.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with RouteAware {
  bool _initialized = false;
  String _selected = 'days';

  final AiChatController aiController = AiChatController();


  @override
  void didPopNext() {
    Provider.of<HomeController>(context, listen: false).fetchTotals();
    setState(() {
    });
    Provider.of<HomeController>(context, listen: false).fetchTotals();
  }

  @override
  void initState() {
    super.initState();
    final homeController = Provider.of<HomeController>(context, listen: false);

    // Cargar el modo seleccionado guardado
    homeController.loadSelectedMode().then((_) {
      homeController.fetchTotals();
    });

  }

  void _showRangeSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Seleccionar rango"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Días"),
                onTap: () {
                  Provider.of<HomeController>(context, listen: false)
                      .changeTimeRangeMode(TimeRangeMode.day);
                  setState(() {
                    _selected = 'days';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text("Meses"),
                onTap: () {
                  Provider.of<HomeController>(context, listen: false)
                      .changeTimeRangeMode(TimeRangeMode.month);
                  setState(() {
                    _selected = 'months';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text("Años"),
                onTap: () {
                  Provider.of<HomeController>(context, listen: false)
                      .changeTimeRangeMode(TimeRangeMode.year);
                  setState(() {
                    _selected = 'years';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text("Todo"),
                onTap: () {
                  Provider.of<HomeController>(context, listen: false)
                      .changeTimeRangeMode(TimeRangeMode.all);
                  setState(() {
                    _selected = 'all';
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<HomeController>(context, listen: false).fetchTotals();
      });
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  final formatoMoneda = NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2);

  Future<void> pickAndReadCsvFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        print("Contenido del CSV:\n$content");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Archivo importado correctamente.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se seleccionó ningún archivo.")),
        );
      }
    } catch (e) {
      print("Error al leer el archivo CSV: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, homeController, child) {

        String formattedDate;
        if (homeController.selectedMode == TimeRangeMode.day) {
          formattedDate = DateFormat("d 'de' MMMM 'del' yyyy", 'es').format(homeController.selectedDate);
        } else if (homeController.selectedMode == TimeRangeMode.month) {
          String monthFormatted = DateFormat("MMMM yyyy", 'es').format(homeController.selectedDate);
          formattedDate = monthFormatted[0].toUpperCase() + monthFormatted.substring(1);
        } else if (homeController.selectedMode == TimeRangeMode.year){
          formattedDate = DateFormat('yyyy').format(homeController.selectedDate);
        } else {
          formattedDate = 'Todo';
        }

        double flujoEfectivoNeto = homeController.totalIngresos - homeController.totalGastos;

        return Scaffold(
          appBar: CustomGradientAppBar(title: '       Zyria', actions: [ CustomAppBarActions(homeController: homeController) ],),

          body: GestureDetector(
            onHorizontalDragEnd: (details) {
              // Cambio de días
              if (homeController.selectedMode == TimeRangeMode.day) {
                // Si se desliza hacia la izquierda (ir al siguiente día)
                if (details.primaryVelocity! < 0) {
                  homeController.changeDay(1);  // Cambiar al siguiente día
                }
                // Si se desliza hacia la derecha (ir al día anterior)
                else if (details.primaryVelocity! > 0) {
                  homeController.changeDay(-1);  // Cambiar al día anterior
                }
              }
              // Cambio de meses
              else if (homeController.selectedMode == TimeRangeMode.month) {
                if (details.primaryVelocity! < 0) {
                  homeController.changeMonth(1);  // Cambiar al siguiente mes
                } else if (details.primaryVelocity! > 0) {
                  homeController.changeMonth(-1);  // Cambiar al mes anterior
                }
              }
              // Cambio de años
              else if (homeController.selectedMode == TimeRangeMode.year) {
                if (details.primaryVelocity! < 0) {
                  homeController.changeYear(1);  // Cambiar al siguiente año
                } else if (details.primaryVelocity! > 0) {
                  homeController.changeYear(-1);  // Cambiar al año anterior
                }
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Selección de mes con flechas y fondo degradado
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.green.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0.5, 0.5),
                                blurRadius: 1.5,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _showRangeSelectorDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      homeController.isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                        formatoMoneda.format(flujoEfectivoNeto),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: flujoEfectivoNeto < 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Center(
                  child: Text(
                    "flujo efectivo neto",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Gráfico
                SizedBox(
                  width: double.infinity,
                  child: ChartWidget(
                    key: ValueKey('${homeController.totalIngresos.toStringAsFixed(2)}-${homeController.totalGastos.toStringAsFixed(2)}'),
                    selectedDate: homeController.selectedDate,
                    selectedMode: homeController.selectedMode,
                  ),
                ),
                const SizedBox(height: 10),
                // Tarjetas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CardWidget(
                        title: 'Ingresos',
                        color: Colors.blue,
                        onTap: () => Provider.of<MovimientosController>(context, listen: false)
                            .navigateToIngresos(
                          context,
                          homeController.selectedDate.day,
                          homeController.selectedDate.month,
                          homeController.selectedDate.year,
                          homeController.selectedMode,
                        ),
                        onAddTap: () {
                          final categoriasController = CategoriasController();
                          categoriasController.loadCategoriasAndNavigate(
                            context,
                            'ingreso',
                              homeController.selectedDate.day,
                              homeController.selectedDate.month,
                              homeController.selectedDate.year,
                              homeController.selectedMode,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CardWidget(
                        title: 'Gastos',
                        color: Colors.red,
                        onTap: () => Provider.of<MovimientosController>(context, listen: false)
                            .navigateToGastos(
                          context,
                          homeController.selectedDate.day,
                          homeController.selectedDate.month,
                          homeController.selectedDate.year,
                          homeController.selectedMode,
                        ),
                        onAddTap: () {
                          final categoriasController = CategoriasController();
                          categoriasController.loadCategoriasAndNavigate(
                            context,
                            'gasto',
                            homeController.selectedDate.day,
                            homeController.selectedDate.month,
                            homeController.selectedDate.year,
                            homeController.selectedMode,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CardWidget(
                        title: 'Activos',
                        color: Colors.green,
                        onTap: () => Provider.of<ActivosController>(context, listen: false)
                            .navigateToActivos(
                          context,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CardWidget(
                        title: 'Deudas',
                        color: Colors.yellow,
                        onTap: () => Provider.of<DeudasController>(context, listen: false)
                            .navigateToDeudas(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AiAssistantButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

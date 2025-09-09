import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/categorias_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/movimientos_controller.dart';
import '../../models/movimiento_class.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_appbar_actions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IngresosView extends StatefulWidget {
  final double totalIngresos;
  final int selectedDay;
  final int selectedMonth;
  final int selectedYear;
  final TimeRangeMode selectedMode;

  const IngresosView({
    super.key,
    required this.totalIngresos,
    required this.selectedDay,
    required this.selectedMonth,
    required this.selectedYear,
    required this.selectedMode,
  });

  @override
  IngresosViewState createState() => IngresosViewState();
}

class IngresosViewState extends State<IngresosView> {
  final MovimientosController _ingresosController = MovimientosController();
  final CategoriasController _categoriasController = CategoriasController();
  late int _selectedMonth;
  late int _selectedYear;
  late int _selectedDay;
  String _selected = 'days';

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDay;
    _selectedMonth = widget.selectedMonth;
    _selectedYear = widget.selectedYear;
    _cargarMovimientosControlador();
  }

  void _cargarMovimientosControlador() {
    final homeController = context.read<HomeController>();
    final movimientosController = context.read<MovimientosController>();

    final selectedDate = homeController.selectedDate;
    final selectedMode = homeController.selectedMode;

    movimientosController.cargarMovimientos(
      day: selectedDate.day,
      month: selectedDate.month,
      year: selectedDate.year,
      tipo: 'ingreso',
      selectedMode: selectedMode,
    );
  }

  void _deleteIngreso(Movimiento ingreso) {
    _ingresosController.confirmarEliminarMovimiento(context: context,
        movimiento: ingreso,
        onSuccess: _cargarMovimientosControlador);
  }

  final formatoMoneda = NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2);

  Future<void> _showDialog({required Movimiento movimientoExistente}) async {
    final _amountController = TextEditingController(text: movimientoExistente.amount.toString());
    final _descripcionController = TextEditingController(text: movimientoExistente.description);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Lógica para cambiar el título según el tipo de movimiento
            String titulo;
            if (movimientoExistente.tipo == "ahorro") {
              titulo = "Editar Ahorro";
            } else if (movimientoExistente.tipo == "gasto") {
              titulo = "Editar Gasto";
            } else if (movimientoExistente.tipo == "ingreso") {
              titulo = "Editar Ingreso";
            } else {
              titulo = "Editar Movimiento";
            }

            return AlertDialog(
              title: Text(titulo),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad (€)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amountText = _amountController.text.trim();
                    final descripcion = _descripcionController.text.trim();

                    if (amountText.isEmpty) return;

                    final amount = double.tryParse(amountText);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingrese un monto válido')),
                      );
                      return;
                    }

                    final updatedGasto = Movimiento(
                      id: movimientoExistente.id,
                      amount: amount,
                      description: descripcion,
                      date: movimientoExistente.date,
                      occurrenceDate: movimientoExistente.occurrenceDate,
                      tipo: movimientoExistente.tipo,
                      categoriaId: movimientoExistente.categoriaId,
                    );

                    await _ingresosController.updateMovimiento(updatedGasto);
                    _cargarMovimientosControlador();
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
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
                      .changeTimeRangeMode(TimeRangeMode.day); // Actualiza el modo
                  setState(() {
                    _selected = 'days';
                  });
                  _cargarMovimientosControlador();
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
                  _cargarMovimientosControlador();
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
                  _cargarMovimientosControlador();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text("Todo"),
                onTap: () {
                  Provider.of<HomeController>(context, listen: false)
                      .changeTimeRangeMode(TimeRangeMode.all); // Actualiza el modo
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
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
        builder: (context, homeController, child) {
          String formattedDate;
          if (homeController.selectedMode == TimeRangeMode.day) {
            formattedDate = DateFormat("d 'de' MMMM 'del' yyyy", 'es').format(
                homeController.selectedDate);
          } else if (homeController.selectedMode == TimeRangeMode.month) {
            String monthFormatted = DateFormat("MMMM yyyy", 'es').format(
                homeController.selectedDate);
            formattedDate =
                monthFormatted[0].toUpperCase() + monthFormatted.substring(1);
          } else if (homeController.selectedMode == TimeRangeMode.year){
            formattedDate = DateFormat('yyyy').format(homeController.selectedDate);
          } else {
            formattedDate = 'Todo';
          }

          double flujoEfectivoNeto = homeController.totalIngresos -
              homeController.totalGastos;

          return Scaffold(
            appBar: CustomGradientAppBar(title: 'Ingresos', actions: [ CustomAppBarActions(homeController: homeController) ],),
            body: GestureDetector(
              onHorizontalDragEnd: (details) {
                const int velocityThreshold = 500;

                if (homeController.selectedMode == TimeRangeMode.day) {
                  if (details.primaryVelocity! < -velocityThreshold) {
                    homeController.changeDay(1);
                  } else if (details.primaryVelocity! > velocityThreshold) {
                    homeController.changeDay(-1);
                  }
                } else if (homeController.selectedMode == TimeRangeMode.month) {
                  if (details.primaryVelocity! < -velocityThreshold) {
                    homeController.changeMonth(1);
                  } else if (details.primaryVelocity! > velocityThreshold) {
                    homeController.changeMonth(-1);
                  }
                } else if (homeController.selectedMode == TimeRangeMode.year) {
                  if (details.primaryVelocity! < -velocityThreshold) {
                    homeController.changeYear(1);
                  } else if (details.primaryVelocity! > velocityThreshold) {
                    homeController.changeYear(-1);
                  }
                }

                // Cargar datos solo si hubo un cambio real
                if (details.primaryVelocity!.abs() > velocityThreshold) {
                  _cargarMovimientosControlador();
                }
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.green.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                            icon: const Icon(Icons.calendar_today, color: Colors.white),
                            onPressed: () => _showRangeSelectorDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ingreso total (fijo)
                  Consumer<MovimientosController>(
                    builder: (context, movimientosController, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1.0),
                        child: Center(
                          child: Container(
                            width: double.infinity, // Ocupará todo el ancho disponible según el padding
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  formatoMoneda.format(movimientosController.totalIngresos),                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Lista de ingresos
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Consumer<MovimientosController>(
                        builder: (context, movimientosController, child) {
                          final ingresosList = movimientosController.ingresosList;

                          if (ingresosList.isEmpty) {
                            return SizedBox(
                              child: Center(
                                child: Text(
                                  'Nada por aquí... ¡agrega tu primer ingreso!',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ingresosList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final ingreso = ingresosList[index];

                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: const Icon(FontAwesomeIcons.handHoldingDollar, color: Colors.white),
                                  ),
                                  title: Text(
                                    '${ingreso.amount.toStringAsFixed(2).replaceAll('.', ',')}€',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    ingreso.date,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        onPressed: () => _showDialog(movimientoExistente: ingreso),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _deleteIngreso(ingreso),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Row(
                                              children: [
                                                const Text(
                                                  'Categoría: ',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                FutureBuilder<String?>(
                                                  future: _categoriasController.getNombreCategoriaById(ingreso.categoriaId!),
                                                  builder: (context, snapshot) {
                                                    return Text(
                                                      snapshot.data ?? 'Sin categoría',
                                                      textAlign: TextAlign.justify,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Text(
                                            'Descripción:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            ingreso.description.isNotEmpty
                                                ? ingreso.description
                                                : 'Sin descripción',
                                            textAlign: TextAlign.justify,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: const Color(0xFF1976D2),
              onPressed: () {
                final categoriasController = CategoriasController();
                categoriasController.loadCategoriasAndNavigate(
                  context,
                  'ingreso',
                  _selectedDay,
                  _selectedMonth,
                  _selectedYear,
                  homeController.selectedMode,

                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        }
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../controllers/categorias_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/movimientos_controller.dart';
import '../../models/movimiento_class.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_appbar_actions.dart';
import 'package:provider/provider.dart';

class GastosView extends StatefulWidget {
  final double totalGastos;
  final int selectedDay;
  final int selectedMonth;
  final int selectedYear;
  final TimeRangeMode selectedMode;

  const GastosView({
    super.key,
    required this.totalGastos,
    required this.selectedDay,
    required this.selectedMonth,
    required this.selectedYear,
    required this.selectedMode,
  });

  @override
  GastosViewState createState() => GastosViewState();
}

class GastosViewState extends State<GastosView> {
  final MovimientosController _movimientosController = MovimientosController();
  final CategoriasController _categoriasController = CategoriasController();
  late int _selectedMonth;
  late int _selectedYear;
  late int _selectedDay;
  late DateTime selectedDate;
  late TimeRangeMode selectedMode;

  String _selected = 'days';

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDay;
    _selectedYear = widget.selectedYear;
    _selectedMonth = widget.selectedMonth;
    selectedDate = DateTime(widget.selectedYear, widget.selectedMonth, widget.selectedDay);
    selectedMode = widget.selectedMode;
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
      tipo: 'gasto',
      selectedMode: selectedMode,
    );

    movimientosController.cargarMovimientos(
      day: selectedDate.day,
      month: selectedDate.month,
      year: selectedDate.year,
      tipo: 'ahorro',
      selectedMode: selectedMode,
    );
  }

  void _delete(Movimiento m) {
    _movimientosController.confirmarEliminarMovimiento(context: context,movimiento: m, onSuccess: _cargarMovimientosControlador);
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
              titulo = "Editar Movimiento"; // En caso de que no coincida con ninguno de los tipos anteriores
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

                    final updatedMovimiento = Movimiento(
                      id: movimientoExistente.id,
                      amount: amount,
                      description: descripcion,
                      date: movimientoExistente.date,
                      occurrenceDate: movimientoExistente.occurrenceDate,
                      tipo: movimientoExistente.tipo,
                      categoriaId: movimientoExistente.categoriaId,
                    );

                    await _movimientosController.updateMovimiento(updatedMovimiento);
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
                      .changeTimeRangeMode(TimeRangeMode.day);
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

          return Scaffold(
            appBar: CustomGradientAppBar(
              title: 'Gastos',
              actions: [CustomAppBarActions(homeController: homeController)],
            ),
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

                if (details.primaryVelocity!.abs() > velocityThreshold) {
                  _cargarMovimientosControlador();
                }
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Fecha (fija)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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

                  Consumer<MovimientosController>(
                    builder: (context, movimientosController, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.0),
                        child: Center(
                          child: Container(
                            width: double.infinity,
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
                                  formatoMoneda.format(movimientosController.totalGastos),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Consumer<MovimientosController>(
                    builder: (context, movimientosController, child) {
                      final ahorros = movimientosController.ahorrosList;
                      return Card(
                        elevation: 3,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.green.shade400, width: 1.5),
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.savings,
                            color: Colors.green.shade700,
                            size: 30,
                          ),
                          title: Text(
                            'Ahorraste: ${formatoMoneda.format(movimientosController.totalAhorros)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          trailing: Icon(
                            Icons.expand_more,
                            color: Colors.green.shade700,
                          ),
                          children: [
                            if (ahorros.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No tienes ahorros registrados.',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: ahorros.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final ahorro = ahorros[index];
                                    return Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      color: Colors.green.shade50,
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                        leading: const Icon(Icons.savings, color: Colors.green),
                                        title: Text(
                                          formatoMoneda.format(ahorro.amount),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              onPressed: () => _showDialog(movimientoExistente: ahorro),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _delete(ahorro),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: RichText(
                                                text: TextSpan(
                                                  text: 'Descripción: ',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                                  children: <TextSpan>[
                                                    TextSpan(
                                                      text: ahorro.description,
                                                      style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black54),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final categoriasController = CategoriasController();
                                    categoriasController.loadCategoriasAndNavigate(
                                      context,
                                      'ahorro',
                                      _selectedDay,
                                      _selectedMonth,
                                      _selectedYear,
                                      homeController.selectedMode,
                                    );
                                  },
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                                  label: const Text(
                                    'Añadir',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),



                  const SizedBox(height: 16),
                  Consumer<MovimientosController>(
                    builder: (context, movimientosController, child) {
                      final gastos = movimientosController.gastosList;

                      if (gastos.isEmpty) {
                        return Center(
                          child: Text(
                            'Nada por aquí... ¡agrega tu primer gasto!',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: gastos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final gasto = gastos[index];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: const Icon(Icons.attach_money, color: Colors.white),
                              ),
                              title: Text(
                                '${gasto.amount.toStringAsFixed(2).replaceAll('.', ',')}€',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                gasto.date,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => _showDialog(movimientoExistente: gasto),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _delete(gasto),
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
                                              future: _categoriasController.getNombreCategoriaById(gasto.categoriaId!),
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
                                        gasto.description.isNotEmpty ? gasto.description : 'Sin descripción',
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
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: const Color(0xFF1976D2),
              onPressed: () {
                final categoriasController = CategoriasController();
                categoriasController.loadCategoriasAndNavigate(
                  context,
                  'gasto',
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
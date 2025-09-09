import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/movimientos_controller.dart';
import '../../models/category_class.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_appbar_actions.dart';

class AddGastoView extends StatefulWidget {
  final List<Categoria> categorias;
  final int? day;
  final int? month;
  final int? year;
  final TimeRangeMode selectedMode;

  AddGastoView({required this.categorias, this.day, this.month, this.year, required this.selectedMode});

  @override
  _AddGastoViewState createState() => _AddGastoViewState();
}

class _AddGastoViewState extends State<AddGastoView> {
  final MovimientosController _gastosController = MovimientosController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Categoria? _selectedCategoria;

  // Controladores para la fecha seleccionada
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Inicializamos la categoría seleccionada si hay alguna categoría
    _selectedCategoria = widget.categorias.isNotEmpty ? widget.categorias[0] : null;

    // Ajustamos la fecha según el modo seleccionado
    if (widget.selectedMode == TimeRangeMode.day) {
      // Si el modo es "día", usamos el día, mes y año que se pasa si existe
      if (widget.day != null && widget.month != null && widget.year != null) {
        _selectedDate = DateTime(widget.year!, widget.month!, widget.day!);
      } else {
        _selectedDate = DateTime.now();  // Si no se pasa fecha, se usa la actual
      }
    } else if (widget.selectedMode == TimeRangeMode.month) {
      // Si el modo es "mes", usamos el primer día del mes seleccionado
      if (widget.month != null && widget.year != null) {
        _selectedDate = DateTime(widget.year!, widget.month!, 1); // Primer día del mes
      } else {
        _selectedDate = DateTime.now(); // Si no hay fecha, usamos la fecha actual
      }
    } else if (widget.selectedMode == TimeRangeMode.year) {
      // Si el modo es "año", usamos el primer día de enero del año seleccionado
      if (widget.year != null) {
        _selectedDate = DateTime(widget.year!, 1, 1); // 1 de enero del año
      } else {
        _selectedDate = DateTime.now(); // Si no hay año, usamos el año actual
      }
    } else {
      // En caso de que no se reconozca el modo, usamos la fecha actual
      _selectedDate = DateTime.now();
    }
  }


  Future<void> _onSavePressed() async {
    await _gastosController.validateAndAddMovimiento(
      context,
      _amountController.text,
      _descriptionController.text,
      _selectedCategoria?.id,
      _selectedDate.day,
      _selectedDate.month,
      _selectedDate.year,
      'gasto',
    );
  }

  // Metodo para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), // Permite seleccionar fechas desde el año 2000
      lastDate: DateTime(2030), // No permitir fechas futuras
    ) ?? _selectedDate; // Si no se selecciona, mantiene la fecha actual

    setState(() {
      _selectedDate = picked;
    });
  }


  @override
  Widget build(BuildContext context) {
    final homeController = Provider.of<HomeController>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomGradientAppBar(title: 'Añadir gasto', actions: [ CustomAppBarActions(homeController: homeController) ],),

      body: Container(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade300, Colors.green.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${DateFormat("dd/MM/yyyy").format(_selectedDate)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Introduce la cantidad',
                    labelStyle: TextStyle(color: Colors.black87, fontSize: 18),
                    suffixText: '€',
                    suffixStyle: TextStyle(color: Colors.black87, fontSize: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Descripción
                TextField(
                  controller: _descriptionController,
                  keyboardType: TextInputType.text,
                  style: TextStyle(color: Colors.black, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Introduce una descripción',
                    labelStyle: TextStyle(color: Colors.black87, fontSize: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<Categoria>(
                  isExpanded: true,
                  value: _selectedCategoria,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    labelStyle: TextStyle(color: Colors.black87, fontSize: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,  // Borde más grueso y sutil
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: widget.categorias.map((categoria) {
                    return DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria.nombre),
                    );
                  }).toList(),
                  onChanged: (newCategoria) {
                    setState(() {
                      _selectedCategoria = newCategoria;
                    });
                  },
                ),
                SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.green.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _onSavePressed,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Text(
                              'Guardar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

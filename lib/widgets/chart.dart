import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../controllers/categorias_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/movimientos_controller.dart';
import '../models/movimiento_class.dart';
import '../models/category_class.dart';

class ChartWidget extends StatefulWidget {

  final DateTime selectedDate;
  final TimeRangeMode selectedMode;

  const ChartWidget({super.key, required this.selectedDate, required this.selectedMode});


  @override
  ChartWidgetState createState() => ChartWidgetState();
}

class ChartWidgetState extends State<ChartWidget> {
  final CategoriasController _categoriasController = CategoriasController();
  final MovimientosController _controller = MovimientosController();

  List<Movimiento> _gastos = [];
  List<Categoria> _categorias = [];
  double _totalGastos = 0.0;
  double _totalIngresos = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadData();
  }

  // Recargar datos de los gastos al cambiar de mes
  @override
  void didUpdateWidget(covariant ChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate || oldWidget.selectedMode != widget.selectedMode) {
      _loadData();  // Recargar datos si cambia la fecha o el modo
    }
  }

  // Metodo que carga las categorías
  Future<void> _loadCategories() async {
    try {
      final categorias = await _categoriasController.getCategoriasByTipo("gasto");
      if (mounted) {
        setState(() {
          _categorias = categorias;
        });
      }
    } catch (error) {
      debugPrint("Error al cargar categorías: $error");
    }
  }

  // Metodo que carga los datos según el modo seleccionado (día, mes, año)
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // Marcar que los datos están siendo cargados
    });

    try {
      // Cargar los totales y gastos según el modo seleccionado
      if (widget.selectedMode == TimeRangeMode.day) {
        final total = await _controller.getTotalMovimientosByDay(
          year: widget.selectedDate.year,
          month: widget.selectedDate.month,
          day: widget.selectedDate.day,
          tipo: 'gasto',
        );

        final gastos = await _controller.getMovimientosByDay(
          year: widget.selectedDate.year,
          month: widget.selectedDate.month,
          day: widget.selectedDate.day,
          tipo: 'gasto',
        );

        final totalIngresos = await _controller.getTotalMovimientosByDay(
          year: widget.selectedDate.year,
          month: widget.selectedDate.month,
          day: widget.selectedDate.day,
          tipo: 'ingreso',
        );

        if (mounted) {
          setState(() {
            _gastos = gastos;
            _totalGastos = total;
            _totalIngresos = totalIngresos;
            _isLoading = false;
          });
        }
      } else if (widget.selectedMode == TimeRangeMode.month) {
        final total = await _controller.getTotalMovimientosByMonth(
          year: widget.selectedDate.year,
          month: widget.selectedDate.month,
          tipo: 'gasto',
        );

        final gastos = await _controller.getMovimientosByMonth(
          year: widget.selectedDate.year,
          month: widget.selectedDate.month,
          tipo: 'gasto',
        );

        final totalIngresos = await _controller.getTotalMovimientosByMonth(
          year: widget.selectedDate.year,
          month: widget.selectedDate.month,
          tipo: 'ingreso',
        );

        if (mounted) {
          setState(() {
            _gastos = gastos;
            _totalGastos = total;
            _totalIngresos = totalIngresos;
            _isLoading = false;
          });
        }
      } else if (widget.selectedMode == TimeRangeMode.year) {
        final total = await _controller.getTotalMovimientosByYear(
          year: widget.selectedDate.year,
          tipo: 'gasto',
        );

        final gastos = await _controller.getMovimientosByYear(
          year: widget.selectedDate.year,
          tipo: 'gasto',
        );

        final totalIngresos = await _controller.getTotalMovimientosByYear(
          year: widget.selectedDate.year,
          tipo: 'ingreso',
        );

        if (mounted) {
          setState(() {
            _gastos = gastos;
            _totalGastos = total;
            _totalIngresos = totalIngresos;
            _isLoading = false;
          });
        }
      }
      else if (widget.selectedMode == TimeRangeMode.all) {
        final total = await _controller.getTotalAllMovimientos(
          tipo: 'gasto',
        );

        final gastos = await _controller.getMovimientos(
          tipo: 'gasto',
        );

        final totalIngresos = await _controller.getTotalAllMovimientos(
          tipo: 'ingreso',
        );

        if (mounted) {
          setState(() {
            _gastos = gastos;
            _totalGastos = total;
            _totalIngresos = totalIngresos;
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      debugPrint("Error al cargar datos: $error");
      if (mounted) {
        setState(() {
          _gastos = [];
          _totalGastos = 0.0;
          _totalIngresos = 0.0;
          _isLoading = false;
        });
      }
    }
  }

  // Variable para almacenar la categoría seleccionada
  Categoria? _selectedCategoria;
  double _selectedCategoriaGasto = 0.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildChart(),
        if (_isLoading)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // Construcción de la gráfica con los gastos
  Widget _buildChart() {
    final sections = _getGastosSections();

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 85,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                          setState(() {
                            _selectedCategoria = null;
                            _selectedCategoriaGasto = 0.0;
                          });
                          return;
                        }

                        final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        final categorias = _getCategoriesWithData();

                        if (touchedIndex < 0 || touchedIndex >= categorias.length) { // Verificación de rango
                          setState(() {
                            _selectedCategoria = null;
                            _selectedCategoriaGasto = 0.0;
                          });
                          return;
                        }

                        final touchedCategoria = categorias[touchedIndex];
                        final categoriaGastos = _gastos
                            .where((gasto) => gasto.categoriaId == touchedCategoria.id)
                            .fold(0.0, (sum, gasto) => sum + gasto.amount);

                        setState(() {
                          _selectedCategoria = touchedCategoria;
                          _selectedCategoriaGasto = categoriaGastos;
                        });
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${_totalIngresos.toStringAsFixed(2).replaceAll('.', ',')} €",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          "${_totalGastos.toStringAsFixed(2).replaceAll('.', ',')} €",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Mostrar gasto de la categoría seleccionada
          if (_selectedCategoria != null && _selectedCategoriaGasto > 0) // SOLO SI HAY DATOS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(top: 10), // Espacio debajo de la gráfica
              decoration: BoxDecoration(
                color: _selectedCategoria!.color.withOpacity(0.2), // Fondo semitransparente
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${_selectedCategoria!.nombre}: ${_selectedCategoriaGasto.toStringAsFixed(2).replaceAll('.', ',')} €",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _selectedCategoria!.color,
                  shadows: [
                    Shadow(
                      blurRadius: 1.0,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 35,
            children: _getCategoriesWithData().map((categoria) {
              return _buildLegendItem(categoria.color, categoria.nombre);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Metodo que devuelve las secciones de la gráfica
  List<PieChartSectionData> _getGastosSections() {
    if (_totalGastos == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300]!,
          value: 100,
          radius: 45,
          title: "",
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ];
    }

    return _getCategoriesWithData().map((categoria) {
      final categoriaGastos = _gastos
          .where((gasto) => gasto.categoriaId == categoria.id)
          .fold(0.0, (sum, gasto) => sum + gasto.amount);

      final porcentaje = (categoriaGastos / _totalGastos) * 100;

      return PieChartSectionData(
        color: categoria.color,
        value: porcentaje,
        radius: 45,
        title: "${porcentaje.toStringAsFixed(1)}%",
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Filtrar las categorías que tienen datos y ordenarlas
  List<Categoria> _getCategoriesWithData() {
    final categoriasConGastos = _categorias.where((categoria) {
      final categoriaGastos = _gastos
          .where((gasto) => gasto.categoriaId == categoria.id)
          .fold(0.0, (sum, gasto) => sum + gasto.amount);

      return categoriaGastos > 0; // Solo incluir categorías con algún gasto
    }).toList();

    categoriasConGastos.sort((a, b) => a.nombre.compareTo(b.nombre));

    return categoriasConGastos;
  }

  // Metodo que construye los elementos de la leyenda
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
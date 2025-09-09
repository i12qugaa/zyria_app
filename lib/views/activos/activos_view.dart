import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../controllers/activos_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/activo_class.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_appbar_actions.dart';
import 'package:intl/intl.dart';

class ActivosView extends StatelessWidget {
  final double totalActivos;
  final List<Activo> activos;
  final Map<TipoActivo, double> totalesPorCategoria;
  final double rentabilidadTotal;
  final double totalCatastral;



  ActivosView({
    Key? key,
    required this.totalActivos,
    required this.activos,
    required this.totalesPorCategoria,
    required this.rentabilidadTotal,
    required this.totalCatastral,
  }) : super(key: key);


  final formatoMoneda = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );

  final formatoDecimal = NumberFormat.decimalPattern('es_ES');


  @override
  Widget build(BuildContext context) {

    final homeController = Provider.of<HomeController>(context);

    final List<_CategoriaActivo> categorias = [
      _CategoriaActivo(
        "Acciones y ETFs",
        Icons.show_chart,
        Colors.green,
        totalesPorCategoria[TipoActivo.accionesEtfs] ?? 0.0,
      ),
      _CategoriaActivo(
        "Fondos inversión",
        Icons.attach_money,
        Colors.blue,
        totalesPorCategoria[TipoActivo.fondosInversion] ?? 0.0,
      ),
      _CategoriaActivo(
        "Inmobiliario",
        Icons.house,
        Colors.orange,
        totalCatastral ?? 0.0,
      ),

      _CategoriaActivo(
        "Criptomonedas",
        Icons.currency_bitcoin,
        Colors.yellow,
        totalesPorCategoria[TipoActivo.criptomonedas] ?? 0.0,
      ),
    ];

    return Scaffold(
      appBar: CustomGradientAppBar(title: 'Activos', actions: [ CustomAppBarActions(homeController: homeController) ],),

      body: SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          formatoMoneda.format(totalActivos),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${rentabilidadTotal >= 0 ? '+' : ''}${formatoDecimal.format(rentabilidadTotal)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: rentabilidadTotal >= 0 ? Colors.blue : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.sync, size: 28),
                        color: Colors.black87,
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Actualizando valores...')),
                          );
                          await ActivosController().actualizarValoresActuales(context);
                          await ActivosController().navigateToActivos(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Valores actualizados')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 45,
                    borderData: FlBorderData(show: false),
                    sections: totalActivos == 0
                        ? [
                      PieChartSectionData(
                        value: 100,
                        color: Colors.grey[300],
                        title: '',
                        radius: 60,
                      ),
                    ]
                        : categorias.map((categoria) {
                      return PieChartSectionData(
                        value: categoria.valor,
                        color: categoria.color,
                        title: totalActivos > 0
                            ? '${(categoria.valor / totalActivos * 100).toStringAsFixed(1)}%'
                            : '0%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 0,
                mainAxisSpacing: 6,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: categorias.map((categoria) => _buildCard(context, categoria)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCard(BuildContext context, _CategoriaActivo categoria) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          if (categoria.nombre == "Acciones y ETFs") {
            await ActivosController().navigateToAccionesEtfs(context);
          }
          else if (categoria.nombre == "Criptomonedas"){
            await ActivosController().navigateToCriptomonedas(context);
          }else if (categoria.nombre == "Fondos inversión"){
            await ActivosController().navigateToFondosInversion(context);
          } else if (categoria.nombre == "Inmobiliario"){
            await ActivosController().navigateToInmobiliario(context);
          }
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 140, minWidth: 170),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                categoria.color.withOpacity(0.2),
                categoria.color.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: categoria.color.withOpacity(0.15),
                child: Icon(categoria.icono, color: categoria.color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                categoria.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: categoria.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatoMoneda.format(categoria.valor),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriaActivo {
  final String nombre;
  final IconData icono;
  final Color color;
  final double valor;

  _CategoriaActivo(this.nombre, this.icono, this.color, this.valor);
}
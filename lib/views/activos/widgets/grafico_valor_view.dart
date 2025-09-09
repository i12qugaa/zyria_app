import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../controllers/home_controller.dart';
import '../../../models/valorHistorico_class.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/custom_appbar_actions.dart';
import 'package:provider/provider.dart';

class GraficoValorView extends StatelessWidget {
  final List<ValorHistorico> historial;

  const GraficoValorView({super.key, required this.historial});



  @override
  Widget build(BuildContext context) {
    final homeController = Provider.of<HomeController>(context);
    if (historial.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Gráfico de Valor")),
        body: const Center(child: Text("No hay datos históricos disponibles.")),
      );
    }

    final sortedHistorial = List<ValorHistorico>.from(historial)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));


    final maxValor = [
      ...sortedHistorial.map((e) => e.valorCompraPromedio),
      ...sortedHistorial.map((e) => e.valorMercadoActual)
    ].reduce((a, b) => a > b ? a : b);

    final margenSuperior = maxValor * 0.1; // 10% de espacio arriba

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Gráfico',
        actions: [CustomAppBarActions(homeController: homeController)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Evolución del valor", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendDot(Colors.purple),
                const SizedBox(width: 8),
                const Text("Valor Compra Promedio"),
                const SizedBox(width: 16),
                _buildLegendDot(Colors.blue),
                const SizedBox(width: 8),
                const Text("Valor Mercado Actual"),
              ],
            ),
            const SizedBox(height: 16),


            SizedBox(
              height: 500,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxValor + margenSuperior,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: (sortedHistorial.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedHistorial.length) {
                            final fecha = sortedHistorial[index].fecha;
                            return Text("${fecha.day}/${fecha.month}");
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItems: (touchedSpots) {
                        return List.generate(touchedSpots.length, (i) {
                          final spot = touchedSpots[i];
                          final index = spot.x.toInt();
                          final fecha = sortedHistorial[index].fecha;
                          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(fecha);

                          final label = spot.bar.color == Colors.purple ? 'Compra' : 'Mercado';

                          final title = i == 0
                              ? '$formattedDate\n$label: ${spot.y.toStringAsFixed(2)}'
                              : '$label: ${spot.y.toStringAsFixed(2)}';

                          return LineTooltipItem(
                            title,
                            const TextStyle(color: Colors.white),
                          );
                        });

                      },
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < sortedHistorial.length; i++)
                          FlSpot(i.toDouble(), sortedHistorial[i].valorCompraPromedio),
                      ],
                      isCurved: false,
                      color: Colors.purple,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < sortedHistorial.length; i++)
                          FlSpot(i.toDouble(), sortedHistorial[i].valorMercadoActual),
                      ],
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

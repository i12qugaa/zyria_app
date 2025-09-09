import 'package:finanzas_app/models/deuda_class.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/deudas_controller.dart';
import '../../controllers/home_controller.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_appbar_actions.dart';
import 'package:intl/intl.dart';


class DeudasView extends StatelessWidget {
  final List<Deuda> deudas;
  final double totalPrestamos;

  DeudasView({
    Key? key,
    required this.deudas,
    required this.totalPrestamos,
  }) : super(key: key);

  final formatoMoneda = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final homeController = Provider.of<HomeController>(context);

    final List<_CategoriaDeuda> categorias = [

      _CategoriaDeuda(
        "Préstamos",
        Icons.account_balance,
        Colors.blue,
        totalPrestamos,
      ),
    ];

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Deudas',
        actions: [CustomAppBarActions(homeController: homeController)],
      ),
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
                          formatoMoneda.format(totalPrestamos),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 0,
                mainAxisSpacing: 6,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children:
                categorias.map((categoria) => _buildCard(context, categoria)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _CategoriaDeuda categoria) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final controller = DeudasController();
          if (categoria.nombre == "Préstamos") {
            await controller.navigateToPrestamos(context);
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

class _CategoriaDeuda {
  final String nombre;
  final IconData icono;
  final Color color;
  final double valor;

  _CategoriaDeuda(this.nombre, this.icono, this.color, this.valor);
}


import 'package:finanzas_app/controllers/deudas_controller.dart';
import 'package:finanzas_app/models/pagosDeuda_class.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/activos_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/deuda_class.dart';
import '../../models/operacion_class.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_appbar_actions.dart';
import 'package:provider/provider.dart';

class PrestamosView extends StatefulWidget {
  final List<Deuda> prestamos;
  final double totalPrestamos;

  const PrestamosView({
    Key? key,
    required this.prestamos,
    required this.totalPrestamos,
  }) : super(key: key);

  @override
  State<PrestamosView> createState() => _PrestamosViewState();
}

class _PrestamosViewState extends State<PrestamosView> {
  final formatoMoneda = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final homeController = Provider.of<HomeController>(context);

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Préstamos',
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
                          formatoMoneda.format(widget.totalPrestamos),
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
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: FutureBuilder<List<Deuda>>(
                  future: DeudasController().obtenerTodasLasDeudas(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final deudas = snapshot.data!;
                    final prestamos = deudas
                        .where((a) => a.tipo == TipoDeuda.prestamo)
                        .toList();

                    return prestamos.isEmpty
                        ? const Center(child: Text("Sin datos"))
                        : ListView.builder(
                      itemCount: prestamos.length,
                      itemBuilder: (context, index) {
                        final deuda = prestamos[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: const Icon(Icons.account_balance, color: Colors.blue),
                            title: Text(
                              deuda.entidad,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              formatoMoneda.format(deuda.saldoPendiente),
                              style: const TextStyle(fontSize: 16, color: Colors.green),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => mostrarDetalleDeuda(context, deuda),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        onPressed: () async {
          final resultado = await _mostrarDialogoNuevoPrestamo(context);
          if (resultado == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Mostrar el diálogo para añadir un nuevo activo
  Future<bool?> _mostrarDialogoNuevoPrestamo(BuildContext context) {
    final entidadCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    final interesCtrl = TextEditingController();
    final plazoCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    String? errorEntidad;
    String? errorValor;
    String? errorInteres;
    String? errorPlazo;

    final controller = DeudasController();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Añadir préstamo"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: entidadCtrl,
                      decoration: InputDecoration(
                        labelText: "Entidad",
                        errorText: errorEntidad,
                      ),
                    ),
                    TextField(
                      controller: valorCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Valor total (€)",
                        errorText: errorValor,
                      ),
                    ),
                    TextField(
                      controller: interesCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Interés anual (%)",
                        errorText: errorInteres,
                      ),
                    ),
                    TextField(
                      controller: plazoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Plazo (meses)",
                        errorText: errorPlazo,
                      ),
                    ),
                    TextField(
                      controller: notasCtrl,
                      decoration: const InputDecoration(labelText: "Notas"),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      errorEntidad = controller.validarEntidad(entidadCtrl.text);
                      errorValor = controller.validarValor(valorCtrl.text);
                      errorInteres = controller.validarInteres(interesCtrl.text);
                      errorPlazo = controller.validarPlazo(plazoCtrl.text);
                    });

                    if (errorEntidad != null ||
                        errorValor != null ||
                        errorInteres != null ||
                        errorPlazo != null) {
                      return;
                    }

                    final double valorTotal = double.parse(valorCtrl.text.replaceAll(',', '.'));
                    final double interesAnual = double.parse(interesCtrl.text.replaceAll(',', '.'));
                    final int plazoMeses = int.parse(plazoCtrl.text);

                    await controller.crearYGuardarPrestamo(
                      entidad: entidadCtrl.text,
                      valorTotal: valorTotal,
                      interesAnual: interesAnual,
                      plazoMeses: plazoMeses,
                      notas: notasCtrl.text,
                    );

                    Navigator.pop(context, true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Préstamo añadido')),
                    );
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void mostrarDetalleDeuda(BuildContext context, Deuda deuda) {
    final formatoFecha = DateFormat('dd/MM/yyyy');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.account_balance, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deuda.entidad,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deuda.tipo.name.toUpperCase(),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatoMoneda.format(deuda.saldoPendiente),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (deuda.valorTotal != null)
                  _infoFila("💰 Cantidad prestada", formatoMoneda.format(deuda.valorTotal)),

                _infoFila("💰 Total a devolver", formatoMoneda.format(deuda.saldoPendiente)),

                _infoFila("📈 Interés anual", "${deuda.interesAnual.toStringAsFixed(2)}%"),

                _infoFila("📅 Plazo", "${deuda.plazoMeses} meses"),

                if (deuda.cuotaMensual != null)
                  _infoFila("📤 Cuota mensual", formatoMoneda.format(deuda.cuotaMensual!)),

                _infoFila("🗓️ Fecha inicio", formatoFecha.format(deuda.fechaInicio)),

                _infoFila("🗓️ Fecha fin", deuda.fechaFin != null ? formatoFecha.format(deuda.fechaFin!) : "No disponible"),

                if (deuda.notas != null && deuda.notas!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📝 Notas: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("📝 Notas"),
                                  content: Text(deuda.notas!),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text("Cerrar"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              deuda.notas!.length > 50
                                  ? "${deuda.notas!.substring(0, 50)}..."
                                  : deuda.notas!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 15.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 0),
                      initiallyExpanded: false,
                      title: const Text(
                        "📋 Pagos",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        if (deuda.historialPagos.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Sin datos"),
                          ),
                        ...deuda.historialPagos.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatearFecha(p.fecha), style: const TextStyle(color: Colors.grey)),
                                    Text("Cantidad: ${formatoMoneda.format(p.cantidad)}"),
                                    if (p.notas != null && p.notas!.isNotEmpty)
                                      Text("Notas: ${p.notas}"),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _mostrarDialogoEditarPago(context, p, deuda.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _mostrarDialogoConfirmarEliminarPago(context, p, deuda),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              final resultado = await _mostrarDialogoNuevoPago(context, deuda);

                              if (resultado == true) {
                                setState(() {});
                              }

                            },
                            icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                            label: const Text("Añadir pago", style: TextStyle(color: Colors.teal)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => _mostrarDialogoEditarPrestamo(context, deuda),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      label: const Text("Editar", style: TextStyle(color: Colors.blue)),
                    ),
                    TextButton.icon(
                      onPressed: () => _mostrarDialogoConfirmarEliminar(context,deuda),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

          ),
        );
      }

    );
  }

  void _mostrarDialogoConfirmarEliminarPago(BuildContext context, PagoDeuda pago, Deuda deuda) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("¿Eliminar pago?"),
          content: const Text("Esta acción no se puede deshacer."),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
                child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                onPressed: () async {

                  final success = await DeudasController().eliminarPago(pago, deuda.id);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  if (success) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Operación eliminada exitosamente")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No se pudo eliminar la operación")),
                    );
                  }
                }
            ),
          ],
        );
      },
    );
  }



  Future<bool?> _mostrarDialogoNuevoPago(BuildContext context, Deuda deuda) async {
    final cantidadCtrl = TextEditingController();
    final notasCtrl = TextEditingController();
    final fechaCtrl = TextEditingController();

    String? errorCantidad;

    final controller = DeudasController();

    DateTime fechaSeleccionada = DateTime.now();

    fechaCtrl.text = "${fechaSeleccionada.day.toString().padLeft(2, '0')}"
        "/${fechaSeleccionada.month.toString().padLeft(2, '0')}"
        "/${fechaSeleccionada.year}";

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Nuevo Pago"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cantidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Cantidad",
                        errorText: errorCantidad,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notasCtrl,
                      decoration: const InputDecoration(labelText: "Notas"),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: fechaCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Fecha de operación",
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final nuevaFecha = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (nuevaFecha != null) {
                          fechaSeleccionada = nuevaFecha;
                          fechaCtrl.text = "${nuevaFecha.day.toString().padLeft(2, '0')}"
                              "/${nuevaFecha.month.toString().padLeft(2, '0')}"
                              "/${nuevaFecha.year}";
                          setStateDialog(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    setStateDialog(() {
                      errorCantidad = controller.validarCantidad(cantidadCtrl.text);
                    });

                    if (errorCantidad != null) {
                      return;
                    }

                    final cantidad = double.parse(cantidadCtrl.text.replaceAll(',', '.'));

                    final nuevo = PagoDeuda(
                      id: 0,
                      deudaId: deuda.id,
                      fecha: fechaSeleccionada,
                      cantidad: cantidad,
                      notas: notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                    );

                    await controller.agregarPago(deuda.id, nuevo);

                    Navigator.pop(context, true);
                    Navigator.pop(context, true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Pago añadido")),
                    );
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _mostrarDialogoEditarPrestamo(BuildContext context, Deuda deuda) {
    final entidadCtrl = TextEditingController(text: deuda.entidad);
    final valorTotalCtrl = TextEditingController(text: deuda.valorTotal.toString());
    final interesCtrl = TextEditingController(text: deuda.interesAnual.toString());
    final notasCtrl = TextEditingController(text: deuda.notas ?? '');

    String? errorEntidad;
    String? errorValorTotal;
    String? errorInteres;

    final controller = DeudasController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Editar prestamo"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: entidadCtrl,
                      decoration: InputDecoration(
                        labelText: "Entidad",
                        errorText: errorEntidad,
                      ),
                    ),
                    TextField(
                      controller: valorTotalCtrl,
                      decoration: InputDecoration(
                        labelText: "Valor Total a devolver",
                        errorText: errorValorTotal,
                      ),
                    ),
                    TextField(
                      controller: interesCtrl,
                      decoration: InputDecoration(
                        labelText: "Interés",
                        errorText: errorInteres,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: notasCtrl,
                      decoration: const InputDecoration(labelText: "Notas"),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    setStateDialog(() {
                      errorEntidad = controller.validarEntidad(entidadCtrl.text);
                      errorValorTotal = controller.validarValor(valorTotalCtrl.text);
                      errorInteres = controller.validarInteres(interesCtrl.text);
                    });

                    if (errorEntidad != null || errorValorTotal != null || errorInteres != null) {
                      return; // Detener si hay errores
                    }

                    // Aplicar los cambios al objeto activo
                    deuda.entidad = entidadCtrl.text.trim();
                    deuda.valorTotal = double.parse(
                      valorTotalCtrl.text.trim().replaceAll(',', '.'),
                    );

                    deuda.interesAnual = double.parse(
                      interesCtrl.text.trim().replaceAll(',', '.'),
                    );

                    deuda.notas = notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim();

                    await controller.actualizarDeuda(deuda);

                    Navigator.pop(context, true);
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prestamo actualizado')),
                    );
                    setState(() {});
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _mostrarDialogoEditarPago(BuildContext context, PagoDeuda p, int idDeuda) {
    final cantidadCtrl = TextEditingController(text: p.cantidad.toString());
    final fechaCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(p.fecha));
    final notasCtrl = TextEditingController(text: p.notas ?? '');

    String? errorCantidad;
    DateTime fechaSeleccionada = p.fecha;

    final controller = DeudasController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Editar operación"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: cantidadCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Cantidad",
                        errorText: errorCantidad,
                      ),
                    ),
                    TextField(
                      controller: fechaCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: "Fecha"),
                      onTap: () async {
                        final nuevaFecha = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (nuevaFecha != null) {
                          fechaSeleccionada = nuevaFecha;
                          fechaCtrl.text = DateFormat('yyyy-MM-dd').format(nuevaFecha);
                          setStateDialog(() {});
                        }
                      },
                    ),
                    TextField(
                      controller: notasCtrl,
                      decoration: const InputDecoration(labelText: "Notas"),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    setStateDialog(() {
                      errorCantidad = controller.validarCantidad(cantidadCtrl.text);
                    });

                    if (errorCantidad != null) {
                      return; // No continuar si hay errores
                    }

                    final nuevaCantidad = double.parse(cantidadCtrl.text.trim().replaceAll(',', '.'));

                    p.cantidad = nuevaCantidad;
                    p.fecha = fechaSeleccionada;
                    p.notas = notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim();

                    await controller.actualizarPago(p);

                    Navigator.of(context).pop();
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Operación actualizada')),
                    );
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }



  void _mostrarDialogoConfirmarEliminar(BuildContext context, Deuda deuda) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar prestamo?"),
        content: Text("¿Estás seguro de que deseas eliminar \"${deuda.entidad}\"? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await DeudasController().eliminarDeuda(deuda.id!);
              Navigator.pop(context);
              Navigator.pop(context); // cerrar el bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Prestamo eliminado")),
              );
              setState(() {});
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  Widget _infoFila(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarOperacion(BuildContext context, Operacion operacion, int idActivo) async {
    // Eliminar la operación de la base de datos
    final bool success = await ActivosController().eliminarOperacion(operacion, idActivo);

    // Si la eliminación fue exitosa, actualizamos el estado
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Operación eliminada exitosamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hubo un error al eliminar la operación")),
      );
    }

    setState(() {});
  }


  String _formatearFecha(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
  }
}

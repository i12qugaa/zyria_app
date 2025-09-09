import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/activos_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/activo_class.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_appbar_actions.dart';
import 'widgets/grafico_valor_view.dart';
import 'package:provider/provider.dart';

class InmobiliarioView extends StatefulWidget {
  final double rentabilidadTotal;
  final double totalActual;
  final double totalCatastral;

  const InmobiliarioView({
    super.key,
    required this.rentabilidadTotal,
    required this.totalActual, required this.totalCatastral,
  });

  @override
  State<InmobiliarioView> createState() => _InmobiliarioViewState();
}

class _InmobiliarioViewState extends State<InmobiliarioView> {
  @override

  final formatoMoneda = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );

  final formatoDecimal = NumberFormat.decimalPattern('es_ES');


  Widget build(BuildContext context) {
    final homeController = Provider.of<HomeController>(context);
    return Scaffold(
      appBar: CustomGradientAppBar(title: 'Inmobiliario', actions: [ CustomAppBarActions(homeController: homeController) ],),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📊 Card superior con rentabilidad y total actual
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 5),
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          formatoMoneda.format(widget.totalCatastral),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${widget.rentabilidadTotal >= 0 ? '+' : ''}${formatoDecimal.format(widget.rentabilidadTotal)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.rentabilidadTotal >= 0 ? Colors.blue : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery
                    .of(context)
                    .size
                    .height * 0.7,
                child: FutureBuilder<List<Activo>>(
                  future: ActivosController().obtenerTodosLosActivos(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final activos = snapshot.data!;
                    final inmobiliario = activos
                        .where((a) => a.tipo == TipoActivo.inmobiliario)
                        .toList();

                    return inmobiliario.isEmpty
                        ? const Center(
                        child: Text("Sin datos"))
                        : ListView.builder(
                      itemCount: inmobiliario.length,
                      itemBuilder: (context, index) {
                        final activo = inmobiliario[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            leading: const Icon(
                                Icons.house, color: Colors.blue),
                            title: Text(
                              activo.nombre,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "${formatoMoneda.format(
                                  activo.valorCatastral)}",
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.green),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => mostrarDetalleActivo(context, activo),
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
          final resultado = await _mostrarDialogoNuevoActivo(context);
          if (resultado == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<bool?> _mostrarDialogoNuevoActivo(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final ingresoMensualCtrl = TextEditingController();
    final gastoMensualCtrl = TextEditingController();
    final gastoMantenimientoAnualCtrl = TextEditingController();
    final valorCatastralCtrl = TextEditingController();
    final hipotecaPendienteCtrl = TextEditingController();
    final impuestoAnualCtrl = TextEditingController();
    final ubicacionCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    String? errorNombre;
    String? errorIngresoMensual;
    String? errorGastoMensual;
    String? errorGastoMantenimientoAnual;
    String? errorValorCatastral;
    String? errorHipotecaPendiente;
    String? errorImpuestoAnual;
    String? errorEstadoPropiedad;

    final controller = ActivosController();
    EstadoPropiedad? estadoSeleccionado;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          bool esAlquilado = estadoSeleccionado == EstadoPropiedad.alquilado;
          bool esUsoPropio = estadoSeleccionado == EstadoPropiedad.usoPropio;
          bool esEnVenta = estadoSeleccionado == EstadoPropiedad.enVenta;
          bool esEnPropiedad = estadoSeleccionado == EstadoPropiedad.enPropiedad;

          return AlertDialog(
            title: const Text("Añadir nuevo"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: InputDecoration(
                      labelText: "Nombre",
                      errorText: errorNombre,
                    ),
                  ),
                  DropdownButtonFormField<EstadoPropiedad>(
                    decoration: InputDecoration(
                      labelText: "Estado de la propiedad",
                      errorText: errorEstadoPropiedad,
                    ),
                    value: estadoSeleccionado,
                    onChanged: (EstadoPropiedad? newValue) {
                      setState(() {
                        estadoSeleccionado = newValue;
                        errorEstadoPropiedad = null;
                      });
                    },
                    items: EstadoPropiedad.values.map((estado) {
                      return DropdownMenuItem<EstadoPropiedad>(
                        value: estado,
                        child: Text(estado.descripcion),
                      );
                    }).toList(),
                  ),

                  if (esAlquilado) ...[
                    TextField(
                      controller: ingresoMensualCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Ingreso mensual",
                        errorText: errorIngresoMensual,
                      ),
                    ),
                    TextField(
                      controller: gastoMensualCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Gasto mensual",
                        errorText: errorGastoMensual,
                      ),
                    ),
                  ],

                  if (esAlquilado || esEnPropiedad || esUsoPropio || esEnVenta) ...[
                    TextField(
                      controller: valorCatastralCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Valor catastral",
                        errorText: errorValorCatastral,
                      ),
                    ),
                    TextField(
                      controller: gastoMantenimientoAnualCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Gasto mantenimiento anual",
                        errorText: errorGastoMantenimientoAnual,
                      ),
                    ),
                    TextField(
                      controller: impuestoAnualCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Impuesto anual",
                        errorText: errorImpuestoAnual,
                      ),
                    ),
                    TextField(
                      controller: hipotecaPendienteCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Hipoteca pendiente",
                        errorText: errorHipotecaPendiente,
                      ),
                    ),
                  ],

                  TextField(
                    controller: ubicacionCtrl,
                    decoration: const InputDecoration(labelText: "Ubicación"),
                    maxLines: 1,
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
                    errorNombre = controller.validarNombre(nombreCtrl.text);
                    errorEstadoPropiedad = controller.validarEstadoPropiedad(estadoSeleccionado);
                    if (esAlquilado) {
                      errorIngresoMensual = controller.validarIngresoMensual(ingresoMensualCtrl.text);
                      errorGastoMensual = controller.validarGastoMensual(gastoMensualCtrl.text);
                    } else {
                      errorIngresoMensual = null;
                      errorGastoMensual = null;
                    }

                    if (esAlquilado || esEnPropiedad || esUsoPropio || esEnVenta) {
                      errorValorCatastral = controller.validarValorCatastral(valorCatastralCtrl.text);
                      errorGastoMantenimientoAnual = controller.validarGastoMantenimientoAnual(gastoMantenimientoAnualCtrl.text);
                      errorHipotecaPendiente = controller.validarHipotecaPendiente(hipotecaPendienteCtrl.text);
                      errorImpuestoAnual = controller.validarImpuestoAnual(impuestoAnualCtrl.text);
                    }
                  });

                  if ([
                    errorNombre,
                    errorEstadoPropiedad,
                    errorIngresoMensual,
                    errorGastoMensual,
                    errorValorCatastral,
                    errorGastoMantenimientoAnual,
                    errorHipotecaPendiente,
                    errorImpuestoAnual,
                  ].any((e) => e != null)) {
                    return;
                  }

                  final nuevoActivo = Activo(
                    id: 0,
                    nombre: nombreCtrl.text.trim(),
                    tipo: TipoActivo.inmobiliario,
                    valorActual: double.tryParse(valorCatastralCtrl.text.trim().replaceAll(',', '.')) ?? 0,
                    valorCatastral: double.tryParse(valorCatastralCtrl.text.trim().replaceAll(',', '.')), // <-- agregás esto
                    notas: notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                    historialOperaciones: [],
                    ingresoMensual: esAlquilado ? double.tryParse(ingresoMensualCtrl.text.trim().replaceAll(',', '.')) : null,
                    gastoMensual: esAlquilado ? double.tryParse(gastoMensualCtrl.text.trim().replaceAll(',', '.')) : null,
                    gastosMantenimientoAnual: double.tryParse(gastoMantenimientoAnualCtrl.text.trim().replaceAll(',', '.')),
                    hipotecaPendiente: double.tryParse(hipotecaPendienteCtrl.text.trim().replaceAll(',', '.')),
                    impuestoAnual: double.tryParse(impuestoAnualCtrl.text.trim().replaceAll(',', '.')),
                    ubicacion: ubicacionCtrl.text.trim(),
                    estadoPropiedad: estadoSeleccionado,
                  );

                  await controller.insertarActivo(nuevoActivo);
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Añadido')),
                  );
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        });
      },
    );
  }


  void mostrarDetalleActivo(BuildContext context, Activo activo) {

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
                      child: Icon(Icons.trending_up, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activo.nombre,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              "Estado: ${activo.estadoPropiedad?.descripcion ?? "Sin especificar"}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),


                if (activo.estadoPropiedad != null)
                  _infoFila("🏠 Estado de la propiedad", activo.estadoPropiedad!.descripcion),
                if (activo.ingresoMensual != null)
                  _infoFila("💰 Ingreso mensual", formatoMoneda.format(activo.ingresoMensual)),
                if (activo.gastoMensual != null)
                  _infoFila("📤 Gasto mensual", formatoMoneda.format(activo.gastoMensual)),
                if (activo.gastosMantenimientoAnual != null)
                  _infoFila("🧾 Mantenimiento anual", formatoMoneda.format(activo.gastosMantenimientoAnual)),
                if (activo.valorCatastral != null)
                  _infoFila("🏷️ Valor catastral", formatoMoneda.format(activo.valorCatastral)),
                if (activo.hipotecaPendiente != null)
                  _infoFila("🏦 Hipoteca pendiente", formatoMoneda.format(activo.hipotecaPendiente)),
                if (activo.impuestoAnual != null)
                  _infoFila("💼 Impuesto anual", formatoMoneda.format(activo.impuestoAnual)),
                if (activo.ubicacion != null && activo.ubicacion!.isNotEmpty)
                  _infoFila("📍 Ubicación", activo.ubicacion!),


                if (activo.estadoPropiedad == EstadoPropiedad.alquilado)
                  _infoFila(
                    "📈 Rentabilidad",
                    "${formatoDecimal.format(activo.rentabilidadInmobiliaria)}%",
                  ),

                if (activo.notas != null && activo.notas!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                                  content: Text(activo.notas!),
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
                              activo.notas!.length > 50
                                  ? "${activo.notas!.substring(0, 50)}..."
                                  : activo.notas!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 15.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => _mostrarDialogoEditarActivo(context, activo),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      label: const Text("Editar", style: TextStyle(color: Colors.blue)),
                    ),
                    TextButton.icon(
                      onPressed: () => _mostrarDialogoConfirmarEliminar(context, activo),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Operaciones como ExpansionTile

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }


  void _mostrarDialogoEditarActivo(BuildContext context, Activo activo) {
    final nombreCtrl = TextEditingController(text: activo.nombre);
    final valorCatastralCtrl = TextEditingController(text: activo.valorCatastral?.toString() ?? '');
    final ingresoMensualCtrl = TextEditingController(text: activo.ingresoMensual?.toString() ?? '');
    final gastoMensualCtrl = TextEditingController(text: activo.gastoMensual?.toString() ?? '');
    final gastoMantenimientoAnualCtrl = TextEditingController(text: activo.gastosMantenimientoAnual?.toString() ?? '');
    final hipotecaPendienteCtrl = TextEditingController(text: activo.hipotecaPendiente?.toString() ?? '');
    final impuestoAnualCtrl = TextEditingController(text: activo.impuestoAnual?.toString() ?? '');
    final ubicacionCtrl = TextEditingController(text: activo.ubicacion ?? '');
    final notasCtrl = TextEditingController(text: activo.notas ?? '');

    EstadoPropiedad? estadoSeleccionado = activo.estadoPropiedad;

    String? errorNombre;
    String? errorValor;
    String? errorEstado;
    String? errorIngresoMensual;
    String? errorGastoMensual;
    String? errorGastoMantenimientoAnual;
    String? errorHipotecaPendiente;
    String? errorImpuestoAnual;

    final controller = ActivosController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Editar activo inmobiliario"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreCtrl,
                      decoration: InputDecoration(
                        labelText: "Nombre",
                        errorText: errorNombre,
                      ),
                    ),
                    DropdownButtonFormField<EstadoPropiedad>(
                      decoration: InputDecoration(
                        labelText: "Estado de la propiedad",
                        errorText: errorEstado,
                      ),
                      value: estadoSeleccionado,
                      onChanged: (estado) {
                        setStateDialog(() {
                          estadoSeleccionado = estado;
                          errorEstado = null;
                        });
                      },
                      items: EstadoPropiedad.values.map((estado) {
                        return DropdownMenuItem<EstadoPropiedad>(
                          value: estado,
                          child: Text(estado.descripcion),
                        );
                      }).toList(),
                    ),
                    if (estadoSeleccionado == EstadoPropiedad.alquilado) ...[
                      TextField(
                        controller: ingresoMensualCtrl,
                        decoration: InputDecoration(
                          labelText: "Ingreso mensual",
                          errorText: errorIngresoMensual,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      TextField(
                        controller: gastoMensualCtrl,
                        decoration: InputDecoration(
                          labelText: "Gasto mensual",
                          errorText: errorGastoMensual,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                    TextField(
                      controller: valorCatastralCtrl,
                      decoration: InputDecoration(
                        labelText: "Valor catastral",
                        errorText: errorValor,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: gastoMantenimientoAnualCtrl,
                      decoration: InputDecoration(
                        labelText: "Gasto mantenimiento anual",
                        errorText: errorGastoMantenimientoAnual,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: hipotecaPendienteCtrl,
                      decoration: InputDecoration(
                        labelText: "Hipoteca pendiente",
                        errorText: errorHipotecaPendiente,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: impuestoAnualCtrl,
                      decoration: InputDecoration(
                        labelText: "Impuesto anual",
                        errorText: errorImpuestoAnual,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: ubicacionCtrl,
                      decoration: const InputDecoration(labelText: "Ubicación"),
                    ),
                    TextField(
                      controller: notasCtrl,
                      decoration: const InputDecoration(labelText: "Notas"),
                      maxLines: 2,
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
                      errorNombre = controller.validarNombre(nombreCtrl.text);
                      errorEstado = controller.validarEstadoPropiedad(estadoSeleccionado);
                      errorValor = controller.validarValor(valorCatastralCtrl.text);
                      errorIngresoMensual = estadoSeleccionado == EstadoPropiedad.alquilado
                          ? controller.validarIngresoMensual(ingresoMensualCtrl.text)
                          : null;
                      errorGastoMensual = estadoSeleccionado == EstadoPropiedad.alquilado
                          ? controller.validarGastoMensual(gastoMensualCtrl.text)
                          : null;
                      errorGastoMantenimientoAnual = controller.validarGastoMantenimientoAnual(gastoMantenimientoAnualCtrl.text);
                      errorHipotecaPendiente = controller.validarHipotecaPendiente(hipotecaPendienteCtrl.text);
                      errorImpuestoAnual = controller.validarImpuestoAnual(impuestoAnualCtrl.text);
                    });

                    if ([
                      errorNombre,
                      errorEstado,
                      errorValor,
                      errorIngresoMensual,
                      errorGastoMensual,
                      errorGastoMantenimientoAnual,
                      errorHipotecaPendiente,
                      errorImpuestoAnual
                    ].any((e) => e != null)) return;

                    // Aplicar cambios
                    activo
                      ..nombre = nombreCtrl.text.trim()
                      ..valorCatastral = double.tryParse(valorCatastralCtrl.text.trim().replaceAll(',', '.'))
                      ..estadoPropiedad = estadoSeleccionado
                      ..ingresoMensual = estadoSeleccionado == EstadoPropiedad.alquilado
                          ? double.tryParse(ingresoMensualCtrl.text.trim().replaceAll(',', '.'))
                          : null
                      ..gastoMensual = estadoSeleccionado == EstadoPropiedad.alquilado
                          ? double.tryParse(gastoMensualCtrl.text.trim().replaceAll(',', '.'))
                          : null
                      ..gastosMantenimientoAnual = double.tryParse(gastoMantenimientoAnualCtrl.text.trim().replaceAll(',', '.'))
                      ..hipotecaPendiente = double.tryParse(hipotecaPendienteCtrl.text.trim().replaceAll(',', '.'))
                      ..impuestoAnual = double.tryParse(impuestoAnualCtrl.text.trim().replaceAll(',', '.'))
                      ..ubicacion = ubicacionCtrl.text.trim()
                      ..notas = notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim();

                    await controller.actualizarValorDeActivo(activo, activo.valorActual);
                    await controller.actualizarActivo(activo);

                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Activo actualizado')),
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


  void _mostrarDialogoConfirmarEliminar(BuildContext context, Activo activo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar activo?"),
        content: Text("¿Estás seguro de que deseas eliminar \"${activo.nombre}\"? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await ActivosController().eliminarActivo(activo.id!);
              Navigator.pop(context);
              Navigator.pop(context); // cerrar el bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Activo eliminado")),
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

  String _formatearFecha(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
  }
}
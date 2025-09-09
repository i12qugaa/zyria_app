import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/activos_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/activo_class.dart';
import '../../models/operacion_class.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_appbar_actions.dart';
import 'widgets/grafico_valor_view.dart';
import 'package:provider/provider.dart';

class FondosinversionView extends StatefulWidget {
  final double rentabilidadTotal;
  final double totalActual;

  const FondosinversionView({
    super.key,
    required this.rentabilidadTotal,
    required this.totalActual,
  });

  @override
  State<FondosinversionView> createState() => _FondosinversionViewState();
}

class _FondosinversionViewState extends State<FondosinversionView> {
  @override

  final formatoMoneda = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );

  final formatoDecimal = NumberFormat.decimalPattern('es_ES');


  @override
  Widget build(BuildContext context) {
    final homeController = Provider.of<HomeController>(context);

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: 'Fondos de inversión',
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
                          formatoMoneda.format(widget.totalActual),
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
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.sync, size: 28),
                        color: Colors.black87,
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Actualizando valores...')),
                          );
                          await ActivosController().actualizarValoresActuales(
                              context);
                          await ActivosController().navigateToAccionesEtfs(
                              context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Valores actualizados')),
                          );
                        },
                      ),
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
                    final fondosInversion = activos
                        .where((a) => a.tipo == TipoActivo.fondosInversion)
                        .toList();

                    return fondosInversion.isEmpty
                        ? const Center(
                        child: Text("Sin datos"))
                        : ListView.builder(
                      itemCount: fondosInversion.length,
                      itemBuilder: (context, index) {
                        final activo = fondosInversion[index];
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
                                Icons.attach_money, color: Colors.blue),
                            title: Text(
                              activo.nombre,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "Valor total actual: ${formatoMoneda.format(
                                  activo.valorActual * activo.cantidad)}",
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

  // Mostrar el diálogo para añadir un nuevo activo
  Future<bool?> _mostrarDialogoNuevoActivo(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final simboloCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    String? errorNombre;
    String? errorSimbolo;
    String? errorValor;

    final controller = ActivosController();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    TextField(
                      controller: simboloCtrl,
                      decoration: InputDecoration(
                        labelText: "Símbolo (AAPL,...)",
                        errorText: errorSimbolo,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: "Buscar valor actual",
                          onPressed: () async {
                            final simbolo = simboloCtrl.text.trim();

                            if (simbolo.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Introduce un símbolo')),
                              );
                              return;
                            }

                            final valor = await controller.obtenerPrecioActual(simbolo);

                            if (valor != null) {
                              valorCtrl.text = valor.toStringAsFixed(2);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Valor actual de $simbolo: €${valor.toStringAsFixed(2)}")),
                              );
                              setState(() {
                                errorValor = null;
                                errorSimbolo = null;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("No se pudo obtener el valor para '$simbolo'")),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    TextField(
                      controller: valorCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Valor Actual",
                        errorText: errorValor,
                      ),
                      keyboardAppearance: Brightness.dark,
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
                      errorSimbolo = controller.validarSimbolo(simboloCtrl.text);
                      errorValor = controller.validarValor(valorCtrl.text);
                    });

                    if (errorNombre != null || errorSimbolo != null || errorValor != null) {
                      return; // No continuar si hay errores
                    }

                    final nuevoActivo = Activo(
                      id: 0,
                      nombre: nombreCtrl.text.trim(),
                      simbolo: simboloCtrl.text.trim().toUpperCase(),
                      tipo: TipoActivo.fondosInversion,
                      valorActual: double.parse(valorCtrl.text.trim().replaceAll(',', '.')),
                      notas: notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                      historialOperaciones: [],
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
          },
        );
      },
    );
  }

  void mostrarDetalleActivo(BuildContext context, Activo activo) {

    final rentabilidad = ActivosController().calcularRentabilidadHistorica(activo);
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
                      child: Icon(Icons.attach_money, color: Colors.white),
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
                            activo.simbolo ?? "Sin símbolo",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      formatoMoneda.format(activo.valorActual * activo.cantidad),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _infoFila("📦 Participaciones",
                  activo.cantidad % 1 == 0
                      ? activo.cantidad.toInt().toString()
                      : activo.cantidad.toString().replaceAll('.', ','),
                ),
                _infoFila("💸 Valor compra promedio", formatoMoneda.format(activo.valorCompraPromedio)),
                _infoFila("💵 Valor actual (por unidad)", formatoMoneda.format(activo.valorActual)),
                _infoFila(
                  "📈 Rentabilidad actual",
                  "${formatoDecimal.format(activo.rentabilidadPorcentual)}%",
                ),
                _infoFila(
                  "📊 Rentabilidad total histórica",
                  "${formatoDecimal.format(rentabilidad)}%",
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "🔄 Actualización automática",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    StatefulBuilder(
                      builder: (context, setLocalState) {
                        return Switch(
                          value: activo.autoActualizar,
                          activeColor: Colors.blue,
                          onChanged: (bool nuevoValor) async {
                            // Actualiza el valor local para que el color del switch cambie
                            setLocalState(() {
                              activo.autoActualizar = nuevoValor;
                            });

                            // Luego realiza la operación en la base de datos o controlador
                            await ActivosController().cambiarActualizacionAutomatica(
                              id: activo.id,
                              nuevoEstado: nuevoValor,
                            );
                          },
                        );
                      },
                    ),
                  ],
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
                Padding(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 0),
                      initiallyExpanded: false,
                      title: const Text(
                        "📋 Operaciones",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        if (activo.historialOperaciones.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No hay operaciones registradas."),
                          ),
                        ...activo.historialOperaciones.map((op) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "🔁 ${op.tipo.name[0].toUpperCase()}${op.tipo.name.substring(1)} - ${op.cantidad} a ${formatoMoneda.format(op.precioUnitario)}/unidad",
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(_formatearFecha(op.fecha), style: const TextStyle(color: Colors.grey)),
                                    if (op.comision != null)
                                      Text("Comisión: ${formatoMoneda.format(op.comision!)}"),

                                    if (op.notas != null && op.notas!.isNotEmpty)
                                      Text("Notas: ${op.notas}"),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatoMoneda.format((op.precioUnitario * op.cantidad) + (op.comision ?? 0)),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _mostrarDialogoEditarOperacion(context, op, activo.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _mostrarDialogoConfirmarEliminarOperacion(context, op, activo),
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
                              final resultado = await _mostrarDialogoNuevaOperacion(context, activo);

                              if (resultado == true) {
                                setState(() {});
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                            label: const Text("Añadir operación", style: TextStyle(color: Colors.teal)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final historial = await ActivosController().obtenerHistorialDeActivo(activo.id!);

                      for (var v in historial) {
                        print('Fecha: ${v.fecha}, Valor Compra Promedio: ${v.valorCompraPromedio}');
                      }
                      if (historial.isEmpty) {
                        print("⛔ Historial vacío para activo con ID: ${activo.id}");
                        // Cierra el modal/pantalla actual
                        Navigator.of(context).pop();
                        Future.delayed(Duration.zero, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Este activo aún no tiene historial de valores.")),
                          );
                        });

                        return;
                      }

                      print("✅ Historial cargado con ${historial.length} entradas, navegando a la gráfica.");

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GraficoValorView(historial: historial),
                        ),
                      );
                    },
                    icon: const Icon(Icons.show_chart),
                    label: const Text("Ver gráfico"),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoConfirmarEliminarOperacion(BuildContext context, Operacion operacion, Activo activo) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("¿Eliminar operación?"),
          content: const Text("Esta acción no se puede deshacer."),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
                child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  //  Navigator.of(ctx).pop();

                  final success = await ActivosController().eliminarOperacion(operacion, activo.id);
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

  Future<bool?> _mostrarDialogoNuevaOperacion(BuildContext context, Activo activo) async {
    final cantidadCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final comisionCtrl = TextEditingController();
    final notasCtrl = TextEditingController();
    final fechaCtrl = TextEditingController();

    String? errorCantidad;
    String? errorPrecio;
    String? errorComision;

    final controller = ActivosController();

    TipoOperacion tipoSeleccionado = TipoOperacion.compra;
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
              title: const Text("Nueva operación"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<TipoOperacion>(
                      value: tipoSeleccionado,
                      decoration: const InputDecoration(labelText: "Tipo de operación"),
                      items: TipoOperacion.values.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text("${tipo.name[0].toUpperCase()}${tipo.name.substring(1)}"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setStateDialog(() => tipoSeleccionado = value);
                      },
                    ),
                    const SizedBox(height: 8),
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
                      controller: precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Precio unitario (€)",
                        errorText: errorPrecio,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: comisionCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Comisión (€)",
                        errorText: errorComision,
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
                      errorPrecio = controller.validarPrecio(precioCtrl.text);
                      errorComision = controller.validarComision(comisionCtrl.text);
                    });

                    if (errorCantidad != null || errorPrecio != null || errorComision != null) {
                      return;
                    }

                    final cantidad = double.parse(cantidadCtrl.text.replaceAll(',', '.'));
                    final precio = double.parse(precioCtrl.text.replaceAll(',', '.'));
                    final comision = comisionCtrl.text.isEmpty
                        ? null
                        : double.parse(comisionCtrl.text.replaceAll(',', '.'));

                    final nueva = Operacion(
                      idActivo: activo.id,
                      tipo: tipoSeleccionado,
                      cantidad: cantidad,
                      precioUnitario: precio,
                      comision: comision,
                      notas: notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                      fecha: fechaSeleccionada,
                      id: 0,
                    );

                    try {
                      await controller.agregarOperacion(activo.id, nueva);

                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Operación añadida")),
                      );
                    } on ArgumentError catch (e) {
                      setStateDialog(() {
                        errorCantidad = e.message;
                      });
                    }
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


  void _mostrarDialogoEditarActivo(BuildContext context, Activo activo) {
    final nombreCtrl = TextEditingController(text: activo.nombre);
    final simboloCtrl = TextEditingController(text: activo.simbolo ?? '');
    final valorActualCtrl = TextEditingController(
      text: activo.valorActual != null ? activo.valorActual.toString() : '',
    );
    final notasCtrl = TextEditingController(text: activo.notas ?? '');

    String? errorNombre;
    String? errorSimbolo;
    String? errorValor;

    final controller = ActivosController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Editar activo"),
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
                    TextField(
                      controller: simboloCtrl,
                      decoration: InputDecoration(
                        labelText: "Símbolo",
                        errorText: errorSimbolo,
                      ),
                    ),
                    TextField(
                      controller: valorActualCtrl,
                      decoration: InputDecoration(
                        labelText: "Valor actual",
                        errorText: errorValor,
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
                      errorNombre = controller.validarNombre(nombreCtrl.text);
                      errorSimbolo = controller.validarSimbolo(simboloCtrl.text);
                      errorValor = controller.validarValor(valorActualCtrl.text);
                    });

                    if (errorNombre != null || errorSimbolo != null || errorValor != null) {
                      return;
                    }

                    // Aplicar los cambios al objeto activo
                    activo.nombre = nombreCtrl.text.trim();
                    activo.simbolo = simboloCtrl.text.trim();
                    activo.notas = notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim();

                    final nuevoValor = double.parse(valorActualCtrl.text.trim().replaceAll(',', '.'));
                    await controller.actualizarValorDeActivo(activo, nuevoValor);
                    await controller.actualizarActivo(activo);

                    Navigator.pop(context, true);
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Activo actualizado')),
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


  void _mostrarDialogoEditarOperacion(BuildContext context, Operacion op, int idActivo) {
    final cantidadCtrl = TextEditingController(text: op.cantidad.toString());
    final precioCtrl = TextEditingController(text: op.precioUnitario.toString());
    final fechaCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(op.fecha));
    final comisionCtrl = TextEditingController(text: op.comision?.toString() ?? '');
    final notasCtrl = TextEditingController(text: op.notas ?? '');

    String? errorCantidad;
    String? errorPrecio;
    String? errorComision;

    DateTime fechaSeleccionada = op.fecha;

    final controller = ActivosController();

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
                        labelText: "Participaciones",
                        errorText: errorCantidad,
                      ),
                    ),
                    TextField(
                      controller: precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Precio unitario (€)",
                        errorText: errorPrecio,
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
                      controller: comisionCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Comisión (€)",
                        errorText: errorComision,
                      ),
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
                      errorPrecio = controller.validarPrecio(precioCtrl.text);
                      errorComision = controller.validarComision(comisionCtrl.text);
                    });

                    if (errorCantidad != null || errorPrecio != null || errorComision != null) {
                      return; // No continuar si hay errores
                    }

                    final nuevaCantidad = double.parse(cantidadCtrl.text.trim().replaceAll(',', '.'));
                    final nuevoPrecio = double.parse(precioCtrl.text.trim().replaceAll(',', '.'));
                    final nuevaComision = comisionCtrl.text.trim().isEmpty
                        ? null
                        : double.parse(comisionCtrl.text.trim().replaceAll(',', '.'));

                    op.cantidad = nuevaCantidad;
                    op.precioUnitario = nuevoPrecio;
                    op.fecha = fechaSeleccionada;
                    op.comision = nuevaComision;
                    op.notas = notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim();

                    await controller.actualizarOperacion(idActivo, op);

                    Navigator.of(context).pop(); // Cierra el diálogo
                    Navigator.of(context).pop(); // Cierra la pantalla previa si es necesario

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

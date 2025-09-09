import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ai_controller.dart';
import '../controllers/home_controller.dart';
import '../models/mensaje_class.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_appbar_actions.dart';
import 'package:flutter/services.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _incluirMovimientos = true;
  bool _incluirActivos = false;
  bool _incluirDeudas = false;

  @override
  void initState() {
    super.initState();
    _inicializarChat();
  }


  Future<void> _inicializarChat() async {
    final controller = Provider.of<AiChatController>(context, listen: false);
    await controller.cargarMensajes();

    if (controller.mensajes.isEmpty) {
      await controller.enviarAsesoriaAutomatica();
    }

    setState(() {
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }


  // Desplazar al final del chat
  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }



  Widget _buildSugerencias(AiChatController aiController) {
    final List<Map<String, dynamic>> sugerencias = [
      {
        "titulo": "📊 Análisis financiero completo",
        "accion": () async {
          if (!_incluirMovimientos || !_incluirActivos || !_incluirDeudas) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("⚠️ Filtros incompletos"),
                content: const Text("Para realizar un análisis financiero completo, debes seleccionar movimientos, activos y deudas en los ajustes de datos."),
                actions: [
                  TextButton(
                    child: const Text("Entendido"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          } else {
            await aiController.enviarPromptAnalisisFinanciero();
            _scrollToEnd();
          }
        },
      },
      {
        "titulo": "💡 Consejos para ahorrar dinero",
        //"accion": () => aiController.enviarPromptConsejosAhorro(),
        "accion": () async {
          if (!_incluirMovimientos) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("⚠️ Filtros incompletos"),
                content: const Text("Para realizar consejos de ahorro, debes seleccionar movimientos en los ajustes de datos."),
                actions: [
                  TextButton(
                    child: const Text("Entendido"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          } else {
            await aiController.enviarPromptConsejosAhorro();
            _scrollToEnd();
          }
        },
      },
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sugerencias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sugerencia = sugerencias[index];
          final String titulo = sugerencia["titulo"] as String;
          final Future<void> Function() accion = sugerencia["accion"] as Future<void> Function();

          return GestureDetector(
            onTap: () async {
              await accion();
              _scrollToEnd();
            },
            child: Chip(
              label: Text(titulo),
              backgroundColor: Colors.indigoAccent,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          );
        },


      ),
    );
  }



  void _mostrarOpcionesFinancieras() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Seleccionar datos a incluir"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Text("Ingresos, gastos y ahorros"),
                    value: _incluirMovimientos,
                    onChanged: (value) {
                      setState(() {
                        _incluirMovimientos = value ?? false;
                      });
                      setStateDialog(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: Text("Activos"),
                    value: _incluirActivos,
                    onChanged: (value) {
                      setState(() {
                        _incluirActivos = value ?? false;
                      });
                      setStateDialog(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: Text("Deudas"),
                    value: _incluirDeudas,
                    onChanged: (value) {
                      setState(() {
                        _incluirDeudas = value ?? false;
                      });
                      setStateDialog(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cerrar"),
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
        builder: (context, homeController, child)
        {
          final aiController = Provider.of<AiChatController>(context);

          return Scaffold(
            appBar: CustomGradientAppBar(
              title: 'Asesor financiero',
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  tooltip: "Borrar conversación",
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirmar eliminación"),
                        content: const Text("¿Seguro que quieres borrar la conversación?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Aceptar"),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      await aiController.reiniciarConversacion();
                      await aiController.enviarAsesoriaAutomatica();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Conversación eliminada")),
                      );
                    }
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: "Datos a incluir",
                  onPressed: _mostrarOpcionesFinancieras,
                ),
                CustomAppBarActions(homeController: homeController),
              ],
            ),

            body: SafeArea(
              child: Column(
                children: [
                  _buildSugerencias(aiController),
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: aiController.mensajes.length,
                      itemBuilder: (context, index) {
                        final mensaje = aiController.mensajes[index];
                        return ChatBubble(
                          mensaje: mensaje.contenido,
                          esUsuario: mensaje.esUsuario,
                          fecha: mensaje.fecha,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInputArea(aiController),
                  const SizedBox(height: 12),
                ],
              ),
            ),

          );
        });
  }


  Widget _buildInputArea(AiChatController aiController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Mensaje",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              final texto = _controller.text.trim();
              if (texto.isEmpty) return;

              _controller.clear();

              final msgUsuario = Mensaje(
                contenido: texto,
                esUsuario: true,
                fecha: DateTime.now(),
              );

              await aiController.enviarMensajeManual(
                msgUsuario,
                incluirMovimientos: _incluirMovimientos,
                incluirActivos: _incluirActivos,
                incluirDeudas: _incluirDeudas,
              );

              // Después de enviar el mensaje, desplazarse al final
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToEnd();
              });
            },
          )
        ],
      ),
    );
  }
}


class ChatBubble extends StatelessWidget {
  final String mensaje;
  final bool esUsuario;
  final DateTime fecha;

  const ChatBubble({
    super.key,
    required this.mensaje,
    required this.esUsuario,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    final estiloFecha = TextStyle(
      fontSize: 11,
      color: esUsuario ? Colors.white70 : Colors.black54,
    );

    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: esUsuario ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: esUsuario ? Colors.blueAccent : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SelectableText(
              mensaje,
              style: TextStyle(color: esUsuario ? Colors.white : Colors.black87),
              // Esta opción permite selección larga y menú nativo
              toolbarOptions: const ToolbarOptions(
                copy: true,
                selectAll: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Text(
              _formatearFecha(fecha),
              style: estiloFecha,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minutos = fecha.minute.toString().padLeft(2, '0');

    return "$dia/$mes/$anio $hora:$minutos";
  }
}

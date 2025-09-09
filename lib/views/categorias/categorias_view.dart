import 'package:flutter/material.dart';
import '../../controllers/categorias_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/category_class.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_appbar_actions.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


class CategoriasView extends StatefulWidget {
  final List<Categoria> categoriasGasto;
  final List<Categoria> categoriasIngreso;

  const CategoriasView({
    super.key,
    required this.categoriasGasto,
    required this.categoriasIngreso,
  });

  @override
  State<CategoriasView> createState() => _CategoriasViewState();
}

class _CategoriasViewState extends State<CategoriasView> {
  final CategoriasController _controller = CategoriasController();

  late List<Categoria> _gastos;
  late List<Categoria> _ingresos;

  @override
  void initState() {
    super.initState();
    _gastos = List.from(widget.categoriasGasto);
    _ingresos = List.from(widget.categoriasIngreso);
  }

  Future<void> _showCategoriaDialog({Categoria? categoriaExistente, String? tipo}) async {
    final isEdit = categoriaExistente != null;
    final TextEditingController _nombreController = TextEditingController(
      text: isEdit ? categoriaExistente!.nombre : '',
    );

    String tipoSeleccionado = isEdit ? categoriaExistente!.tipo : (tipo ?? 'gasto');

    Color _colorSeleccionado = isEdit ? categoriaExistente!.color : Colors.blue;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Editar Categoría' : 'Nueva Categoría'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 10),
                    if (!isEdit)
                      DropdownButton<String>(
                        value: tipoSeleccionado,
                        items: const [
                          DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                          DropdownMenuItem(value: 'ingreso', child: Text('Ingreso')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              tipoSeleccionado = value;
                            });
                          }
                        },
                      ),
                    if (isEdit) ...[
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Color:'),
                      ),
                      const SizedBox(height: 10),
                      ColorPicker(
                        pickerColor: _colorSeleccionado,
                        onColorChanged: (color) {
                          setStateDialog(() {
                            _colorSeleccionado = color;
                          });
                        },
                        showLabel: true,
                        pickerAreaHeightPercent: 0.7,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final nombre = _nombreController.text.trim();
                    if (nombre.isEmpty) return;

                    if (isEdit) {
                      final updated = Categoria(
                        id: categoriaExistente!.id,
                        nombre: nombre,
                        tipo: tipoSeleccionado,
                        color: _colorSeleccionado,
                      );
                      await _controller.updateCategoria(updated);
                    } else {
                      await _controller.addCategoria(nombre, tipoSeleccionado);
                    }

                    await _refreshCategorias();
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


  Future<void> _eliminarCategoria(Categoria categoria) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Seguro que quieres eliminar "${categoria.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _controller.deleteCategoria(categoria.id!);
        await _refreshCategorias();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Esta categoría no puede eliminarse")),
        );
      }
    }
  }

  Future<void> _refreshCategorias() async {
    final gastos = await _controller.getCategoriasByTipo('gasto');
    final ingresos = await _controller.getCategoriasByTipo('ingreso');
    setState(() {
      _gastos = gastos;
      _ingresos = ingresos;
    });
  }

  Widget _buildCategoriaList(String tipo, List<Categoria> categorias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              tipo == 'gasto' ? "Categorías de Gasto" : "Categorías de Ingreso",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...categorias.map((c) => ListTile(
          leading: GestureDetector(
            onTap: () => _mostrarDialogoCambiarColor(c),
            child: CircleAvatar(backgroundColor: c.color),
          ),
          title: Text(c.nombre),
          trailing: Wrap(
            spacing: 10,
            children: [
              if (c.erasable)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _showCategoriaDialog(categoriaExistente: c),
                ),
              if (c.erasable)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _eliminarCategoria(c),
                ),
            ],
          ),
        )),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
        builder: (context, homeController, child)
    {
      return Scaffold(
        appBar: CustomGradientAppBar(title: 'Categorías', actions: [ CustomAppBarActions(homeController: homeController) ],),

        body: ListView(
          children: [
            _buildCategoriaList('gasto', _gastos),
            _buildCategoriaList('ingreso', _ingresos),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCategoriaDialog(),
          child: const Icon(Icons.add),
        ),
      );
    });
  }

  Future<void> _mostrarDialogoCambiarColor(Categoria categoria) async {
    Color colorSeleccionado = categoria.color;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Seleccione un color'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: colorSeleccionado,
                  onColorChanged: (color) {
                    setStateDialog(() {
                      colorSeleccionado = color;
                    });
                  },
                  showLabel: true,
                  pickerAreaHeightPercent: 0.7,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nuevaCategoria = Categoria(
                      id: categoria.id,
                      nombre: categoria.nombre,
                      tipo: categoria.tipo,
                      color: colorSeleccionado,
                      erasable: categoria.erasable,
                    );

                    await _controller.updateCategoria(nuevaCategoria);
                    await _refreshCategorias();
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
}



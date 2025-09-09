import 'package:flutter/material.dart';
import '../db/categoria_dao.dart';
import '../models/category_class.dart';
import '../views/ahorros/addAhorro_view.dart';
import '../views/categorias/categorias_view.dart';
import '../views/gastos/addGasto_view.dart';
import '../views/ingresos/addIngreso_view.dart';
import 'home_controller.dart';

class CategoriasController {
  final CategoriasDao _categoriasDao = CategoriasDao.instance;

  // Obtener categorías por tipo
  Future<List<Categoria>> getCategoriasByTipo(String tipo) async {
    return await _categoriasDao.getCategoriasByTipo(tipo);
  }

  // Agregar una nueva categoría con color
  Future<void> addCategoria(String nombre, String tipo) async {
    final categoria = Categoria(
      nombre: nombre,
      tipo: tipo,
      color: _generateColor(nombre), // Genera un color basado en el nombre
    );
    await _categoriasDao.insertCategoria(categoria);
  }

  // Metodo para cargar las categorías por tipo y navegar a la vista de añadir gasto
  Future<void> loadCategoriasAndNavigate(BuildContext context, String tipoCategoria, int day, int month, int year, TimeRangeMode selectedMode,) async {
    try {
      // Cargar las categorías usando el tipo que se pasa como parámetro
      final categorias = await getCategoriasByTipo(tipoCategoria);
      // Verificar si las categorías son válidas
      if (categorias.isNotEmpty) {
        // Redirigir según el tipo de categoría
        if (tipoCategoria == 'ingreso') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddIngresoView(
                  categorias: categorias,
                  day: day,
                  month: month,
                  year: year,
                  selectedMode: selectedMode),
            ),
          );
        } else if (tipoCategoria == 'gasto') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddGastoView(
                  categorias: categorias,
                  day: day,
                  month: month,
                  year: year,
                  selectedMode: selectedMode
              ), // Vista para gastos
            ),
          );
        } else if (tipoCategoria == 'ahorro') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAhorroView(
                  categorias: categorias,
                  day: day,
                  month: month,
                  year: year,
                  selectedMode: selectedMode
              ),
            ),
          );
        } else {
          // Mensaje en caso de tipo no reconocido
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tipo de categoría no válido: $tipoCategoria')),
          );
        }
      } else {
        // Si no hay categorías, mostrar un mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron cargar las categorías de tipo $tipoCategoria')),
        );
      }
    } catch (error) {
      print('Error al cargar categorías y navegar: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las categorías')),
      );
    }
  }

  Future<void> loadCategoriasAndNavigateToGestion(BuildContext context) async {
    try {
      final gastos = await getCategoriasByTipo('gasto');
      final ingresos = await getCategoriasByTipo('ingreso');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoriasView(
            categoriasGasto: gastos,
            categoriasIngreso: ingresos,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar las categorías")),
      );
    }
  }


  //Metodo para generar color basado en el nombre de la categoría
  Color _generateColor(String nombre) {
    int hash = nombre.hashCode;
    return Color((hash & 0xFFFFFF) | 0xFF000000);
  }

  // Eliminar una categoría por ID
  Future<void> deleteCategoria(int id) async {
    try {
      // 1. Obtener la categoría completa por su ID
      final categoriasGasto = await _categoriasDao.getCategoriasByTipo('gasto');
      final categoriasIngreso = await _categoriasDao.getCategoriasByTipo('ingreso');
      final todas = [...categoriasGasto, ...categoriasIngreso];
      final categoria = todas.firstWhere((c) => c.id == id);

      // 2. Verificar si es eliminable
      if (!categoria.erasable) {
        throw Exception("La categoría '${categoria.nombre}' no puede eliminarse.");
      }

      // 3. Eliminar si es eliminable
      await _categoriasDao.deleteCategoria(id);

    } catch (e) {
      print("Error al eliminar categoría: $e");
      rethrow;
    }
  }


  Future<String?> getNombreCategoriaById(int id) async {
    try {
      return await _categoriasDao.getCategoriaNombreById(id);
    } catch (e) {
      print("Error al obtener el nombre de la categoría: $e");
      return null;
    }
  }

// Actualizar una categoría existente
  Future<void> updateCategoria(Categoria categoria) async {
    try {
      await _categoriasDao.updateCategoria(categoria);
    } catch (e) {
      print("Error al actualizar categoría: $e");
    }
  }

  // Verificar si una categoría ya existe (por nombre y tipo)
  Future<bool> categoriaExists(String nombre, String tipo) async {
    try {
      return await _categoriasDao.categoriaExists(nombre, tipo);
    } catch (e) {
      print("Error al verificar existencia de categoría: $e");
      return false;
    }
  }

}





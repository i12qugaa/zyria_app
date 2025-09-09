import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:finanzas_app/db/activos_dao.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../db/categoria_dao.dart';
import '../db/deudas_dao.dart';
import '../db/movimientos_dao.dart';
import '../models/activo_class.dart';
import '../models/category_class.dart';
import '../models/deuda_class.dart';
import '../models/operacion_class.dart';
import '../models/pagosDeuda_class.dart';
import '../models/valorHistorico_class.dart';
import '../services/google_drive.dart';
import '../services/csv_service.dart';
import '../models/movimiento_class.dart';
import 'package:archive/archive.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:typed_data' as typed_data;


class DriveController {
  final GoogleDriveService _driveService = GoogleDriveService();
  final MovimientosDao _movimientosDao = MovimientosDao.instance;
  final ActivosDao _activosDao = ActivosDao.instance;
  final DeudasDao _deudasDao = DeudasDao.instance;

  Future<void> subirDatosDrive(BuildContext context, List<String> tiposSeleccionados) async {
    await _driveService.signIn();

    if (_driveService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, inicia sesión en Google Drive.')),
      );
      return;
    }

    if (tiposSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un tipo de dato.')),
      );
      return;
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final Map<String, String> archivosCSV = {};

    for (String tipo in tiposSeleccionados) {
      switch (tipo) {
        case 'activos':
          final activos = await _activosDao.obtenerTodosActivosComoMapa();
          if (activos.isNotEmpty) {
            final contenido = await generarCsvActivos(activos);
            archivosCSV['activos_$timestamp.csv'] = contenido;
          }

          final operaciones = await _activosDao.obtenerTodasOperaciones();
          if (operaciones.isNotEmpty) {
            final contenido = await generarCsvOperaciones(operaciones);
            archivosCSV['operaciones_$timestamp.csv'] = contenido;
          }

          final historial = await _activosDao.obtenerTodoHistorialValorPromedio();
          if (historial.isNotEmpty) {
            final contenido = await generarCsvHistorialValorPromedio(historial);
            archivosCSV['historial_valor_promedio_$timestamp.csv'] = contenido;
          }
          break;

        case 'deudas':
          final deudas = await _deudasDao.obtenerTodasDeudasComoMapa();
          if (deudas.isNotEmpty) {
            final contenido = await generarCsvDeudas(deudas);
            archivosCSV['deudas_$timestamp.csv'] = contenido;
          }

          final pagos = await _deudasDao.obtenerTodosPagos();
          if (pagos.isNotEmpty) {
            final contenido = await generarCsvPagos(pagos);
            archivosCSV['pagos_$timestamp.csv'] = contenido;
          }
          break;

        default:
        // Para movimientos por tipo
          final datos = await _movimientosDao.obtenerMovimientosPorTipo(tipo);
          if (datos.isNotEmpty) {
            final contenido = await generarCsvMovimientos(datos);
            archivosCSV['${tipo}_$timestamp.csv'] = contenido;
          }
          break;
      }
    }

    if (archivosCSV.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para respaldar.')),
      );
      return;
    }

    // Crear ZIP
    final Uint8List zipBytes = _crearZipDesdeCsvs(archivosCSV);

    // Guardar ZIP temporalmente
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/backup_$timestamp.zip';
    final zipFile = File(zipPath)..writeAsBytesSync(zipBytes);

    // Subir ZIP
    await _driveService.uploadFile(zipFile);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup subido correctamente a Google Drive.')),
    );

    Navigator.pop(context);
  }


  String generarCSVDesdeMapas(List<Map<String, dynamic>> datos) {
    if (datos.isEmpty) return '';

    final headers = datos.first.keys.toList();
    final csv = StringBuffer();
    csv.writeln(headers.join(','));

    for (final fila in datos) {
      final row = headers.map((key) => '"${fila[key] ?? ''}"').join(',');
      csv.writeln(row);
    }

    return csv.toString();
  }

  Uint8List _crearZipDesdeCsvs(Map<String, String> archivos) {
    final archive = Archive();

    archivos.forEach((fileName, content) {
      final data = utf8.encode(content);
      archive.addFile(ArchiveFile(fileName, data.length, data));
    });

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive)!;
    return Uint8List.fromList(zipData);
  }

  // Función para crear el archivo CSV para una tabla específica
  Future<File> createCsvFileForTable(String table, List<Map<String, dynamic>> data, String fileName) async {
    if (data.isEmpty) {
      print("La tabla $table está vacía, no se generará CSV.");
      return Future.error("Tabla vacía");
    }

    String csvContent = generarCsvMovimientos(data); // Genera el CSV con los datos de la tabla

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName'); // Usa el nombre con fecha actual
    await file.writeAsString(csvContent);

    return file;
  }

  // Restaurar los datos desde Google Drive
  Future<bool> restoreDataFromDrive(BuildContext context, String fileId) async {
    try {
      await _driveService.signIn();

      if (_driveService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, inicia sesión en Google Drive.')),
        );
        return false;
      }

      final typed_data.Uint8List? fileBytes = await _driveService.getFileBytes(fileId);

      if (fileBytes == null || fileBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudo leer el archivo ZIP.')),
        );
        return false;
      }

      return await restoreZipBackup(fileBytes, context);
    } catch (e) {
      print("Error al restaurar los datos: $e");
      return false;
    }
  }


  String _getTableNameFromFileName(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.startsWith('gasto_') ||
        lower.startsWith('gastos_') ||
        lower.startsWith('ingreso_') ||
        lower.startsWith('ingresos_') ||
        lower.startsWith('ahorro_') ||
        lower.startsWith('ahorros_')) {
      return 'movimientos';
    } else if (lower.startsWith('categorias_')) {
      return 'categorias';
    } else if (lower.startsWith('activos_')) {
      return 'activos';
    } else if (lower.startsWith('deudas_')) {
      return 'deudas';
    } else if (lower.startsWith('pagos_')) {
      return 'pagos';
    } else if (lower.startsWith('operaciones_')) {
      return 'operaciones';
    } else if (lower.startsWith('historial_valor_promedio_')) {
      return 'historial_valor_promedio';
    } else {
      return '';
    }
  }

  Future<void> _insertDataIntoMovimientos(List<Map<String, dynamic>> data, String tipo) async {
    print("Iniciando inserción de movimientos. Total filas: ${data.length}");

    // Cache local para evitar consultar la BD repetidamente
    final Map<String, int> _cacheCategorias = {};

    String _normalizeName(String? name) {
      if (name == null) return '';
      var s = name.trim();
      s = s.replaceAll(RegExp(r'\s+'), ' '); // colapsa espacios múltiples
      return s.toLowerCase(); // para comparación insensible a mayúsculas/minúsculas
    }

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      print("🔸 Procesando fila $i: $row");

      // Validaciones básicas
      if (!row.containsKey('categoria') || row['categoria'] == null) {
        print('⚠Fila $i omitida: falta campo "categoria".');
        continue;
      }
      if (!row.containsKey('amount') || row['amount'] == null) {
        print('Fila $i omitida: falta campo "amount".');
        continue;
      }

      try {
        final categoriaNombreRaw = row['categoria'].toString();
        final normalizedNombre = _normalizeName(categoriaNombreRaw);

        final movimientoTipo = row.containsKey('tipo') && row['tipo'] != null
            ? row['tipo'].toString()
            : tipo;

        final description = row['description']?.toString() ?? '';
        final date = row['date']?.toString() ?? '';
        final occurrenceDate = row['occurrenceDate']?.toString() ?? date;
        final amount = double.tryParse(row['amount'].toString()) ?? 0.0;

        // Buscar o crear categoría usando cache
        int? categoriaId;
        if (_cacheCategorias.containsKey(normalizedNombre)) {
          categoriaId = _cacheCategorias[normalizedNombre]!;
        } else {
          categoriaId = await CategoriasDao.instance.getCategoriaIDByNombre(normalizedNombre);
          if (categoriaId == null) {
            print("Insertando nueva categoría: $categoriaNombreRaw ($movimientoTipo)");
            categoriaId = await CategoriasDao.instance.insertCategoria(
              Categoria(nombre: categoriaNombreRaw, tipo: movimientoTipo),
            );
          }
          _cacheCategorias[normalizedNombre] = categoriaId;
        }

        final movimiento = Movimiento(
          amount: amount,
          description: description,
          date: date,
          occurrenceDate: occurrenceDate,
          tipo: movimientoTipo,
          categoriaId: categoriaId,
        );

        bool exists = await MovimientosDao.instance.movimientoExists(date, description);
        if (!exists) {
          await MovimientosDao.instance.insertMovimiento(movimiento);
          print("Insertado: ${description} - \$${amount}");
        } else {
          print("⚠Duplicado: ${description} - ${date}, no insertado.");
        }
      } catch (e, stack) {
        print("Error al procesar fila $i: $e");
        print(stack);
      }
    }

    print("Inserción de movimientos finalizada.");
  }


  Future<void> _insertDataIntoActivos(List<Map<String, dynamic>> data) async {
    print("Iniciando inserción de activos. Total filas: ${data.length}");

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      print("Procesando fila $i: $row");

      // Validaciones básicas
      if (!row.containsKey('nombre') || row['nombre'] == null || row['nombre'].toString().isEmpty) {
        print('Fila $i omitida: falta campo "nombre".');
        continue;
      }
      if (!row.containsKey('tipo') || row['tipo'] == null || row['tipo'].toString().isEmpty) {
        print('Fila $i omitida: falta campo "tipo".');
        continue;
      }

      try {
        // Tipo de activo con valor por defecto si no se encuentra
        final tipoActivo = TipoActivo.values.firstWhere(
              (e) => e.toString().split('.').last.toLowerCase() == row['tipo'].toString().toLowerCase(),
          orElse: () {
            print('Tipo de activo desconocido: ${row['tipo']}, usando default accionesEtfs');
            return TipoActivo.accionesEtfs;
          },
        );

        // Estado de propiedad solo para activos inmobiliarios
        EstadoPropiedad? estadoPropiedad;
        if (tipoActivo == TipoActivo.inmobiliario &&
            row['estadoPropiedad'] != null &&
            row['estadoPropiedad'].toString().isNotEmpty) {
          estadoPropiedad = EstadoPropiedad.values.firstWhere(
                (e) => e.toString().split('.').last.toLowerCase() ==
                row['estadoPropiedad'].toString().toLowerCase(),
          );
        }

        final activo = Activo(
          id: 0,
          nombre: row['nombre'].toString(),
          simbolo: row['simbolo']?.toString(),
          tipo: tipoActivo,
          autoActualizar: row['autoActualizar']?.toString().toLowerCase() == 'true',
          valorActual: double.tryParse(row['valorActual']?.toString() ?? '0') ?? 0.0,
          notas: row['notas']?.toString(),
          ubicacion: row['ubicacion']?.toString(),
          estadoPropiedad: estadoPropiedad,
          ingresoMensual: double.tryParse(row['ingresoMensual']?.toString() ?? ''),
          gastoMensual: double.tryParse(row['gastoMensual']?.toString() ?? ''),
          gastosMantenimientoAnual: double.tryParse(row['gastosMantenimientoAnual']?.toString() ?? ''),
          valorCatastral: double.tryParse(row['valorCatastral']?.toString() ?? ''),
          hipotecaPendiente: double.tryParse(row['hipotecaPendiente']?.toString() ?? ''),
          impuestoAnual: double.tryParse(row['impuestoAnual']?.toString() ?? ''),
        );

        // Evitar duplicados por símbolo
        bool exists = await ActivosDao.instance.activoExists(activo.simbolo ?? '');
        if (!exists) {
          await ActivosDao.instance.insertarActivo(activo);
          print("Activo insertado: ${activo.nombre}");
        } else {
          print("Activo duplicado no insertado: ${activo.nombre}");
        }
      } catch (e, stack) {
        print("Error al procesar fila $i: $e");
        print(stack);
      }
    }

    print("Inserción de activos finalizada.");
  }


  Future<void> _insertDataIntoDeudas(List<Map<String, dynamic>> data) async {
    print("Iniciando inserción de deudas. Total filas: ${data.length}");

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      print("Procesando fila $i: $row");

      if (!row.containsKey('entidad') || row['entidad'] == null) {
        print('Fila $i omitida: falta campo "entidad".');
        continue;
      }

      if (!row.containsKey('tipo') || row['tipo'] == null) {
        print('Fila $i omitida: falta campo "tipo".');
        continue;
      }

      try {
        final entidad = row['entidad'].toString();
        final tipoStr = row['tipo'].toString();
        final tipoDeuda = TipoDeuda.values.firstWhere(
              (e) => e.toString().split('.').last.toLowerCase() == tipoStr.toLowerCase(),
        );

        final deuda = Deuda(
          id: 0,
          tipo: tipoDeuda,
          entidad: entidad,
          valorTotal: double.tryParse(row['valorTotal']?.toString() ?? '0') ?? 0.0,
          interesAnual: double.tryParse(row['interesAnual']?.toString() ?? '0') ?? 0.0,
          plazoMeses: int.tryParse(row['plazoMeses']?.toString() ?? '0') ?? 0,
          fechaInicio: row['fechaInicio'] != null
              ? DateTime.tryParse(row['fechaInicio'].toString()) ?? DateTime.now()
              : DateTime.now(),
          idActivo: row['idActivo'] != null
              ? int.tryParse(row['idActivo'].toString())
              : null,
          notas: row['notas']?.toString(),
          saldo: double.tryParse(row['saldo']?.toString() ?? ''),
          cuotaMensual: double.tryParse(row['cuotaMensual']?.toString() ?? ''),
          fechaFin: row['fechaFin'] != null
              ? DateTime.tryParse(row['fechaFin'].toString())
              : null,
          historialPagos: [], // lo puedes cargar si tu JSON trae pagos
        );

        bool exists = await DeudasDao.instance.deudaExists(entidad);
        if (!exists) {
          await DeudasDao.instance.insertardeuda(deuda);
          print("Deuda insertada: $entidad");
        } else {
          print("Deuda duplicada no insertada: $entidad");
        }
      } catch (e, stack) {
        print("Error al procesar fila $i: $e");
        print(stack);
      }
    }

    print("Inserción de deudas finalizada.");
  }


  Future<void> _insertDataIntoOperaciones(List<Map<String, dynamic>> data) async {
    print("Iniciando inserción de operaciones. Total filas: ${data.length}");

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      print("Procesando fila $i: $row");

      try {
        // Validaciones
        if (!row.containsKey('Activo') || row['Activo'] == null || row['Activo'].toString().isEmpty) {
          print('Fila $i omitida: falta campo "Activo".');
          continue;
        }
        if (!row.containsKey('Tipo de Operación') || row['Tipo de Operación'] == null) {
          print('Fila $i omitida: falta campo "Tipo de Operación".');
          continue;
        }
        if (!row.containsKey('Cantidad') || row['Cantidad'] == null) {
          print('Fila $i omitida: falta campo "Cantidad".');
          continue;
        }
        if (!row.containsKey('Precio Unitario') || row['Precio Unitario'] == null) {
          print('Fila $i omitida: falta campo "Precio Unitario".');
          continue;
        }
        if (!row.containsKey('Fecha') || row['Fecha'] == null) {
          print('Fila $i omitida: falta campo "Fecha".');
          continue;
        }

        // Obtener idActivo desde el nombre
        final nombreActivo = row['Activo'].toString();
        final idActivo = await _activosDao.getIdByNombre(nombreActivo);
        if (idActivo == null) {
          print("Activo no encontrado para fila $i: $nombreActivo");
          continue;
        }

        // Parseo de tipo de operación
        final tipoStr = row['Tipo de Operación'].toString().toLowerCase();
        TipoOperacion tipo;
        if (tipoStr == 'compra') {
          tipo = TipoOperacion.compra;
        } else if (tipoStr == 'venta') {
          tipo = TipoOperacion.venta;
        } else {
          print("Tipo de operación inválido en fila $i: $tipoStr");
          continue;
        }

        // Parseo de numéricos
        final cantidad = double.tryParse(row['Cantidad'].toString()) ?? 0;
        final precioUnitario = double.tryParse(row['Precio Unitario'].toString()) ?? 0;
        final comision = row['Comisión'] != null && row['Comisión'].toString().isNotEmpty
            ? double.tryParse(row['Comisión'].toString())
            : null;

        // Notas opcionales
        final notas = row['Notas']?.toString();

        // Fecha
        DateTime fecha;
        try {
          var fechaStr = row['Fecha'].toString().trim();

          // Quitar sufijo Z (UTC)
          if (fechaStr.endsWith('Z')) {
            fechaStr = fechaStr.substring(0, fechaStr.length - 1);
          }

          fecha = DateTime.parse(fechaStr);
        } catch (_) {
          print("Fecha inválida en fila $i: ${row['Fecha']}");
          continue;
        }

        // Crear objeto Operacion
        final operacion = Operacion(
          id: 0,
          idActivo: idActivo,
          tipo: tipo,
          cantidad: cantidad,
          precioUnitario: precioUnitario,
          comision: comision,
          notas: notas,
          fecha: fecha,
        );

        // Verificar si la operación ya existe
        bool exists = await _activosDao.operacionExists(
          idActivo: idActivo,
          tipo: tipo,
          cantidad: cantidad,
          fecha: fecha,
        );

        if (!exists) {
          await _activosDao.insertarOperacion(idActivo, operacion);
          print("Operación insertada correctamente: ${operacion.toMap()}");
        } else {
          print("Operación duplicada detectada, no se insertó: ${operacion.toMap()}");
        }

      } catch (e, stack) {
        print("Error al procesar fila $i: $e");
        print(stack);
      }
    }

    print("Inserción de operaciones finalizada.");
  }


  Future<void> _insertDataIntoHistorial(List<Map<String, dynamic>> data) async {
    print("Iniciando inserción de historial de valores. Total filas: ${data.length}");

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      print("Procesando fila $i: $row");

      try {
        // Validación de campo obligatorio "Activo"
        if (!row.containsKey('activo') || row['activo'] == null || row['activo'].toString().isEmpty) {
          print('Fila $i omitida: falta campo "Activo".');
          continue;
        }

        // Obtener idActivo desde el nombre
        final nombreActivo = row['activo'].toString();
        final idActivo = await _activosDao.getIdByNombre(nombreActivo);
        if (idActivo == null) {
          print("Activo no encontrado para fila $i: $nombreActivo");
          continue;
        }

        // Validación de fecha
        if (!row.containsKey('fecha') || row['fecha'] == null) {
          print('Fila $i omitida: falta campo "Fecha".');
          continue;
        }

        // Fecha
        DateTime fecha;
        try {
          var fechaStr = row['Fecha'].toString().trim();

          // Quitar sufijo Z (UTC)
          if (fechaStr.endsWith('Z')) {
            fechaStr = fechaStr.substring(0, fechaStr.length - 1);
          }

          fecha = DateTime.parse(fechaStr);
        } catch (_) {
          print("Fechas inválida en fila $i: ${row['Fecha']}");
          continue;
        }


        // Valores numéricos
        final valorCompraPromedio = row['valor_compra_promedio'] != null
            ? double.tryParse(row['valor_compra_promedio'].toString()) ?? 0.0
            : 0.0;
        final valorMercadoActual = row['valor_mercado_actual'] != null
            ? double.tryParse(row['valor_mercado_actual'].toString()) ?? 0.0
            : 0.0;

        // Crear objeto ValorHistorico
        final valorHistorico = ValorHistorico(
          fecha: fecha,
          valorCompraPromedio: valorCompraPromedio,
          valorMercadoActual: valorMercadoActual,
        );

        await _activosDao.insertarValorHistorico(idActivo, valorHistorico);

        print("Valor histórico insertado correctamente para activo $nombreActivo: ${valorHistorico.toMap()}");

      } catch (e, stack) {
        print("Error al procesar fila $i: $e");
        print(stack);
      }
    }

    print("Inserción de historial de valores finalizada.");
  }

  Future<void> _insertDataIntoPagos(List<Map<String, dynamic>> data) async {
    print("📥 Iniciando inserción de pagos. Total filas: ${data.length}");

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      print("Procesando fila $i: $row");

      try {
        // Validar nombre de la deuda
        if (!row.containsKey('Deuda') || row['Deuda'] == null) {
          print('Fila $i omitida: falta campo "Deuda".');
          continue;
        }
        final deudaNombre = row['Deuda'].toString().trim();

        // Buscar idDeuda a partir del nombre
        final idDeuda = await _deudasDao.getIdByNombre(deudaNombre);
        if (idDeuda == null) {
          print('Fila $i omitida: deuda no encontrada: $deudaNombre');
          continue;
        }

        // Validar cantidad
        if (!row.containsKey('Cantidad') || row['Cantidad'] == null) {
          print('Fila $i omitida: falta campo "Cantidad".');
          continue;
        }
        final cantidad = double.tryParse(row['Cantidad'].toString()) ?? 0.0;

        // Validar fecha
        if (!row.containsKey('Fecha') || row['Fecha'] == null) {
          print('Fila $i omitida: falta campo "Fecha".');
          continue;
        }
        DateTime fecha;
        try {
          var fechaStr = row['Fecha'].toString().trim();
          if (fechaStr.endsWith('Z')) {
            fechaStr = fechaStr.substring(0, fechaStr.length - 1);
          }
          fecha = DateTime.parse(fechaStr);
        } catch (_) {
          print("Fecha inválida en fila $i: ${row['Fecha']}");
          continue;
        }

        final notas = row['Notas']?.toString();

        final pago = PagoDeuda(
          id: 0,
          deudaId: idDeuda,
          fecha: fecha,
          cantidad: cantidad,
          notas: notas,
        );

        // Verificar duplicados
        final exists = await _deudasDao.pagoExists(
          deudaId: idDeuda,
          cantidad: cantidad,
          fecha: fecha,
        );

        if (!exists) {
          await _deudasDao.insertarPago(idDeuda, pago);
          print("Pago insertado correctamente: ${pago.toMap()}");
        } else {
          print("Pago duplicado detectado, no se insertó: ${pago.toMap()}");
        }

      } catch (e, stack) {
        print("Error al procesar fila $i: $e");
        print(stack);
      }
    }

    print("Inserción de pagos finalizada.");
  }

  final CategoriasDao _categoriasDao = CategoriasDao.instance;

  Future<void> importCsv() async {
  try {
  // Seleccionar archivo CSV
  FilePickerResult? result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['csv'],
  );

  if (result == null || result.files.single.path == null) {
  print("No se seleccionó ningún archivo.");
  return;
  }

  final file = File(result.files.single.path!);
  final content = await file.readAsLines(); // Leer el CSV línea por línea

  if (content.length < 2) {
  print("El archivo CSV no tiene datos suficientes.");
  return;
  }

  // Omitir la primera línea (encabezado) y procesar datos
  for (int i = 1; i < content.length; i++) {
  List<String> fields = content[i].split(',');

  if (fields.length < 5) {
  print("Línea inválida: ${content[i]}");
  continue;
  }

  double amount = double.tryParse(fields[0]) ?? 0.0;
  String description = fields[1].trim();
  String date = fields[2].trim();
  String occurrenceDate = fields[3].trim();
  String categoriaNombre = fields[4].trim();

  // Buscar o crear la categoría
  int? categoriaId = await _categoriasDao.getCategoriaIDByNombre(categoriaNombre);

  categoriaId ??= await _categoriasDao.insertCategoria(Categoria(
  nombre: categoriaNombre,
  tipo: 'Gasto',
  ));

  // Crear instancia del movimiento
  Movimiento movimiento = Movimiento(
  amount: amount,
  description: description,
  date: date,
  occurrenceDate: occurrenceDate,
  tipo: 'Gasto',
  categoriaId: categoriaId,
  );

  // Verificar si ya existe un movimiento similar
  bool exists = await _movimientosDao.movimientoExists(movimiento.date, movimiento.description);

  if (!exists) {
  await _movimientosDao.insertMovimiento(movimiento);
  print("Movimiento insertado: ${movimiento.description} - ${movimiento.amount}€");
  } else {
  print("Movimiento duplicado, omitiendo inserción.");
  }
  }
  } catch (e) {
  print("Error al importar CSV: $e");
  }
  }


  Future<bool> restoreZipBackup(Uint8List zipBytes, BuildContext context) async {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final Map<String, String> filesContent = {};

      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.csv')) {
          final content = utf8.decode(file.content);

          // Validacón: imprime las primeras 200 caracteres del CSV
          print('Contenido CSV (${file.name}):\n${content.substring(0, content.length > 200 ? 200 : content.length)}');

          filesContent[file.name] = content;
        }
      }

      // Orden de restauración fijo
      final ordenRestauracion = [
        'categorias',
        'activos',
        'operaciones',
        'historial_valor_promedio',
        'deudas',
        'pagos',
        'movimientos',
      ];

      for (String tabla in ordenRestauracion) {
        final entries = filesContent.entries.where(
              (e) => _getTableNameFromFileName(e.key) == tabla,
        );

        for (final entry in entries) {
          List<Map<String, dynamic>> parsedData = [];

          switch (tabla) {
            case 'pagos':
              parsedData = await parseCsvPagos(entry.value);
              await _insertDataIntoPagos(parsedData);
              break;
            case 'historial_valor_promedio':
              parsedData = parseCsvHistorialValoresActivos(entry.value);
              await _insertDataIntoHistorial(parsedData);
              break;
            case 'movimientos':
              parsedData = parseCsvMovimientos(entry.value);
              final tipo = obtenerTipoDesdeNombreArchivo(entry.key);
              await _insertDataIntoMovimientos(parsedData, tipo);
              break;
            case 'activos':
              parsedData = parseCsvActivos(entry.value);
              await _insertDataIntoActivos(parsedData);
              break;
            case 'deudas':
              parsedData = parseCsvDeudas(entry.value);
              await _insertDataIntoDeudas(parsedData);
              break;
            case 'operaciones':
              parsedData = parseCsvOperaciones(entry.value);
              await _insertDataIntoOperaciones(parsedData);
              break;
          }

          print('Datos parseados para $tabla: $parsedData');

          if (parsedData.isEmpty) {
            print('CSV para $tabla vacío o con error al parsear.');
          }
        }
      }
      return true;
    } catch (e) {
      print("Error al restaurar el ZIP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al restaurar datos: $e')),
      );
      return false;
    }
  }
}

String obtenerTipoDesdeNombreArchivo(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.startsWith('ingreso')) return 'ingreso';
  if (lower.startsWith('gasto')) return 'gasto';
  if (lower.startsWith('ahorro')) return 'ahorro';
  return 'desconocido';
}
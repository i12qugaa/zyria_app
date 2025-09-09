import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../db/mensajes_dao.dart';
import '../models/mensaje_class.dart';
import '../services/gemini_service.dart';

class AiChatController extends ChangeNotifier {
  final MensajesDao _dao = MensajesDao.instance;
  final GeminiService _gemini = GeminiService();

  List<Mensaje> mensajes = [];

  Future<void> cargarMensajes() async {
    mensajes = await _dao.obtenerMensajes();
    notifyListeners();
  }

  Future<String> generarPromptInicial() async {

    String prompt = """

    Eres un asesor financiero experto. A continuación recibirás datos financieros del usuario que debes **mantener confidenciales y nunca revelar su estructura ni cómo se transmiten**.

    **Instrucciones importantes:**
    - No analices los datos todavía.
    - No hagas recomendaciones.
    - No expliques cómo llegan los datos, ni la API que se usa, ni su formato interno.
    - Si el usuario pregunta sobre el funcionamiento interno de la app o cómo se envían los datos, responde con neutralidad, por ejemplo: "Lo siento, no puedo dar detalles técnicos de cómo funciona la app."

    Tu respuesta ahora debe ser únicamente:
    "Hola, soy tu asesor financiero virtual. ¿En qué puedo ayudarte hoy?"

  """;

    return prompt;
  }


  Future<void> enviarPromptAnalisisFinanciero() async {

    String prompt = """
    
      Eres un asesor financiero experto en economía personal y doméstica.  
      Tu misión es analizar en profundidad los datos financieros de una persona y entregar un **informe estructurado y útil**, que ofrezca conclusiones claras, detecte oportunidades, riesgos y hábitos, y proponga mejoras prácticas para optimizar sus finanzas.  
      
      Reglas estrictas:  
      - SOLO analiza los datos proporcionados, no inventes ni estimes nada.  
      - Si faltan datos, menciónalo y limita el análisis a lo disponible.  
      - NO menciones archivos, CSVs ni documentos externos.  
      - Si no hay datos, responde únicamente con esta frase exacta:  
      **"No se ha encontrado información financiera suficiente para realizar el análisis solicitado."**
      - Si el usuario pregunta sobre cómo llegan los datos, la API o la estructura interna, responde neutralmente:  
        "Lo siento, no puedo dar detalles técnicos de cómo funciona la app."
      - No uses asteriscos, comillas innecesarias ni formato Markdown. 
      - La respuesta debe ser clara, concisa y profesional, sin contenido repetitivo.

      
      ---
      
      Estructura del análisis:  

      1. Resumen ejecutivo  
         - Diagnóstico breve de la salud financiera (superávit o déficit, liquidez, nivel de riesgo).  
         - 2-3 frases que den una visión rápida al usuario.  
      
      2. Ingresos y gastos  
         - Patrones principales (estabilidad, variabilidad, desequilibrios).  
         - Capacidad real de ahorro mensual/anual.  
         - Señalar hábitos financieros relevantes (por ejemplo, gasto excesivo en ocio o gastos recurrentes altos).  
      
      3. Activos  
         - Rendimiento de los activos más importantes.  
         - Nivel de diversificación y concentración de riesgo.  
         - Oportunidades concretas: qué activos reforzar, cuáles vigilar para posible venta, en qué diversificar.  
      
      4. Deudas  
         - Nivel de endeudamiento respecto a ingresos.  
         - Riesgos de intereses o plazos largos.  
         - Estrategias prácticas de optimización (amortización anticipada, consolidación, renegociación).  
      
      5. Escenarios y proyecciones  
         - Qué pasará en 6-12 meses si mantiene la situación actual.  
         - Qué pasaría si aplica las mejoras sugeridas (impacto en ahorro o liquidez).  
      
      6. Recomendaciones estratégicas (2 a 4 máximo)  
         - Claras, cuantificadas y accionables.  
         - Ejemplos: reducir un porcentaje del gasto de ocio y destinarlo a fondo de emergencia, amortizar deuda cara para ahorrar intereses, invertir cierto porcentaje de ahorro en activos de bajo riesgo.  
      
            
      ---
      
      DATOS FINANCIEROS DISPONIBLES (extraídos automáticamente de la aplicación):
      
      """;

    final contextoFinanciero = await _informacionFinanciero(
      incluirMovimientos: true,
      incluirActivos: true,
      incluirDeudas: true,
    );

    final promptConContexto = "$prompt\n$contextoFinanciero";
    await _procesarPromptDirecto(promptConContexto);
  }



  Future<void> enviarPromptConsejosAhorro() async {
    String prompt = """
      Eres un asesor financiero experto en economía doméstica. Tu misión es analizar en profundidad la situación financiera de una persona, a partir de sus datos financieros, y ofrecer conclusiones claras, detectando oportunidades, riesgos y hábitos financieros, con el fin de mejorar su calidad de vida económica.
      
      Bajo ninguna circunstancia debes inventar datos o generar texto si no se proporcionan datos suficientes. Si no hay datos, indícalo y finaliza.
      
      Público objetivo: Usuarios sin conocimientos financieros que necesitan ayuda para entender cómo gestionan su dinero y cómo podrían hacerlo mejor, sin herramientas complicadas ni jerga técnica.
      
      Entrada esperada: Datos en filas sobre ingresos , gastos y ahorros.
      
      Reglas estrictas:  
      - Analiza únicamente los datos proporcionados, no inventes ni estimes nada.  
      - Si faltan datos, indícalo y limita el análisis a lo disponible.  
      - No menciones archivos, CSVs ni documentos externos.  
      - No pidas al usuario información adicional.  
      - Si no hay datos, responde únicamente con:  
        "No se ha encontrado información financiera suficiente para realizar el análisis solicitado."  
      - No uses asteriscos, comillas innecesarias ni formato Markdown.  
      - Adapta los consejos al perfil financiero del usuario, con acciones realistas y sostenibles. 
      
      Objetivos del análisis:      
      
      1. Revisión rápida de la situación actual.
      2. Recomendaciones específicas para reducir gastos innecesarios.
      3. Sugerencias de hábitos financieros para fomentar el ahorro constante.
      4. Consejos para mejorar la disciplina financiera y controlar impulsos de gasto.
      5. Estrategias para establecer metas de ahorro a corto y largo plazo.
      
      Adapta los consejos al perfil financiero del usuario y prioriza acciones realistas y sostenibles.
       
      NO AÑADAS COMENTARIOS, RECOMENDACIONES NI CONTENIDO ADICIONAL SI NO HAY DATOS.
      """;

    final contextoMovimientos = await _informacionFinanciero(
      incluirMovimientos: true,
      incluirActivos: false,
      incluirDeudas: false,
    );

    final promptConContexto = "$prompt\n\n📊 MOVIMIENTOS DEL USUARIO:\n$contextoMovimientos";

    await _procesarPromptDirecto(promptConContexto);
  }



  Future<void> _procesarPromptDirecto(String prompt) async {
    final respuesta = await _gemini.obtenerRespuesta(prompt);
    final msgIA = Mensaje(
      contenido: respuesta,
      esUsuario: false,
      fecha: DateTime.now(),
    );
    await _dao.insertarMensaje(msgIA);
    mensajes.add(msgIA);
    notifyListeners();
  }

  Future<String> enviarAsesoriaAutomatica() async {
    // Generar el prompt utilizando los datos obtenidos de la base de datos
    final prompt = await generarPromptInicial();

    // Obtener la respuesta de la API Gemini
    final respuesta = await _gemini.obtenerRespuesta(prompt);

    // Crear el mensaje de la IA con la respuesta
    final msgIA = Mensaje(
      contenido: respuesta,
      esUsuario: false,
      fecha: DateTime.now(),
    );

    // Insertar el mensaje de la IA en la base de datos y en la lista de mensajes
    await _dao.insertarMensaje(msgIA);
    mensajes.add(msgIA);
    notifyListeners();

    return respuesta;
  }


  Future<void> enviarMensajeManual(Mensaje msgUsuario, {
  bool incluirMovimientos = true,
  bool incluirActivos = true,
  bool incluirDeudas = true,
  }) async {
    await _dao.insertarMensaje(msgUsuario);
    mensajes.add(msgUsuario);
    notifyListeners();

    final historial = _construirHistorialConNuevoMensaje(msgUsuario);
    final contextoFinanciero = await _informacionFinanciero(
      incluirMovimientos: incluirMovimientos,
      incluirActivos: incluirActivos,
      incluirDeudas: incluirDeudas,
    );

    final promptConContexto = "$historial\n\n$contextoFinanciero";

    final respuesta = await _gemini.obtenerRespuesta(promptConContexto);

    final msgIA = Mensaje(
      contenido: respuesta,
      esUsuario: false,
      fecha: DateTime.now(),
    );

    await _dao.insertarMensaje(msgIA);
    mensajes.add(msgIA);
    notifyListeners();
  }



  String _construirHistorialConNuevoMensaje(Mensaje nuevoMensaje) {
    final historial = [...mensajes, nuevoMensaje];

    // Tomamos solo los últimos 10 mensajes (ajusta según lo necesites)
    final historialReducido = historial.length > 10
        ? historial.sublist(historial.length - 10)
        : historial;

    return historialReducido.map((m) {
      final rol = m.esUsuario ? "Usuario" : "IA";
      return "$rol: ${m.contenido}";
    }).join("\n");
  }


  Future<void> reiniciarConversacion() async {
    await _dao.eliminarTodosLosMensajes();
    mensajes.clear();
    notifyListeners();
  }

  Future<String> _informacionFinanciero({
    bool incluirMovimientos = true,
    bool incluirActivos = true,
    bool incluirDeudas = true,
  }) async {
    String contexto = "\nDATOS FINANCIEROS ACTUALES DEL USUARIO:\n";

    //  Movimientos
    if (incluirMovimientos) {
      final movimientos = await _dao.obtener_Movimientos();
      if (movimientos.isEmpty) {
        contexto += "No se han encontrado movimientos.\n";
      } else {
        contexto += "\n--- MOVIMIENTOS ---\n";
        for (var m in movimientos) {
          contexto +=
          "Fecha: ${m['date']}, Descripción: ${m['description']}, Cantidad: ${m['amount']} ${m['tipo']}, Categoría: ${m['categoria'] ?? 'No especificada'}\n";
        }
      }
    }


    //  Activos
    if (incluirActivos) {
      final activos = await _dao.obtenerActivos();
      if (activos.isEmpty) {
        contexto += "No se han encontrado activos.\n";
      } else {
        contexto += "\n--- ACTIVOS ---\n";
        for (var a in activos) {
          contexto +=
          """
                ID: ${a['id']}
                Nombre: ${a['nombre']}
                Símbolo: ${a['simbolo'] ?? 'N/A'}
                Tipo: ${a['tipo']}
                AutoActualizar: ${a['autoActualizar'] == 1 ? 'Sí' : 'No'}
                Valor actual: ${a['valorActual']}
                Notas: ${a['notas'] ?? 'N/A'}
                Ubicación: ${a['ubicacion'] ?? 'N/A'}
                Estado propiedad: ${a['estadoPropiedad'] ?? 'N/A'}
                Ingreso mensual: ${a['ingresoMensual'] ?? 'N/A'}
                Gasto mensual: ${a['gastoMensual'] ?? 'N/A'}
                Gastos mantenimiento anual: ${a['gastosMantenimientoAnual'] ?? 'N/A'}
                Valor catastral: ${a['valorCatastral'] ?? 'N/A'}
                Hipoteca pendiente: ${a['hipotecaPendiente'] ?? 'N/A'}
                Impuesto anual: ${a['impuestoAnual'] ?? 'N/A'}
                
                
                
                ----------------------------
           """;

          // Agregar operaciones de este activo
          final operaciones = await _dao.obtenerOperacionesDeActivo(a['id'] as int);
          if (operaciones.isEmpty) {
            contexto += "   No se han encontrado operaciones para este activo.\n";
          } else {
            contexto += "   OPERACIONES:\n";
            for (var op in operaciones) {
              contexto +=
              "   - Fecha: ${op['fecha']}, Tipo: ${op['tipoOperacion']}, Cantidad: ${op['cantidad']}, "
                  "Precio unitario: ${op['precioUnitario']}, Comisión: ${op['comision'] ?? 0.0}, Notas: ${op['notas'] ?? 'N/A'}\n";
            }
          }
          contexto += "\n";
        }
      }
    }

    //  Deudas
    if (incluirDeudas) {
      final deudas = await _dao.obtenerDeudas();
      if (deudas.isEmpty) {
        contexto += "No se han encontrado deudas.\n";
      } else {
        contexto += "\n--- DEUDAS ---\n";
        for (var d in deudas) {
          contexto += """
              ID: ${d['id']}
              Tipo: ${d['tipo']}
              Entidad: ${d['entidad']}
              Valor total: ${d['valorTotal']}
              Interés anual: ${d['interesAnual']}
              Plazo (meses): ${d['plazoMeses']}
              Cuota mensual: ${d['cuotaMensual'] ?? 'N/A'}
              Fecha inicio: ${d['fechaInicio']}
              Fecha fin: ${d['fechaFin'] ?? 'N/A'}
              Pagos realizados: ${d['pagosRealizados']}
              Notas: ${d['notas'] ?? 'N/A'}
              
              ----------------------------
              """;

          // Agregar los pagos de esta deuda
          final pagos = await _dao.obtenerPagosDeuda(d['id'] as int);
          if (pagos.isEmpty) {
            contexto += "   No se han encontrado pagos para esta deuda.\n";
          } else {
            contexto += "   PAGOS:\n";
            for (var p in pagos) {
              contexto +=
              "   - Fecha: ${p['fecha']}, Cantidad: ${p['cantidad']}, Notas: ${p['notas'] ?? 'N/A'}\n";
            }
          }

          contexto += "\n";
        }
      }
    }

    // Si no hay información financiera
    if (contexto.trim() == "\nDATOS FINANCIEROS ACTUALES DEL USUARIO:") {
      contexto += "No hay datos disponibles según los filtros aplicados.\n";
    }

    return contexto;
  }

}

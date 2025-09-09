import 'package:flutter/material.dart';
import 'package:finanzas_app/themes/light_theme.dart';
import 'package:finanzas_app/themes/dark_theme.dart';
import 'package:finanzas_app/themes/theme_provider.dart';
import 'package:finanzas_app/views/home_view.dart';
import 'package:provider/provider.dart'; // Paquete de gestión de estado
import 'controllers/activos_controller.dart';
import 'controllers/ai_controller.dart';
import 'controllers/deudas_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/movimientos_controller.dart';
import 'db/database.dart';
import 'package:intl/date_symbol_data_local.dart';


final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que flutter este inicializado

  // Inicializa la base de datos
  await DatabaseHelper.instance.database;
  await initializeDateFormatting('es_ES', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider<HomeController>(
          create: (context) => HomeController(),
        ),
        ChangeNotifierProvider(create: (_) => MovimientosController()),
        ChangeNotifierProvider(create: (_) => ActivosController()),
        ChangeNotifierProvider(create: (_) => DeudasController()),
        ChangeNotifierProvider(create: (_) => AiChatController()),
      ],
      child: const MyApp(),
    ),
  );

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>( // Consumer se utiliza para escuchar los cambios del ThemeProvider
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Finanzas App',
          theme: lightTheme, // Tema claro
          darkTheme: darkTheme, // Tema oscuro
          themeMode: themeProvider.themeMode, // Modo de tema según el estado del provider
          navigatorObservers: [routeObserver],
          home: HomeView(),
           // home: ImportCsvView(),
        );
      },
    );
  }
}

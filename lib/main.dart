import 'package:flutter/material.dart';
import 'screens/splash_animado.dart';
import 'screens/catalogo_palmito.dart';
import 'screens/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Palmito NM',
      theme: ThemeData(
        primaryColor: const Color(0xFF3F4E34),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF3F4E34),
        ),
      ),
      
      // La app arranca con la animación circular
      home: const SplashAnimado(),

      // Rutas para navegación limpia
      routes: {
        '/login': (context) => const Login(),
        '/catalogo': (context) => const CatalogoPalmito(
          usuarioActual: {}, 
          mfaActivo: false, 
          tienePreguntas: false,
        ),
      },
    );
  }
}
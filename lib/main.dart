import 'package:flutter/material.dart';
import 'screens/catalogo_palmito.dart'; // Importamos el catálogo como pantalla inicial

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
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Iniciamos directamente en el Catálogo pasando un mapa vacío
      home: const CatalogoPalmito(
        usuarioActual: {}, 
        mfaActivo: false, 
        tienePreguntas: false
      ),
    );
  }
}
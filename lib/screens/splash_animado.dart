import 'package:flutter/material.dart';
import 'catalogo_palmito.dart'; // Cambiamos el import de login por el de catálogo

class SplashAnimado extends StatefulWidget {
  const SplashAnimado({super.key});

  @override
  State<SplashAnimado> createState() => _SplashAnimadoState();
}

class _SplashAnimadoState extends State<SplashAnimado> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    
    // VELOCIDAD: 6 segundos para un giro suave y profesional
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), 
    )..repeat(); 

    // TIEMPO DE ESPERA: 3 segundos de animación antes de entrar
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Redirección directa al Catálogo con los parámetros iniciales
            builder: (context) => const CatalogoPalmito(
              usuarioActual: {}, 
              mfaActivo: false, 
              tienePreguntas: false,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5), // Fondo crema de Palmito NM
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0), 
          child: RotationTransition(
            turns: _controller,
            child: Image.asset(
              'assets/img/LOGOV2.png',
              height: 160, 
              fit: BoxFit.contain, 
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.eco, size: 100, color: Color(0xFF3F4E34)),
            ),
          ),
        ),
      ),
    );
  }
}
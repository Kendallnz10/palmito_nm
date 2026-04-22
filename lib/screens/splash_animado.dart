import 'package:flutter/material.dart';
import 'login.dart'; 

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
    
    // VELOCIDAD: Subimos a 6 segundos para que el giro sea más lento
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), 
    )..repeat(); 

    // TIEMPO DE ESPERA: Bajamos a 3 segundos para que sea más dinámico
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()), 
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
      backgroundColor: const Color(0xFFF2E8D5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0), // Margen para que no se corte
          child: RotationTransition(
            turns: _controller,
            child: Image.asset(
              'assets/img/LOGOV2.png',
              height: 160, // Ajustamos el tamaño para que no se corte
              fit: BoxFit.contain, // Asegura que la imagen quepa completa
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.eco, size: 100, color: Color(0xFF3F4E34)),
            ),
          ),
        ),
      ),
    );
  }
}
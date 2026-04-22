import 'package:flutter/material.dart';
import 'login.dart'; // Asegúrate de que el nombre del archivo sea correcto (login.dart o login_screen.dart)

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
    
    // Configuración de la rotación
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // Gira indefinidamente

    // Tiempo de espera para pasar a la siguiente pantalla
    Future.delayed(const Duration(seconds: 4), () {
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
      backgroundColor: const Color(0xFFF2E8D5), // Tu color crema
      body: Center(
        child: RotationTransition(
          turns: _controller,
          child: Image.asset(
            'assets/img/LOGOV2.png',
            height: 180,
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.eco, size: 100, color: Color(0xFF3F4E34)),
          ),
        ),
      ),
    );
  }
}
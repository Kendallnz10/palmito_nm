import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/producto.dart';
import '../services/producto_services.dart';
import 'catalogo_palmito.dart';

class SplashAnimado extends StatefulWidget {
  final Map<String, dynamic>? usuarioActual;
  final bool mfaActivo;
  final bool tienePreguntas;

  const SplashAnimado({
    super.key,
    this.usuarioActual,
    this.mfaActivo = false,
    this.tienePreguntas = false,
  });

  @override
  State<SplashAnimado> createState() => _SplashAnimadoState();
}

class _SplashAnimadoState extends State<SplashAnimado>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final ProductoService _productoService = ProductoService();
  List<Producto>? _productosPreCargados;
  bool _tiempoMinimoCumplido = false;
  bool _imagenesPreCargadas = false;

  @override
  void initState() {
    super.initState();

    // Animación de rotación infinita para el logo
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Animación de aparición suave
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();

    // Temporizador: El splash durará al menos 2.5 segundos
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _tiempoMinimoCumplido = true);
        _intentarNavegar();
      }
    });

    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    try {
      // 1. Cargar productos desde la base de datos
      final productos = await _productoService.fetchProductos();
      _productosPreCargados = productos;

      // 2. Pre-cargar las imágenes en la memoria caché de Flutter
      if (mounted) {
        await Future.wait(
          productos.map((p) {
            return precacheImage(NetworkImage(p.imagen), context)
                .catchError((_) => {}); // Evita que un error de URL detenga todo
          }),
        );
      }
    } catch (e) {
      debugPrint("Error precargando datos: $e");
      _productosPreCargados = [];
    }

    if (mounted) {
      setState(() => _imagenesPreCargadas = true);
      _intentarNavegar();
    }
  }

  void _intentarNavegar() {
    // Solo navega si ya pasó el tiempo mínimo Y los datos están cargados
    if (_tiempoMinimoCumplido && _imagenesPreCargadas) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CatalogoPalmito(
            usuarioActual: widget.usuarioActual ?? {},
            mfaActivo: widget.mfaActivo,
            tienePreguntas: widget.tienePreguntas,
            productosPreCargados: _productosPreCargados,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D5),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: RotationTransition(
                  turns: _rotationController,
                  child: Image.asset(
                    'assets/img/LOGOV2.png',
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.eco, size: 100, color: Color(0xFF3F4E34)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Cargando...",
                style: GoogleFonts.lora(
                  color: const Color(0xFF3B4D28),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
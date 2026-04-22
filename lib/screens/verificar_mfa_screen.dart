import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- SERVICIOS ---
import '../services/usuario_service.dart';

// --- PANTALLAS ---
import 'splash_animado.dart'; // IMPORTANTE: Cambiado de catalogo a splash

class VerificarMFAScreen extends StatefulWidget {
  final dynamic idUsuario;

  const VerificarMFAScreen({super.key, required this.idUsuario});

  @override
  State<VerificarMFAScreen> createState() => _VerificarMFAScreenState();
}

class _VerificarMFAScreenState extends State<VerificarMFAScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final UsuarioService _usuarioService = UsuarioService();
  bool _cargando = false;

  // Colores Corporativos Palmito NM
  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color fondoCrema = const Color(0xFFF2E8D5);
  final Color rojoElegante = const Color(0xFF9E2A2B);

  Future<void> _validarCodigo() async {
    String codigo = _codigoController.text.trim();

    if (codigo.length < 6) {
      _mostrarAlerta("Ingrese los 6 dígitos del autenticador");
      return;
    }

    setState(() => _cargando = true);

    try {
      final res = await _usuarioService.verificarMFA(widget.idUsuario, codigo);
      
      final int statusCode = res['statusCode'];
      final dynamic body = res['body'];

      if (mounted) setState(() => _cargando = false);

      if (statusCode == 200 && body != null) {
        var usuarioDataRaw = body['usuario'] ?? 
                             (body['body'] != null ? body['body']['usuario'] : null);

        if (usuarioDataRaw != null) {
          Map<String, dynamic> usuarioFinal = Map<String, dynamic>.from(usuarioDataRaw);
          
          usuarioFinal['nombre'] = usuarioFinal['nombre'] ?? usuarioFinal['Nombre'] ?? "Usuario";
          bool mfaActivo = usuarioFinal['mfa_activado'] == true || usuarioFinal['mfa_activado'] == 1;

          if (mounted) {
            debugPrint(">>> MFA EXITOSO: Navegando al Splash de carga...");
            
            // NAVEGACIÓN AL SPLASH ANIMADO
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => SplashAnimado(
                  usuarioActual: usuarioFinal,
                  mfaActivo: mfaActivo,        
                  tienePreguntas: usuarioFinal['preguntas_configuradas'] ?? true,   
                ),
              ),
              (route) => false, 
            );
          }
        } else {
          _mostrarAlerta("Error: No se recibieron los datos del perfil.");
        }
      } else {
        String mensaje = (body != null && body['mensaje'] != null) 
            ? body['mensaje'] 
            : "Código de seguridad incorrecto";
        _mostrarAlerta(mensaje);
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
      debugPrint(">>> ERROR CRÍTICO VERIFICAR_MFA: $e");
      _mostrarAlerta("Error de conexión con el servidor");
    }
  }

  void _mostrarAlerta(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        backgroundColor: rojoElegante,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: verdeBosque),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: verdeBosque.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.security_update_good_outlined, size: 70, color: verdeBosque),
              ),
              const SizedBox(height: 25),
              Text(
                "VERIFICACIÓN",
                style: GoogleFonts.lora(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: verdeBosque,
                  letterSpacing: 1.2
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Ingresa el código de 6 dígitos generado por tu aplicación de autenticación.",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: verdeBosque.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8)
                    )
                  ]
                ),
                child: TextField(
                  controller: _codigoController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: GoogleFonts.montserrat(
                    fontSize: 35, 
                    letterSpacing: 12, 
                    fontWeight: FontWeight.bold, 
                    color: verdeBosque
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "000000",
                    hintStyle: TextStyle(color: verdeBosque.withOpacity(0.1)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _validarCodigo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verdeBosque,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _cargando
                    ? const SizedBox(
                        height: 28, 
                        width: 28, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                    : Text(
                        "VERIFICAR ACCESO",
                        style: GoogleFonts.montserrat(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          letterSpacing: 1.1
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "VOLVER AL INICIO", 
                  style: GoogleFonts.montserrat(
                    color: Colors.black45, 
                    fontWeight: FontWeight.w600,
                    fontSize: 13
                  )
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/usuario_service.dart';

class ConfigurarMFAScreen extends StatefulWidget {
  final Map<String, dynamic> usuarioActual;
  const ConfigurarMFAScreen({super.key, required this.usuarioActual});

  @override
  State<ConfigurarMFAScreen> createState() => _ConfigurarMFAScreenState();
}

class _ConfigurarMFAScreenState extends State<ConfigurarMFAScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _codigoController = TextEditingController();
  
  String? qrCodeData; 
  bool _isLoading = true;
  bool _isVerifying = false;
  int mfaActivado = 0; 

  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color fondoLogoCrema = const Color(0xFFF2E8D5);
  final Color cremaInput = const Color(0xFFF9F7F2);

  @override
  void initState() {
    super.initState();
    _inicializarEstado();
  }

  void _inicializarEstado() {
    // CORRECCIÓN: Buscamos MFA_Activado tanto en mayúsculas como minúsculas
    final mfaRaw = widget.usuarioActual['MFA_Activado'] ?? widget.usuarioActual['mfa_activado'];
    setState(() {
      mfaActivado = (mfaRaw == true || mfaRaw == 1 || mfaRaw == '1') ? 1 : 0;
      if (mfaActivado == 0) {
        _generarQR();
      } else {
        _isLoading = false;
      }
    });
  }

  Future<void> _generarQR() async {
    try {
      // CORRECCIÓN DE ID: Buscamos el ID en ambos formatos
      final dynamic idRaw = widget.usuarioActual['id_usuario'] ?? widget.usuarioActual['ID_Usuario'];
      final String correo = widget.usuarioActual['Correo'] ?? widget.usuarioActual['correo'] ?? "correo@ejemplo.com";

      if (idRaw == null) throw "No se encontró el ID del usuario";

      final res = await _usuarioService.activarMFA(idRaw, correo);

      if (res['statusCode'] == 200) {
        setState(() {
          // Validamos si la respuesta trae 'body' o viene directo
          final data = res['body'] ?? res;
          qrCodeData = data['qrCode']; 
          _isLoading = false;
        });
      } else {
        throw res['mensaje'] ?? "Error en servidor";
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _mostrarMensaje("Error al cargar QR: $e");
    }
  }

  Future<void> _validarYActivar() async {
    if (_codigoController.text.length < 6) {
      _mostrarMensaje("El código debe ser de 6 dígitos");
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // CORRECCIÓN DE ID: Buscamos el ID en ambos formatos antes de enviar
      final idRaw = widget.usuarioActual['id_usuario'] ?? widget.usuarioActual['ID_Usuario'];
      
      final res = await _usuarioService.verificarMFA(idRaw, _codigoController.text.trim());

      // Validamos éxito (algunos backends devuelven success dentro de body)
      final bool esExitoso = res['statusCode'] == 200 || (res['body'] != null && res['body']['success'] == true);

      if (esExitoso) {
        if (mounted) {
          _mostrarMensaje("¡MFA ACTIVADO EXITOSAMENTE!", esError: false);
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context, true); 
        }
      } else {
        _mostrarMensaje(res['mensaje'] ?? "Código incorrecto o expirado");
      }
    } catch (e) {
      _mostrarMensaje("Error de conexión: $e");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje, style: GoogleFonts.montserrat()), 
          backgroundColor: esError ? const Color(0xFF9E2A2B) : verdeBosque,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mfaActivado == 1) return _buildPantallaProtegida();

    return Scaffold(
      backgroundColor: fondoLogoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: verdeBosque,
        title: Text("SEGURIDAD", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: verdeBosque))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Mantenemos tu logo original
                  Image.asset('assets/img/LOGOV2.png', height: 90, 
                    errorBuilder: (c, e, s) => Icon(Icons.security, size: 60, color: verdeBosque)),
                  const SizedBox(height: 10),
                  Text("Doble Factor (2FA)", 
                    style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.bold, color: verdeBosque)),
                  const SizedBox(height: 10),
                  Text("Escanea el código con Google Authenticator", 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 30),
                  
                  _buildQRContainer(),
                  
                  const SizedBox(height: 40),
                  _buildInputSeccion(),
                  
                  const SizedBox(height: 30),
                  _buildBotonAccion(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildQRContainer() {
    if (qrCodeData == null) return Text("Cargando código QR...", style: GoogleFonts.montserrat());
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: qrCodeData!.startsWith('data:image')
            ? Image.memory(base64Decode(qrCodeData!.split(',').last), width: 200)
            : Image.network(qrCodeData!, width: 200),
      ),
    );
  }

  Widget _buildInputSeccion() {
    return Column(
      children: [
        Text("CÓDIGO DE VERIFICACIÓN", 
          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: verdeBosque)),
        const SizedBox(height: 15),
        TextField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 10, color: verdeBosque),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: cremaInput,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: verdeBosque)),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonAccion() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: verdeBosque, 
          foregroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        onPressed: _isVerifying ? null : _validarYActivar,
        child: _isVerifying 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(
              "ACTIVAR SEGURIDAD", 
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)
            ),
      ),
    );
  }

  Widget _buildPantallaProtegida() {
    return Scaffold(
      backgroundColor: fondoLogoCrema,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 100, color: Color(0xFF3B4D28)),
              const SizedBox(height: 20),
              Text("¡PROTECCIÓN ACTIVA!", 
                style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold, color: verdeBosque)),
              const SizedBox(height: 10),
              Text("Tu cuenta cuenta con doble factor de autenticación.", 
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 50),
              SizedBox(
                width: 200,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: verdeBosque),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("VOLVER", style: GoogleFonts.montserrat(color: verdeBosque, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
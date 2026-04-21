import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'registrar_cuenta.dart';

class VerificarCorreo extends StatefulWidget {
  const VerificarCorreo({super.key});

  @override
  State<VerificarCorreo> createState() => _VerificarCorreoState();
}

class _VerificarCorreoState extends State<VerificarCorreo> {
  final _correoController = TextEditingController();
  final _codigoController = TextEditingController();
  
  bool _codigoEnviado = false; 
  bool _cargando = false;      

  // --- COLORES CORPORATIVOS ---
  final Color fondoLogoCrema = const Color(0xFFF2E8D5); 
  final Color verdeBosque = const Color(0xFF3B4D28);    
  final Color verdeSalvia = const Color(0xFF7D9452);    
  final Color cremaInput = const Color(0xFFF9F7F2);     
  final Color rojoElegante = const Color(0xFF9E2A2B);

  final String baseUrl = "https://backend-palmitonm.onrender.com/usuarios"; 

  Future<void> _enviarCodigo() async {
    if (_correoController.text.trim().isEmpty) {
      _mostrarAlerta("Por favor, ingresa un correo válido");
      return;
    }
    setState(() => _cargando = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/enviar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': _correoController.text.trim()}),
      );
      if (res.statusCode == 200) {
        setState(() => _codigoEnviado = true);
        _mostrarAlerta("Código enviado. Revisa tu correo.", esError: false);
      } else {
        final data = jsonDecode(res.body);
        _mostrarAlerta(data['mensaje'] ?? "Error al enviar código");
      }
    } catch (e) {
      _mostrarAlerta("Error de conexión con el servidor");
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _validarYProceder() async {
    if (_codigoController.text.trim().isEmpty) {
      _mostrarAlerta("Ingresa el código de 6 dígitos");
      return;
    }
    setState(() => _cargando = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/validar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _correoController.text.trim(),
          'codigo': _codigoController.text.trim()
        }),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrarCuenta(correoVerificado: _correoController.text.trim())
            ),
          );
        }
      } else {
        _mostrarAlerta("Código incorrecto o expirado");
      }
    } catch (e) {
      _mostrarAlerta("Error al validar código");
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarAlerta(String msg, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat()), 
        backgroundColor: esError ? rojoElegante : verdeBosque,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoLogoCrema,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: verdeBosque),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 35.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Image.asset('assets/img/LOGOV2.png', height: 140, 
              errorBuilder: (c, e, s) => Icon(Icons.eco, size: 100, color: verdeBosque)),
            const SizedBox(height: 8),
            Text(
              "Verificación", 
              style: GoogleFonts.lora(fontSize: 34, fontWeight: FontWeight.bold, color: verdeBosque)
            ),
            const SizedBox(height: 10),
            Text(
              "Validaremos tu identidad antes del registro",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 45),

            // Campo de Correo
            _buildInput(
              controller: _correoController, 
              icon: Icons.email_outlined, 
              hint: "Correo Electrónico",
              habilitado: !_codigoEnviado
            ),

            if (_codigoEnviado) ...[
              const SizedBox(height: 18),
              _buildInput(
                controller: _codigoController, 
                icon: Icons.lock_clock_outlined, 
                hint: "Código de 6 dígitos",
                tipo: TextInputType.number
              ),
            ],

            const SizedBox(height: 40),

            _buildBoton(
              texto: _codigoEnviado ? "VERIFICAR CÓDIGO" : "OBTENER CÓDIGO", 
              color: verdeBosque, 
              accion: _codigoEnviado ? _validarYProceder : _enviarCodigo, 
              cargando: _cargando
            ),
            
            if (_codigoEnviado)
              TextButton(
                onPressed: () => setState(() => _codigoEnviado = false),
                child: Text(
                  "¿Usar otro correo?", 
                  style: GoogleFonts.montserrat(
                    color: rojoElegante, 
                    fontSize: 12, 
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
              
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBoton({required String texto, required Color color, required VoidCallback accion, bool cargando = false}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: cargando ? null : accion,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, 
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
        child: cargando 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(texto, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller, 
    required IconData icon, 
    required String hint, 
    bool habilitado = true,
    TextInputType tipo = TextInputType.text
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cremaInput, 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: TextField(
        controller: controller,
        enabled: habilitado,
        keyboardType: tipo,
        style: GoogleFonts.montserrat(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: verdeBosque, size: 22),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        ),
      ),
    );
  }
}
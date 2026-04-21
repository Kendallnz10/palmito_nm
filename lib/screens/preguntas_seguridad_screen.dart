import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/usuario_service.dart';

class PreguntasSeguridadScreen extends StatefulWidget {
  final Map<String, dynamic> usuarioActual;
  const PreguntasSeguridadScreen({super.key, required this.usuarioActual});

  @override
  State<PreguntasSeguridadScreen> createState() => _PreguntasSeguridadScreenState();
}

class _PreguntasSeguridadScreenState extends State<PreguntasSeguridadScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  
  final TextEditingController _respuesta1 = TextEditingController();
  final TextEditingController _respuesta2 = TextEditingController();

  String? _pregunta1Seleccionada;
  String? _pregunta2Seleccionada;

  final List<String> _catalogoPreguntas = [
    "¿CUÁL ES EL NOMBRE DE TU PRIMERA MASCOTA?",
    "¿EN QUÉ CIUDAD NACIERON TUS PADRES?",
    "¿CUÁL FUE TU ESCUELA PRIMARIA?",
    "¿CUÁL ES TU COMIDA FAVORITA DE LA INFANCIA?",
    "¿CÓMO SE LLAMABA TU MEJOR AMIGO DE NIÑO?",
  ];

  bool _isSaving = false;

  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color cremaInput = const Color(0xFFF9F7F2);
  final Color fondoCrema = const Color(0xFFF2E8D5);

  Future<void> _guardarConfiguracion() async {
    // 1. CORRECCIÓN DE ID: Buscamos el ID en los dos formatos posibles para asegurar que no sea null
    final dynamic idRaw = widget.usuarioActual['id_usuario'] ?? widget.usuarioActual['ID_Usuario'];
    
    if (idRaw == null) {
      _mostrarMsj("Error: No se pudo recuperar el ID del usuario. Reintente el login.", esError: true);
      return;
    }

    if (_pregunta1Seleccionada == null || _pregunta2Seleccionada == null || 
        _respuesta1.text.isEmpty || _respuesta2.text.isEmpty) {
      _mostrarMsj("Por favor completa todas las preguntas y respuestas", esError: true);
      return;
    }

    if (_pregunta1Seleccionada == _pregunta2Seleccionada) {
      _mostrarMsj("No puedes elegir la misma pregunta dos veces", esError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // DEBUG para consola de Flutter
      print("Enviando a Backend - ID: $idRaw");

      final res = await _usuarioService.guardarPreguntasSeguridad(
        idUsuario: idRaw, // <--- ID CORREGIDO
        p1: _pregunta1Seleccionada!,
        r1: _respuesta1.text.trim().toUpperCase(),
        p2: _pregunta2Seleccionada!,
        r2: _respuesta2.text.trim().toUpperCase(),
      );

      // Verificamos éxito tanto por booleano como por código HTTP
      if (res['success'] == true || res['statusCode'] == 200) {
        _mostrarMsj("Configuración guardada correctamente", esError: false);
        
        // Esperamos un poco para que el usuario vea el mensaje verde
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        _mostrarMsj(res['mensaje'] ?? "Error al guardar configuración");
      }
    } catch (e) {
      _mostrarMsj("Error de conexión: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarMsj(String msj, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msj, style: GoogleFonts.montserrat()),
      backgroundColor: esError ? const Color(0xFF9E2A2B) : verdeBosque,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: verdeBosque),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              // --- EL LOGO ESTÁ DE VUELTA AQUÍ ---
              Image.asset('assets/img/LOGOV2.png', height: 100),
              // ------------------------------------
              const SizedBox(height: 10),
              Text("Seguridad", 
                style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold, color: verdeBosque)
              ),
              const SizedBox(height: 10),
              Text("Configura tus preguntas para recuperar tu cuenta.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 30),
              
              _buildLabel("SELECCIONE PREGUNTA 1"),
              _buildDropdownPregunta(
                currentVal: _pregunta1Seleccionada,
                onChanged: (val) => setState(() => _pregunta1Seleccionada = val),
              ),
              const SizedBox(height: 15),
              _buildLabel("RESPUESTA 1"),
              _buildInputRespuesta(_respuesta1),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Divider(color: Colors.black12, thickness: 1),
              ),
              
              _buildLabel("SELECCIONE PREGUNTA 2"),
              _buildDropdownPregunta(
                currentVal: _pregunta2Seleccionada,
                onChanged: (val) => setState(() => _pregunta2Seleccionada = val),
              ),
              const SizedBox(height: 15),
              _buildLabel("RESPUESTA 2"),
              _buildInputRespuesta(_respuesta2),

              const SizedBox(height: 40),
              _buildGuardarButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(texto, 
        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: verdeBosque, letterSpacing: 0.5)
      ),
    );
  }

  Widget _buildDropdownPregunta({required String? currentVal, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: cremaInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          decoration: const InputDecoration(border: InputBorder.none),
          value: currentVal,
          isExpanded: true,
          hint: Text("SELECCIONE UNA OPCIÓN", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black38)),
          items: _catalogoPreguntas.map((p) => DropdownMenuItem(
            value: p, 
            child: Text(p, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500))
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInputRespuesta(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: cremaInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        inputFormatters: [UpperCaseTextFormatter()],
        style: GoogleFonts.montserrat(fontSize: 14),
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: "ESCRIBA SU RESPUESTA AQUÍ...",
          hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.black26),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildGuardarButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: verdeBosque,
          foregroundColor: Colors.white,
          disabledBackgroundColor: verdeBosque.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        onPressed: _isSaving ? null : _guardarConfiguracion,
        child: _isSaving 
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ) 
          : Text("GUARDAR CONFIGURACIÓN", 
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.5,
                fontSize: 13
              )),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
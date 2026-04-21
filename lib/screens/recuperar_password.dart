import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/usuario_service.dart';

class RecuperarPassword extends StatefulWidget {
  const RecuperarPassword({super.key});

  @override
  State<RecuperarPassword> createState() => _RecuperarPasswordState();
}

class _RecuperarPasswordState extends State<RecuperarPassword> {
  final _usuarioController = TextEditingController();
  final _correoController = TextEditingController();
  final _codigoController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final UsuarioService _usuarioService = UsuarioService();
  bool _cargando = false;
  
  // ESTADOS DE FLUJO
  bool _correoEnviado = false; // Habilita el campo OTP
  bool _codigoValidado = false; // Habilita los campos de Password
  
  dynamic _idUsuarioCapturado; 

  bool _obscurePass1 = true;
  bool _obscurePass2 = true;

  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color cremaInput = const Color(0xFFF9F7F2);
  final Color fondoCrema = const Color(0xFFF2E8D5);

  // Validaciones de contraseña
  bool get _tieneLargoOk => _passController.text.length >= 10;
  bool get _noTieneVocales => !RegExp(r'[aeiouAEIOU]').hasMatch(_passController.text) && _passController.text.isNotEmpty;
  bool get _tieneNumero => RegExp(r'\d').hasMatch(_passController.text);
  bool get _tieneSimbolo => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passController.text);
  bool get _esMayusculas => _passController.text == _passController.text.toUpperCase() && _passController.text.isNotEmpty;

  @override
  void dispose() {
    _usuarioController.dispose();
    _correoController.dispose();
    _codigoController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE NEGOCIO ---

Future<void> _validarYEnviarCodigo() async {
  if (_correoController.text.isEmpty || _usuarioController.text.isEmpty) {
    _msg("Ingrese usuario y correo electrónico");
    return;
  }
  setState(() => _cargando = true);
  try {
    final res = await _usuarioService.obtenerPreguntasPorCorreo(_correoController.text.trim());
    
    // DEBUG: Copia lo que salga aquí en la consola de VS Code para ver la estructura real
    print("DEBUG PAYLOAD: $res");

    if (res['success'] == true) {
      // Intentamos extraer el usuario con la ruta que mencionas
      final userData = res['body']?['body']?['usuario'];

      if (userData != null) {
        // REVISIÓN: Verifica si en tu BD es 'usuario' o 'nombre_usuario'
        // En tu login usaste 'user.usuario', fíjate si aquí es igual
        String nombreServidor = (userData['usuario'] ?? userData['nombre_usuario'] ?? "").toString().trim().toUpperCase();
        String nombreIngresado = _usuarioController.text.trim().toUpperCase();

        print("Comparando: '$nombreServidor' vs '$nombreIngresado'");

        if (nombreServidor == nombreIngresado) {
          _idUsuarioCapturado = userData['id_usuario']; 

          final otpRes = await _usuarioService.enviarCodigoVerificacion(_correoController.text.trim());
          if (otpRes['success'] == true) {
            setState(() => _correoEnviado = true);
            _msg("Código enviado a su correo", esError: false);
          } else {
            _msg("Error al enviar el código");
          }
        } else {
          _msg("El usuario no coincide con el correo");
        }
      } else {
        _msg("Error: Estructura de usuario no encontrada en la respuesta");
      }
    } else {
      _msg("Correo no encontrado");
    }
  } catch (e) {
    print("Error catch: $e");
    _msg("Error de conexión");
  } finally {
    setState(() => _cargando = false);
  }
}

  Future<void> _validarCodigoOTP() async {
    if (_codigoController.text.isEmpty) return;
    setState(() => _cargando = true);
    try {
      final res = await _usuarioService.validarCodigoOTP(
        _correoController.text.trim(), 
        _codigoController.text.trim()
      );
      
      if (res['success'] == true) {
        setState(() => _codigoValidado = true); // ACTIVAR CAMPOS PASSWORD
        _msg("Código correcto. Defina su nueva contraseña", esError: false);
      } else {
        _msg("Código incorrecto o expirado");
      }
    } catch (e) {
      _msg("Error validando código");
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarCambio() async {
    if (!_codigoValidado || _idUsuarioCapturado == null) return;
    
    if (_passController.text != _confirmPassController.text) {
      _msg("Las contraseñas no coinciden");
      return;
    }

    if (!_tieneLargoOk || !_esMayusculas || !_noTieneVocales || !_tieneNumero || !_tieneSimbolo) {
      _msg("La contraseña no cumple los requisitos");
      return;
    }
    
    setState(() => _cargando = true);
    try {
      final res = await _usuarioService.restablecerCredenciales(
        idUsuario: _idUsuarioCapturado.toString(), 
        nuevoUser: _usuarioController.text.trim().toUpperCase(),
        nuevaPass: _passController.text.trim()
      );

      if (res['success'] == true) {
        _msg("Acceso restablecido con éxito", esError: false);
        Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
      } else {
        _msg(res['mensaje'] ?? "Error al actualizar");
      }
    } catch (e) {
      _msg("Error al procesar el cambio");
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _msg(String texto, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto, style: GoogleFonts.montserrat()),
      backgroundColor: esError ? const Color(0xFF9E2A2B) : verdeBosque,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoCrema,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: verdeBosque)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Image.asset('assets/img/LOGOV2.png', height: 80),
            Text("Recuperar Acceso", style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold, color: verdeBosque)),
            const SizedBox(height: 20),

            _buildField(
              label: "Nombre de Usuario", 
              controller: _usuarioController, 
              hint: "USUARIO", 
              enabled: !_correoEnviado, // Se bloquea al enviar correo
              isUpperCase: true
            ),
            const SizedBox(height: 15),

            _buildActionField(
              label: "Correo electrónico", 
              controller: _correoController, 
              hint: "correo@ejemplo.com", 
              btnText: "ENVIAR", 
              enabled: !_correoEnviado, // Se bloquea al enviar correo
              onTap: _validarYEnviarCodigo
            ),
            const SizedBox(height: 15),

            // CAMPO OTP: Solo se habilita si _correoEnviado es true
            _buildActionField(
              label: "Código OTP", 
              controller: _codigoController, 
              hint: "Ingrese el código", 
              btnText: "VALIDAR", 
              enabled: _correoEnviado && !_codigoValidado, 
              onTap: _validarCodigoOTP
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

            // CAMPOS PASSWORD: Solo se habilitan si _codigoValidado es true
            _buildPasswordField(
              label: "Nueva contraseña", 
              controller: _passController, 
              isObscured: _obscurePass1, 
              enabled: _codigoValidado,
              onToggle: () => setState(() => _obscurePass1 = !_obscurePass1)
            ),
            const SizedBox(height: 15),

            _buildPasswordField(
              label: "Confirmar contraseña", 
              controller: _confirmPassController, 
              isObscured: _obscurePass2, 
              enabled: _codigoValidado,
              onToggle: () => setState(() => _obscurePass2 = !_obscurePass2)
            ),
            const SizedBox(height: 20),

            _buildRequerimientosPanel(),
            const SizedBox(height: 30),

            _buildPrimaryButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES DE INTERFAZ REUTILIZABLES ---

  Widget _buildField({required String label, required TextEditingController controller, required String hint, bool isUpperCase = false, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: verdeBosque)),
        const SizedBox(height: 8),
        Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(color: cremaInput, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: controller,
              enabled: enabled,
              inputFormatters: isUpperCase ? [UpperCaseTextFormatter()] : [],
              decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.all(15)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionField({required String label, required TextEditingController controller, required String hint, required String btnText, required bool enabled, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: verdeBosque)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: enabled ? 1.0 : 0.5,
                child: Container(
                  decoration: BoxDecoration(color: cremaInput, borderRadius: const BorderRadius.horizontal(left: Radius.circular(10))),
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.all(15)),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (enabled && !_cargando) ? onTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: verdeBosque, 
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(10))),
                  elevation: 0
                ),
                child: _cargando && enabled ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : Text(btnText, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField({required String label, required TextEditingController controller, required bool isObscured, required bool enabled, required VoidCallback onToggle}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: verdeBosque)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: cremaInput, borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: controller,
              obscureText: isObscured,
              enabled: enabled,
              inputFormatters: [UpperCaseTextFormatter()],
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(15),
                suffixIcon: IconButton(
                  icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: verdeBosque, size: 20),
                  onPressed: enabled ? onToggle : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequerimientosPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("La contraseña debe tener:", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: verdeBosque)),
          const SizedBox(height: 10),
          _reqItem("Mínimo 10 caracteres", _tieneLargoOk),
          _reqItem("Solo letras Mayúsculas", _esMayusculas),
          _reqItem("No debe contener vocales", _noTieneVocales),
          _reqItem("Al menos 1 número", _tieneNumero),
          _reqItem("Al menos 1 símbolo", _tieneSimbolo),
        ],
      ),
    );
  }

  Widget _reqItem(String texto, bool cumple) {
    return Row(
      children: [
        Icon(cumple ? Icons.check_circle : Icons.cancel, color: cumple ? Colors.green : Colors.red, size: 16),
        const SizedBox(width: 8),
        Text(texto, style: GoogleFonts.montserrat(fontSize: 11, color: cumple ? verdeBosque : Colors.black54)),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: (_cargando || !_codigoValidado) ? null : _confirmarCambio,
        style: ElevatedButton.styleFrom(backgroundColor: verdeBosque, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Text("CONFIRMAR CAMBIO", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
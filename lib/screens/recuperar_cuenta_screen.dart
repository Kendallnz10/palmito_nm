import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/usuario_service.dart';

class RecuperarCuentaScreen extends StatefulWidget {
  const RecuperarCuentaScreen({super.key});

  @override
  State<RecuperarCuentaScreen> createState() => _RecuperarCuentaScreenState();
}

class _RecuperarCuentaScreenState extends State<RecuperarCuentaScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final PageController _pageController = PageController();

  // Estados de flujo
  int _pasoActual = 0;
  String _correo = "";
  List<dynamic> _preguntasTexto = [];
  int? _idUsuarioEncontrado;
  bool _isLoading = false;

  // Colores Identidad Palmito NM
  final Color fondoLogoCrema = const Color(0xFFF2E8D5);
  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color cremaInput = const Color(0xFFF9F7F2);
  final Color rojoElegante = const Color(0xFF9E2A2B);

  // Controladores de texto
  final TextEditingController _ctrlCorreo = TextEditingController();
  final TextEditingController _ctrlOTP = TextEditingController();
  final TextEditingController _ctrlR1 = TextEditingController();
  final TextEditingController _ctrlR2 = TextEditingController();
  final TextEditingController _ctrlMFA = TextEditingController();
  final TextEditingController _ctrlNuevoUser = TextEditingController();
  final TextEditingController _ctrlNuevaPass = TextEditingController();
  final TextEditingController _ctrlConfirmPass = TextEditingController();

  // Estados de visibilidad de contraseña
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Variables de validación de requisitos (Para el panel de Checks)
  bool _tieneLargoOk = false;
  bool _esMayusculas = false;
  bool _noTieneVocales = false;
  bool _tieneNumero = false;
  bool _tieneSimbolo = false;

  @override
  void initState() {
    super.initState();
    // Listener para validar requisitos en tiempo real
    _ctrlNuevaPass.addListener(_evaluarRequisitos);
  }

  void _evaluarRequisitos() {
    final p = _ctrlNuevaPass.text;
    setState(() {
      _tieneLargoOk = p.length >= 10;
      // Solo mayúsculas: No debe tener minúsculas y debe tener al menos una letra
      _esMayusculas = p.isNotEmpty && !p.contains(RegExp(r'[a-z]')) && p.contains(RegExp(r'[A-Z]'));
      // No vocales
      _noTieneVocales = p.isNotEmpty && !p.contains(RegExp(r'[AEIOU]'));
      // Al menos un número
      _tieneNumero = p.contains(RegExp(r'[0-9]'));
      // Al menos un símbolo
      _tieneSimbolo = p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  @override
  void dispose() {
    _ctrlNuevaPass.removeListener(_evaluarRequisitos);
    _pageController.dispose();
    _ctrlCorreo.dispose();
    _ctrlOTP.dispose();
    _ctrlR1.dispose();
    _ctrlR2.dispose();
    _ctrlMFA.dispose();
    _ctrlNuevoUser.dispose();
    _ctrlNuevaPass.dispose();
    _ctrlConfirmPass.dispose();
    super.dispose();
  }

  // --- LÓGICA DE NAVEGACIÓN ---

  void _siguientePaso() {
    _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    setState(() => _pasoActual++);
  }

  void _pasoAnterior() {
    if (_pasoActual > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _pasoActual--);
    } else {
      Navigator.pop(context);
    }
  }

  // --- SERVICIOS ---

  Future<void> _validarCorreo() async {
    if (_ctrlCorreo.text.isEmpty) return _msg("Ingresa tu correo");
    setState(() => _isLoading = true);
    try {
      final resEnvio = await _usuarioService.enviarCodigoVerificacion(_ctrlCorreo.text.trim());
      if (resEnvio['success'] == true) {
        final resPreg = await _usuarioService.obtenerPreguntasPorCorreo(_ctrlCorreo.text.trim());
        if (resPreg['success'] == true) {
          final body = resPreg['body']['body'];
          setState(() {
            _correo = _ctrlCorreo.text.trim();
            _preguntasTexto = body['preguntas'];
            _idUsuarioEncontrado = body['usuario']['id_usuario'];
          });
          _siguientePaso();
        }
      } else { _msg("Correo no registrado"); }
    } catch (e) { _msg("Error de conexión"); }
    finally { setState(() => _isLoading = false); }
  }

  Future<void> _validarOTP() async {
    if (_ctrlOTP.text.isEmpty) return _msg("Ingresa el código");
    setState(() => _isLoading = true);
    try {
      final res = await _usuarioService.validarCodigoOTP(_correo, _ctrlOTP.text.trim());
      if (res['success'] == true) _siguientePaso();
      else _msg("Código incorrecto");
    } finally { setState(() => _isLoading = false); }
  }

  Future<void> _validarPreguntas() async {
    if (_ctrlR1.text.isEmpty || _ctrlR2.text.isEmpty) return _msg("Responde todo");
    setState(() => _isLoading = true);
    try {
      final res = await _usuarioService.verificarRespuestas(
        idUsuario: _idUsuarioEncontrado,
        r1: _ctrlR1.text.trim().toUpperCase(),
        r2: _ctrlR2.text.trim().toUpperCase(),
      );
      if (res['success'] == true) _siguientePaso();
      else _msg("Respuestas incorrectas");
    } finally { setState(() => _isLoading = false); }
  }

  Future<void> _validarMFA() async {
    if (_ctrlMFA.text.length < 6) return _msg("Código incompleto");
    setState(() => _isLoading = true);
    try {
      final res = await _usuarioService.verificarMFA(_idUsuarioEncontrado, _ctrlMFA.text.trim());
      if (res['success'] == true || res['statusCode'] == 200) _siguientePaso();
      else _msg("Código MFA inválido");
    } finally { setState(() => _isLoading = false); }
  }

  Future<void> _finalizarProceso() async {
    if (_ctrlNuevoUser.text.isEmpty || _ctrlNuevaPass.text.isEmpty) return _msg("Completa los datos");
    if (_ctrlNuevaPass.text != _ctrlConfirmPass.text) return _msg("Contraseñas no coinciden");
    
    // Validar checks
    if (!(_tieneLargoOk && _esMayusculas && _noTieneVocales && _tieneNumero && _tieneSimbolo)) {
      return _msg("No cumple los requisitos de seguridad");
    }

    setState(() => _isLoading = true);
    try {
      final res = await _usuarioService.restablecerCredenciales(
        idUsuario: _idUsuarioEncontrado.toString(),
        nuevoUser: _ctrlNuevoUser.text.trim().toUpperCase(),
        nuevaPass: _ctrlNuevaPass.text.trim(),
      );

      if (res['success'] == true) {
        _msg("¡ÉXITO! CUENTA RESTABLECIDA", esError: false);
        Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false));
      } else {
        // AQUÍ CAPTURA EL ERROR DE LAS ÚLTIMAS 10 CONTRASEÑAS DEL BACKEND
        _msg(res['mensaje'] ?? "Contraseña y/o usuario utilizada recientemente");
      }
    } finally { setState(() => _isLoading = false); }
  }

  // --- UI WIDGETS ---

  void _msg(String texto, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: esError ? rojoElegante : verdeBosque,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoLogoCrema,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF3B4D28)), onPressed: _pasoAnterior)),
      body: Stack(children: [
        PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [_stepEmail(), _stepOTP(), _stepPreguntas(), _stepMFA(), _stepFinal()],
        ),
        if (_isLoading) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFF3B4D28)))),
      ]),
    );
  }

  // --- PASOS ESPECÍFICOS ---

  Widget _stepEmail() => _buildStepLayout("Recuperación", "Ingresa tu correo para buscar tu cuenta.", [
    _buildTextField(_ctrlCorreo, "Correo electrónico", Icons.email_outlined),
    const SizedBox(height: 30),
    _buildPrimaryBtn("BUSCAR CUENTA", _validarCorreo),
  ]);

  Widget _stepOTP() => _buildStepLayout("Verificación", "Ingresa el código enviado a tu email.", [
    _buildTextField(_ctrlOTP, "Código OTP", Icons.key_outlined),
    const SizedBox(height: 30),
    _buildPrimaryBtn("VERIFICAR CÓDIGO", _validarOTP),
  ]);

  Widget _stepPreguntas() => _buildStepLayout("Seguridad", "Responde tus preguntas de respaldo.", [
    _preguntaTitulo(_preguntasTexto.isNotEmpty ? _preguntasTexto[0] : "..."),
    _buildTextField(_ctrlR1, "Respuesta 1", Icons.question_answer_outlined, isUpper: true),
    const SizedBox(height: 20),
    _preguntaTitulo(_preguntasTexto.length > 1 ? _preguntasTexto[1] : "..."),
    _buildTextField(_ctrlR2, "Respuesta 2", Icons.question_answer_outlined, isUpper: true),
    const SizedBox(height: 30),
    _buildPrimaryBtn("CONTINUAR", _validarPreguntas),
  ]);

  Widget _stepMFA() => _buildStepLayout("Authenticator", "Ingresa el código de tu app de seguridad.", [
    _buildTextField(_ctrlMFA, "Código 6 dígitos", Icons.phonelink_lock_outlined),
    const SizedBox(height: 30),
    _buildPrimaryBtn("VALIDAR MFA", _validarMFA),
  ]);

  Widget _stepFinal() => _buildStepLayout("Finalizar", "Define tus nuevas credenciales de acceso.", [
    _buildTextField(_ctrlNuevoUser, "Nuevo Usuario", Icons.person_outline, isUpper: true),
    const SizedBox(height: 15),
    _buildTextField(_ctrlNuevaPass, "Nueva Contraseña", Icons.lock_open_outlined, isPass: _obscurePass, isUpper: true, 
      suffix: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePass = !_obscurePass))),
    const SizedBox(height: 10),
    _buildTextField(_ctrlConfirmPass, "Confirmar Contraseña", Icons.lock_outline, isPass: _obscureConfirm, isUpper: true,
      suffix: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
    const SizedBox(height: 20),
    _panelRequisitos(),
    const SizedBox(height: 30),
    _buildPrimaryBtn("RESTABLECER TODO", _finalizarProceso),
  ]);

  // --- SUB-WIDGETS REUTILIZABLES ---

  Widget _buildStepLayout(String tit, String sub, List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(children: [
        const SizedBox(height: 20), Image.asset('assets/img/LOGOV2.png', height: 80),
        const SizedBox(height: 10), Text(tit, style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.bold, color: verdeBosque)),
        Text(sub, textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 30), ...children,
      ]),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool isPass = false, bool isUpper = false, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(color: cremaInput, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: ctrl, obscureText: isPass,
        inputFormatters: isUpper ? [UpperCaseTextFormatter()] : [],
        style: GoogleFonts.montserrat(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: verdeBosque, size: 20), suffixIcon: suffix,
          hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        ),
      ),
    );
  }

  Widget _panelRequisitos() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("REQUISITOS:", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: verdeBosque)),
        const SizedBox(height: 10),
        _itemReq("Mínimo 10 caracteres", _tieneLargoOk),
        _itemReq("Solo letras Mayúsculas", _esMayusculas),
        _itemReq("No debe contener vocales", _noTieneVocales),
        _itemReq("Al menos 1 número", _tieneNumero),
        _itemReq("Al menos 1 símbolo", _tieneSimbolo),
      ]),
    );
  }

  Widget _itemReq(String txt, bool ok) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : rojoElegante, size: 14),
      const SizedBox(width: 8),
      Text(txt, style: GoogleFonts.montserrat(fontSize: 11, color: ok ? verdeBosque : Colors.black54)),
    ]),
  );

  Widget _preguntaTitulo(String t) => Align(alignment: Alignment.centerLeft, child: Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 5),
    child: Text(t.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: verdeBosque)),
  ));

  Widget _buildPrimaryBtn(String t, VoidCallback fn) => SizedBox(width: double.infinity, height: 50, 
    child: ElevatedButton(onPressed: _isLoading ? null : fn, style: ElevatedButton.styleFrom(backgroundColor: verdeBosque, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
    child: Text(t, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold))));
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newVal) => TextEditingValue(text: newVal.text.toUpperCase(), selection: newVal.selection);
}
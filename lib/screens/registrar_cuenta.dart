import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:palmito_nm/services/ubicacion_service.dart'; 
import 'package:palmito_nm/services/tse_services.dart'; 
import 'package:palmito_nm/models/ubicacion.dart';
import 'package:palmito_nm/services/usuario_service.dart'; 

class RegistrarCuenta extends StatefulWidget {
  final String correoVerificado;
  final Map<String, dynamic>? datosGoogle;

  const RegistrarCuenta({
    super.key, 
    required this.correoVerificado,
    this.datosGoogle,
  });

  @override
  State<RegistrarCuenta> createState() => _RegistrarCuentaState();
}

class _RegistrarCuentaState extends State<RegistrarCuenta> {
  final UsuarioService _usuarioService = UsuarioService();
  final UbicacionService _ubicacionService = UbicacionService();
  final TSEService _tseService = TSEService();

  // Controladores
  final _cedulaController = TextEditingController(); 
  final _usuarioController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telController = TextEditingController();
  final _correoController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _senasController = TextEditingController();

  // Ubicación
  List<Pais> _listaPaises = [];
  List<Provincia> _listaProvincias = [];
  List<Canton> _listaCantones = [];
  List<Distrito> _listaDistritos = [];

  Pais? _paisSel;
  Provincia? _provSel;
  Canton? _cantSel;
  Distrito? _distSel;

  bool _cargando = false;
  bool _buscandoTSE = false; 
  bool _verPass = true; 
  bool _verConfirmPass = true;

  // Variables de validación reactiva
  bool _tieneLargoOk = false;
  bool _esMayusculas = false;
  bool _noTieneVocales = false;
  bool _tieneNumero = false;
  bool _tieneSimbolo = false;

  final Color fondoLogoCrema = const Color(0xFFF2E8D5); 
  final Color verdeBosque = const Color(0xFF3B4D28);    
  final Color cremaInput = const Color(0xFFF9F7F2);
  final Color rojoElegante = const Color(0xFF9E2A2B);

  @override
  void initState() {
    super.initState();
    _correoController.text = widget.correoVerificado;

    if (widget.datosGoogle != null) {
      _nombreController.text = widget.datosGoogle!['nombre'] ?? "";
      _apellidosController.text = widget.datosGoogle!['apellido'] ?? "";
      _usuarioController.text = widget.datosGoogle!['usuarioSugerido'] ?? "";
    }

    _cargarPaises();
    
    // Escuchar cambios para validar requisitos en tiempo real
    _passController.addListener(_validarRequisitosPass);
  }

  void _validarRequisitosPass() {
    final p = _passController.text;
    setState(() {
      _tieneLargoOk = p.length >= 10;
      _esMayusculas = p.isNotEmpty && !p.contains(RegExp(r'[a-z]')) && p.contains(RegExp(r'[A-Z]'));
      _noTieneVocales = p.isNotEmpty && !p.contains(RegExp(r'[AEIOUaeiou]'));
      _tieneNumero = p.contains(RegExp(r'[0-9]'));
      _tieneSimbolo = p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  @override
  void dispose() {
    _passController.removeListener(_validarRequisitosPass);
    _cedulaController.dispose(); _usuarioController.dispose();
    _nombreController.dispose(); _apellidosController.dispose();
    _telController.dispose(); _correoController.dispose();
    _passController.dispose(); _confirmPassController.dispose();
    _senasController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE UBICACIÓN Y TSE ---

  String _limpiarTexto(String? texto) {
    if (texto == null) return "";
    var conTildes = 'ÁÉÍÓÚáéíóú';
    var sinTildes = 'AEIOUaeiou';
    String res = texto.trim().toUpperCase();
    for (int i = 0; i < conTildes.length; i++) {
      res = res.replaceAll(conTildes[i], sinTildes[i]);
    }
    return res;
  }

  void _cargarPaises() async {
    try {
      final data = await _ubicacionService.getPaises();
      if (mounted) setState(() => _listaPaises = data);
    } catch (e) { debugPrint("Error países: $e"); }
  }

  Future<void> _validarConTSE() async {
    if (_cedulaController.text.trim().isEmpty) {
      _msg("Por favor ingrese la cédula");
      return;
    }
    setState(() { _buscandoTSE = true; });
    try {
      final res = await _tseService.consultarCedula(_cedulaController.text.trim());
      if (res['encontrado'] == true) {
        final datos = res['datos'];
        setState(() {
          _nombreController.text = datos['nombre'] ?? "";
          _apellidosController.text = "${datos['primer_apellido']} ${datos['segundo_apellido']}".trim();
        });
        await _autoSeleccionarUbicacion(datos['pais'], datos['provincia'], datos['canton'], datos['distrito']);
        _msg("Datos actualizados correctamente", esError: false);
      } else { _msg("Cédula no encontrada."); }
    } finally { if (mounted) setState(() => _buscandoTSE = false); }
  }

  Future<void> _autoSeleccionarUbicacion(String? p, String? prov, String? cant, String? dist) async {
    try {
      if (p != null && _listaPaises.isNotEmpty) {
        _paisSel = _listaPaises.firstWhere((e) => _limpiarTexto(e.nombre) == _limpiarTexto(p), orElse: () => _listaPaises.first);
        final provincias = await _ubicacionService.getProvincias(_paisSel!.id);
        if (!mounted) return;
        setState(() => _listaProvincias = provincias);
        
        if (prov != null) {
          try {
            _provSel = _listaProvincias.firstWhere((e) => _limpiarTexto(e.nombre) == _limpiarTexto(prov));
            final cantones = await _ubicacionService.getCantones(_provSel!.id);
            if (!mounted) return;
            setState(() => _listaCantones = cantones);
            if (cant != null) {
              try {
                _cantSel = _listaCantones.firstWhere((e) => _limpiarTexto(e.nombre) == _limpiarTexto(cant));
                final distritos = await _ubicacionService.getDistritos(_cantSel!.id);
                if (!mounted) return;
                setState(() => _listaDistritos = distritos);
                if (dist != null) {
                  try {
                    _distSel = _listaDistritos.firstWhere((e) => _limpiarTexto(e.nombre) == _limpiarTexto(dist));
                  } catch (_) { _distSel = null; }
                }
              } catch (_) { _cantSel = null; }
            }
          } catch (_) { _provSel = null; }
        }
      }
      setState(() {}); 
    } catch (e) { debugPrint("Error en cascada: $e"); }
  }

  Future<void> _registrar() async {
    if (_passController.text != _confirmPassController.text) {
      _msg("Las contraseñas no coinciden");
      return;
    }
    
    bool todoOk = _tieneLargoOk && _esMayusculas && _noTieneVocales && _tieneNumero && _tieneSimbolo;
    if (!todoOk) {
      _msg("La contraseña no cumple con los requisitos de seguridad");
      return;
    }

    if (_paisSel == null || _provSel == null || _cantSel == null || _distSel == null) {
      _msg("Seleccione su ubicación completa");
      return;
    }

    setState(() => _cargando = true);
    final datos = {
      "cedula": _cedulaController.text.trim(),
      "usuario": _usuarioController.text.trim().toUpperCase(),
      "nombre": _nombreController.text.trim(),
      "apellido": _apellidosController.text.trim(),
      "correo": _correoController.text.trim(),
      "telefono": _telController.text.trim(),
      "contrasena": _passController.text,
      "direccion": "${_paisSel!.nombre}, ${_provSel!.nombre}, ${_cantSel!.nombre}, ${_distSel!.nombre} - ${_senasController.text}"
    };

    try {
      final res = await _usuarioService.registrarUsuario(datos);
      if (res.statusCode == 201 || res.statusCode == 200) {
        _msg("¡Registro exitoso!", esError: false);
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final body = jsonDecode(res.body);
        _msg(body['mensaje'] ?? "Error de servidor");
      }
    } catch (e) { _msg("Error de conexión"); }
    finally { if (mounted) setState(() => _cargando = false); }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoLogoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, foregroundColor: verdeBosque,
        title: Text("Paso Final", style: GoogleFonts.montserrat(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 40),
        child: Column(
          children: [
            Image.asset('assets/img/LOGOV2.png', height: 90, errorBuilder: (c, e, s) => Icon(Icons.eco, size: 60, color: verdeBosque)),
            Text("Completar Perfil", style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold, color: verdeBosque)),
            const SizedBox(height: 25),
            
            _crearTextField(_cedulaController, "Cédula de Identidad", Icons.badge_outlined, 
              sufijo: _buscandoTSE 
                ? Container(padding: const EdgeInsets.all(12), width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: verdeBosque))
                : IconButton(icon: const Icon(Icons.search), onPressed: _validarConTSE)),
            
            _crearTextField(_usuarioController, "Nombre de Usuario", Icons.account_circle_outlined, isUpper: true),
            _crearTextField(_nombreController, "Nombre", Icons.person_outline),
            _crearTextField(_apellidosController, "Apellidos", Icons.person_pin_outlined),
            _crearTextField(_telController, "Teléfono", Icons.phone_android, tipo: TextInputType.phone),
            _crearTextField(_correoController, "Correo", Icons.verified_user, habilitado: false),
            
            const Divider(height: 30),

            _crearTextField(_passController, "Nueva Contraseña", Icons.lock_outline, ocultar: _verPass, isUpper: true,
              sufijo: IconButton(icon: Icon(_verPass ? Icons.visibility_off : Icons.visibility, color: verdeBosque, size: 20), onPressed: () => setState(() => _verPass = !_verPass))),
            
            _crearTextField(_confirmPassController, "Confirmar Contraseña", Icons.lock_clock_outlined, ocultar: _verConfirmPass, isUpper: true,
              sufijo: IconButton(icon: Icon(_verConfirmPass ? Icons.visibility_off : Icons.visibility, color: verdeBosque, size: 20), onPressed: () => setState(() => _verConfirmPass = !_verConfirmPass))),
            
            _buildRequisitosPanel(),

            const Divider(height: 30),

            _crearDrop<Pais>("PAÍS", _paisSel, _listaPaises, (v) => v.nombre, (v) async {
              setState(() { _paisSel = v; _provSel = null; _cantSel = null; _distSel = null; _listaProvincias = []; });
              final data = await _ubicacionService.getProvincias(v!.id);
              setState(() => _listaProvincias = data);
            }),
            const SizedBox(height: 12),
            _crearDrop<Provincia>("PROVINCIA", _provSel, _listaProvincias, (v) => v.nombre, (v) async {
              setState(() { _provSel = v; _cantSel = null; _distSel = null; _listaCantones = []; });
              final data = await _ubicacionService.getCantones(v!.id);
              setState(() => _listaCantones = data);
            }),
            const SizedBox(height: 12),
            _crearDrop<Canton>("CANTÓN", _cantSel, _listaCantones, (v) => v.nombre, (v) async {
              setState(() { _cantSel = v; _distSel = null; _listaDistritos = []; });
              final data = await _ubicacionService.getDistritos(v!.id);
              setState(() => _listaDistritos = data);
            }),
            const SizedBox(height: 12),
            _crearDrop<Distrito>("DISTRITO", _distSel, _listaDistritos, (v) => v.nombre, (v) => setState(() => _distSel = v)),
            const SizedBox(height: 15),
            _crearTextField(_senasController, "Otras señas", Icons.map_outlined, maxLines: 2),
            const SizedBox(height: 35),
            
            SizedBox(width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _cargando ? null : _registrar, 
                style: ElevatedButton.styleFrom(backgroundColor: verdeBosque, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _cargando ? const CircularProgressIndicator(color: Colors.white) : Text("FINALIZAR REGISTRO", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequisitosPanel() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20, top: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("REQUISITOS DE SEGURIDAD:", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: verdeBosque)),
        const SizedBox(height: 10),
        _itemReq("Mínimo 10 caracteres", _tieneLargoOk),
        _itemReq("Solo letras Mayúsculas", _esMayusculas),
        _itemReq("No debe contener vocales", _noTieneVocales),
        _itemReq("Al menos un número", _tieneNumero),
        _itemReq("Un carácter especial", _tieneSimbolo),
      ]),
    );
  }

  Widget _itemReq(String texto, bool ok) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
      Icon(ok ? Icons.check_circle : Icons.cancel, size: 16, color: ok ? Colors.green : rojoElegante),
      const SizedBox(width: 8),
      Text(texto, style: GoogleFonts.montserrat(fontSize: 12, color: ok ? Colors.green.shade700 : Colors.black54)),
    ]));
  }

  void _msg(String texto, {bool esError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)), backgroundColor: esError ? rojoElegante : verdeBosque));
  }

  Widget _crearTextField(TextEditingController ctrl, String label, IconData icono, {bool ocultar = false, TextInputType tipo = TextInputType.text, int maxLines = 1, bool habilitado = true, Widget? sufijo, bool isUpper = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
      controller: ctrl, obscureText: ocultar, keyboardType: tipo, maxLines: maxLines, enabled: habilitado,
      inputFormatters: isUpper ? [UpperCaseTextFormatter()] : [],
      style: GoogleFonts.montserrat(fontSize: 14),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icono, color: verdeBosque, size: 20), suffixIcon: sufijo, 
        filled: true, fillColor: habilitado ? cremaInput : Colors.grey.shade300, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)
      ),
      onChanged: (v) => setState(() {}),
    ));
  }

  Widget _crearDrop<T>(String label, T? valor, List<T> items, String Function(T) itemLabel, Function(T?) onChange) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: cremaInput, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), labelStyle: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: verdeBosque)),
      value: valor,
      items: items.isEmpty ? null : items.map((i) => DropdownMenuItem<T>(value: i, child: Text(itemLabel(i), style: GoogleFonts.montserrat(fontSize: 14)))).toList(),
      onChanged: items.isEmpty ? null : onChange,
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newVal) => TextEditingValue(text: newVal.text.toUpperCase(), selection: newVal.selection);
}
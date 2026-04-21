import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/usuario_service.dart';
import '../services/ubicacion_service.dart';
import '../models/ubicacion.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> usuarioActual;
  const EditarPerfilScreen({super.key, required this.usuarioActual});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final UbicacionService _ubicacionService = UbicacionService();

  // Controladores
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _telController;
  late TextEditingController _senasController;

  // Listas para combos (Igual que en RegistrarCuenta)
  List<Pais> _listaPaises = [];
  List<Provincia> _listaProvincias = [];
  List<Canton> _listaCantones = [];
  List<Distrito> _listaDistritos = [];

  Pais? _paisSel;
  Provincia? _provSel;
  Canton? _cantSel;
  Distrito? _distSel;

  bool _cargando = false;
  bool _inicializandoUbicacion = true;

  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color fondoLogoCrema = const Color(0xFFF2E8D5);
  final Color cremaInput = const Color(0xFFF9F7F2);

  @override
  void initState() {
    super.initState();
    final u = widget.usuarioActual;
    
    // CARGA DE DATOS PERSONALES (Soporta mayúsculas y minúsculas de la DB)
    _nombreController = TextEditingController(text: (u['nombre'] ?? u['Nombre'] ?? "").toString());
    _apellidoController = TextEditingController(text: (u['apellido'] ?? u['Apellido'] ?? "").toString());
    _telController = TextEditingController(text: (u['telefono'] ?? u['Telefono'] ?? u['celular'] ?? "").toString());
    _senasController = TextEditingController();

    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      // 1. Cargar Países primero
      final paises = await _ubicacionService.getPaises();
      if (mounted) setState(() => _listaPaises = paises);

      // 2. Procesar Dirección: "País, Provincia, Cantón, Distrito - Señas"
      String dirCompleta = (widget.usuarioActual['direccion'] ?? widget.usuarioActual['Direccion'] ?? "").toString();
      
      if (dirCompleta.contains(",") && dirCompleta.contains("-")) {
        List<String> partesBase = dirCompleta.split("-");
        _senasController.text = partesBase[1].trim();

        List<String> locales = partesBase[0].split(",");
        if (locales.length >= 4) {
          // Ejecutamos la cascada de preselección asíncrona
          await _preseleccionarUbicacion(
            locales[0].trim(), // País
            locales[1].trim(), // Provincia
            locales[2].trim(), // Cantón
            locales[3].trim()  // Distrito
          );
        }
      } else {
        _senasController.text = dirCompleta;
      }
    } catch (e) {
      debugPrint("Error inicializando: $e");
    } finally {
      if (mounted) setState(() => _inicializandoUbicacion = false);
    }
  }

  Future<void> _preseleccionarUbicacion(String pNom, String prNom, String cNom, String dNom) async {
    try {
      // PAÍS
      if (_listaPaises.any((x) => x.nombre == pNom)) {
        _paisSel = _listaPaises.firstWhere((x) => x.nombre == pNom);
        
        // PROVINCIA
        _listaProvincias = await _ubicacionService.getProvincias(_paisSel!.id);
        if (_listaProvincias.any((x) => x.nombre == prNom)) {
          _provSel = _listaProvincias.firstWhere((x) => x.nombre == prNom);

          // CANTÓN
          _listaCantones = await _ubicacionService.getCantones(_provSel!.id);
          if (_listaCantones.any((x) => x.nombre == cNom)) {
            _cantSel = _listaCantones.firstWhere((x) => x.nombre == cNom);

            // DISTRITO
            _listaDistritos = await _ubicacionService.getDistritos(_cantSel!.id);
            if (_listaDistritos.any((x) => x.nombre == dNom)) {
              _distSel = _listaDistritos.firstWhere((x) => x.nombre == dNom);
            }
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error en cascada de ubicación: $e");
    }
  }

  Future<void> _actualizar() async {
    if (_paisSel == null || _provSel == null || _cantSel == null || _distSel == null) {
      _msg("Seleccione su ubicación completa");
      return;
    }

    setState(() => _cargando = true);
    final String direccionFinal = "${_paisSel!.nombre}, ${_provSel!.nombre}, ${_cantSel!.nombre}, ${_distSel!.nombre} - ${_senasController.text.trim()}";
    
    final idRaw = widget.usuarioActual['id_usuario'] ?? widget.usuarioActual['ID_Usuario'];
    final datos = {
      "nombre": _nombreController.text.trim(),
      "apellido": _apellidoController.text.trim(),
      "telefono": _telController.text.trim(),
      "direccion": direccionFinal,
      "usuario": widget.usuarioActual['usuario'] ?? widget.usuarioActual['Usuario']
    };

    bool exito = await _usuarioService.actualizarPerfil(int.parse(idRaw.toString()), datos);

    if (exito && mounted) {
      _msg("¡Perfil actualizado!", esError: false);
      // Devolvemos el mapa actualizado para refrescar la pantalla de Ajustes
      Map<String, dynamic> actualizado = Map.from(widget.usuarioActual)..addAll(datos);
      Navigator.pop(context, actualizado); 
    } else {
      _msg("Error al guardar cambios");
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoLogoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, foregroundColor: verdeBosque,
        title: Text("EDITAR MI PERFIL", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _inicializandoUbicacion 
        ? Center(child: CircularProgressIndicator(color: verdeBosque))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              children: [
                _crearTextField(_nombreController, "Nombre", Icons.person_outline),
                _crearTextField(_apellidoController, "Apellidos", Icons.person_pin_outlined),
                _crearTextField(_telController, "Teléfono / Celular", Icons.phone_android, tipo: TextInputType.phone),
                const Divider(height: 35),
                
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
                
                const SizedBox(height: 12),
                _crearTextField(_senasController, "Otras señas", Icons.map_outlined, maxLines: 2),
                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _actualizar,
                    style: ElevatedButton.styleFrom(backgroundColor: verdeBosque, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _cargando 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text("GUARDAR CAMBIOS", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _msg(String texto, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto, style: GoogleFonts.montserrat()), 
      backgroundColor: esError ? const Color(0xFF9E2A2B) : verdeBosque,
    ));
  }

  Widget _crearTextField(TextEditingController controller, String label, IconData icono, {TextInputType tipo = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller, keyboardType: tipo, maxLines: maxLines,
        style: GoogleFonts.montserrat(fontSize: 14),
        decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icono, color: verdeBosque, size: 20),
          filled: true, fillColor: cremaInput,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)
        ),
      ),
    );
  }

  Widget _crearDrop<T>(String label, T? valor, List<T> items, String Function(T) itemLabel, Function(T?) onChange) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label, filled: true, fillColor: cremaInput,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        labelStyle: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: verdeBosque)
      ),
      value: valor,
      items: items.isEmpty ? null : items.map((i) => DropdownMenuItem<T>(value: i, child: Text(itemLabel(i), style: GoogleFonts.montserrat(fontSize: 14)))).toList(),
      onChanged: items.isEmpty ? null : onChange,
    );
  }
}
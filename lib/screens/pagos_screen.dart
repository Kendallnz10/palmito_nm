import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/carrito_item.dart';
import '../services/carrito_service.dart';
import '../services/banco_services.dart';
import '../services/tipo_cambio_service.dart';
import '../services/paypal_services.dart';
import '../screens/menu_lateral.dart';
import '../screens/factura_screen.dart';

// ─── FORMATTER PARA MM/AA ──────────────────────────────────────────────────
class _VencimientoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitos.isEmpty) return newValue.copyWith(text: '');

    String formatted = '';

    if (digitos.length <= 2) {
      int mes = int.tryParse(digitos) ?? 0;
      if (digitos.length == 2 && mes > 12) {
        formatted = '12/';
      } else if (digitos.length == 2) {
        formatted = '$digitos/';
      } else {
        formatted = digitos;
      }
    } else {
      final mes  = digitos.substring(0, 2);
      final anio = digitos.substring(2, digitos.length > 4 ? 4 : digitos.length);
      formatted  = '$mes/$anio';
    }

    return newValue.copyWith(
      text:      formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PagosScreen extends StatefulWidget {
  final List<CarritoItem>    items;
  final double               total;
  final Map<String, dynamic> usuarioActual;

  const PagosScreen({
    super.key,
    required this.items,
    required this.total,
    required this.usuarioActual,
  });

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  // ─── Servicios ────────────────────────────────
  final TipoCambioService        _bccrService    = TipoCambioService();
  final BancoService             _bancoService   = BancoService();
  final CarritoService           _carritoService = CarritoService();
  final PaypalService            _paypalService  = PaypalService();
  final GlobalKey<ScaffoldState> _scaffoldKey    = GlobalKey<ScaffoldState>();

  // ─── Deep Links ───────────────────────────────
  late AppLinks            _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // ─── Estado ───────────────────────────────────
  String  _metodoSeleccionado = "TARJETA";
  String  _emisor             = "DESCONOCIDO";
  double  _tipoVenta          = 512.45;
  double  _tipoCompra         = 506.20;
  bool    _procesando         = false;
  bool    _verificandoSinpe   = false;
  bool    _cargandoTipoCambio = true;
  String  _nombreSinpeDestino = "";



  // ─── Controladores ────────────────────────────
  final _numTarjetaController    = TextEditingController();
  final _nombreTitularController = TextEditingController();
  final _vencimientoController   = TextEditingController();
  final _cvvController           = TextEditingController();
  final _telOrigenController     = TextEditingController();
  final _detalleSinpeController  = TextEditingController();
  final _emailPaypalController   = TextEditingController();

  // ─── Getter ───────────────────────────────────
  double get _totalEnDolares =>
      _tipoVenta > 0 ? widget.total / _tipoVenta : 0.0;

  // ─── Ciclo de vida ────────────────────────────

  @override
  void initState() {
    super.initState();
    _cargarTiposCambio();
    _telOrigenController.addListener(_onTelefonoChanged);
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _telOrigenController.removeListener(_onTelefonoChanged);
    _numTarjetaController.dispose();
    _nombreTitularController.dispose();
    _vencimientoController.dispose();
    _cvvController.dispose();
    _telOrigenController.dispose();
    _detalleSinpeController.dispose();
    _emailPaypalController.dispose();
    super.dispose();
  }

  // ─── Deep Links ───────────────────────────────────────────────────────────

void _initDeepLinks() {
  _appLinks = AppLinks();

  _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
    if (!mounted) return;

    print("Deep link recibido: $uri");

    if (uri.scheme == 'palmitonm' && uri.host == 'success') {

      final String? token = uri.queryParameters['token'];

      print("Token recibido: $token");

      if (token != null) {
        _procesarRegresoAutomatico(token);
      } else {
        _mostrarError("No se pudo obtener el token de PayPal");
      }
    }
  });
}

  // ─── Captura automática al regresar de PayPal ─────────────────────────────
Future<void> _procesarRegresoAutomatico(String orderID) async {
  if (!mounted) return;

  setState(() => _procesando = true);

  try {
    final resultado = await _paypalService.capturarPago(orderID);

    print("Resultado captura: $resultado");

    if (resultado['status'] == 'COMPLETED') {
    await _finalizarYMostrar(orderID, "PAYPAL");
  } else {
    _mostrarError("Pago no completado");
}
  } catch (e) {
    print("Error capturando: $e");
    _mostrarError("Error al procesar el pago");
  } finally {
    if (mounted) {
      setState(() => _procesando = false);
    }
  }
}

  // ─── Lógica de negocio ────────────────────────

  Future<void> _cargarTiposCambio() async {
    setState(() => _cargandoTipoCambio = true);
    final valores = await _bccrService.obtenerTipoCambio();
    if (mounted) {
      setState(() {
        _tipoCompra         = valores["compra"]!;
        _tipoVenta          = valores["venta"]!;
        _cargandoTipoCambio = false;
      });
    }
  }

  Future<void> _onTelefonoChanged() async {
    final t = _telOrigenController.text.trim();
    if (t.length == 8) {
      setState(() {
        _verificandoSinpe   = true;
        _nombreSinpeDestino = "";
      });
      final nombre = await _bancoService.consultarNombrePorTelefono(t);
      if (mounted) {
        setState(() {
          _nombreSinpeDestino = nombre ?? "No registrado";
          _verificandoSinpe   = false;
        });
      }
    } else if (_nombreSinpeDestino.isNotEmpty) {
      setState(() => _nombreSinpeDestino = "");
    }
  }

  void _detectarEmisor(String numero) {
    setState(() {
      if (numero.startsWith('4'))      _emisor = "VISA";
      else if (numero.startsWith('5')) _emisor = "MASTERCARD";
      else                             _emisor = "DESCONOCIDO";
    });
  }

  bool _camposValidos() {
    if (_metodoSeleccionado == "TARJETA") {
      if (_numTarjetaController.text.length < 16) {
        _mostrarError("Ingresá un número de tarjeta válido (16 dígitos).");
        return false;
      }
      if (_nombreTitularController.text.trim().isEmpty) {
        _mostrarError("Ingresá el nombre del titular.");
        return false;
      }
      final venc = _vencimientoController.text;
      if (venc.length < 5 || !venc.contains('/')) {
        _mostrarError("Ingresá la fecha de vencimiento en formato MM/AA.");
        return false;
      }
      if (_cvvController.text.length < 3) {
        _mostrarError("Ingresá el CVV.");
        return false;
      }
    } else if (_metodoSeleccionado == "SINPE") {
      if (_telOrigenController.text.trim().length != 8) {
        _mostrarError("Ingresá un número de teléfono de 8 dígitos.");
        return false;
      }
    }
    return true;
  }

  // ─── LÓGICA PRINCIPAL DE TRANSACCIÓN ──────────────────────────────────────

Future<void> _ejecutarTransaccion() async {
  if (!_camposValidos()) return;

  FocusScope.of(context).unfocus();
  setState(() => _procesando = true);

  if (_metodoSeleccionado == "PAYPAL") {
    if (_emailPaypalController.text.isEmpty ||
        !_emailPaypalController.text.contains("@")) {
      _mostrarError("Ingresá un correo válido de PayPal");
      setState(() => _procesando = false);
      return;
    }

    await _paypalService.realizarPago(
      context: context,
      totalColones: widget.total,
      tipoCambio: _tipoVenta,
      items: widget.items,
      usuarioActual: widget.usuarioActual,

      // 🔥 YA NO SE USA orderID AQUÍ
      onSuccess: (_) {},

      onError: (error) {
        if (mounted) {
          setState(() => _procesando = false);
          _mostrarError(error);
        }
      },
    );

    return;
  }
    // ── TARJETA / SINPE ───────────────────────────────────────────────────
    Map<String, dynamic> resultado;

    try {
      if (_metodoSeleccionado == "TARJETA") {
        resultado = await _bancoService.pagarConTarjeta(
          numero:      _numTarjetaController.text,
          cvv:         _cvvController.text,
          vencimiento: _vencimientoController.text,
          monto:       widget.total,
        );
      } else {
        resultado = await _bancoService.pagarConSinpe(
          telOrigen:   _telOrigenController.text,
          monto:       widget.total,
          descripcion: _detalleSinpeController.text,
        );
      }

      if (resultado['success'] == true) {
        await _finalizarYMostrar(
          resultado['comprobante'].toString(),
          _metodoSeleccionado,
          mensajeExito: resultado['mensaje'],
        );
      } else {
        if (mounted) {
          setState(() => _procesando = false);
          _mostrarError(resultado['mensaje'] ?? "Error en la transacción");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        _mostrarError("Error de conexión: $e");
      }
    }
  }

  // ─── FUNCIÓN FINALIZAR COMPRA ─────────────────────────────────────────────

  Future<void> _finalizarYMostrar(
    String  comprobante,
    String  metodo, {
    String? mensajeExito,
  }) async {
    final int idUser =
        int.parse(widget.usuarioActual['id_usuario'].toString());

    final bool guardado = await _carritoService.finalizarCompra(
      idUser,
      widget.total,
      metodo,
    );

    if (mounted) {
      setState(() {
        _procesando    = false;
      });
      if (guardado) {
        _mostrarFinal(mensajeExito ?? "Pago realizado con éxito", comprobante);
      } else {
        _mostrarError("Pago procesado, pero error al registrar factura.");
      }
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key:             _scaffoldKey,
      backgroundColor: const Color(0xFFF2E8D5),
      endDrawer:       MenuLateral(usuarioActual: widget.usuarioActual),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation:       0,
        centerTitle:     true,
        title: Image.asset(
          'assets/img/LOGOV2.png',
          height: 40,
          errorBuilder: (_, __, ___) => const Text("PALMITO NM"),
        ),
        actions: [
          IconButton(
            icon:      const Icon(Icons.menu, color: Color(0xFF3B4D28)),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSelectorTabs(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_metodoSeleccionado == "TARJETA") ...[
                    _buildTarjetaVisual(),
                    const SizedBox(height: 25),
                    _buildInput(
                      _nombreTitularController,
                      "Nombre del titular",
                      Icons.person,
                      type: TextInputType.text,
                    ),
                    const SizedBox(height: 15),
                    _buildInput(
                      _numTarjetaController,
                      "Número de tarjeta",
                      Icons.credit_card,
                      maxLen:       16,
                      esNumTarjeta: true,
                    ),
                    const SizedBox(height: 15),
                    Row(children: [
                      Expanded(child: _buildVencimientoInput()),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInput(
                          _cvvController,
                          "CVV",
                          Icons.lock,
                          maxLen: 3,
                        ),
                      ),
                    ]),
                  ] else if (_metodoSeleccionado == "SINPE") ...[
                    _buildSinpeForm(),
                  ] else ...[
                    _buildPaypalForm(),
                  ],
                  const SizedBox(height: 35),
                  _buildMontoDisplay(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width:  double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _metodoSeleccionado == "PAYPAL"
                            ? const Color(0xFF003087)
                            : const Color(0xFF3B4D28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _procesando ? null : _ejecutarTransaccion,
                      child: _procesando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _metodoSeleccionado == "PAYPAL"
                                  ? "PAGAR CON PAYPAL"
                                  : "PROCESAR PAGO",
                              style: const TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBccrBar(),
        ],
      ),
    );
  }

  // ── Campo vencimiento MM/AA ───────────────────────────────────────────────

  Widget _buildVencimientoInput() {
    return TextField(
      controller:      _vencimientoController,
      keyboardType:    TextInputType.number,
      maxLength:       5,
      inputFormatters: [_VencimientoFormatter()],
      onChanged:       (_) => setState(() {}),
      decoration: InputDecoration(
        labelText:   "MM/AA",
        prefixIcon:  const Icon(Icons.date_range, color: Color(0xFF3B4D28)),
        filled:      true,
        fillColor:   Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        counterText: "",
        hintText:    "MM/AA",
        hintStyle:   const TextStyle(color: Colors.black26, fontSize: 13),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildSelectorTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        _buildTabItem("TARJETA", Icons.credit_card),
        const SizedBox(width: 8),
        _buildTabItem("SINPE",   Icons.phone_iphone),
        const SizedBox(width: 8),
        _buildTabItem("PAYPAL",  Icons.language),
      ]),
    );
  }

  Widget _buildTabItem(String label, IconData icon) {
    final bool  selected    = _metodoSeleccionado == label;
    final Color activeColor = label == "PAYPAL"
        ? const Color(0xFF003087)
        : const Color(0xFF3B4D28);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _metodoSeleccionado = label),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:         selected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color:      selected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize:   10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Monto dual ────────────────────────────────────────────────────────────

  Widget _buildMontoDisplay() {
    final bool esPaypal = _metodoSeleccionado == "PAYPAL";

    return Column(
      children: [
        Text(
          "₡${widget.total.toStringAsFixed(0)}",
          style: GoogleFonts.montserrat(
            fontSize:   42,
            fontWeight: FontWeight.w900,
            color:      const Color(0xFF3B4D28),
          ),
        ),
        const Text(
          "TOTAL DE LA ORDEN",
          style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        _cargandoTipoCambio
            ? const SizedBox(
                width:  18,
                height: 18,
                child:  CircularProgressIndicator(
                  strokeWidth: 2,
                  color:       Color(0xFF3B4D28),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: esPaypal
                      ? const Color(0xFF003087).withOpacity(0.08)
                      : const Color(0xFF3B4D28).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: esPaypal
                        ? const Color(0xFF003087).withOpacity(0.25)
                        : const Color(0xFF3B4D28).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      esPaypal ? Icons.language : Icons.attach_money,
                      size:  14,
                      color: esPaypal
                          ? const Color(0xFF003087)
                          : const Color(0xFF3B4D28),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "\$${_totalEnDolares.toStringAsFixed(2)} USD",
                      style: GoogleFonts.montserrat(
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                        color: esPaypal
                            ? const Color(0xFF003087)
                            : const Color(0xFF3B4D28),
                      ),
                    ),
                    if (esPaypal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical:   2,
                        ),
                        decoration: BoxDecoration(
                          color:         const Color(0xFF003087),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "PayPal",
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        if (!_cargandoTipoCambio)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              "Tipo de cambio: ₡${_tipoVenta.toStringAsFixed(2)} por dólar (BCCR venta)",
              style: const TextStyle(color: Colors.grey, fontSize: 9),
            ),
          ),
      ],
    );
  }

  // ── Tarjeta visual ────────────────────────────────────────────────────────

  Widget _buildEmisorIcon() {
    switch (_emisor) {
      case "VISA":
        return Text(
          "VISA",
          style: GoogleFonts.merriweather(
            color:      Colors.white,
            fontWeight: FontWeight.w900,
            fontSize:   22,
            fontStyle:  FontStyle.italic,
          ),
        );
      case "MASTERCARD":
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width:  22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
          ),
          Transform.translate(
            offset: const Offset(-10, 0),
            child: Container(
              width:  22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ]);
      default:
        return const Icon(Icons.credit_card, color: Colors.white38);
    }
  }

  Widget _buildTarjetaVisual() {
    Color c1;
    Color c2;

    switch (_emisor) {
      case "VISA":
        c1 = const Color(0xFF1A237E);
        c2 = const Color(0xFF0D47A1);
        break;
      case "MASTERCARD":
        c1 = const Color(0xFFE65100);
        c2 = const Color(0xFFBF360C);
        break;
      default:
        c1 = const Color(0xFF2C3E50);
        c2 = const Color(0xFF000000);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height:   190,
      width:    double.infinity,
      padding:  const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.wifi, color: Colors.white54),
              _buildEmisorIcon(),
            ],
          ),
          const Spacer(),
          Text(
            _numTarjetaController.text.isEmpty
                ? "XXXX XXXX XXXX XXXX"
                : _numTarjetaController.text,
            style: GoogleFonts.sourceCodePro(
              color:         Colors.white,
              fontSize:      18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TITULAR",
                      style: TextStyle(color: Colors.white60, fontSize: 9),
                    ),
                    Text(
                      _nombreTitularController.text.toUpperCase(),
                      style: const TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize:   13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "VALIDEZ",
                    style: TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                  Text(
                    _vencimientoController.text.isEmpty
                        ? "MM/AA"
                        : _vencimientoController.text,
                    style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Formulario SINPE ──────────────────────────────────────────────────────

  Widget _buildSinpeForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:         Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DATOS DE TRANSFERENCIA",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Divider(),
          _buildInput(
            _telOrigenController,
            "Número de teléfono",
            Icons.phone,
            maxLen: 8,
          ),
          if (_verificandoSinpe) const LinearProgressIndicator(),
          if (_nombreSinpeDestino.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Titular: $_nombreSinpeDestino",
                style: const TextStyle(
                  color:      Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                  fontSize:   12,
                ),
              ),
            ),
          const SizedBox(height: 10),
          _buildInput(
            _detalleSinpeController,
            "Detalle del pago",
            Icons.chat_bubble_outline,
            type: TextInputType.text,
          ),
        ],
      ),
    );
  }

  // ── Formulario PayPal ─────────────────────────────────────────────────────

  Widget _buildPaypalForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:         Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF003087).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:         const Color(0xFF003087),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Pay",
                  style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:         const Color(0xFF009CDE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Pal",
                  style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Pago en USD · seguro y encriptado",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          TextField(
            controller:   _emailPaypalController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText:  "Correo electrónico de PayPal",
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF003087)),
              filled:     true,
              fillColor:  const Color(0xFFF7F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   const BorderSide(color: Color(0xFF003087), width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF003087).withOpacity(0.3),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   const BorderSide(color: Color(0xFF003087), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF003087).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF003087).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF003087)),
                const SizedBox(width: 8),
                Expanded(
                  child: _cargandoTipoCambio
                      ? const Text(
                          "Cargando tipo de cambio...",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        )
                      : Text(
                          "Se cobrarán \$${_totalEnDolares.toStringAsFixed(2)} USD "
                          "(₡${widget.total.toStringAsFixed(0)} ÷ ₡${_tipoVenta.toStringAsFixed(2)} BCCR)",
                          style: const TextStyle(
                            fontSize: 11, color: Color(0xFF003087),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Barra BCCR ───────────────────────────────────────────────────────────

  Widget _buildBccrBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color:  Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: _cargandoTipoCambio
          ? const Center(
              child: SizedBox(
                width:  18,
                height: 18,
                child:  CircularProgressIndicator(
                  strokeWidth: 2,
                  color:       Color(0xFF3B4D28),
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:         const Color(0xFF3B4D28),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "BCCR",
                    style: TextStyle(
                      color:         Colors.white,
                      fontSize:      9,
                      fontWeight:    FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPildoraTipoCambio(
                    "COMPRA", _tipoCompra, const Color(0xFF1565C0), Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPildoraTipoCambio(
                    "VENTA", _tipoVenta, const Color(0xFF2E7D32), Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _cargarTiposCambio,
                  child: Container(
                    width:  34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:         const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size:  16,
                      color: Color(0xFF3B4D28),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPildoraTipoCambio(
    String   label,
    double   valor,
    Color    color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:         color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize:      8,
                  color:         color.withOpacity(0.8),
                  fontWeight:    FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "₡${valor.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize:   12,
                  color:      color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Input reutilizable ────────────────────────────────────────────────────

  Widget _buildInput(
    TextEditingController controller,
    String   label,
    IconData icon, {
    int?          maxLen,
    TextInputType type         = TextInputType.number,
    bool          esNumTarjeta = false,
  }) {
    return TextField(
      controller:   controller,
      maxLength:     maxLen,
      keyboardType: type,
      onChanged: (val) {
        setState(() {});
        if (esNumTarjeta) _detectarEmisor(val);
      },
      decoration: InputDecoration(
        labelText:   label,
        prefixIcon:  Icon(icon, color: const Color(0xFF3B4D28)),
        filled:      true,
        fillColor:   Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        counterText: "",
      ),
    );
  }

  // ── Diálogos ─────────────────────────────────────────────────────────────

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarFinal(String mensaje, String comprobante) {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(children: [
          Icon(Icons.check_circle, color: Colors.green, size: 50),
          SizedBox(height: 10),
          Text("¡ÉXITO!"),
        ]),
        content: Text(mensaje, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => FacturaScreen(
                    items:       widget.items,
                    total:       widget.total,
                    comprobante: comprobante,
                    usuario:     widget.usuarioActual,
                  ),
                ),
              );
            },
            child: const Text(
              "VER FACTURA",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
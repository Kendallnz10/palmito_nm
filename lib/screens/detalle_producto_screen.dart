import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/producto.dart';
import '../services/carrito_service.dart';
import '../screens/menu_lateral.dart'; 
import 'login.dart'; // Importante para la redirección al login

class DetalleProductoScreen extends StatefulWidget {
  final List<Producto> listaProductos;
  final int inicialIndex;
  final Map<String, dynamic> usuarioActual;

  const DetalleProductoScreen({
    super.key, 
    required this.listaProductos, 
    required this.inicialIndex,
    required this.usuarioActual 
  });

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  late PageController _pageController;
  int cantidad = 1;
  bool cargando = false;

  // Paleta de colores Palmito NM (Definidas aquí para evitar errores de scope)
  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color verdeSalvia = const Color(0xFF7D9452);
  final Color fondoLogoCrema = const Color(0xFFF2E8D5);
  final Color rojoElegante = const Color(0xFF9E2A2B);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.inicialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get idUsuarioLogueado {
    final id = widget.usuarioActual['id_usuario'] ?? 
               widget.usuarioActual['ID_Usuario'] ?? 
               widget.usuarioActual['id'] ?? 0;
    return int.tryParse(id.toString()) ?? 0;
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _moverPagina(bool adelante) {
    if (adelante) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Widget _buildStockStatus(Producto producto) {
    int stock = producto.stock;
    if (stock <= 0) {
      return Text("PRODUCTO AGOTADO", 
        style: GoogleFonts.montserrat(color: rojoElegante, fontWeight: FontWeight.bold, fontSize: 12));
    }
    return Text(
      stock > 10 ? "DISPONIBLE ($stock UNIDADES)" : "¡SOLO QUEDAN $stock UNIDADES!",
      style: GoogleFonts.montserrat(
        color: stock > 10 ? verdeSalvia : Colors.orange[800],
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }

  // --- LÓGICA DE INVITADO ---
  void _mostrarDialogoLogin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Inicia Sesión"),
        content: const Text("Para agregar productos a tu carrito de Palmito NM, debes ingresar a tu cuenta."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCELAR", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: verdeBosque),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
            child: const Text("IR AL LOGIN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarAlCarritoDB(Producto producto) async {
    // Si el ID es 0, es un invitado
    if (idUsuarioLogueado == 0) {
      _mostrarDialogoLogin();
      return;
    }

    if (cantidad > producto.stock) {
      _mostrarError("Lo sentimos, no hay suficiente stock.");
      return;
    }

    setState(() => cargando = true);

    try {
      bool exito = await CarritoService().agregarProducto(
        idUsuarioLogueado, 
        producto.id,
        cantidad,
        producto.precio,
      );

      if (!mounted) return;
      setState(() => cargando = false);

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡${producto.nombre} añadido al carrito!"),
            backgroundColor: verdeSalvia,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _mostrarError("No pudimos agregar el producto. Intente de nuevo.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
      _mostrarError("Error de conexión al servidor.");
    }
  }

  void _mostrarError(String msj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msj), backgroundColor: rojoElegante, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: MenuLateral(usuarioActual: widget.usuarioActual), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: verdeBosque),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/img/LOGOV2.png', height: 50),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: verdeBosque),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.listaProductos.length,
            onPageChanged: (index) => setState(() => cantidad = 1),
            itemBuilder: (context, index) {
              final producto = widget.listaProductos[index];
              return _buildDetalleContenido(producto);
            },
          ),
          Positioned(
            left: 0, top: 0, bottom: 100,
            child: _buildBotonNavegacion(false),
          ),
          Positioned(
            right: 0, top: 0, bottom: 100,
            child: _buildBotonNavegacion(true),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonNavegacion(bool esDerecha) {
    return GestureDetector(
      onTap: () => _moverPagina(esDerecha),
      child: Container(
        width: 60,
        color: Colors.transparent, 
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              esDerecha ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              color: verdeBosque.withOpacity(0.4),
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleContenido(Producto producto) {
    bool hayStock = producto.stock > 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: fondoLogoCrema,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Hero(
              tag: 'prod_${producto.id}',
              child: Image.network(
                producto.imagen,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.image_not_supported, size: 80, color: verdeBosque),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre.toUpperCase(), 
                  style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.bold, color: verdeBosque)
                ),
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₡${producto.precio.toStringAsFixed(0)}", 
                      style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: verdeSalvia)
                    ),
                    _buildStockStatus(producto),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(thickness: 1),
                ),
                
                Text("CANTIDAD A PEDIR", 
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _botonCantidad(Icons.remove, hayStock ? () {
                      if (cantidad > 1) setState(() => cantidad--);
                    } : null),
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Text("${hayStock ? cantidad : 0}", 
                        style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    _botonCantidad(Icons.add, hayStock ? () {
                      if (cantidad < producto.stock) {
                        setState(() => cantidad++);
                      } else {
                        _mostrarError("Alcanzaste el límite de unidades disponibles.");
                      }
                    } : null),
                  ],
                ),
                
                const SizedBox(height: 30),

                Text("DESCRIPCIÓN", 
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                const SizedBox(height: 10),
                Text(
                  producto.descripcion, 
                  style: GoogleFonts.montserrat(fontSize: 15, height: 1.6, color: Colors.black87)
                ),
                
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (cargando || !hayStock) ? null : () => _agregarAlCarritoDB(producto),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hayStock ? verdeBosque : Colors.grey,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: cargando 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          hayStock ? "AÑADIR AL CARRITO" : "SIN EXISTENCIAS", 
                          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                        ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonCantidad(IconData icono, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: verdeSalvia.withOpacity(0.3)),
          color: onTap == null ? Colors.grey[100] : Colors.transparent,
        ),
        child: Icon(icono, color: onTap == null ? Colors.grey : verdeBosque, size: 24),
      ),
    );
  }
}
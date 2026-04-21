import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/carrito_item.dart';
import '../services/carrito_service.dart';
import 'pagos_screen.dart';

class CarritoScreen extends StatefulWidget {
  final Map<String, dynamic> usuarioActual;

  const CarritoScreen({super.key, required this.usuarioActual});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  // Colores de identidad Palmito NM
  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color verdeSalvia = const Color(0xFF7D9452);
  final Color fondoLogoCrema = const Color(0xFFF2E8D5);

  final CarritoService _carritoService = CarritoService();
  List<CarritoItem> itemsCarrito = [];
  bool estaCargando = true;

  // Sincronización con las llaves de tu backend (Postgres usa minúsculas)
  int get idUsuarioLogueado => 
      widget.usuarioActual['id_usuario'] ?? widget.usuarioActual['ID_Usuario'] ?? 0;

  double get totalPedido => 
      itemsCarrito.fold(0, (sum, item) => sum + (item.producto.precio * item.cantidad));

  @override
  void initState() {
    super.initState();
    _obtenerDatosCarrito();
  }

  Future<void> _obtenerDatosCarrito() async {
    if (idUsuarioLogueado == 0) {
      if (mounted) _mostrarMensaje("Error: Sesión de usuario no válida");
      return;
    }

    setState(() => estaCargando = true);
    try {
      final resultado = await _carritoService.obtenerCarrito(idUsuarioLogueado);
      if (mounted) {
        setState(() {
          itemsCarrito = resultado;
          estaCargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => estaCargando = false);
        _mostrarMensaje("Error al conectar con el catálogo de productos");
      }
    }
  }

  void _modificarCantidad(CarritoItem item, int nuevaCantidad) async {
    if (nuevaCantidad < 1) return;
    
    // Llamada al servicio con el nuevo esquema de IDs de Postgres
    bool exito = await _carritoService.actualizarCantidad(idUsuarioLogueado, item.producto.id, nuevaCantidad);
    if (exito) {
      setState(() {
        item.cantidad = nuevaCantidad;
      });
    } else {
      _mostrarMensaje("Error de sincronización con el inventario");
    }
  }

  void _eliminarProducto(CarritoItem item, int index) async {
    bool exito = await _carritoService.eliminarProducto(idUsuarioLogueado, item.producto.id);
    if (exito) {
      setState(() {
        itemsCarrito.removeAt(index);
      });
      _mostrarMensaje("Producto removido correctamente");
    } else {
      _mostrarMensaje("No se pudo eliminar el producto");
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat()), 
        backgroundColor: verdeBosque,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoLogoCrema,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: verdeBosque, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/img/LOGOV2.png', 
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: verdeBosque), 
            onPressed: _obtenerDatosCarrito
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: estaCargando 
          ? Center(child: CircularProgressIndicator(color: verdeBosque))
          : itemsCarrito.isEmpty
              ? _buildCarritoVacio()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                        itemCount: itemsCarrito.length,
                        itemBuilder: (context, index) => _buildItemCarrito(itemsCarrito[index], index),
                      ),
                    ),
                    _buildResumenTotal(),
                  ],
                ),
    );
  }

  Widget _buildItemCarrito(CarritoItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // Imagen del Producto con Blindaje de Nulos
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: item.producto.imagen.isNotEmpty 
              ? Image.network(
                  item.producto.imagen, 
                  width: 75, height: 75, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Container(width: 75, height: 75, color: Colors.grey[100], child: const Icon(Icons.image)),
                )
              : Container(width: 75, height: 75, color: Colors.grey[100], child: const Icon(Icons.image)),
          ),
          const SizedBox(width: 15),
          // Detalles del Producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto.nombre.isEmpty ? "Producto Palmito" : item.producto.nombre, 
                  style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 16, color: verdeBosque),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "₡${item.producto.precio.toStringAsFixed(0)}", 
                  style: GoogleFonts.montserrat(color: verdeSalvia, fontWeight: FontWeight.w700, fontSize: 15)
                ),
                // Selector de Cantidad
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.remove_circle_outline, color: verdeSalvia, size: 22), 
                      onPressed: () => _modificarCantidad(item, item.cantidad - 1)
                    ),
                    Text(
                      "${item.cantidad}", 
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.add_circle_outline, color: verdeSalvia, size: 22), 
                      onPressed: () => _modificarCantidad(item, item.cantidad + 1)
                    ),
                  ],
                )
              ],
            ),
          ),
          // Botón Eliminar
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 26), 
            onPressed: () => _eliminarProducto(item, index)
          ),
        ],
      ),
    );
  }

  Widget _buildResumenTotal() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total a pagar:", 
                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                Text("₡${totalPedido.toStringAsFixed(0)}", 
                  style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: verdeBosque)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: itemsCarrito.isEmpty ? null : _confirmarPedido,
                style: ElevatedButton.styleFrom(
                  backgroundColor: verdeBosque, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 4,
                ),
                child: Text(
                  "CONTINUAR AL PAGO", 
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarPedido() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("Confirmar Orden", 
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: verdeBosque)),
        content: Text(
          "Se generará un pedido por un total de ₡${totalPedido.toStringAsFixed(0)}. ¿Deseas proceder?",
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("REVISAR MÁS", style: TextStyle(color: Colors.grey[600]))
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => PagosScreen(
                    items: itemsCarrito, 
                    total: totalPedido,
                    usuarioActual: widget.usuarioActual
                  )
                )
              );
            }, 
            style: ElevatedButton.styleFrom(
              backgroundColor: verdeSalvia, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("SÍ, PAGAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCarritoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 120, color: verdeBosque.withOpacity(0.1)),
            const SizedBox(height: 20),
            Text("¡Tu cesta está vacía!", 
              style: GoogleFonts.lora(fontSize: 22, color: verdeBosque, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Parece que aún no has agregado nuestras delicias de palmito.", 
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), 
              style: ElevatedButton.styleFrom(
                backgroundColor: verdeBosque,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ), 
              child: const Text("EXPLORAR CATÁLOGO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/producto.dart';
import '../services/producto_services.dart';
import '../screens/menu_lateral.dart'; 
import 'detalle_producto_screen.dart';
import 'carrito.dart'; 
import 'historial_compras.dart'; 
import 'ajustes_screen.dart';
import 'login.dart';

class CatalogoPalmito extends StatefulWidget {
  final Map<String, dynamic> usuarioActual; 
  final bool mfaActivo;
  final bool tienePreguntas;

  const CatalogoPalmito({
    super.key, 
    required this.usuarioActual,
    this.mfaActivo = true, 
    this.tienePreguntas = true,
  });

  @override
  State<CatalogoPalmito> createState() => _CatalogoPalmitoState();
}

class _CatalogoPalmitoState extends State<CatalogoPalmito> {
  final Color fondoLogoCrema = const Color(0xFFF2E8D5);
  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color verdeSalvia = const Color(0xFF7D9452);
  final Color rojoElegante = const Color(0xFF9E2A2B);

  int _selectedIndex = 0;
  final ProductoService _productoService = ProductoService();
  late Future<List<Producto>> _futureProductos;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _mfaReal = false;
  bool _preguntasReales = false;

  @override
  void initState() {
    super.initState();
    _futureProductos = _productoService.fetchProductos();
    _sincronizarSeguridad();

    final id = widget.usuarioActual['id_usuario'] ?? widget.usuarioActual['ID_Usuario'] ?? 0;
    if (id != 0 && (!_mfaReal || !_preguntasReales)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarAvisoSeguridad();
      });
    }
  }

  void _sincronizarSeguridad() {
    _mfaReal = widget.usuarioActual['mfa_activado'] == true || 
               widget.usuarioActual['MFA_Activado'] == true ||
               widget.mfaActivo;

    _preguntasReales = widget.usuarioActual['preguntas_configuradas'] == true || 
                       widget.usuarioActual['Preguntas_Configuradas'] == true ||
                       widget.tienePreguntas;
  }

  Widget _buildBadgeStock(int stock) {
    Color color;
    String texto;

    if (stock > 10) {
      color = Colors.green[700]!;
      texto = "DISPONIBLE";
    } else if (stock > 0) {
      color = Colors.orange[800]!;
      texto = "POCAS UNIDADES";
    } else {
      color = rojoElegante;
      texto = "AGOTADO";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        texto,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _mostrarAvisoSeguridad() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: const Color(0xFFF9F7F2),
        title: Row(
          children: [
            Icon(Icons.security_update_warning_rounded, color: rojoElegante),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Cuenta Desprotegida", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          "Por su seguridad, le recomendamos activar la autenticación de doble factor (MFA) "
          "y configurar sus preguntas de seguridad.",
          style: GoogleFonts.montserrat(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("LUEGO", style: GoogleFonts.montserrat(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: verdeBosque,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => AjustesScreen(usuarioActual: widget.usuarioActual)
                )
              );
            },
            child: Text("IR A AJUSTES", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoLogin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Acceso Restringido"),
        content: const Text("Para acceder a esta sección o realizar compras, debes iniciar sesión con tu cuenta."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCELAR", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: verdeBosque),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
            },
            child: const Text("INICIAR SESIÓN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() { _selectedIndex = index; });
    } else {
      final id = widget.usuarioActual['id_usuario'] ?? widget.usuarioActual['ID_Usuario'] ?? 0;
      if (id == 0) {
        _mostrarDialogoLogin();
      } else {
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CarritoScreen(usuarioActual: widget.usuarioActual)));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HistorialScreen(usuarioActual: widget.usuarioActual)));
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AjustesScreen(usuarioActual: widget.usuarioActual)));
        }
      }
    }
  }

  // ── HELPER: ¿es invitado? ──────────────────────────────────────────────────
  bool get _esInvitado {
    final id = widget.usuarioActual['id_usuario'] ?? widget.usuarioActual['ID_Usuario'] ?? 0;
    return id == 0;
  }

  // ── LEADING DEL APPBAR ─────────────────────────────────────────────────────
  Widget _buildLeadingAppBar() {
    if (_esInvitado) {
      // Botón "Iniciar sesión" compacto para invitados
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: verdeBosque,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
          child: Text(
            "Iniciar\nsesión",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
      );
    } else {
      // Botón de notificaciones para usuarios autenticados
      return IconButton(
        icon: Icon(Icons.notifications_none_outlined, color: verdeBosque, size: 28),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No tienes notificaciones nuevas")),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombreRaw = widget.usuarioActual['nombre'] ?? 
                             widget.usuarioActual['Nombre'] ?? 
                             widget.usuarioActual['usuario'] ?? 
                             widget.usuarioActual['Usuario'] ?? 'Invitado';

    return Scaffold(
      key: _scaffoldKey, 
      backgroundColor: fondoLogoCrema,
      endDrawer: MenuLateral(usuarioActual: widget.usuarioActual), 

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        toolbarHeight: 80,

        // ── CAMBIO PRINCIPAL: leading dinámico ────────────────────────────
        leading: _buildLeadingAppBar(),

        title: Image.asset(
          'assets/img/LOGOV2.png',
          height: 60,
          errorBuilder: (context, error, stackTrace) => Text(
            "PALMITO NM",
            style: GoogleFonts.lora(color: verdeBosque, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: verdeBosque, size: 28), 
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: Column(
        children: [
          const SizedBox(height: 15),
          Text(
            "BIENVENIDO/A, ${nombreRaw.toUpperCase()}",
            style: GoogleFonts.montserrat(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: verdeBosque.withOpacity(0.7),
            ),
          ),
          const Divider(indent: 100, endIndent: 100, thickness: 0.5),
          
          Expanded(
            child: FutureBuilder<List<Producto>>(
              future: _futureProductos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: verdeSalvia));
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error al cargar productos", style: GoogleFonts.montserrat()));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No hay productos disponibles"));
                }

                final productos = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleProductoScreen(
                              listaProductos: productos, 
                              inicialIndex: index,
                              usuarioActual: widget.usuarioActual 
                            ),
                          ),
                        ).then((_) {
                          setState(() {
                            _futureProductos = _productoService.fetchProductos();
                          });
                        });
                      },
                      child: _buildProductoCard(producto),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: verdeSalvia,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_mosaic), label: 'Catálogo'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Carrito'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }

  Widget _buildProductoCard(Producto producto) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
        ],
        border: Border.all(color: verdeBosque.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                producto.imagen,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Container(
                    color: Colors.grey[100],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))
                  ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre, 
                  style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 13, color: verdeBosque),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "₡${producto.precio.toStringAsFixed(0)}",
                  style: GoogleFonts.montserrat(color: verdeSalvia, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Center(
                  child: _buildBadgeStock(producto.stock),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
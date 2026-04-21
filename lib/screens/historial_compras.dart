import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/carrito_service.dart';
import '../screens/menu_lateral.dart';
import 'detalle_historial.dart'; 

class HistorialScreen extends StatefulWidget {
  final Map<String, dynamic> usuarioActual;
  const HistorialScreen({super.key, required this.usuarioActual});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final CarritoService _service = CarritoService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: Según tu tabla, el campo es 'id_usuario'
    final int? idUsuarioReal = widget.usuarioActual['id_usuario'] ?? 
                               widget.usuarioActual['ID_Usuario'] ?? 
                               widget.usuarioActual['id'];

    const Color verdeBosque = Color(0xFF3B4D28);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2E8D5),
      endDrawer: MenuLateral(usuarioActual: widget.usuarioActual),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: verdeBosque),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/img/LOGOV2.png', height: 45, 
          errorBuilder: (c, e, s) => const Text("HISTORIAL", style: TextStyle(color: verdeBosque))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: verdeBosque, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: idUsuarioReal == null 
        ? const Center(child: Text("Sesión no válida. Por favor reingrese."))
        : FutureBuilder<List<dynamic>>(
            // Este método en el service debe hacer: 
            // SELECT * FROM Historial_Pedido WHERE id_usuario = $idUsuarioReal
            future: _service.obtenerHistorial(idUsuarioReal),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: verdeBosque));
              }
              
              if (snapshot.hasError) {
                return Center(child: Text("Error de conexión: ${snapshot.error}"));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_toggle_off, size: 70, color: Colors.grey),
                      const SizedBox(height: 15),
                      Text("Aún no tienes pedidos registrados", 
                        style: GoogleFonts.montserrat(fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                );
              }

              final pedidos = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: pedidos.length,
                itemBuilder: (context, index) {
                  final pedido = pedidos[index];
                  
                  // Mapeo según tu tabla Historial_Pedido
                  final String fechaRaw = pedido['fecha'].toString();
                  final String fecha = fechaRaw.split('T')[0];
                  final int idPedido = pedido['id_pedido'];
                  final int nPedido = pedido['n_pedido_usuario'] ?? (index + 1);
                  final String estado = pedido['estado'] ?? "Procesado";

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.only(bottom: 15), 
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7D9452).withOpacity(0.2),
                          shape: BoxShape.circle
                        ),
                        child: const Icon(Icons.shopping_bag, color: Color(0xFF7D9452)),
                      ),
                      title: Text(
                        "Pedido #$nPedido", 
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: verdeBosque),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Fecha: $fecha"),
                          Text("Estado: $estado", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: verdeBosque),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleHistorialScreen(
                              idPedido: idPedido, 
                              fecha: fechaRaw,
                              usuarioActual: widget.usuarioActual,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}
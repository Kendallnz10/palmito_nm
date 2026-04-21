import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetalleHistorialScreen extends StatelessWidget {
  final int idPedido;
  final String fecha;
  final Map<String, dynamic> usuarioActual;

  const DetalleHistorialScreen({
    super.key, 
    required this.idPedido, 
    required this.fecha, 
    required this.usuarioActual
  });

  Future<List<dynamic>> fetchDetalle() async {
    try {
      final url = Uri.parse('https://backend-palmitonm.onrender.com/historial/detalle/$idPedido');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("Error conexión historial: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color verdeBosque = Color(0xFF3B4D28);
    const Color verdeSalvia = Color(0xFF7D9452);
    const Color fondoLogoCrema = Color(0xFFF2E8D5);

    String fechaLimpia = fecha.split('T')[0];

    return Scaffold(
      backgroundColor: fondoLogoCrema,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: verdeBosque),
        title: Image.asset('assets/img/LOGOV2.png', height: 40, fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const Text("DETALLE PEDIDO", style: TextStyle(color: verdeBosque))),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchDetalle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: verdeBosque));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No se encontraron productos para este pedido."));
          }

          final productos = snapshot.data!;
          
          double totalPedido = 0;
          for (var p in productos) {
            totalPedido += double.tryParse(p['subtotal'].toString()) ?? 0.0;
          }

          return Column(
            children: [
              // BANNER DE ORDEN
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: verdeBosque,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PEDIDO", style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("#$idPedido", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(fechaLimpia, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),

              // LISTADO DE PRODUCTOS (LÓGICA IGUAL AL CARRITO)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: productos.length,
                  itemBuilder: (context, i) {
                    final item = productos[i];
                    
                    // Manejo de imagen idéntico al carrito
                    String imgPath = item['imagen']?.toString() ?? "";
                    String urlFinal = imgPath.isEmpty 
                        ? "" 
                        : (imgPath.startsWith('http') 
                            ? imgPath 
                            : "https://backend-palmitonm.onrender.com${imgPath.startsWith('/') ? '' : '/'}$imgPath");

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          // CUADRO CREMA DE IMAGEN
                          Container(
                            width: 75, height: 75,
                            decoration: BoxDecoration(
                              color: fondoLogoCrema,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: urlFinal.isNotEmpty 
                                ? Image.network(
                                    urlFinal, 
                                    width: 75, height: 75, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                      const Icon(Icons.image, color: verdeSalvia),
                                  )
                                : const Icon(Icons.image, color: verdeSalvia),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nombre']?.toString() ?? "Producto", 
                                  style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 16, color: verdeBosque),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Cant: ${item['cantidad']} x ₡${double.parse(item['precio_unitario'].toString()).toStringAsFixed(0)}", 
                                  style: GoogleFonts.montserrat(fontSize: 13, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "₡${double.parse(item['subtotal'].toString()).toStringAsFixed(0)}", 
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: verdeBosque, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // RESUMEN FINAL
              Container(
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)]
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("TOTAL PAGADO", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                          Text("₡${totalPedido.toStringAsFixed(0)}", 
                            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: verdeBosque)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: verdeBosque,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text("VOLVER AL HISTORIAL", 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
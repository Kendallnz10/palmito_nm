import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../models/carrito_item.dart';

class FacturaScreen extends StatelessWidget {
  final List<CarritoItem> items;
  final double total;
  final String comprobante;
  final Map<String, dynamic> usuario;

  const FacturaScreen({
    super.key, 
    required this.items, 
    required this.total, 
    required this.comprobante,
    required this.usuario
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comprobante de Compra"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ENCABEZADO ---
            Center(
              child: Column(
                children: [
                  Image.asset('assets/img/LOGOV2.png', height: 80), // Un poco más grande
                  const SizedBox(height: 10),
                  const Text("PALMITO NM", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 1.2)),
                  const SizedBox(height: 5),
                  Text("Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text("Ticket: #$comprobante", 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Divider(height: 40, thickness: 1.5),
            
            // --- INFO CLIENTE ---
            Text("Cliente:", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            Text(usuario['nombre'] ?? 'Usuario General', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 25),
            const Text("DETALLE DE PRODUCTOS", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
            const SizedBox(height: 10),

            // --- LISTA DE PRODUCTOS ---
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        // Cantidad resaltada
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${item.cantidad}x", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Nombre y precio unitario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.producto.nombre, 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text("Precio unitario: ₡${item.producto.precio.toStringAsFixed(0)}", 
                                style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                        // Subtotal por producto
                        Text(
                          "₡${(item.producto.precio * item.cantidad).toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(thickness: 2),
            
            // --- TOTAL ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL PAGADO", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    "₡${total.toStringAsFixed(0)}", 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // --- BOTÓN INFERIOR ---
            SizedBox(
              width: double.infinity,
              height: 55, // Más alto para mejor tacto
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // Color más intuitivo
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text("VOLVER AL INICIO", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
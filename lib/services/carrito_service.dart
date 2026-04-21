import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/carrito_item.dart';
import '../models/producto.dart';

class CarritoService {
  final String baseUrl = "https://backend-palmitonm.onrender.com"; // URL de tu backend en Render

  // 1. AGREGAR PRODUCTO
  Future<bool> agregarProducto(int idUsuario, int idProducto, int cantidad, double precio) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/carrito/agregar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_usuario": idUsuario,
          "id_producto": idProducto,
          "cantidad": cantidad,
          "precio_unitario": precio
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al agregar: $e");
      return false;
    }
  }

  // 2. OBTENER PRODUCTOS DEL CARRITO
  Future<List<CarritoItem>> obtenerCarrito(int idUsuario) async {
    if (idUsuario == 0) return []; // Evita peticiones basura
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/carrito/$idUsuario'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          // Mapeo robusto: Postgres (minúsculas) vs SQL Server (CamelCase)
          return CarritoItem(
            producto: Producto(
              id: item['id'] ?? item['id_producto'] ?? item['ID'] ?? 0, 
              nombre: item['nombre'] ?? item['nombre_producto'] ?? item['Nombre'] ?? 'Producto',
              descripcion: item['descripcion'] ?? item['Descripcion'] ?? '',
              // Convertimos a double de forma segura para evitar el error de 'String is not a subtype of double'
              precio: double.tryParse((item['precio'] ?? item['precio_unitario'] ?? item['Precio'] ?? 0).toString()) ?? 0.0,
              stock: item['stock'] ?? item['Stock'] ?? 0,
              imagen: item['imagen'] ?? item['Imagen'] ?? '',
              // Si el estado en la DB es 'Disponible', el bool será true, de lo contrario false.
              estado: (item['estado'] ?? item['Estado']) == 'Disponible',
            ),
            cantidad: item['cantidad'] ?? item['Cantidad'] ?? 1,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print("Error al obtener carrito: $e");
      return [];
    }
  }

  // 3. ACTUALIZAR CANTIDAD
  Future<bool> actualizarCantidad(int idUsuario, int idProducto, int nuevaCantidad) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/carrito/actualizar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_usuario": idUsuario,
          "id_producto": idProducto,
          "cantidad": nuevaCantidad,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al actualizar cantidad: $e");
      return false;
    }
  }

  // 4. ELIMINAR PRODUCTO
  Future<bool> eliminarProducto(int idUsuario, int idProducto) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/carrito/eliminar/$idUsuario/$idProducto'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al eliminar producto: $e");
      return false;
    }
  }

  // 5. FINALIZAR COMPRA 
// 5. FINALIZAR COMPRA (Actualizado)
  Future<bool> finalizarCompra(int idUsuario, double total, String metodo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/carrito/procesar-pago'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_usuario": idUsuario,
          "total": total,      // Enviamos el monto total
          "metodo": metodo     // Enviamos si fue TARJETA o SINPE
        }),
      );

      // Imprimimos el cuerpo de la respuesta si falla para ver qué dice el error 400
      if (response.statusCode != 200 && response.statusCode != 201) {
        print("Error del servidor: ${response.body}");
      }

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error al procesar pago: $e");
      return false;
    }
  }

  // 6. OBTENER HISTORIAL 
  Future<List<dynamic>> obtenerHistorial(int idUsuario) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/historial/$idUsuario'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error al obtener historial: $e");
      return [];
    }
  }

  // 7. OBTENER DETALLE 
  Future<List<dynamic>> obtenerDetalleHistorial(int idPedido) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/historial/detalle/$idPedido'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error al obtener detalle historial: $e");
      return [];
    }
  }
}
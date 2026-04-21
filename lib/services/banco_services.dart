import 'dart:convert';
import 'package:http/http.dart' as http;

class BancoService {
  // Reemplazamos la IP local por tu URL de Render
  final String baseUrl = "https://backend-palmitonm.onrender.com/banco";

  // --- 1. Consultar Nombre por Teléfono ---
  Future<String?> consultarNombrePorTelefono(String telefono) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nombre/$telefono'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['nombre'];
        }
      }
      return null; 
    } catch (e) {
      print("Error consultando nombre: $e");
      return null;
    }
  }

  // --- 2. Pago con Tarjeta (Débito o Crédito) ---
  Future<Map<String, dynamic>> pagarConTarjeta({
    required String numero,
    required String cvv,
    required String vencimiento,
    required double monto,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pagar-tarjeta'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "numero": numero,
          "cvv": cvv,
          "vencimiento": vencimiento,
          "monto": monto
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "mensaje": "Error de conexión con el banco"};
    }
  }

  // --- 3. SINPE Móvil ---
  Future<Map<String, dynamic>> pagarConSinpe({
    required String telOrigen,
    required double monto,
    required String descripcion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sinpe-movil'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "tel_origen": telOrigen,
          "tel_destino": "84214439", 
          "monto": monto,
          "descripcion": descripcion
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "mensaje": "Error de conexión SINPE"};
    }
  }

  // --- 4. Procesar Registro de PayPal en Backend ---
  Future<Map<String, dynamic>> pagarConPaypal({
    required double monto,
    required String orderID,
    required int idUsuario,
    String? descripcion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pagar-paypal'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_usuario": idUsuario,
          "monto": monto,
          "orderID": orderID,
          "descripcion": descripcion ?? "Compra en Tienda Palmito NM vía PayPal"
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false, 
          "mensaje": errorData['mensaje'] ?? "Error al registrar pago PayPal"
        };
      }
    } catch (e) {
      print("Error en BancoService PayPal: $e");
      return {"success": false, "mensaje": "Error de conexión con el servidor bancario"};
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;

class HistorialService {
  final String _baseUrl = "http://192.168.100.4:3000/historial"; 

  Future<List<dynamic>> obtenerDetalleHistorial(int idPedido) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/detalle/$idPedido'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("Error conexión: $e");
      return [];
    }
  }
}
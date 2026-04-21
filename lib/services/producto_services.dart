import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto.dart'; 

class ProductoService {
  final String _baseUrl = "https://backend-palmitonm.onrender.com/productos"; 

  Future<List<Producto>> fetchProductos() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        
        return decodedData.map((item) => Producto.fromJson(item)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print("Error en fetchProductos: $e");
      throw Exception('Falló la conexión con el servidor');
    }
  }
}
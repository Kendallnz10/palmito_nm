import 'dart:convert';
import 'package:http/http.dart' as http;

class TSEService {
  final String _urlBase = "https://backend-palmitonm.onrender.com/tse"; 

Future<Map<String, dynamic>> consultarCedula(String cedula) async {
  try {
    final url = Uri.parse('$_urlBase/buscar/${cedula.replaceAll('-', '').trim()}');
    final response = await http.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      
      if (body['datos'] == null) return {'encontrado': false};

      return {
        'encontrado': true,
        'datos': body['datos'] 
      };
    }
    return {'encontrado': false};
  } catch (e) {
    print(" Error en TSEService: $e");
    return {'encontrado': false};
  }
}
}
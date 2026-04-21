import 'dart:convert';
import 'package:http/http.dart' as http;

class TipoCambioService {

  Future<Map<String, double>> obtenerTipoCambio() async {
    try {
      final url = Uri.parse("https://backend-palmitonm.onrender.com/tipo-cambio");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          "compra": (data["compra"] as num).toDouble(),
          "venta":  (data["venta"]  as num).toDouble(),
        };
      } else {
        throw Exception("Error backend");
      }
    } catch (e) {
      print("ERROR FLUTTER: $e");

      return {
        "compra": 0,
        "venta": 0,
      };
    }
  }
}
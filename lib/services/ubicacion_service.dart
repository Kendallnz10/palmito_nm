import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:palmito_nm/models/ubicacion.dart';

class UbicacionService {
  final String baseUrl = "https://backend-palmitonm.onrender.com"; // URL de tu backend en Render

  Future<List<Pais>> getPaises() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/ubicacion/paises'));
      
      // Print de depuración para ver el error exacto en VS Code
      print("DEBUG PAISES: Status ${res.statusCode} - Body: ${res.body}");

      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);
        return data.map((json) => Pais.fromJson(json)).toList();
      }
    } catch (e) {
      // Este print te avisará si el servidor no está encendido o la IP es errónea
      print("Error en getPaises (Verifica que tu API en el puerto 3000 esté activa): $e");
    }
    return [];
  }

  Future<List<Provincia>> getProvincias(int idPais) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/ubicacion/provincias/$idPais'));
      print("DEBUG PROVINCIAS: Status ${res.statusCode} - Body: ${res.body}");

      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);
        return data.map((json) => Provincia.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error en getProvincias: $e");
    }
    return [];
  }

  Future<List<Canton>> getCantones(int idProv) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/ubicacion/cantones/$idProv'));
      print("DEBUG CANTONES: Status ${res.statusCode} - Body: ${res.body}");

      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);
        return data.map((json) => Canton.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error en getCantones: $e");
    }
    return [];
  }

  Future<List<Distrito>> getDistritos(int idCant) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/ubicacion/distritos/$idCant'));
      print("DEBUG DISTRITOS: Status ${res.statusCode} - Body: ${res.body}");

      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);
        return data.map((json) => Distrito.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error en getDistritos: $e");
    }
    return [];
  }

  Future<http.Response> registrarUsuario(Map<String, dynamic> datos) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/usuarios/registrar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(datos),
      );
    } catch (e) {
      print("Error en registrarUsuario: $e");
      rethrow;
    }
  }
}
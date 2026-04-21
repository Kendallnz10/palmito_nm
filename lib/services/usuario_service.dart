import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class UsuarioService {

  final String baseUrl = "https://backend-palmitonm.onrender.com/usuarios";

  // 1. AUTENTICACIÓN (LOGIN)

  Future<Map<String, dynamic>> login(String usuario, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usuario": usuario.trim(),
          "contrasena": password,
        }),
      );

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      debugPrint("Error en Login: $e");
      return {
        'statusCode': 500,
        'body': {'mensaje': 'Error de conexión con el servidor'},
      };
    }
  }

  /// Login con Google usando ID Token 
  Future<Map<String, dynamic>> loginConGoogle(String? idToken) async {
    return _postToGoogleLogin({"idToken": idToken});
  }

  /// Login con Google Manual 
  Future<Map<String, dynamic>> loginConGoogleManual(Map<String, String> datos) async {
    return _postToGoogleLogin(datos);
  }

  /// Método privado para centralizar las peticiones de Google (SIN CAMBIOS)
  Future<Map<String, dynamic>> _postToGoogleLogin(Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl/login-google');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.body.startsWith('<!DOCTYPE') || response.body.startsWith('<html')) {
        return {
          'statusCode': response.statusCode,
          'body': {'mensaje': 'El servidor retornó un error inesperado (HTML).'},
        };
      }

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      debugPrint("Error en Google Login Service: $e");
      return {
        'statusCode': 500,
        'body': {'mensaje': 'Error al procesar la respuesta del servidor'},
      };
    }
  }

  /// --- NUEVA FUNCIÓN PARA FACEBOOK ---
  Future<Map<String, dynamic>> loginConFacebook(String token) async {
    try {
      final url = Uri.parse('$baseUrl/login-facebook');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token}),
      );

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      debugPrint("Error en Facebook Login Service: $e");
      return {
        'statusCode': 500,
        'body': {'mensaje': 'Error de conexión con el servidor'},
      };
    }
  }

  // ---------------------------------------------------------------------------
  // 2. REGISTRO DE USUARIOS
  // ---------------------------------------------------------------------------

  Future<http.Response> registrarUsuario(Map<String, dynamic> datos) async {
    try {
      final url = Uri.parse('$baseUrl/registrar');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 15));
      
      return response;
    } catch (e) {
      debugPrint("ERROR EN registrarUsuario: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. MULTI-FACTOR AUTHENTICATION (MFA)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> activarMFA(dynamic idUsuario, String correo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mfa/activar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_usuario': idUsuario, 'correo': correo}),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'mensaje': 'Error de conexión'}};
    }
  }

  Future<Map<String, dynamic>> verificarMFA(dynamic idUsuario, String codigo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mfa/verificar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idUsuario': idUsuario, 'codigo': codigo}),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'mensaje': 'Error de conexión'}};
    }
  }

  // ---------------------------------------------------------------------------
  // 4. VERIFICACIÓN POR CORREO (OTP)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> enviarCodigoVerificacion(String correo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enviar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );
      return {
        'success': response.statusCode == 200, 
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body)
      };
    } catch (e) {
      return {'success': false, 'mensaje': 'Error de red', 'statusCode': 500};
    }
  }

  Future<Map<String, dynamic>> validarCodigoOTP(String correo, String codigo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'codigo': codigo}),
      );
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body)
      };
    } catch (e) {
      return {'success': false, 'statusCode': 500};
    }
  }

  // ---------------------------------------------------------------------------
  // 5. PREGUNTAS DE SEGURIDAD
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> guardarPreguntasSeguridad({
    required dynamic idUsuario,
    required String p1,
    required String r1,
    required String p2,
    required String r2,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/seguridad/preguntas');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idUsuario': idUsuario,
          'p1': p1,
          'r1': r1.toLowerCase().trim(),
          'p2': p2,
          'r2': r2.toLowerCase().trim(),
        }),
      );
      return {
        'statusCode': response.statusCode, 
        'body': response.body.isNotEmpty ? jsonDecode(response.body) : {}
      };
    } catch (e) {
      debugPrint("Error en guardarPreguntasSeguridad: ${e.toString()}");
      return {'statusCode': 500, 'body': {'mensaje': 'Error de conexión'}};
    }
  }

  // ---------------------------------------------------------------------------
  // 6. RECUPERACIÓN DE CUENTA
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> obtenerPreguntasPorCorreo(String correo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar/obtener-preguntas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {'success': false, 'mensaje': 'Error de conexión', 'statusCode': 500};
    }
  }

  Future<Map<String, dynamic>> verificarRespuestas({
    required dynamic idUsuario,
    required String r1,
    required String r2,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar/verificar-respuestas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idUsuario': idUsuario, 
          'r1': r1.toLowerCase().trim(), 
          'r2': r2.toLowerCase().trim()
        }),
      );
      return {'success': response.statusCode == 200, 'statusCode': response.statusCode};
    } catch (e) {
      return {'success': false, 'statusCode': 500};
    }
  }

  Future<Map<String, dynamic>> restablecerPasswordPostValidacion({
    required dynamic idUsuario,
    required String nuevaPass,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar/restablecer-solo-pass'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idUsuario': idUsuario,
          'nuevaPass': nuevaPass,
        }),
      );
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body)
      };
    } catch (e) {
      return {'success': false, 'statusCode': 500, 'mensaje': 'Error de conexión'};
    }
  }

  Future<Map<String, dynamic>> restablecerCredenciales({
    required dynamic idUsuario,
    required String nuevoUser,
    required String nuevaPass,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar/restablecer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idUsuario': idUsuario,
          'nuevoUser': nuevoUser,
          'nuevaPass': nuevaPass,
        }),
      );
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body)
      };
    } catch (e) {
      return {'success': false, 'statusCode': 500};
    }
  }

  // ---------------------------------------------------------------------------
  // 7. PERFIL Y MANTENIMIENTO
  // ---------------------------------------------------------------------------

  Future<bool> actualizarPerfil(int id, Map<String, dynamic> datos) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/actualizar/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error actualizando perfil: $e");
      return false;
    }
  }

  Future<List<dynamic>> obtenerUsuarios() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("Error obteniendo usuarios: $e");
      return [];
    }
  }

  /// Validación de cédula mediante el Padrón (TSE)
  Future<Map<String, dynamic>> validarCedulaTSE(String cedula) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validar-cedula'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cedula': cedula}),
      );
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body)
      };
    } catch (e) {
      return {'statusCode': 500, 'body': {'mensaje': 'Error de conexión con el TSE'}};
    }
  }
}
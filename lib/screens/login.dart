import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/usuario_service.dart';
import 'catalogo_palmito.dart';
import 'verificar_mfa_screen.dart';
import 'opciones_recuperacion_screen.dart';
import 'verificar_correo.dart';
import 'registrar_cuenta.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final UsuarioService _usuarioService = UsuarioService();
  bool _cargando = false;
  
  // --- NUEVO ESTADO PARA LA CONTRASEÑA ---
  bool _mostrarPass = false; 

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "626253654724-68sicbt3a4vgmlb7klmfi0tb195ik2bt.apps.googleusercontent.com",
    scopes: ['email', 'profile'],
  );

  final Color verdeBosque = const Color(0xFF3F4E34);
  final Color fondoCrema = const Color(0xFFF2E8D5);
  final Color rojoError = const Color(0xFF9E2A2B);
  final Color lavandaFondoBtn = const Color(0xFFF3F1FF);
  final Color lavandaTextoBtn = const Color(0xFF6B6281);

  void _procesarRespuestaServicio(dynamic res, String correoFallback) {
  if (mounted) setState(() => _cargando = false);

  // Verificamos si la respuesta del servidor de Render fue exitosa
  if (res['statusCode'] == 200) {
    final body = res['body'];

    // CASO 1: El correo NO existe en la base de datos
    if (body['nuevoUsuario'] == true) {
      final Map<String, dynamic> datosSeguros = 
          (body['datosPrecargados'] != null) 
          ? Map<String, dynamic>.from(body['datosPrecargados']) 
          : {};

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrarCuenta(
            correoVerificado: correoFallback,
            datosGoogle: datosSeguros,
          ),
        ),
      );
    } 
    // CASO 2: El usuario ya existe y tiene MFA activo
    else if (body['requiereMFA'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificarMFAScreen(idUsuario: body['id_usuario']),
        ),
      );
    } 
    // CASO 3: El usuario ya existe y NO tiene MFA (o ya se validó)
    else {
      // Mandamos directamente al catálogo con los datos del usuario
      _irAlCatalogo(body['usuario']);
    }
  } else {
    // Si el servidor responde con 401, 404 o 500
    _mostrarAlerta(res['body']['mensaje'] ?? "Error en la autenticación");
  }
}

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _cargando = true);
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _cargando = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? token = googleAuth.idToken;
      dynamic res;

      if (token != null && token.isNotEmpty) {
        res = await _usuarioService.loginConGoogle(token);
      } else {
        final datosManuales = {
          "idToken": "",
          "correo": googleUser.email,
          "nombre": googleUser.displayName?.split(' ').first ?? "",
          "apellido": googleUser.displayName?.split(' ').last ?? "",
        };
        res = await _usuarioService.loginConGoogleManual(datosManuales);
      }

      _procesarRespuestaServicio(res, googleUser.email);
    } catch (error) {
      if (mounted) setState(() => _cargando = false);
      debugPrint("Error Google Auth: $error");
      _mostrarAlerta("No se pudo conectar con Google.");
    }
  }

  Future<void> _handleFacebookSignIn() async {
    try {
      setState(() => _cargando = true);

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final res = await _usuarioService.loginConFacebook(accessToken.tokenString);
        
        final userData = await FacebookAuth.instance.getUserData();
        _procesarRespuestaServicio(res, userData['email'] ?? "");
      } else {
        setState(() => _cargando = false);
        if (result.status != LoginStatus.cancelled) {
          _mostrarAlerta("Error de conexión con Facebook.");
        }
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
      _mostrarAlerta("No se pudo iniciar sesión con Facebook");
    }
  }

  Future<void> _hacerLogin() async {
    final String userText = _usuarioController.text.trim();
    final String passText = _passController.text;

    if (userText.isEmpty || passText.isEmpty) {
      _mostrarAlerta("Ingrese usuario y contraseña");
      return;
    }

    setState(() => _cargando = true);

    try {
      final res = await _usuarioService.login(userText, passText);
      _procesarRespuestaServicio(res, "");
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
      _mostrarAlerta("Error de conexión con el servidor");
    }
  }

  void _irAlCatalogo(dynamic usuarioData) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CatalogoPalmito(
            usuarioActual: usuarioData,
            mfaActivo: usuarioData['mfa_activado'] ?? false,
            tienePreguntas: usuarioData['preguntas_configuradas'] ?? false,
          ),
        ),
      );
    }
  }

  void _mostrarAlerta(String msg, {bool esError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat()),
        backgroundColor: esError ? rojoError : verdeBosque,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: fondoCrema,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Image.asset('assets/img/LOGOV2.png', height: 130, 
                    errorBuilder: (c, e, s) => Icon(Icons.eco, size: 80, color: verdeBosque)),
                  const SizedBox(height: 15),
                  Text("Palmito NM", 
                    style: GoogleFonts.lora(fontSize: 34, fontWeight: FontWeight.bold, color: verdeBosque)),
                  const SizedBox(height: 40),
                  
                  // Campo Usuario
                  _buildField(_usuarioController, "Usuario", Icons.person_outline),
                  const SizedBox(height: 15),
                  
                  // Campo Contraseña con Botón de Ojo
                  _buildField(
                    _passController, 
                    "Contraseña", 
                    Icons.lock_outline, 
                    isPassword: true
                  ),
                  
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, 
                        MaterialPageRoute(builder: (context) => const OpcionesRecuperacionScreen())),
                      child: Text("¿Olvidó sus credenciales?", 
                        style: GoogleFonts.montserrat(color: rojoError, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildButton("CONTINUAR", verdeBosque, Colors.white, _hacerLogin, cargando: _cargando),
                  const SizedBox(height: 30),
                  _buildDivider(),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton('assets/img/google_logo.png', Icons.g_mobiledata, _handleGoogleSignIn),
                      const SizedBox(width: 25),
                      _buildSocialButton('assets/img/facebook_logo.png', Icons.facebook, _handleFacebookSignIn, isFacebook: true),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildButton("CREAR CUENTA", lavandaFondoBtn, lavandaTextoBtn, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificarCorreo()));
                  }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: Colors.black12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text("O ingresa con", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black45)),
        ),
        const Expanded(child: Divider(thickness: 1, color: Colors.black12)),
      ],
    );
  }

  // --- WIDGET DE CAMPO DE TEXTO ACTUALIZADO ---
  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: TextField(
        controller: controller,
        // Si es password, controla la visibilidad con el booleano
        obscureText: isPassword ? !_mostrarPass : false,
        style: GoogleFonts.montserrat(fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: verdeBosque, size: 22),
          // --- AQUÍ ESTÁ EL BOTÓN DEL OJO ---
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  _mostrarPass ? Icons.visibility : Icons.visibility_off,
                  color: verdeBosque.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _mostrarPass = !_mostrarPass;
                  });
                },
              )
            : null,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, Color textColor, VoidCallback action, {bool cargando = false}) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, 
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        onPressed: cargando ? null : action,
        child: cargando 
          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: textColor, strokeWidth: 2)) 
          : Text(text, style: GoogleFonts.montserrat(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSocialButton(String assetPath, IconData icon, VoidCallback action, {bool isFacebook = false}) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Image.asset(assetPath, height: 32, width: 32, 
          errorBuilder: (context, error, stackTrace) => Icon(icon, color: isFacebook ? Colors.blue : Colors.red, size: 32)),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'editar_perfil.dart';      
import 'acerca_screen.dart';      
import 'configurar_mfa_screen.dart'; 
import 'preguntas_seguridad_screen.dart'; 
import 'login.dart';

class AjustesScreen extends StatefulWidget {
  final Map<String, dynamic> usuarioActual;
  const AjustesScreen({super.key, required this.usuarioActual});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  // Colores del tema Palmito NM
  final Color verdeBosque = const Color(0xFF3B4D28);
  final Color cremaFondo = const Color(0xFFF2E8D5);
  final Color oroMuted = const Color(0xFFC5A358);
  final Color rojoElegante = const Color(0xFF9E2A2B);

  late Map<String, dynamic> _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuarioActual;
  }

  @override
  Widget build(BuildContext context) {
    // Lógica para extraer datos sin importar si vienen como 'Nombre' o 'nombre'
    final String nombreUser = (_usuario['nombre'] ?? _usuario['Nombre'] ?? "USUARIO").toString();
    final String correoUser = (_usuario['correo'] ?? _usuario['Correo'] ?? "correo@palmito.com").toString();

    return Scaffold(
      backgroundColor: cremaFondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: verdeBosque, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("MI CUENTA", 
          style: GoogleFonts.montserrat(
            color: verdeBosque, 
            fontWeight: FontWeight.bold, 
            fontSize: 13, 
            letterSpacing: 2
          )
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeaderMinimalPremium(nombreUser, correoUser),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                children: [
                  _buildAjusteCard(context, "Datos Personales", Icons.person_outline_rounded, verdeBosque, () async {
                    // Esperamos el resultado al volver de editar perfil
                    final resultado = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => EditarPerfilScreen(usuarioActual: _usuario))
                    );
                    if (resultado != null && resultado is Map<String, dynamic>) {
                      setState(() {
                        _usuario = resultado;
                      });
                    }
                  }),
                  _buildAjusteCard(context, "Seguridad 2FA", Icons.lock_person_outlined, verdeBosque, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ConfigurarMFAScreen(usuarioActual: _usuario)));
                  }),
                  _buildAjusteCard(context, "Recuperación", Icons.shield_outlined, verdeBosque, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PreguntasSeguridadScreen(usuarioActual: _usuario)));
                  }),
                  _buildAjusteCard(context, "Acerca de", Icons.info_outline_rounded, verdeBosque, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AcercaDeScreen()));
                  }),
                  _buildAjusteCard(context, "Cerrar Sesión", Icons.power_settings_new_rounded, rojoElegante, () => _confirmarCierreSesion(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMinimalPremium(String nombre, String correo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            verdeBosque.withOpacity(0.06),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: oroMuted, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/img/LOGOV2.png',
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => CircleAvatar(
                  radius: 37,
                  backgroundColor: verdeBosque.withOpacity(0.1),
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : "?",
                    style: TextStyle(color: verdeBosque, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            nombre.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: verdeBosque,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: verdeBosque.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              correo,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: verdeBosque.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAjusteCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                title, 
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: color == rojoElegante ? rojoElegante : verdeBosque
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarCierreSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cremaFondo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("¿Cerrar Sesión?", 
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: verdeBosque)),
        content: Text("¿Estás seguro de que deseas salir de tu cuenta?", 
          style: GoogleFonts.montserrat(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("CANCELAR", 
              style: GoogleFonts.montserrat(color: verdeBosque, fontWeight: FontWeight.bold))
          ),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (context) => const Login()), 
              (r) => false
            ), 
            child: Text("SÍ, SALIR", 
              style: GoogleFonts.montserrat(color: rojoElegante, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}
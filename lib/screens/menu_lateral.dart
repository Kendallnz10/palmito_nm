import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart'; 
import 'editar_perfil.dart'; 
import 'acerca_screen.dart'; 

class MenuLateral extends StatelessWidget {
  final Map<String, dynamic>? usuarioActual;

  const MenuLateral({super.key, this.usuarioActual});

  @override
  Widget build(BuildContext context) {
    final Color verdeBosque = const Color(0xFF3B4D28);
    final String nombreMostrar = usuarioActual?['Nombre'] ?? "MI PERFIL";

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: verdeBosque),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF3B4D28), size: 40),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      nombreMostrar.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 1. DATOS PERSONALES
            _itemMenu(
              context, 
              Icons.account_circle_outlined, 
              "Datos Personales", 
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditarPerfilScreen(
                      usuarioActual: usuarioActual ?? {
                        'ID_Usuario': 0,
                        'Usuario': '',
                        'Nombre': '',
                        'Apellido': '',
                        'Telefono': '',
                        'Correo': '',
                        'Direccion': '',
                      },
                    ),
                  ),
                );
              }
            ),

            
            // ACERCA DE 
            _itemMenu(
              context, 
              Icons.info_outline_rounded, 
              "Acerca de", 
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AcercaDeScreen()),
                );
              }
            ),
            
            const Spacer(), 
            
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(
                "Cerrar Sesión",
                style: GoogleFonts.montserrat(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _itemMenu(BuildContext context, IconData icono, String titulo, VoidCallback accion) {
    return ListTile(
      leading: Icon(icono, color: const Color(0xFF3B4D28)),
      title: Text(
        titulo,
        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context); 
        accion(); 
      },
    );
  }
}
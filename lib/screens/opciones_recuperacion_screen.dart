import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recuperar_cuenta_screen.dart'; 
import 'recuperar_password.dart';      

class OpcionesRecuperacionScreen extends StatelessWidget {
  const OpcionesRecuperacionScreen({super.key});


  final Color fondoLogoCrema = const Color(0xFFF2E8D5); 
  final Color verdeBosque = const Color(0xFF3B4D28);    
  final Color verdeSalvia = const Color(0xFF7D9452);    
  final Color cremaInput = const Color(0xFFF9F7F2);     

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoLogoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        foregroundColor: verdeBosque,
      ),
   
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 35.0),
        child: Column(
          children: [
     
            const SizedBox(height: 40), 

            // --- LOGO ---
            Image.asset(
              'assets/img/LOGOV2.png', 
              height: 140, 
              errorBuilder: (c, e, s) => Icon(Icons.lock_reset_rounded, size: 100, color: verdeBosque)
            ),
            const SizedBox(height: 8),
            
            Text(
              "Recuperación", 
              style: GoogleFonts.lora(fontSize: 34, fontWeight: FontWeight.bold, color: verdeBosque)
            ),
            const SizedBox(height: 10),
            
            Text(
              "Selecciona una opción para validar tu identidad.",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 45),

            // SOLO CONTRASEÑA 
            _buildOptionButton(
              context: context,
              icon: Icons.vpn_key_outlined,
              title: "Solo Contraseña",
              description: "Si recuerdas tu nombre de usuario.",
              color: verdeBosque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecuperarPassword()),
                );
              },
            ),

            const SizedBox(height: 20),

            // USUARIO Y CONTRASEÑA
            _buildOptionButton(
              context: context,
              icon: Icons.account_box_outlined,
              title: "Usuario y Contraseña",
              description: "Flujo de alta seguridad con MFA y preguntas.",
              color: verdeSalvia,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecuperarCuentaScreen()),
                );
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  
  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cremaInput,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: verdeBosque,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.montserrat(
                          fontSize: 12, 
                          color: Colors.black54
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
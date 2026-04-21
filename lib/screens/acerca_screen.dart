import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color verdeBosque = Color(0xFF3B4D28);
    const Color verdeSalvia = Color(0xFF7D9452);
    const Color fondoCrema = Color(0xFFF2E8D5);

    return Scaffold(
      backgroundColor: fondoCrema,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: verdeBosque),
        title: Text(
          "ACERCA DE",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: verdeBosque,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Center(
              child: Image.asset(
                'assets/img/LOGOV2.png',
                height: 120,
              ),
            ),
            const SizedBox(height: 30),
            _buildCardInformativa(
              titulo: "Nuestra Historia",
              contenido:
                  "Palmito NM nace de la pasión por los productos artesanales y naturales. Nos dedicamos a ofrecer la mejor calidad en palmito y productos derivados, apoyando siempre lo local y lo auténtico.",
              icono: Icons.history_edu,
              colorIcono: verdeSalvia,
            ),

            const SizedBox(height: 20),

            _buildCardInformativa(
              titulo: "Sobre la Aplicación",
              contenido:
                  "Esta app ha sido diseñada para acercar nuestros productos directamente a tu mesa. Aquí puedes explorar nuestro catálogo, gestionar tus pedidos y conocer más sobre nuestra cultura artesanal de forma rápida y segura.",
              icono: Icons.smartphone,
              colorIcono: verdeBosque,
            ),

            const SizedBox(height: 30),

            Text(
              "Versión 1.0.0",
              style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: verdeSalvia),
                const SizedBox(width: 5),
                Text(
                  "Costa Rica",
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: verdeBosque,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInformativa({
    required String titulo,
    required String contenido,
    required IconData icono,
    required Color colorIcono,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: colorIcono),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: GoogleFonts.lora(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF3B4D28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            contenido,
            textAlign: TextAlign.justify,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
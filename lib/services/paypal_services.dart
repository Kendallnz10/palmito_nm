import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaypalService {
  final String _baseUrl = "https://backend-palmitonm.onrender.com/paypal";

  Future<void> realizarPago({
    required BuildContext context,
    required double totalColones,
    required double tipoCambio,
    required List<dynamic> items,
    required Map<String, dynamic> usuarioActual,
    required Function(String comprobante) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      double totalUSD = totalColones / tipoCambio;

      final response = await http.post(
        Uri.parse("$_baseUrl/create-order"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "total": totalUSD.toStringAsFixed(2),
          // ← Le decimos a PayPal a dónde redirigir al terminar
          "return_url": "palmitonm://success",
          "cancel_url": "palmitonm://cancel",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String approvalUrl = data['links'].firstWhere(
          (link) => link['rel'] == 'approve',
        )['href'];

        final String orderID = data['id'];
        final Uri url = Uri.parse(approvalUrl);

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          onSuccess(orderID);
        } else {
          onError("No se pudo abrir PayPal.");
        }
      } else {
        onError("Servidor respondió con error: ${response.statusCode}");
      }
    } catch (e) {
      onError("Fallo de conexión: $e");
    }
  }

  Future<Map<String, dynamic>> capturarPago(String orderID) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/capture-order"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"orderID": orderID}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": "ERROR", "detalle": response.body};
      }
    } catch (e) {
      return {"status": "ERROR", "detalle": e.toString()};
    }
  }
}
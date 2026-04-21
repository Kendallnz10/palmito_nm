import 'producto.dart';

class CarritoItem {
  final Producto producto;
  int cantidad;

  CarritoItem({
    required this.producto,
    this.cantidad = 1,
  });

  // Cálculo dinámico del subtotal para la interfaz de la App
  double get subtotal => producto.precio * cantidad;

  factory CarritoItem.fromJson(Map<String, dynamic> json) {
    return CarritoItem(
      // Usamos el factory del modelo Producto para no repetir código
      // y asegurar que si cambias algo en Producto.dart, se aplique aquí también.
      producto: Producto.fromJson(json), 
      
      // La cantidad suele venir de la tabla 'carrito' o 'detalle_pedido'
      cantidad: json['cantidad'] ?? 1,
    );
  }
}
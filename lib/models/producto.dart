class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String imagen;
  final bool estado; // <--- CAMBIAR String por bool

  Producto({
    required this.id, 
    required this.nombre, 
    required this.descripcion,
    required this.precio, 
    required this.stock, 
    required this.imagen, 
    required this.estado,
  });

 factory Producto.fromJson(Map<String, dynamic> json) {
  return Producto(
    id: json['id'] ?? 0,
    nombre: json['nombre'] ?? 'Sin nombre',
    descripcion: json['descripcion'] ?? 'Sin descripción',
    precio: double.tryParse(json['precio'].toString()) ?? 0.0,
    stock: json['stock'] ?? 0,
    imagen: json['imagen'] ?? '',
    // En tu nueva tabla 'estado' es un VARCHAR, no un BOOLEAN
    estado: json['estado'] == 'Disponible', 
  );
}
}
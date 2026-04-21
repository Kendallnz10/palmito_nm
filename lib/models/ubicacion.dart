class Pais {
  final int id;
  final String nombre;

  Pais({required this.id, required this.nombre});

  factory Pais.fromJson(Map<String, dynamic> json) {
    return Pais(
      // Forzamos la búsqueda de llaves tanto en minúsculas como en Mayúsculas
      id: json['id_pais'] ?? json['ID_Pais'] ?? 0,
      nombre: json['nombre'] ?? json['Nombre'] ?? "País desconocido",
    );
  }
}

// Haz lo mismo para Provincia, Canton y Distrito (asegurando el id y nombre)
class Provincia {
  final int id;
  final String nombre;
  Provincia({required this.id, required this.nombre});
  factory Provincia.fromJson(Map<String, dynamic> json) => Provincia(
    id: json['id_provincia'] ?? json['ID_Provincia'] ?? 0,
    nombre: json['nombre'] ?? json['Nombre'] ?? "Provincia desconocida",
  );
}

class Canton {
  final int id;
  final String nombre;
  Canton({required this.id, required this.nombre});
  factory Canton.fromJson(Map<String, dynamic> json) => Canton(
    id: json['id_canton'] ?? json['ID_Canton'] ?? 0,
    nombre: json['nombre'] ?? json['Nombre'] ?? "Cantón desconocido",
  );
}

class Distrito {
  final int id;
  final String nombre;
  Distrito({required this.id, required this.nombre});
  factory Distrito.fromJson(Map<String, dynamic> json) => Distrito(
    id: json['id_distrito'] ?? json['ID_Distrito'] ?? 0,
    nombre: json['nombre'] ?? json['Nombre'] ?? "Distrito desconocido",
  );
}
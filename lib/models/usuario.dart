class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String? telefono;
  final String? direccion;
  final String cedula;
  final bool mfaActivado;
  final String? fotoPerfil;
  final int? idRol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    this.telefono,
    this.direccion,
    required this.cedula,
    required this.mfaActivado,
    this.fotoPerfil,
    this.idRol,
  });

  // El Factory es el que hace la magia de traducir el JSON a Flutter
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      // Soporta 'id_usuario' (Postgres) o 'ID' (SQL Server)
      id: json['id_usuario'] ?? json['id'] ?? 0,
      
      nombre: json['nombre'] ?? json['Nombre'] ?? 'Usuario',
      
      correo: json['correo'] ?? json['Correo'] ?? '',
      
      telefono: json['telefono'] ?? json['Telefono'],
      
      direccion: json['direccion'] ?? json['Direccion'],
      
      cedula: json['cedula'] ?? json['Cedula'] ?? '',
      
      // Maneja booleanos bit (0/1) o boolean de Postgres
      mfaActivado: json['mfa_activado'] == true || json['mfa_activado'] == 1 || json['MFA_Activado'] == 1,
      
      fotoPerfil: json['foto_perfil'] ?? json['Imagen'],
      
      idRol: json['id_rol'] ?? json['ID_Rol'],
    );
  }

  // Útil para enviar datos de vuelta al servidor en el body del JSON
  Map<String, dynamic> toJson() {
    return {
      'id_usuario': id,
      'nombre': nombre,
      'correo': correo,
      'telefono': telefono,
      'direccion': direccion,
      'cedula': cedula,
      'mfa_activado': mfaActivado,
    };
  }
}
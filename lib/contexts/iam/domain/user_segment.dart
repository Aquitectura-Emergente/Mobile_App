/// Experiencia que la app le da a la cuenta.
///
/// Las dos son cuentas CLIENT en el backend: el operario se distingue por su
/// membresía en Personal Dosimetry.
enum UserSegment {
  /// Cliente del hogar: sensores, enchufe, mapa e informes.
  home,

  /// Operario industrial: jornada, exposición y alertas de su dosímetro.
  operator;

  static UserSegment? fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// Ciclo de vida de uma ATA (gerada → indexada automaticamente no RAG).
///
/// Viaja na API como string em MAIÚSCULAS_COM_UNDERSCORE. Valores desconhecidos
/// caem em [AtaStatus.desconhecido] (tolerância a evolução do backend).
enum AtaStatus {
  gerada('GERADA', 'Gerada'),
  reprocessada('REPROCESSADA', 'Reprocessada'),
  cancelada('CANCELADA', 'Cancelada'),
  desconhecido('DESCONHECIDO', 'Desconhecido');

  const AtaStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AtaStatus fromApi(String? value) {
    if (value == null) return AtaStatus.desconhecido;
    return AtaStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => AtaStatus.desconhecido,
    );
  }
}

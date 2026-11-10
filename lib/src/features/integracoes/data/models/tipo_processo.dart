/// Natureza de um processo de integracao, espelhando `TipoProcessoIntegracao`
/// no backend.
enum TipoProcesso {
  delta('DELTA', 'Delta'),
  cargaCompleta('CARGA_COMPLETA', 'Carga completa'),
  sync('SYNC', 'Sincronização'),
  desconhecido('DESCONHECIDO', 'Outro');

  const TipoProcesso(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TipoProcesso fromApi(String? value) {
    if (value == null) return TipoProcesso.desconhecido;
    return TipoProcesso.values.firstWhere(
      (t) => t.apiValue == value,
      orElse: () => TipoProcesso.desconhecido,
    );
  }
}

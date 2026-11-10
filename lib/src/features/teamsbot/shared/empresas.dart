/// Empresas do Grupo José Alves usadas nos formulários/filtros do TeamsBot.
///
/// [outros] libera a digitação livre do nome (empresas fora da lista).
enum EmpresaOption {
  refrescosBandeirantes('REFRESCOS BANDEIRANTES'),
  vitamedic('VITAMEDIC'),
  trustfuel('TRUSTFUEL'),
  nlIndustria('N&L INDÚSTRIA'),
  rembal('REMBAL'),
  alfaEducacao('ALFA EDUCAÇÃO'),
  jlRealEstate('J&L REAL ESTATE'),
  tresTSystems('3T SYSTEMS'),
  outros('Outros');

  const EmpresaOption(this.label);

  /// Nome exibido e gravado (para [outros] o nome vem do campo de texto).
  final String label;

  bool get isOutros => this == EmpresaOption.outros;

  /// Opção cujo label casa com [valor] (case-insensitive), ou `null`.
  static EmpresaOption? fromLabel(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    final v = valor.trim().toUpperCase();
    for (final e in EmpresaOption.values) {
      if (!e.isOutros && e.label.toUpperCase() == v) return e;
    }
    return null;
  }
}

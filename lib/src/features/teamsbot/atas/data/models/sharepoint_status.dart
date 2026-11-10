/// Situação do envio do .docx da ATA ao SharePoint.
///
/// Viaja na API como string em MAIÚSCULAS_COM_UNDERSCORE. `null` na API =
/// ATA anterior à integração (nunca enviada) → [SharePointStatus.naoEnviada].
/// Valores desconhecidos caem em [SharePointStatus.desconhecido].
enum SharePointStatus {
  naoEnviada(null, 'Não enviada'),
  pendenteEnvio('PENDENTE_ENVIO', 'Enviando…'),
  enviada('ENVIADA', 'Enviada'),
  erroEnvio('ERRO_ENVIO', 'Erro no envio'),
  desconhecido('DESCONHECIDO', 'Desconhecido');

  const SharePointStatus(this.apiValue, this.label);

  /// `null` para [naoEnviada] (a coluna vem nula do backend).
  final String? apiValue;
  final String label;

  static SharePointStatus fromApi(String? value) {
    if (value == null || value.isEmpty) return SharePointStatus.naoEnviada;
    return SharePointStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => SharePointStatus.desconhecido,
    );
  }

  bool get isEnviando => this == SharePointStatus.pendenteEnvio;

  bool get isErro => this == SharePointStatus.erroEnvio;

  bool get isEnviada => this == SharePointStatus.enviada;

  /// `true` quando o (re)envio manual pode ser disparado — ou seja, quando NÃO
  /// há um envio automático já em andamento ([pendenteEnvio]).
  bool get podeEnviar => this != SharePointStatus.pendenteEnvio;
}

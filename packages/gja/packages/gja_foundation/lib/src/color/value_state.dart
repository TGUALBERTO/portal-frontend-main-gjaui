/// Estado semântico de valor, compartilhado por entradas e status.
///
/// Nível: semântico.
///
/// Cada estado tem cores próprias em `GjaColorTokens.stateColors`. A
/// mensagem associada (ex.: "Obrigatório") é responsabilidade do widget.
enum GjaValueState {
  /// Sem destaque semântico.
  none,

  /// Valor válido ou operação concluída.
  success,

  /// Valor aceito com ressalva.
  warning,

  /// Valor inválido ou operação com falha.
  error,

  /// Informação complementar, sem juízo de valor.
  information,
}

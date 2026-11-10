import 'package:equatable/equatable.dart';

/// Chamado sincronizado do GLPI, retornado por
/// `GET /chamados/search/buscar` (HAL / Spring Data REST) para o autocomplete
/// de apontamento. O `id` (UUID do portal) não vem no corpo — o Spring Data
/// REST só o expõe no link `self` — então é extraído do próprio link.
class Chamado extends Equatable {
  /// UUID do chamado no portal (usado no POST de apontamento).
  final String id;

  /// Id do ticket na origem (GLPI).
  final int origemId;

  final String titulo;
  final DateTime? dataCriacao;

  const Chamado({
    required this.id,
    required this.origemId,
    required this.titulo,
    this.dataCriacao,
  });

  factory Chamado.fromHal(Map<String, dynamic> json) {
    final dataCriacao = json['dataCriacao'];
    return Chamado(
      id: _idFromSelfLink(json),
      origemId: (json['origemId'] as num?)?.toInt() ?? 0,
      titulo: (json['titulo'] as String?) ?? '',
      dataCriacao: dataCriacao is String ? DateTime.tryParse(dataCriacao) : null,
    );
  }

  /// `_links.self.href` termina em `/chamados/{uuid}`.
  static String _idFromSelfLink(Map<String, dynamic> json) {
    final links = json['_links'];
    if (links is! Map<String, dynamic>) return '';
    final self = links['self'];
    if (self is! Map<String, dynamic>) return '';
    final href = self['href'];
    if (href is! String || href.isEmpty) return '';
    final segments = Uri.parse(href).pathSegments;
    return segments.isEmpty ? '' : segments.last;
  }

  /// Rótulo exibido no autocomplete: `#4242 — Título`.
  String get label => '#$origemId — $titulo';

  @override
  List<Object?> get props => [id, origemId, titulo, dataCriacao];
}

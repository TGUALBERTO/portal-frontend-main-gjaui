import 'package:equatable/equatable.dart';

/// Estado da tarefa no GLPI (campo `state` do planejamento):
/// 0 = sem estado, 1 = a fazer, 2 = concluída.
enum TarefaEstado {
  nenhum(0),
  pendente(1),
  concluida(2);

  const TarefaEstado(this.api);

  /// Valor usado pelo backend.
  final int api;

  static TarefaEstado fromApi(int? value) => switch (value) {
        1 => TarefaEstado.pendente,
        2 => TarefaEstado.concluida,
        _ => TarefaEstado.nenhum,
      };

  /// Rótulo pt-BR; nulo para "sem estado" (não exibe badge).
  String? get label => switch (this) {
        TarefaEstado.pendente => 'Pendente',
        TarefaEstado.concluida => 'Concluída',
        TarefaEstado.nenhum => null,
      };
}

/// Apontamento de tarefa em chamado (GLPI `tickettasks`), retornado por
/// `GET /chamados-tarefas/search/findByUsersIdTechAndDateBetween` (HAL).
///
/// O `id` da tarefa não vem no corpo (o Spring Data REST oculta a `@Id` por
/// padrão); é extraído de `_links.self.href` (`.../chamados-tarefas/{id}`).
class Apontamento extends Equatable {
  /// Id da tarefa no GLPI (de `_links.self.href`).
  final int? id;

  /// Chamado (ticket) ao qual a tarefa pertence (`ticketsId`).
  final int? chamadoId;

  /// Momento do apontamento (horário local). Nulo em registros sem data.
  final DateTime? data;

  /// Usuário dono do apontamento (`usersId` = matrícula GLPI).
  final int? usuarioId;

  /// Descrição/conteúdo da tarefa.
  final String content;

  /// Tempo apontado, em segundos (GLPI `actiontime`).
  final int actiontime;

  final DateTime? beginDate;
  final DateTime? endDate;

  /// Estado da tarefa (GLPI `state`).
  final TarefaEstado estado;

  /// Tarefa privada (GLPI `is_private`, 0/1).
  final bool privado;

  const Apontamento({
    required this.id,
    required this.chamadoId,
    required this.data,
    required this.usuarioId,
    required this.content,
    required this.actiontime,
    required this.beginDate,
    required this.endDate,
    this.estado = TarefaEstado.nenhum,
    this.privado = false,
  });

  /// Duração apontada (a partir de [actiontime], em segundos).
  Duration get duration => Duration(seconds: actiontime);

  /// Início do apontamento: o GLPI grava `begin_date` nulo no que nasce pela
  /// API, então o horário útil é o `date`. Nulo só em registro sem data.
  DateTime? get inicio => beginDate ?? data;

  /// Fim do apontamento; sem `end_date`, reconstrói de início + [duration]
  /// (mesma regra do backend na edição).
  DateTime? get fim {
    if (endDate != null) return endDate;
    final ini = inicio;
    return ini?.add(duration);
  }

  static final RegExp _htmlTag = RegExp(r'<[^>]+>');
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _decimalEntity = RegExp(r'&#(\d+);');
  static final RegExp _hexEntity = RegExp(r'&#[xX]([0-9a-fA-F]+);');

  /// [content] sem HTML: o GLPI grava a tarefa como HTML *escapado*
  /// (`&#60;p&#62;Texto&#60;/p&#62;`). Decodifica entidades numéricas e
  /// nomeadas (o que revela as tags), remove as tags e colapsa espaços para
  /// exibição legível.
  String get contentPlain => content
      // Entidades numéricas primeiro: `&#60;p&#62;` → `<p>`.
      .replaceAllMapped(
          _decimalEntity, (m) => String.fromCharCode(int.parse(m[1]!)))
      .replaceAllMapped(_hexEntity,
          (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)))
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      // `&amp;` por último para não reativar outras entidades.
      .replaceAll('&amp;', '&')
      .replaceAll(_htmlTag, ' ')
      .replaceAll(_whitespace, ' ')
      .trim();

  factory Apontamento.fromJson(Map<String, dynamic> json) {
    return Apontamento(
      id: idFromLinks(json),
      chamadoId: (json['ticketsId'] as num?)?.toInt(),
      data: _parseDate(json['date']),
      usuarioId: (json['usersId'] as num?)?.toInt(),
      content: (json['content'] as String?) ?? '',
      actiontime: (json['actiontime'] as num?)?.toInt() ?? 0,
      beginDate: _parseDate(json['beginDate']),
      endDate: _parseDate(json['endDate']),
      estado: TarefaEstado.fromApi((json['state'] as num?)?.toInt()),
      privado: (json['isPrivate'] as num?)?.toInt() == 1,
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

  /// Extrai a `@Id` do recurso HAL: usa `id` do corpo se exposto, senão o
  /// último segmento numérico de `_links.self.href` (`.../{path}/{id}`).
  /// Tolera template URI (`{?projection}`), query string e barra final.
  static int? idFromLinks(Map<String, dynamic> json) {
    final direct = (json['id'] as num?)?.toInt();
    if (direct != null) return direct;
    final links = json['_links'];
    if (links is! Map<String, dynamic>) return null;
    final self = links['self'];
    if (self is! Map<String, dynamic>) return null;
    final href = self['href'] as String?;
    if (href == null) return null;
    // Remove template URI (`{...}`) e query string, e ignora segmentos vazios
    // (barra final), pegando o último segmento com conteúdo.
    final path = href.split('{').first.split('?').first;
    final segments = path.split('/').where((s) => s.isNotEmpty);
    if (segments.isEmpty) return null;
    return int.tryParse(segments.last);
  }

  @override
  List<Object?> get props => [
        id,
        chamadoId,
        data,
        usuarioId,
        content,
        actiontime,
        beginDate,
        endDate,
        estado,
        privado,
      ];
}

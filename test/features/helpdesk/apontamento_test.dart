import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';

Apontamento _com(String content) => Apontamento(
      id: 1,
      chamadoId: 100,
      data: DateTime(2026, 7, 9, 8),
      usuarioId: 5270,
      content: content,
      actiontime: 3600,
      beginDate: null,
      endDate: null,
    );

void main() {
  group('Apontamento.contentPlain', () {
    test('decodifica HTML escapado do GLPI (entidades numéricas)', () {
      // Formato real do backend: &#60;p&#62;Apontamento&#60;/p&#62;
      expect(
        _com('&#60;p&#62;Apontamento&#60;/p&#62;').contentPlain,
        'Apontamento',
      );
    });

    test('remove tags HTML diretas e colapsa espaços', () {
      expect(
        _com('<p>Deploy do  módulo</p><br><p>em produção</p>').contentPlain,
        'Deploy do módulo em produção',
      );
    });

    test('decodifica entidades nomeadas e hexadecimais', () {
      expect(_com('a&nbsp;b &amp; c&#x3C;d&#x3E;').contentPlain, 'a b & c');
      expect(_com('&quot;ok&quot; &#39;x&#39;').contentPlain, '"ok" \'x\'');
    });

    test('texto sem HTML passa intacto', () {
      expect(_com('Reunião de alinhamento').contentPlain,
          'Reunião de alinhamento');
    });

    test('conteúdo vazio vira string vazia', () {
      expect(_com('').contentPlain, '');
    });
  });

  group('TarefaEstado', () {
    test('fromApi mapeia os estados do GLPI', () {
      expect(TarefaEstado.fromApi(0), TarefaEstado.nenhum);
      expect(TarefaEstado.fromApi(1), TarefaEstado.pendente);
      expect(TarefaEstado.fromApi(2), TarefaEstado.concluida);
      expect(TarefaEstado.fromApi(null), TarefaEstado.nenhum);
      expect(TarefaEstado.fromApi(99), TarefaEstado.nenhum);
    });

    test('label pt-BR (nulo para sem estado)', () {
      expect(TarefaEstado.pendente.label, 'Pendente');
      expect(TarefaEstado.concluida.label, 'Concluída');
      expect(TarefaEstado.nenhum.label, isNull);
    });

    test('fromJson lê o campo state', () {
      final ap = Apontamento.fromJson(const {
        'ticketsId': 100,
        'date': '2026-07-09T08:00:00',
        'usersId': 5270,
        'content': 'x',
        'actiontime': 3600,
        'state': 2,
      });
      expect(ap.estado, TarefaEstado.concluida);
    });
  });

  group('Apontamento — período e privacidade (semeiam a edição)', () {
    test('fromJson lê isPrivate (0/1) como bool', () {
      Apontamento comPrivado(Object? valor) => Apontamento.fromJson({
            'ticketsId': 100,
            'date': '2026-07-09T08:00:00',
            'actiontime': 3600,
            'isPrivate': valor,
          });
      expect(comPrivado(1).privado, isTrue);
      expect(comPrivado(0).privado, isFalse);
      // Ausente (registro antigo) não pode virar "privado" por engano.
      expect(comPrivado(null).privado, isFalse);
    });

    test('sem begin/end, o período sai de date + actiontime', () {
      // É o caso de tudo que nasce pela API do GLPI: begin_date/end_date nulos.
      final ap = _com('x');
      expect(ap.inicio, DateTime(2026, 7, 9, 8));
      expect(ap.fim, DateTime(2026, 7, 9, 9));
    });

    test('com begin/end preenchidos, eles têm prioridade', () {
      final ap = Apontamento(
        id: 1,
        chamadoId: 100,
        data: DateTime(2026, 7, 9, 8),
        usuarioId: 5270,
        content: 'x',
        actiontime: 3600,
        beginDate: DateTime(2026, 7, 9, 14),
        endDate: DateTime(2026, 7, 9, 16, 30),
      );
      expect(ap.inicio, DateTime(2026, 7, 9, 14));
      expect(ap.fim, DateTime(2026, 7, 9, 16, 30));
    });

    test('sem data, não há período para editar', () {
      final ap = Apontamento.fromJson(const {'ticketsId': 100});
      expect(ap.inicio, isNull);
      expect(ap.fim, isNull);
    });
  });
}

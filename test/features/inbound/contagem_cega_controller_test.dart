import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_item.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_log_registro.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_header_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_nf_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_mensagem_tipo.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_resultado.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/controllers/contagem_cega_controller.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'fakes/fake_contagem_cega.dart';

/// Regras da conferência: acerto grava o item, erro consome tentativa e a
/// terceira divergência condena a NF-e inteira — tudo isso **só depois** de o
/// SAP aceitar a gravação.
void main() {
  late ContagemCegaController controller;
  late FakeContagemCegaRepository repository;

  /// `accesskey` da primeira nota do mock, usada para plantar histórico.
  const accesskeyNota1 = '52260450143483000151550020000077961000213831';

  ContagemCegaController novoController({FakeSapBackendResolver? backends}) =>
      ContagemCegaController(
        repository: repository,
        backends: backends ?? FakeSapBackendResolver(),
      );

  setUp(() async {
    repository = FakeContagemCegaRepository();
    controller = novoController();
    await controller.carregarCheckin('3');
  });

  tearDown(() => controller.dispose());

  /// Grava uma contagem no item aberto.
  Future<ContagemResultado> contar({
    required String lote,
    required String qtd,
  }) {
    controller.loteController.text = lote;
    controller.quantidadeController.text = qtd;
    return controller.confirmarContagem();
  }

  test('carrega as notas do check-in', () {
    expect(controller.checkinSignal.value, '3');
    expect(controller.notasSignal.value, hasLength(2));
    expect(controller.notasSignal.value.first.numero, '021.383');
  });

  test('check-in sem dígito não abre sessão', () async {
    final vazio = novoController();
    addTearDown(vazio.dispose);

    expect(await vazio.carregarCheckin('abc'), isFalse);
    expect(vazio.checkinSignal.value, isNull);
  });

  test('a chave vai zero-padded em 10 para o SAP', () {
    // NUMC(10): `INCheckin('3')` devolve 404; a key precisa do valor completo.
    expect(repository.checkinsRecebidos, ['0000000003']);
    // Mas a tela mostra só os dígitos.
    expect(controller.checkinSignal.value, '3');
  });

  test('status que não permite contagem bloqueia e não inicia entrega', () async {
    repository = FakeContagemCegaRepository(status: CheckinStatus.realizado);
    final bloqueado = novoController();
    addTearDown(bloqueado.dispose);

    expect(await bloqueado.carregarCheckin('3'), isFalse);
    expect(bloqueado.erroSignal.value, isA<ValidationFailure>());
    expect(repository.iniciarEntregaCalls, 0);
    // A tela ainda precisa de motorista e placa para explicar o bloqueio.
    expect(bloqueado.checkinInfoSignal.value?.placa, 'ABC1D23');
  });

  test("status 'E' retoma a contagem sem reescrever o status", () async {
    // Coletor caiu no meio da conferência: o check-in ficou em 'E' e precisa
    // poder ser reaberto, senão o caminhão trava na doca.
    repository = FakeContagemCegaRepository(status: CheckinStatus.emEntrega);
    final retomado = novoController();
    addTearDown(retomado.dispose);

    expect(await retomado.carregarCheckin('3'), isTrue);
    expect(repository.jaIniciadoRecebido, [true]);
  });

  test("status 'L' inicia a entrega", () {
    expect(repository.iniciarEntregaCalls, 1);
    expect(repository.jaIniciadoRecebido, [false]);
  });

  test('falha na leitura propaga o AppFailure para a tela', () async {
    repository = FakeContagemCegaRepository(
      falha: const ServerFailure('SAP fora do ar'),
    );
    final comFalha = novoController();
    addTearDown(comFalha.dispose);

    expect(await comFalha.carregarCheckin('3'), isFalse);
    expect(comFalha.erroSignal.value?.message, 'SAP fora do ar');
    expect(repository.iniciarEntregaCalls, 0);
  });

  test('falha ao iniciar a entrega não abre a conferência', () async {
    repository = FakeContagemCegaRepository(
      falhaIniciarEntrega: const ServerFailure('CSRF inválido'),
    );
    final comFalha = novoController();
    addTearDown(comFalha.dispose);

    expect(await comFalha.carregarCheckin('3'), isFalse);
    expect(comFalha.erroSignal.value?.message, 'CSRF inválido');
    // Não pode ter aberto a sessão de conferência pela metade.
    expect(comFalha.notasSignal.value, isEmpty);
  });

  test('empresa sem SAP mapeado bloqueia a tela', () async {
    final semBackend = novoController(
      backends: FakeSapBackendResolver(null),
    );
    addTearDown(semBackend.dispose);

    expect(await semBackend.carregarCheckin('3'), isFalse);
    expect(semBackend.configErrorSignal.value, contains('Empresa de Teste'));
    expect(semBackend.erroSignal.value, isNull);
  });

  test('lancamentos projetam a conferência com as chaves do SAP', () async {
    controller.abrirItem(0);
    await contar(lote: 'C2212026', qtd: '2');

    final lancamento = controller.lancamentos.first;
    expect(lancamento.checkin, '0000000003');
    expect(lancamento.chave, 'AUT0000000000000001');
    expect(lancamento.accesskey, hasLength(44));
    expect(lancamento.item, '00010');
    expect(lancamento.lote, 'C2212026');
    expect(lancamento.quantidadeContada, 2);
    expect(lancamento.loteLido, 'C2212026');
    expect(lancamento.status, ContagemItemStatus.ok);

    // Uma linha por (item, lote) de todas as notas.
    expect(controller.lancamentos, hasLength(6));
    expect(controller.lancamentos.where((l) => l.vazio), hasLength(5));
  });

  group('abrirNota', () {
    test('garante o cabeçalho ANTES de ler o histórico', () async {
      repository.chamadas.clear();

      expect(await controller.abrirNota(0), isTrue);

      // A ordem importa: se o serviço tiver integridade referencial
      // Header→Log, ler antes de criar devolveria vazio ou erro.
      expect(repository.chamadas, ['cabecalho', 'historico']);
      // O cabeçalho leva o check-in que está sendo contado, zero-padded.
      expect(repository.checkinsGravados, ['0000000003']);
    });

    test('falha no cabeçalho não deixa entrar na nota', () async {
      repository.falhaCabecalho = const ServerFailure('chave duplicada');
      final antes = controller.notasSignal.value;

      expect(await controller.abrirNota(1), isFalse);

      expect(controller.erroSapSignal.value?.message, 'chave duplicada');
      // Nem o índice nem as notas podem ter mudado — a tela não navegou.
      expect(controller.notaIndex, 0);
      expect(controller.notasSignal.value, same(antes));
      // E o histórico nem chegou a ser pedido.
      expect(repository.chamadas, isNot(contains('historico')));
    });

    test('falha no histórico não deixa entrar na nota', () async {
      repository.falhaHistorico = const ServerFailure('timeout');

      expect(await controller.abrirNota(1), isFalse);

      expect(controller.erroSapSignal.value?.message, 'timeout');
      expect(controller.notaIndex, 0);
    });

    test('reidrata a nota com o que já foi contado no SAP', () async {
      // Coletor caiu depois de uma contagem certa no item 00010/C2212026 (a
      // NF pede 2) e de uma divergente no 00020 (a NF pede 3).
      repository.historico = {
        accesskeyNota1: const [
          ContagemLogRegistro(
            item: '00010',
            lote: 'C2212026',
            contagem: 1,
            quantidade: 2,
            loteLido: 'C2212026',
          ),
          ContagemLogRegistro(
            item: '00020',
            lote: '',
            contagem: 1,
            quantidade: 9,
          ),
        ],
      };

      expect(await controller.abrirNota(0), isTrue);

      final itens = controller.notasSignal.value.first.itens;
      expect(itens[0].status, ContagemItemStatus.ok);
      expect(itens[0].quantidadeContada, 2);
      expect(itens[1].status, ContagemItemStatus.pendente);
      expect(itens[1].tentativas, 1);
      // Sem contagem gravada, o item continua intocado.
      expect(itens[2].tentativas, 0);
    });

    test('sem backend SAP bloqueia com erro de configuração', () async {
      // Empresa trocada no meio da sessão (ou vínculo perdido): as notas já
      // estão carregadas, mas não há mais para onde gravar.
      final backends = FakeSapBackendResolver();
      final semBackend = novoController(backends: backends);
      addTearDown(semBackend.dispose);
      await semBackend.carregarCheckin('3');
      repository.chamadas.clear();
      backends.backend = null;

      expect(await semBackend.abrirNota(0), isFalse);

      expect(semBackend.configErrorSignal.value, contains('Empresa de Teste'));
      // Erro de configuração não é falha de rede — nada foi tentado.
      expect(semBackend.erroSapSignal.value, isNull);
      expect(repository.chamadas, isEmpty);
    });

    test('índice fora da faixa não chama o SAP', () async {
      repository.chamadas.clear();

      expect(await controller.abrirNota(99), isFalse);

      expect(repository.chamadas, isEmpty);
    });

    test('o loading desliga também no caminho de falha', () async {
      repository.falhaCabecalho = const ServerFailure('SAP fora');

      await controller.abrirNota(1);

      // Sem o `finally`, a lista de notas ficaria bloqueada para sempre.
      expect(controller.abrindoNotaSignal.value, isFalse);
    });
  });

  group('sincronizarRota', () {
    test('não dispara signal nenhum — roda durante o build', () {
      // Regressão: `_notaIndex`/`_itemIndex` já foram signals e as telas os
      // escreviam no `initState`. Como `initState` roda DURANTE o build, o
      // signal fazia um SignalBuilder já montado pedir rebuild no meio do
      // build e o app quebrava com SignalEffectException ao abrir a lista de
      // itens. Índice de navegação não pode notificar.
      var disparos = 0;
      final dispose = effect(() {
        // Exatamente o que o SignalBuilder de ItensNotaScreen e
        // ContagemItemScreen lê. `notaAtual`/`itemAtual` eram Computed sobre o
        // índice: sob o desenho antigo este effect dispararia aqui.
        controller.notaAtual;
        controller.itemAtual;
        controller.mensagemSignal.value;
        controller.checkinSignal.value;
        disparos++;
      });
      addTearDown(dispose);

      expect(disparos, 1, reason: 'execução inicial do effect');

      controller.sincronizarRota(nota: 1, item: 1);

      expect(
        disparos,
        1,
        reason: 'sincronizarRota notificou um signal e quebraria o build',
      );
    });

    test('move a nota e o item abertos', () {
      controller.sincronizarRota(nota: 1);
      expect(controller.notaIndex, 1);
      expect(controller.notaAtual?.numero, '019.847');

      controller.sincronizarRota(item: 1);
      expect(controller.itemIndex, 1);
      expect(controller.itemAtual?.materialSap, '6003310');
    });

    test('índice fora da faixa devolve null em vez de estourar', () {
      controller.sincronizarRota(nota: 99, item: 99);
      expect(controller.notaAtual, isNull);
      expect(controller.itemAtual, isNull);
    });

    test('preserva a mensagem — quem limpa é o handler de toque', () async {
      controller.abrirItem(0);
      await contar(lote: 'C2212026', qtd: '2');
      expect(controller.mensagemSignal.value, isNotNull);

      controller.sincronizarRota(nota: 0, item: 0);

      // A faixa de "item conferido" precisa sobreviver à navegação de volta
      // para a lista — é o retorno da contagem que o conferente acabou de fazer.
      expect(controller.mensagemSignal.value, isNotNull);
    });
  });

  test('lote ou quantidade em branco não grava nada', () async {
    controller.abrirItem(0);

    expect(await contar(lote: '', qtd: '2'), ContagemResultado.invalido);
    expect(await contar(lote: 'C2212026', qtd: ''), ContagemResultado.invalido);
    expect(controller.itemAtual?.status, ContagemItemStatus.pendente);
    expect(controller.itemAtual?.tentativas, 0);
    // Validação local acontece antes de qualquer rede.
    expect(repository.contagensGravadas, isEmpty);
  });

  test('quantidade correta confere o item e registra o lote lido', () async {
    controller.abrirItem(0);

    expect(
      await contar(lote: 'C2212026', qtd: '2'),
      ContagemResultado.conferido,
    );

    final item = controller.notasSignal.value.first.itens.first;
    expect(item.status, ContagemItemStatus.ok);
    expect(item.quantidadeContada, 2);
    expect(item.loteLido, 'C2212026');
    expect(
      controller.mensagemSignal.value?.tipo,
      ContagemMensagemTipo.sucesso,
    );
  });

  test('divergência consome tentativa e limpa só a quantidade', () async {
    controller.abrirItem(0);

    expect(await contar(lote: 'C2212026', qtd: '5'), ContagemResultado.reconte);

    expect(controller.itemAtual?.status, ContagemItemStatus.pendente);
    expect(controller.itemAtual?.tentativas, 1);
    // O lote permanece: o material é o mesmo, o que se reconta é a quantidade.
    expect(controller.loteController.text, 'C2212026');
    expect(controller.quantidadeController.text, isEmpty);
    expect(controller.tentativaLabel, '2/3');
  });

  test('terceira divergência condena a NF-e inteira', () async {
    controller.abrirItem(0);

    expect(await contar(lote: 'C2212026', qtd: '5'), ContagemResultado.reconte);
    expect(await contar(lote: 'C2212026', qtd: '5'), ContagemResultado.reconte);
    expect(
      await contar(lote: 'C2212026', qtd: '5'),
      ContagemResultado.divergenciaConfirmada,
    );

    final nota = controller.notasSignal.value.first;
    expect(nota.itens.first.status, ContagemItemStatus.divergente);
    expect(nota.status, ContagemNfStatus.devolver);
    // Os demais itens continuam pendentes, mas a tela os bloqueia.
    expect(controller.notaBloqueada, isTrue);
    expect(controller.temItemPendente, isFalse);
    expect(
      controller.mensagemSignal.value?.tipo,
      ContagemMensagemTipo.devolucao,
    );
  });

  test('nota fica OK só quando todos os itens conferem', () async {
    // A segunda nota tem dois itens: 10 PC e 6 UN.
    controller.selecionarNota(1);

    controller.abrirItem(0);
    await contar(lote: 'L240811', qtd: '10');
    expect(controller.notaAtual?.status, ContagemNfStatus.pendente);

    controller.abrirItem(1);
    await contar(lote: 'S/LOTE', qtd: '6');
    expect(controller.notaAtual?.status, ContagemNfStatus.ok);
  });

  test('finalizar só libera quando nenhuma nota está pendente', () async {
    expect(controller.todasResolvidasSignal.value, isFalse);

    // Nota 0: condena com três divergências.
    controller.selecionarNota(0);
    controller.abrirItem(0);
    await contar(lote: 'C2212026', qtd: '5');
    await contar(lote: 'C2212026', qtd: '5');
    await contar(lote: 'C2212026', qtd: '5');
    expect(controller.todasResolvidasSignal.value, isFalse);

    // Nota 1: confere os dois itens.
    controller.selecionarNota(1);
    controller.abrirItem(0);
    await contar(lote: 'L240811', qtd: '10');
    controller.abrirItem(1);
    await contar(lote: 'S/LOTE', qtd: '6');

    expect(controller.todasResolvidasSignal.value, isTrue);
    expect(
      controller.resumoFinalSignal.value,
      '1 NF(s) recebida(s) · 1 NF(s) para devolução ao fornecedor',
    );

    expect(await controller.finalizar(), isTrue);
    expect(controller.finalizadoSignal.value, isTrue);

    // Uma nota condenada basta para o caminhão inteiro fechar como devolução.
    expect(repository.finalizacoes, [
      {'checkin': '0000000003', 'comDevolucao': true},
    ]);
  });

  group('finalizar o check-in', () {
    /// Confere as duas notas do mock inteiras, sem nenhuma divergência — a
    /// primeira tem quatro itens (o 00030 aparece sob dois lotes), a segunda,
    /// dois.
    Future<void> conferirTudo() async {
      const quantidades = [
        (0, ['2', '3', '4', '4']),
        (1, ['10', '6']),
      ];

      for (final (indiceNota, qtds) in quantidades) {
        controller.selecionarNota(indiceNota);
        for (var i = 0; i < qtds.length; i++) {
          controller.abrirItem(i);
          // O lote já vem preenchido da NF-e por `abrirItem`; contar com ele é o
          // caminho real do conferente.
          await contar(lote: controller.loteController.text, qtd: qtds[i]);
        }
      }
    }

    test('tudo conferido fecha o cabeçalho sem devolução', () async {
      await conferirTudo();

      expect(await controller.finalizar(), isTrue);
      expect(controller.finalizadoSignal.value, isTrue);
      expect(repository.finalizacoes, [
        {'checkin': '0000000003', 'comDevolucao': false},
      ]);
    });

    test('nota pendente não chega a chamar o SAP', () async {
      // Só o primeiro item da primeira nota.
      controller.abrirItem(0);
      await contar(lote: 'C2212026', qtd: '2');

      expect(controller.todasResolvidasSignal.value, isFalse);
      expect(await controller.finalizar(), isFalse);
      expect(controller.finalizadoSignal.value, isFalse);
      expect(repository.finalizacoes, isEmpty);
    });

    test('falha no MERGE não finaliza a sessão', () async {
      await conferirTudo();
      repository.falhaFinalizacao = const ServerFailure('SAP fora do ar');

      expect(await controller.finalizar(), isFalse);

      // A sessão continua aberta: o painel de "finalizado" não tem volta, e
      // trocá-lo com o SAP ainda em 'E' deixaria o check-in aberto para sempre.
      expect(controller.finalizadoSignal.value, isFalse);
      expect(controller.erroSapSignal.value?.message, 'SAP fora do ar');
      expect(controller.gravandoSignal.value, isFalse);

      // O botão é o retry: a segunda tentativa fecha.
      repository.falhaFinalizacao = null;
      expect(await controller.finalizar(), isTrue);
      expect(controller.finalizadoSignal.value, isTrue);
    });

    test('duplo toque fecha uma vez só', () async {
      await conferirTudo();

      final primeiro = controller.finalizar();
      final segundo = controller.finalizar();

      expect(await primeiro, isTrue);
      expect(await segundo, isFalse);
      expect(repository.finalizacoes, hasLength(1));
    });

    /// Abre um check-in cujo `INCContagemACegaHeader` já está fechado no SAP —
    /// outro coletor finalizou, ou esta sessão finalizou e o coletor caiu antes
    /// de a tela trocar pelo painel.
    Future<ContagemCegaController> comCabecalhoFinalizado(
      ContagemHeaderStatus status,
    ) async {
      repository.statusContagem = status;
      final outro = novoController();
      addTearDown(outro.dispose);
      await outro.carregarCheckin('3');
      return outro;
    }

    for (final status in [
      ContagemHeaderStatus.finalizadoConforme,
      ContagemHeaderStatus.finalizadoDivergente,
    ]) {
      test('cabeçalho em ${status.name} não deixa finalizar de novo', () async {
        final outro = await comCabecalhoFinalizado(status);

        expect(outro.checkinJaFinalizadoSignal.value, isTrue);
        expect(outro.situacaoContagem, isNotEmpty);

        // Sem o gate, a guarda de "todas resolvidas" seria a única, e um
        // check-in que o SAP já fechou passaria por ela assim que a conferência
        // local completasse.
        expect(await outro.finalizar(), isFalse);
        expect(outro.finalizadoSignal.value, isFalse);
        expect(repository.finalizacoes, isEmpty);
      });
    }

    test('cabeçalho aberto ou ausente não bloqueia', () async {
      for (final status in [
        ContagemHeaderStatus.inexistente,
        ContagemHeaderStatus.aberto,
        // Status que o app não conhece NÃO bloqueia: travar a doca por causa de
        // uma letra nova do SAP é pior que deixar finalizar.
        ContagemHeaderStatus.desconhecido,
      ]) {
        final outro = await comCabecalhoFinalizado(status);
        expect(
          outro.checkinJaFinalizadoSignal.value,
          isFalse,
          reason: status.name,
        );
      }
    });

    test('reiniciar limpa o bloqueio do check-in anterior', () async {
      final outro = await comCabecalhoFinalizado(
        ContagemHeaderStatus.finalizadoDivergente,
      );
      expect(outro.checkinJaFinalizadoSignal.value, isTrue);

      // O próximo caminhão não herda o fecho do anterior.
      outro.reiniciar();
      expect(outro.checkinJaFinalizadoSignal.value, isFalse);
    });
  });

  test('abrir item traz o lote da NF e zera a quantidade', () {
    controller.abrirItem(0);
    expect(controller.loteController.text, 'C2212026');

    controller.loteController.text = 'CORRIGIDO-NA-ETIQUETA';
    controller.quantidadeController.text = '9';

    // Trocar de item não arrasta o que foi digitado no anterior: o lote passa a
    // ser o da linha aberta (o item 1 do mock não tem lote na NF) e a
    // quantidade sempre volta do zero — é ela que é contada às cegas.
    controller.abrirItem(1);

    expect(controller.loteController.text, 'S/LOTE');
    expect(controller.quantidadeController.text, isEmpty);
  });

  test('escanear lote preenche com o lote da NF (ou S/LOTE)', () {
    controller.abrirItem(0);
    controller.aplicarLoteLido();
    expect(controller.loteController.text, 'C2212026');

    // Item 1 do mock não tem lote na nota.
    controller.abrirItem(1);
    controller.aplicarLoteLido();
    expect(controller.loteController.text, 'S/LOTE');
  });

  test('reiniciar zera a sessão para o próximo check-in', () async {
    controller.abrirItem(0);
    await contar(lote: 'C2212026', qtd: '2');
    await controller.finalizar();

    controller.reiniciar();

    expect(controller.checkinSignal.value, isNull);
    expect(controller.notasSignal.value, isEmpty);
    expect(controller.finalizadoSignal.value, isFalse);
    expect(controller.mensagemSignal.value, isNull);
    expect(controller.checkinController.text, isEmpty);
    expect(controller.erroSapSignal.value, isNull);
  });

  test('novo check-in começa com todos os itens pendentes', () async {
    controller.abrirItem(0);
    await contar(lote: 'C2212026', qtd: '2');

    controller.reiniciar();
    await controller.carregarCheckin('7');

    final pendentes = controller.notasSignal.value
        .expand((n) => n.itens)
        .every((i) => i.status == ContagemItemStatus.pendente);
    expect(pendentes, isTrue);
  });

  group('gravação no SAP', () {
    test('manda as chaves do SAP, o lote da NF e o lote lido', () async {
      controller.abrirItem(0);

      await contar(lote: 'C2212099', qtd: '2');

      final gravada = repository.contagensGravadas.single;
      // NUMC(10): o mesmo formato que a leitura do check-in usa na key.
      expect(gravada['checkin'], '0000000003');
      expect(gravada['chave'], 'AUT0000000000000001');
      expect(gravada['accesskey'], accesskeyNota1);
      // Literal zero-padded, como o SAP devolveu na leitura.
      expect(gravada['item'], '00010');
      // Identidade da linha é o lote da NF...
      expect(gravada['lote'], 'C2212026');
      // ...e o que o conferente digitou vai como rastro, mesmo divergindo.
      expect(gravada['loteLido'], 'C2212099');
      expect(gravada['quantidade'], 2);
      expect(gravada['matricula'], '28109');
    });

    test('falha na gravação não consome tentativa nem marca o item', () async {
      repository.falhaRegistro = const ServerFailure('SAP recusou');
      controller.abrirItem(0);

      expect(
        await contar(lote: 'C2212026', qtd: '5'),
        ContagemResultado.falhaGravacao,
      );

      // Uma contagem que não chegou ao SAP não aconteceu.
      expect(controller.itemAtual?.status, ContagemItemStatus.pendente);
      expect(controller.itemAtual?.tentativas, 0);
      // O campo não é limpo: o conferente só toca "Confirmar" de novo.
      expect(controller.quantidadeController.text, '5');
      expect(controller.mensagemSignal.value?.tipo, ContagemMensagemTipo.erro);
      expect(controller.erroSapSignal.value?.message, 'SAP recusou');
    });

    test('usuário sem matrícula não chega a chamar o SAP', () async {
      // Backend válido, matrícula ausente — é o caso que se quer isolar.
      final semMatricula = novoController(
        backends: FakeSapBackendResolver()..matricula = null,
      );
      addTearDown(semMatricula.dispose);
      await semMatricula.carregarCheckin('3');
      semMatricula.abrirItem(0);
      semMatricula.loteController.text = 'C2212026';
      semMatricula.quantidadeController.text = '2';

      expect(
        await semMatricula.confirmarContagem(),
        ContagemResultado.falhaGravacao,
      );

      // Registro de auditoria sem autor é pior que a tela travada.
      expect(repository.contagensGravadas, isEmpty);
      expect(semMatricula.erroSapSignal.value, isA<ValidationFailure>());
    });

    test('duplo toque grava uma vez só', () async {
      // O leitor físico do coletor manda o Enter e não é raro mandar duas
      // vezes — contagem dobrada é o desfecho que este guard evita.
      final bloqueio = Completer<void>();
      repository.bloqueioRegistro = bloqueio;
      controller.abrirItem(0);
      controller.loteController.text = 'C2212026';
      controller.quantidadeController.text = '2';

      final primeira = controller.confirmarContagem();
      final segunda = await controller.confirmarContagem();

      expect(segunda, ContagemResultado.invalido);
      bloqueio.complete();
      expect(await primeira, ContagemResultado.conferido);
      expect(repository.contagensGravadas, hasLength(1));
    });

    test('o loading desliga também no caminho de falha', () async {
      repository.falhaRegistro = const ServerFailure('SAP recusou');
      controller.abrirItem(0);

      await contar(lote: 'C2212026', qtd: '2');

      // Sem o `finally`, o botão "Confirmar" ficaria travado para sempre.
      expect(controller.gravandoSignal.value, isFalse);
    });
  });

  group('quantidade decimal', () {
    /// Nota com material comprado em KG: a NF-e declara 2,5.
    const notaKg = ContagemNotaFiscal(
      chave: 'AUT0000000000000009',
      chaveAcesso: '52260450143483000151550020000077961000999999',
      numero: '000.999',
      fornecedor: 'QUIMICA LTDA',
      itens: [
        ContagemItem(
          itemXml: '00010',
          loteNf: 'Q1',
          pedidos: ['4501550000 / 00010'],
          quantidadeNf: 2.5,
          unidade: 'KG',
          materialSap: '6009001',
          descricaoSap: 'SODA CAUSTICA',
          materialXml: 'SC-25',
          descricaoXml: 'SODA CAUSTICA SACO 2,5KG',
        ),
      ],
    );

    late ContagemCegaController decimal;

    setUp(() async {
      repository = FakeContagemCegaRepository(notas: [notaKg]);
      decimal = novoController();
      await decimal.carregarCheckin('3');
      decimal.abrirItem(0);
    });

    tearDown(() => decimal.dispose());

    Future<ContagemResultado> contarKg(String qtd) {
      decimal.loteController.text = 'Q1';
      decimal.quantidadeController.text = qtd;
      return decimal.confirmarContagem();
    }

    test('2,5 com vírgula confere', () async {
      expect(await contarKg('2,5'), ContagemResultado.conferido);

      final item = decimal.notasSignal.value.single.itens.single;
      expect(item.status, ContagemItemStatus.ok);
      expect(item.quantidadeContada, closeTo(2.5, 1e-9));
      expect(item.quantidadeContadaLabel, '2,5 KG');
    });

    test('2.5 com ponto também confere', () async {
      // O teclado numérico do coletor mostra vírgula ou ponto conforme o
      // locale do Android; nenhum dos dois pode travar o conferente.
      expect(await contarKg('2.5'), ContagemResultado.conferido);
    });

    test('vai ao SAP com a fração, sem arredondar', () async {
      await contarKg('2,5');

      expect(repository.contagensGravadas.single['quantidade'], 2.5);
    });

    test('3 diverge de 2,5 — a contagem não é arredondada para bater',
        () async {
      expect(await contarKg('3'), ContagemResultado.reconte);
      expect(decimal.itemAtual?.tentativas, 1);
    });

    test('diferença na 4ª casa ainda é divergência', () async {
      // A tolerância é meia unidade da última casa que o SAP grava — serve
      // para absorver ruído de ponto flutuante, não para aceitar contagem
      // aproximada.
      expect(await contarKg('2,5001'), ContagemResultado.reconte);
    });

    test('só o separador não é quantidade', () async {
      expect(await contarKg(','), ContagemResultado.invalido);
      expect(repository.contagensGravadas, isEmpty);
    });
  });
}

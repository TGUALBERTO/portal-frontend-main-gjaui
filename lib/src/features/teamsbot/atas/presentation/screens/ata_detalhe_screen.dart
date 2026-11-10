import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/repositories/atas_repository.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/controllers/ata_detalhe_controller.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/widgets/ata_metadata_panel.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/widgets/reprocessar_dialog.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/widgets/status_badges.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/repositories/reunioes_repository.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/markdown_actions.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/markdown_view.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela 2 — Detalhe da ATA (`/teamsbot/atas/:id`).
///
/// Em telas largas o conteúdo da ATA é o foco (coluna principal) e as ações /
/// metadados ficam num painel lateral; em telas estreitas tudo empilha na
/// ordem: metadados → ações → conteúdo.
class AtaDetalheScreen extends StatefulWidget {
  const AtaDetalheScreen({super.key, required this.id});

  final int id;

  @override
  State<AtaDetalheScreen> createState() => _AtaDetalheScreenState();
}

class _AtaDetalheScreenState extends State<AtaDetalheScreen> {
  late final AtaDetalheController _controller;
  late final AccessController _access;

  /// Carregando a busca pela reunião vinculada (resolução do id numérico).
  bool _abrindoReuniao = false;

  @override
  void initState() {
    super.initState();
    _controller = AtaDetalheController(
      id: widget.id,
      repository: AppInjector.get<AtasRepository>(),
    );
    _access = AppInjector.get<AccessController>();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reprocessar() async {
    final ok = await showReprocessarDialog();
    if (ok ?? false) await _controller.reprocessar();
  }

  Future<void> _editar() async {
    await context.push(AppRoutes.teamsbotAtaEditorPath(widget.id));
    if (mounted) _controller.load();
  }

  /// Baixa a ATA em Word (.docx) no formato executivo (template GJA).
  Future<void> _baixar() async {
    final result = await AppInjector.get<AtasRepository>().docx(widget.id);
    result.onSuccess((bytes) {
      baixarWord(widget.id, bytes);
    }).onFailure((f) {
      showGlobalToast(message: f.message, status: 'error');
    });
  }

  Future<void> _copiar() async {
    final md = _controller.detalhe.value?.markdown ?? '';
    await Clipboard.setData(ClipboardData(text: md));
    showGlobalToast(message: 'Conteúdo copiado.', status: 'success');
  }

  /// Abre a reunião monitorada vinculada a esta ATA.
  ///
  /// A ATA carrega o `meetingId` do Teams (texto), mas a tela de reunião usa o
  /// id numérico interno. Resolvemos esse id buscando, entre as reuniões
  /// monitoradas, aquela cujo `ataId` é igual ao id desta ATA.
  Future<void> _verReuniao() async {
    final ata = _controller.detalhe.value;
    if (ata == null) return;

    setState(() => _abrindoReuniao = true);
    final result =
        await AppInjector.get<ReunioesRepository>().listarMonitoradas();
    if (!mounted) return;
    setState(() => _abrindoReuniao = false);

    result.onSuccess((lista) {
      int? meetingId;
      for (final m in lista) {
        if (m.ataId == ata.id) {
          meetingId = m.id;
          break;
        }
      }
      if (meetingId == null) {
        showGlobalToast(
          message: 'Não encontramos a reunião vinculada a esta ATA.',
          status: 'warning',
        );
      } else {
        context.push(AppRoutes.teamsbotReuniaoDetalhePath(meetingId));
      }
    }).onFailure((f) {
      showGlobalToast(message: f.message, status: 'error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'ATA #${widget.id}',
        actions: [
          SignalBuilder(builder: (context) {
            final ocupado = _controller.isLoading.value ||
                _controller.isMutating.value ||
                _controller.isPolling.value;
            if (ocupado) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return IconButton(
              tooltip: 'Atualizar',
              icon: const Icon(GjaIcons.refresh),
              onPressed: () => _controller.load(showLoading: false),
            );
          }),
        ],
      ),
      body: AppResponsiveContainer(
        child: SignalBuilder(builder: (context) {
          // Lê todos os signals reativos aqui dentro (escopo rastreado).
          final detalhe = _controller.detalhe.value;
          final isLoading = _controller.isLoading.value;
          final error = _controller.error.value;
          final isMutating = _controller.isMutating.value;
          final isPolling = _controller.isPolling.value;

          if (detalhe == null) {
            if (isLoading) return const AppLoading(message: 'Carregando ATA…');
            return AppErrorWidget(
              title: 'Não foi possível carregar a ATA',
              message: error?.message,
              onRetry: _controller.load,
            );
          }
          return _DetalheBody(
            detalhe: detalhe,
            isAdmin: _access.isAdminSignal.value,
            isMutating: isMutating,
            isPolling: isPolling,
            isAbrindoReuniao: _abrindoReuniao,
            onReprocessar: _reprocessar,
            onEditar: _editar,
            onReindexar: _controller.indexar,
            onBaixar: _baixar,
            onCopiar: _copiar,
            onVerReuniao: _verReuniao,
            onEnviarSharepoint: _controller.enviarSharepoint,
          );
        }),
      ),
    );
  }
}

class _DetalheBody extends StatelessWidget {
  const _DetalheBody({
    required this.detalhe,
    required this.isAdmin,
    required this.isMutating,
    required this.isPolling,
    required this.isAbrindoReuniao,
    required this.onReprocessar,
    required this.onEditar,
    required this.onReindexar,
    required this.onBaixar,
    required this.onCopiar,
    required this.onVerReuniao,
    required this.onEnviarSharepoint,
  });

  final AtaDetalhe detalhe;
  final bool isAdmin;
  final bool isMutating;
  final bool isPolling;
  final bool isAbrindoReuniao;
  final VoidCallback onReprocessar;
  final VoidCallback onEditar;
  final VoidCallback onReindexar;
  final VoidCallback onBaixar;
  final VoidCallback onCopiar;
  final VoidCallback onVerReuniao;
  final VoidCallback onEnviarSharepoint;

  @override
  Widget build(BuildContext context) {
    // Banners de estado (falha de reprocessamento, indexação).
    final banners = _Banners(detalhe: detalhe, isPolling: isPolling);

    final conteudo = _ConteudoCard(
      detalhe: detalhe,
      onCopiar: onCopiar,
      onBaixar: onBaixar,
    );

    final painelAcoes = _AcoesCard(
      detalhe: detalhe,
      isMutating: isMutating,
      isPolling: isPolling,
      isAbrindoReuniao: isAbrindoReuniao,
      onReprocessar: onReprocessar,
      onEditar: onEditar,
      onReindexar: onReindexar,
      onVerReuniao: onVerReuniao,
    );

    final sharepoint = _SharePointCard(
      detalhe: detalhe,
      isMutating: isMutating,
      onEnviar: onEnviarSharepoint,
    );

    final metadados = AtaMetadataPanel(detalhe: detalhe, isAdmin: isAdmin);

    // Layout empilhado em qualquer largura: metadados no topo da tela,
    // depois avisos, ações, SharePoint e o conteúdo da ATA.
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        metadados,
        SizedBox(height: AppSpacing.md),
        banners,
        painelAcoes,
        SizedBox(height: AppSpacing.md),
        sharepoint,
        SizedBox(height: AppSpacing.md),
        conteudo,
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Card de publicação no SharePoint: mostra o estado do envio do .docx e permite
/// disparar o (re)envio manual — inclusive o backfill de ATAs geradas antes da
/// integração ([SharePointStatus.naoEnviada]).
class _SharePointCard extends StatelessWidget {
  const _SharePointCard({
    required this.detalhe,
    required this.isMutating,
    required this.onEnviar,
  });

  final AtaDetalhe detalhe;
  final bool isMutating;
  final VoidCallback onEnviar;

  Future<void> _abrir(BuildContext context) async {
    final url = detalhe.sharepointWebUrl;
    if (url == null || url.isEmpty) return;
    final result = await UrlLauncherService.instance.launch(url);
    result.onFailure((f) {
      showGlobalToast(message: f.message, status: 'error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final sp = detalhe.sharepointStatus;
    final cancelada = detalhe.status == AtaStatus.cancelada;

    // Rótulo do botão: "Enviar" para o primeiro envio (backfill), "Reenviar"
    // quando já houve tentativa (enviada/erro).
    final label =
        sp == SharePointStatus.naoEnviada ? 'Enviar ao SharePoint' : 'Reenviar ao SharePoint';

    // Texto de apoio conforme o estado.
    final apoio = switch (sp) {
      SharePointStatus.naoEnviada =>
        'Esta ATA foi gerada antes da integração e ainda não está no SharePoint.',
      SharePointStatus.pendenteEnvio => 'Envio automático em andamento…',
      SharePointStatus.enviada => detalhe.sharepointEnviadoEm == null
          ? 'Arquivo publicado no SharePoint.'
          : 'Publicado em ${AtaFormat.dataHora(detalhe.sharepointEnviadoEm)}.',
      SharePointStatus.erroEnvio => 'O último envio falhou. Você pode tentar novamente.',
      SharePointStatus.desconhecido => null,
    };

    return AppCard(
      title: 'SharePoint',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Publicação (.docx): ',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
              SharePointStatusBadge(status: sp),
            ],
          ),
          if (apoio != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(apoio,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
          if (sp.isErro && detalhe.sharepointErro != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(detalhe.sharepointErro!,
                style: tt.bodySmall?.copyWith(color: cs.error)),
          ],
          SizedBox(height: AppSpacing.sm),
          if (cancelada)
            Text('ATA cancelada — envio ao SharePoint indisponível.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _AcaoButton(
                  label: sp.isEnviando ? 'Enviando…' : label,
                  icon: GjaIcons.uploadToCloud,
                  background: cs.primary,
                  foreground: cs.onPrimary,
                  // Bloqueia enquanto há mutação em curso ou envio automático
                  // em andamento (o backend responderia 409).
                  isLoading: isMutating || sp.isEnviando,
                  onPressed: onEnviar,
                ),
                if (sp.isEnviada && (detalhe.sharepointWebUrl?.isNotEmpty ?? false))
                  OutlinedButton.icon(
                    onPressed: () => _abrir(context),
                    icon: const Icon(GjaIcons.popupWindow, size: 18),
                    label: const Text('Abrir no SharePoint'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Empilha os banners de estado pertinentes (nada quando não há avisos).
class _Banners extends StatelessWidget {
  const _Banners({required this.detalhe, required this.isPolling});

  final AtaDetalhe detalhe;
  final bool isPolling;

  @override
  Widget build(BuildContext context) {
    final status = detalhe.status;
    final children = <Widget>[
      if (detalhe.erroProcessamento != null)
        _ErroProcessamento(
          erro: detalhe.erroProcessamento!,
          quando: detalhe.erroProcessamentoEm,
        ),
      if (status != AtaStatus.cancelada &&
          (isPolling ||
              detalhe.indexStatus.isTransitorio ||
              detalhe.indexStatus.isErro))
        _IndexacaoCard(
          indexStatus: detalhe.indexStatus,
          isPolling: isPolling,
        ),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in children) ...[c, SizedBox(height: AppSpacing.sm)],
      ],
    );
  }
}

/// Card principal com o conteúdo (Markdown renderizado) e ações rápidas.
class _ConteudoCard extends StatelessWidget {
  const _ConteudoCard({
    required this.detalhe,
    required this.onCopiar,
    required this.onBaixar,
  });

  final AtaDetalhe detalhe;
  final VoidCallback onCopiar;
  final VoidCallback onBaixar;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return AppCard(
      title: 'Conteúdo da ATA',
      trailing: Wrap(
        spacing: AppSpacing.xxs,
        children: [
          IconButton(
            tooltip: 'Copiar conteúdo',
            icon: Icon(GjaIcons.copy, size: 18.sp),
            color: cs.onSurfaceVariant,
            onPressed: onCopiar,
          ),
          IconButton(
            tooltip: 'Ver Markdown bruto',
            icon: Icon(GjaIcons.sourceCode, size: 18.sp),
            color: cs.onSurfaceVariant,
            onPressed: () => mostrarMarkdownBruto(detalhe.id, detalhe.markdown),
          ),
          IconButton(
            tooltip: 'Baixar Word (.docx)',
            icon: Icon(GjaIcons.download, size: 18.sp),
            color: cs.onSurfaceVariant,
            onPressed: onBaixar,
          ),
        ],
      ),
      child: MarkdownView(data: detalhe.markdown),
    );
  }
}

/// Painel de ações da ATA: edição (editar/reprocessar), indexação (reindexar)
/// e navegação (ver reunião).
class _AcoesCard extends StatelessWidget {
  const _AcoesCard({
    required this.detalhe,
    required this.isMutating,
    required this.isPolling,
    required this.isAbrindoReuniao,
    required this.onReprocessar,
    required this.onEditar,
    required this.onReindexar,
    required this.onVerReuniao,
  });

  final AtaDetalhe detalhe;
  final bool isMutating;
  final bool isPolling;
  final bool isAbrindoReuniao;
  final VoidCallback onReprocessar;
  final VoidCallback onEditar;
  final VoidCallback onReindexar;
  final VoidCallback onVerReuniao;

  @override
  Widget build(BuildContext context) {
    final status = detalhe.status;
    final tt = context.textTheme;
    final cs = context.colors;

    // Botões com tamanho fixo (o AppButton escala com o screenutil e ficava
    // desproporcional em monitores grandes).
    final principais = <Widget>[
      if (status != AtaStatus.cancelada) ...[
        _AcaoButton(
          label: 'Editar',
          icon: GjaIcons.edit,
          background: cs.primary,
          foreground: cs.onPrimary,
          isLoading: false,
          onPressed: onEditar,
        ),
        _AcaoButton.outline(
          label: 'Reprocessar',
          icon: GjaIcons.refresh,
          isLoading: isMutating,
          onPressed: onReprocessar,
        ),
        _AcaoButton.outline(
          label: 'Reindexar',
          icon: GjaIcons.synchronize,
          isLoading: isMutating || isPolling,
          onPressed: onReindexar,
        ),
      ],
    ];

    return AppCard(
      title: 'Ações',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (principais.isEmpty)
            Text(
              status == AtaStatus.cancelada
                  ? 'ATA cancelada — nenhuma ação disponível.'
                  : 'Nenhuma ação disponível para o status atual.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: principais,
            ),
          SizedBox(height: AppSpacing.sm),
          const Divider(),
          TextButton.icon(
            onPressed: isAbrindoReuniao ? null : onVerReuniao,
            icon: isAbrindoReuniao
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(GjaIcons.appointment, size: 18),
            label: const Text('Ver reunião vinculada'),
          ),
        ],
      ),
    );
  }
}

/// Botão de ação do detalhe com dimensões fixas (não escala com o screenutil).
class _AcaoButton extends StatelessWidget {
  const _AcaoButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.isLoading,
    required this.onPressed,
  }) : outline = false;

  const _AcaoButton.outline({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  })  : outline = true,
        background = null,
        foreground = null;

  final String label;
  final IconData icon;
  final Color? background;
  final Color? foreground;
  final bool outline;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 18);

    if (outline) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: child,
        label: Text(label),
      );
    }
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
      ),
      icon: child,
      label: Text(label),
    );
  }
}

class _IndexacaoCard extends StatelessWidget {
  const _IndexacaoCard({required this.indexStatus, required this.isPolling});

  final IndexStatus indexStatus;
  final bool isPolling;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    final isErro = indexStatus.isErro;

    return AppCard(
      color: isErro ? cs.errorContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Indexação no RAG: ',
                  style: tt.bodyMedium?.copyWith(
                    color: isErro ? cs.onErrorContainer : cs.onSurface,
                  )),
              IndexStatusBadge(status: indexStatus),
            ],
          ),
          if (isPolling) ...[
            SizedBox(height: AppSpacing.sm),
            const LinearProgressIndicator(),
            SizedBox(height: AppSpacing.xs),
            Text('Acompanhando a indexação…',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
          if (isErro) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              'Houve um erro ao indexar. Tente reindexar.',
              style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner de falha do último reprocessamento — o backend regera em background
/// e grava o erro na ATA quando a regeração morre (Graph/IA fora, etc.).
class _ErroProcessamento extends StatelessWidget {
  const _ErroProcessamento({required this.erro, required this.quando});
  final String erro;
  final DateTime? quando;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    return AppCard(
      color: cs.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(GjaIcons.error, size: 18.sp, color: cs.onErrorContainer),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  quando == null
                      ? 'O último reprocessamento falhou'
                      : 'O último reprocessamento falhou (${AtaFormat.dataHora(quando)})',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(erro,
              style: tt.bodyMedium?.copyWith(color: cs.onErrorContainer)),
          SizedBox(height: AppSpacing.xs),
          Text('A ATA continua na versão anterior. Você pode tentar reprocessar novamente.',
              style: tt.bodySmall?.copyWith(color: cs.onErrorContainer)),
        ],
      ),
    );
  }
}


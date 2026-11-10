import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/widgets/status_badges.dart';
import 'package:gjamobile/src/features/teamsbot/fila/data/models/fila_item.dart';
import 'package:gjamobile/src/features/teamsbot/fila/presentation/widgets/fila_status_badge.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/repositories/reunioes_repository.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/presentation/controllers/reuniao_detalhe_controller.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/presentation/widgets/reuniao_badges.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/presentation/widgets/transcricao_card.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/presentation/widgets/transcricao_chat_dialog.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/status_pill.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela — Detalhe da reunião monitorada (`/teamsbot/reunioes/:id`).
class ReuniaoDetalheScreen extends StatefulWidget {
  const ReuniaoDetalheScreen({super.key, required this.id});

  final int id;

  @override
  State<ReuniaoDetalheScreen> createState() => _ReuniaoDetalheScreenState();
}

class _ReuniaoDetalheScreenState extends State<ReuniaoDetalheScreen> {
  late final ReuniaoDetalheController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReuniaoDetalheController(
      id: widget.id,
      repository: AppInjector.get<ReunioesRepository>(),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Reunião #${widget.id}'),
      body: AppResponsiveContainer(
        child: SignalBuilder(builder: (context) {
          final d = _controller.detalhe.value;
          final isLoading = _controller.isLoading.value;
          final error = _controller.error.value;
          final isMutating = _controller.isMutating.value;
          final isPolling = _controller.isPolling.value;

          if (d == null) {
            if (isLoading) {
              return const AppLoading(message: 'Carregando reunião…');
            }
            return AppErrorWidget(
              title: 'Não foi possível carregar a reunião',
              message: error?.message,
              onRetry: _controller.load,
            );
          }
          return _Body(
            d: d,
            isMutating: isMutating,
            isPolling: isPolling,
            onReprocessar: _controller.reprocessar,
            onEnfileirar: _controller.enfileirar,
          );
        }),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.d,
    required this.isMutating,
    required this.isPolling,
    required this.onReprocessar,
    required this.onEnfileirar,
  });

  final MonitoredMeetingDetalhe d;
  final bool isMutating;
  final bool isPolling;
  final Future<bool> Function() onReprocessar;
  final Future<bool> Function() onEnfileirar;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        _MetaPanel(d: d),
        if (d.erroProcessamento != null) ...[
          SizedBox(height: AppSpacing.md),
          _ErroBanner(erro: d.erroProcessamento!),
        ],
        SizedBox(height: AppSpacing.md),
        _Acoes(
          d: d,
          isMutating: isMutating,
          isPolling: isPolling,
          onReprocessar: onReprocessar,
          onEnfileirar: onEnfileirar,
        ),
        if (d.transcricao != null) ...[
          SizedBox(height: AppSpacing.md),
          TranscricaoCard(transcricao: d.transcricao!),
        ],
        if (d.fila != null) ...[
          SizedBox(height: AppSpacing.md),
          _FilaCard(fila: d.fila!),
        ],
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({required this.d});
  final MonitoredMeetingDetalhe d;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ReuniaoStatusBadge(status: d.statusProcessamento),
              if (d.statusAta != null) AtaStatusBadge(status: d.statusAta!),
              _OnlinePill(online: d.online),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(d.assunto ?? '(sem assunto)',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: AppSpacing.xs),
          Text('Organizador: ${d.organizador ?? '—'}',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _Info(label: 'Início', value: AtaFormat.dataHora(d.inicio)),
              _Info(label: 'Fim', value: AtaFormat.dataHora(d.fim)),
              _Info(label: 'Tentativas', value: '${d.tentativasProcessamento}'),
              _Info(
                  label: 'Processado em',
                  value: AtaFormat.dataHora(d.processadoEm)),
              _Info(label: 'iCalUID', value: d.icalUid),
            ],
          ),
          if (d.participantes.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Text('Participantes',
                style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final p in d.participantes)
                  // Cores explícitas do scheme para funcionar no tema escuro.
                  Chip(
                    label: Text(_participanteLabel(p)),
                    labelStyle: tt.bodySmall?.copyWith(color: cs.onSurface),
                    backgroundColor: cs.surfaceContainerHigh,
                    side: BorderSide(color: cs.outlineVariant),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
          if (d.joinUrl != null && d.joinUrl!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Text('Link da reunião',
                style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            SizedBox(height: AppSpacing.xxs),
            SelectableText(d.joinUrl!,
                style: tt.bodySmall?.copyWith(color: cs.primary)),
          ],
        ],
      ),
    );
  }

  String _participanteLabel(Participante p) {
    final extra = [p.papel, p.resposta].where((e) => e != null).join(' · ');
    return extra.isEmpty ? p.displayName : '${p.displayName} ($extra)';
  }
}

class _Acoes extends StatelessWidget {
  const _Acoes({
    required this.d,
    required this.isMutating,
    required this.isPolling,
    required this.onReprocessar,
    required this.onEnfileirar,
  });

  final MonitoredMeetingDetalhe d;
  final bool isMutating;
  final bool isPolling;
  final Future<bool> Function() onReprocessar;
  final Future<bool> Function() onEnfileirar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPolling) ...[
          const LinearProgressIndicator(),
          SizedBox(height: AppSpacing.xs),
          Text('Acompanhando o processamento…',
              style: context.textTheme.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant)),
          SizedBox(height: AppSpacing.sm),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (d.transcricao?.disponivel ?? false)
              AppButton(
                label: 'Ver transcrição',
                variant: ButtonVariant.secondary,
                prefixIcon: const Icon(GjaIcons.discussion, size: 18),
                onPressed: () => showTranscricaoChatDialog(
                  meetingId: d.id,
                  titulo: d.assunto,
                ),
              ),
            AppButton(
              label: 'Reprocessar',
              variant: ButtonVariant.outline,
              isLoading: isMutating,
              prefixIcon: const Icon(GjaIcons.reset, size: 18),
              onPressed: () => onReprocessar(),
            ),
            AppButton(
              label: 'Reenfileirar',
              isLoading: isMutating,
              prefixIcon: const Icon(GjaIcons.workflowTasks, size: 18),
              onPressed: () => onEnfileirar(),
            ),
            if (d.ataId != null)
              AppButton(
                label: 'Abrir ATA',
                variant: ButtonVariant.secondary,
                prefixIcon: const Icon(GjaIcons.documentText, size: 18),
                onPressed: () =>
                    context.push(AppRoutes.teamsbotAtaDetalhePath(d.ataId!)),
              ),
          ],
        ),
      ],
    );
  }
}

class _FilaCard extends StatelessWidget {
  const _FilaCard({required this.fila});
  final FilaItem fila;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(GjaIcons.workflowTasks, color: cs.primary, size: 20.sp),
              SizedBox(width: AppSpacing.xs),
              Text('Fila de criação',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              FilaStatusBadge(status: fila.status),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              _Info(label: 'Item nº', value: '${fila.id}'),
              _Info(label: 'Tentativas', value: '${fila.tentativas}'),
              _Info(
                  label: 'Criado em', value: AtaFormat.dataHora(fila.criadoEm)),
              _Info(
                  label: 'Iniciado em',
                  value: AtaFormat.dataHora(fila.iniciadoEm)),
              _Info(
                  label: 'Concluído em',
                  value: AtaFormat.dataHora(fila.concluidoEm)),
            ],
          ),
          if (fila.erro != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(fila.erro!, style: tt.bodySmall?.copyWith(color: cs.error)),
          ],
        ],
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    return StatusPill.tone(
      context,
      label: online ? 'Online' : 'Presencial',
      tone: online ? BadgeTone.info : BadgeTone.neutral,
    );
  }
}

class _ErroBanner extends StatelessWidget {
  const _ErroBanner({required this.erro});
  final String erro;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return AppCard(
      color: cs.errorContainer,
      child: Row(
        children: [
          Icon(GjaIcons.error, color: cs.onErrorContainer, size: 20.sp),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(erro,
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: tt.labelMedium?.copyWith(
                color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        SizedBox(height: AppSpacing.xxs),
        Text((value == null || value!.isEmpty) ? '—' : value!,
            style: tt.bodyMedium),
      ],
    );
  }
}

import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;
import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/apontamento.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/controllers/apontamento_controller.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/apontamento_acoes.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/chamado_origem_button.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/utils/timesheet_dates.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// O que o sheet fez — a tela usa para escolher o toast. Fechar sem salvar
/// (ou salvar sem nenhuma alteração) devolve `null`.
enum ApontamentoFormResult { criado, atualizado, excluido }

/// Bottom-sheet de apontamento no dia [day] do Timesheet. Cria quando
/// [apontamento] é nulo e edita caso contrário — mesmo formulário, como nos
/// demais form-sheets do projeto.
///
/// Fecha com `pop(resultado)` no sucesso (a tela mostra o toast e recarrega);
/// em erro mostra o toast e permanece aberto com os dados preenchidos.
class ApontamentoFormSheet extends StatefulWidget {
  const ApontamentoFormSheet({
    super.key,
    required this.day,
    this.weekDays,
    this.apontamento,
    this.tituloChamado,
    this.chamadoPreSelecionado,
    this.modelo,
  });

  /// Dia inicial do apontamento (dia selecionado no Timesheet).
  final DateTime day;

  /// Dias da semana exibida — presente quando o sheet abre da visão semanal:
  /// o formulário ganha o campo "Dia" limitado a esta semana. Nulo na visão
  /// diária (dia fixo em [day]).
  final List<DateTime>? weekDays;

  /// Apontamento sendo editado; nulo abre o formulário em modo de criação.
  final Apontamento? apontamento;

  /// Título do chamado do [apontamento], para exibir o campo travado.
  final String? tituloChamado;

  /// Chamado escolhido no painel "Meus chamados": o formulário abre em modo de
  /// criação com ele já selecionado e o campo travado. A escolha já foi feita
  /// na lista — reabrir o autocomplete só permitiria trocar por engano.
  final Chamado? chamadoPreSelecionado;

  /// Apontamento usado como molde na **duplicação**: horários, descrição e
  /// privacidade abrem preenchidos com os dele, para o usuário só ajustar o dia.
  ///
  /// Diferente de [apontamento]: este continua sendo um formulário de
  /// *criação*. O modo de edição é decidido só por [apontamento], então o
  /// título, o botão, o diff do envio e o botão de excluir não mudam aqui.
  final Apontamento? modelo;

  @override
  State<ApontamentoFormSheet> createState() => _ApontamentoFormSheetState();
}

class _ApontamentoFormSheetState extends State<ApontamentoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = AppInjector.get<ApontamentoController>();
  final _chamadoCtrl = TextEditingController();
  final _inicioCtrl = TextEditingController();
  final _fimCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();

  late DateTime _dia = dateOnly(widget.apontamento?.inicio ?? widget.day);
  late final TextEditingController _diaCtrl =
      TextEditingController(text: dayLabelPt(_dia));

  TimeOfDay? _inicio;
  TimeOfDay? _fim;
  bool _privado = true;

  /// Valores originais do apontamento em edição — é contra eles que o `_submit`
  /// monta o diff, para enviar (e propagar ao GLPI) só o que o usuário mexeu.
  DateTime? _inicioOriginal;
  DateTime? _fimOriginal;
  String _descricaoOriginal = '';
  bool _privadoOriginal = true;

  /// `TimeOfDay.format` depende das `MaterialLocalizations`, que não existem
  /// ainda no `initState` — os campos de hora são preenchidos no primeiro
  /// `didChangeDependencies`.
  bool _horasPreenchidas = false;

  bool get _edicao => widget.apontamento != null;

  /// O chamado não é editável quando veio pronto: na edição porque um
  /// apontamento não muda de ticket, na pré-seleção porque a escolha foi feita
  /// no painel.
  bool get _chamadoTravado =>
      _edicao || widget.chamadoPreSelecionado != null;
  bool get _diaSelecionavel => widget.weekDays != null;

  /// Número do chamado na origem — o mesmo `#4242` do rótulo e a chave do link
  /// para o Verdana Desk. Nulo quando o apontamento não tem chamado (tarefa
  /// avulsa): aí não há o que abrir.
  int? get _chamadoOrigemId =>
      widget.apontamento?.chamadoId ?? widget.chamadoPreSelecionado?.origemId;

  @override
  void initState() {
    super.initState();

    // Pré-seleção do painel: alimenta o mesmo signal que o autocomplete
    // preencheria, então o validator e o submit seguem inalterados.
    final preSelecionado = widget.chamadoPreSelecionado;
    if (preSelecionado != null) {
      _controller.selecionar(preSelecionado);
      _chamadoCtrl.text = preSelecionado.label;
    }

    // Na edição o apontamento é a origem dos campos; na duplicação, o molde.
    // Os dois preenchem o formulário do mesmo jeito — só a edição guarda os
    // valores originais, que existem apenas para montar o diff do envio.
    final apontamento = widget.apontamento;
    final origem = apontamento ?? widget.modelo;
    if (origem == null) return;

    if (apontamento != null) {
      _inicioOriginal = apontamento.inicio;
      _fimOriginal = apontamento.fim;
      _descricaoOriginal = apontamento.contentPlain;
      _privadoOriginal = apontamento.privado;
      _chamadoCtrl.text = _labelChamado(apontamento);
    }

    final inicio = origem.inicio;
    final fim = origem.fim;
    _inicio = inicio == null ? null : TimeOfDay.fromDateTime(inicio);
    _fim = fim == null ? null : TimeOfDay.fromDateTime(fim);
    _descricaoCtrl.text = origem.contentPlain;
    _privado = origem.privado;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_horasPreenchidas) return;
    _horasPreenchidas = true;
    final inicio = _inicio;
    final fim = _fim;
    if (inicio != null) _inicioCtrl.text = inicio.format(context);
    if (fim != null) _fimCtrl.text = fim.format(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _chamadoCtrl.dispose();
    _diaCtrl.dispose();
    _inicioCtrl.dispose();
    _fimCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  /// `#4242 — Título` (ou só `#4242` quando o título não foi resolvido).
  String _labelChamado(Apontamento apontamento) {
    final numero =
        apontamento.chamadoId != null ? '#${apontamento.chamadoId}' : 'Tarefa';
    final titulo = widget.tituloChamado?.trim();
    return titulo == null || titulo.isEmpty ? numero : '$numero — $titulo';
  }

  DateTime _noDia(TimeOfDay hora) =>
      DateTime(_dia.year, _dia.month, _dia.day, hora.hour, hora.minute);

  /// Escolha do dia — mesmo [dp.DayPicker] do header do Timesheet (semana
  /// dom→sáb), com o mesmo intervalo aberto: apontar fora da semana exibida é
  /// comum (lançar a sexta passada na segunda), e travar no intervalo obrigava
  /// a fechar o formulário, navegar a semana e reabrir.
  Future<void> _pickDia() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: dp.DayPicker.single(
            selectedDate: _dia,
            firstDate: DateTime(2000),
            lastDate: DateTime(DateTime.now().year + 1, 12, 31),
            datePickerStyles: dp.DatePickerRangeStyles(firstDayOfWeekIndex: 0),
            onChanged: (day) => Navigator.of(dialogContext).pop(day),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dia = dateOnly(picked);
      _diaCtrl.text = dayLabelPt(_dia);
    });
  }

  Future<void> _pickHora({required bool isInicio}) async {
    final atual = isInicio ? _inicio : _fim;
    final hora = await showTimePicker(
      context: context,
      initialTime: atual ?? TimeOfDay.now(),
    );
    if (hora == null || !mounted) return;
    setState(() {
      if (isInicio) {
        _inicio = hora;
        _inicioCtrl.text = hora.format(context);
      } else {
        _fim = hora;
        _fimCtrl.text = hora.format(context);
      }
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_edicao) {
      await _submitEdicao();
      return;
    }
    final error = await _controller.criar(
      inicio: _noDia(_inicio!),
      fim: _noDia(_fim!),
      descricao: _descricaoCtrl.text.trim(),
      privado: _privado,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(ApontamentoFormResult.criado);
    } else {
      showToast(context, message: error, status: 'error');
    }
  }

  /// Envia só os campos alterados. Trocar o dia desloca início e fim, então os
  /// dois entram no diff — que é o correto: o período inteiro mudou.
  Future<void> _submitEdicao() async {
    final id = widget.apontamento?.id;
    if (id == null) return;

    final inicioNovo = _noDia(_inicio!);
    final fimNovo = _noDia(_fim!);
    final descricaoNova = _descricaoCtrl.text.trim();

    final inicio = inicioNovo == _inicioOriginal ? null : inicioNovo;
    final fim = fimNovo == _fimOriginal ? null : fimNovo;
    final descricao = descricaoNova == _descricaoOriginal ? null : descricaoNova;
    final privado = _privado == _privadoOriginal ? null : _privado;

    if (inicio == null && fim == null && descricao == null && privado == null) {
      // Nada mudou: fecha sem chamar o backend e sem toast de sucesso.
      Navigator.of(context).pop();
      return;
    }

    final error = await _controller.atualizar(
      id: id,
      inicio: inicio,
      fim: fim,
      descricao: descricao,
      privado: privado,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(ApontamentoFormResult.atualizado);
    } else {
      showToast(context, message: error, status: 'error');
    }
  }

  Future<void> _excluir() async {
    final id = widget.apontamento?.id;
    if (id == null) return;
    final confirmado = await confirmarExclusaoApontamento(context);
    if (!confirmado || !mounted) return;

    final error = await _controller.excluir(id: id);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(ApontamentoFormResult.excluido);
    } else {
      showToast(context, message: error, status: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppBorders.bottomSheet,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titulo(),
                style: context.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppSpacing.md),
              if (_chamadoTravado) _buildChamadoTravado() else _buildChamadoField(),
              SizedBox(height: AppSpacing.md),
              if (_diaSelecionavel) ...[
                _buildDiaField(),
                SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Expanded(child: _buildHoraField(isInicio: true)),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildHoraField(isInicio: false)),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Descrição',
                hint: 'O que foi feito neste período?',
                controller: _descricaoCtrl,
                minLines: 2,
                maxLines: 4,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Informe a descrição' : null,
              ),
              CheckboxListTile(
                value: _privado,
                onChanged: (v) => setState(() => _privado = v ?? true),
                title: const Text('Privado'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SizedBox(height: AppSpacing.sm),
              SignalBuilder(builder: (context) {
                final enviando = _controller.enviandoSignal.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: _edicao
                          ? 'Salvar alterações'
                          : 'Salvar apontamento',
                      isFullWidth: true,
                      isLoading: enviando,
                      onPressed: _submit,
                    ),
                    if (_edicao)
                      TextButton.icon(
                        onPressed: enviando ? null : _excluir,
                        style: TextButton.styleFrom(
                          foregroundColor: context.colors.error,
                        ),
                        icon: const Icon(GjaIcons.delete, size: 18),
                        label: const Text('Excluir apontamento'),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Na visão semanal o dia aparece (e muda) no campo "Dia".
  String _titulo() {
    final acao = _edicao ? 'Editar apontamento' : 'Novo apontamento';
    return _diaSelecionavel ? acao : '$acao — ${dayLabelPt(_dia)}';
  }

  /// Campo de chamado com autocomplete: digitar dispara a busca (debounce no
  /// controller); as sugestões aparecem logo abaixo e o toque seleciona.
  Widget _buildChamadoField() {
    return SignalBuilder(builder: (context) {
      final selecionado = _controller.chamadoSelecionadoSignal.value;
      final resultados = _controller.resultadosSignal.value;
      final status = _controller.buscaStatusSignal.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Chamado',
            hint: 'Busque por título ou nº do chamado',
            controller: _chamadoCtrl,
            onChanged: _controller.buscar,
            suffixIcon: status.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            validator: (_) => _controller.chamadoSelecionadoSignal.peek() == null
                ? 'Selecione um chamado da lista'
                : null,
          ),
          if (selecionado == null && resultados.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: AppSpacing.xs),
              constraints: const BoxConstraints(maxHeight: 220),
              clipBehavior: Clip.antiAlias,
              // Borda como no cardTheme: no dark, surfaceContainerHighest é o
              // mesmo fill dos inputs — sem borda a lista some na superfície.
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: AppBorders.md,
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: resultados.length,
                itemBuilder: (context, index) {
                  final chamado = resultados[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      chamado.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selecionar(chamado),
                  );
                },
              ),
            ),
          if (selecionado == null &&
              status.isSuccess &&
              resultados.isEmpty &&
              _chamadoCtrl.text.trim().length >= 2)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Nenhum chamado encontrado',
                style: context.textTheme.bodySmall
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
        ],
      );
    });
  }

  /// Chamado só leitura: na edição porque um apontamento não muda de ticket (o
  /// backend nem aceita `tickets_id` no PUT); na pré-seleção porque a escolha
  /// veio do painel.
  ///
  /// `enabled: false` só na edição: ele esmaece o texto, aceitável para um dado
  /// herdado, mas ruim para o chamado que o usuário acabou de escolher e ainda
  /// precisa conferir antes de salvar.
  Widget _buildChamadoTravado() {
    final campo = AppTextField(
      label: 'Chamado',
      controller: _chamadoCtrl,
      readOnly: true,
      enabled: !_edicao,
      suffixIcon: const Icon(GjaIcons.locked, size: 18),
    );

    final origemId = _chamadoOrigemId;
    if (origemId == null) return campo;

    return Row(
      children: [
        Expanded(child: campo),
        SizedBox(width: AppSpacing.xs),
        ChamadoOrigemButton(origemId: origemId),
      ],
    );
  }

  void _selecionar(Chamado chamado) {
    _controller.selecionar(chamado);
    _chamadoCtrl.text = chamado.label;
  }

  Widget _buildDiaField() {
    return GestureDetector(
      onTap: _pickDia,
      child: AbsorbPointer(
        child: AppTextField(
          label: 'Dia',
          controller: _diaCtrl,
          readOnly: true,
          suffixIcon: const Icon(GjaIcons.calendar, size: 18),
        ),
      ),
    );
  }

  Widget _buildHoraField({required bool isInicio}) {
    return GestureDetector(
      onTap: () => _pickHora(isInicio: isInicio),
      child: AbsorbPointer(
        child: AppTextField(
          label: isInicio ? 'Hora início' : 'Hora fim',
          hint: '--:--',
          controller: isInicio ? _inicioCtrl : _fimCtrl,
          readOnly: true,
          suffixIcon: const Icon(GjaIcons.pending, size: 18),
          validator: (_) {
            if (isInicio) {
              return _inicio == null ? 'Informe a hora de início' : null;
            }
            if (_fim == null) return 'Informe a hora de fim';
            if (_inicio != null &&
                !_noDia(_fim!).isAfter(_noDia(_inicio!))) {
              return 'Fim deve ser depois do início';
            }
            return null;
          },
        ),
      ),
    );
  }
}

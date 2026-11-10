import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../container/gja_container.dart';

/// Estrutura da aplicação, como o `sap.tnt.ToolPage` do SAPUI5.
///
/// No topo ficam o [header], em geral um `GjaShellBar`, e o [subHeader].
/// Abaixo, o [sideContent], em geral a navegação, fica ao lado dos
/// [mainContents]; na classe de tela `small`, ele cobre o conteúdo principal
/// quando expandido e sai da tela quando recolhido.
///
/// O conteúdo lateral define a própria largura e lê o estado em vigor com
/// [sideExpandedOf]. Sem [sideExpanded], o estado começa expandido, exceto na
/// classe `small`, e depois só muda por [toggleSideContentMode], como no UI5;
/// com [sideExpanded], o estado é controlado e a alternância só chama
/// [onSideExpandedChanged].
///
/// ```dart
/// GjaToolPage(
///   header: Builder(
///     builder: (context) => GjaShellBar(
///       title: 'Compras',
///       showMenuButton: true,
///       onMenuButtonPressed: () =>
///           GjaToolPage.toggleSideContentMode(context),
///     ),
///   ),
///   sideContent: const MinhaNavegacao(),
///   mainContents: const [PaginaDePedidos()],
/// )
/// ```
class GjaToolPage extends StatefulWidget {
  /// Cria a página de ferramentas.
  const GjaToolPage({
    this.header,
    this.subHeader,
    this.sideContent,
    this.mainContents = const [],
    this.sideExpanded,
    this.onSideExpandedChanged,
    super.key,
  });

  /// Cabeçalho no topo, em geral um `GjaShellBar`.
  final Widget? header;

  /// Subcabeçalho, logo abaixo do cabeçalho.
  final Widget? subHeader;

  /// Conteúdo lateral, em geral a navegação; define a própria largura.
  final Widget? sideContent;

  /// Conteúdos principais, empilhados e dividindo a altura em partes iguais;
  /// o caso usual é um só, que ocupa toda a área.
  final List<Widget> mainContents;

  /// Estado controlado do conteúdo lateral; nulo usa o estado automático.
  final bool? sideExpanded;

  /// Chamado com o novo estado quando [toggleSideContentMode] é acionado.
  final ValueChanged<bool>? onSideExpandedChanged;

  /// Estado do conteúdo lateral em vigor no [GjaToolPage] mais próximo, ou
  /// nulo fora de um.
  static bool? sideExpandedOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_GjaToolPageScope>()
      ?.expanded;

  /// Alterna o conteúdo lateral do [GjaToolPage] mais próximo, como o
  /// `toggleSideContentMode` do UI5; fora de um, não faz nada.
  static void toggleSideContentMode(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_GjaToolPageScope>()?.toggle();

  @override
  State<GjaToolPage> createState() => _GjaToolPageState();
}

class _GjaToolPageState extends State<GjaToolPage>
    with SingleTickerProviderStateMixin {
  /// Mantêm o estado dos conteúdos quando a estrutura em volta deles muda.
  final _mainKey = GlobalKey();
  final _sideKey = GlobalKey();

  /// Estado automático: decidido na primeira exibição e depois mantido.
  bool? _automatic;

  late GjaSizeClass _sizeClass;

  /// Posição do conteúdo lateral na classe `small`: 1 é expandido.
  late final AnimationController _slide = AnimationController(vsync: this);

  bool get _expanded => widget.sideExpanded ?? _automatic!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sizeClass = GjaResponsive.screenSizeClassOf(context);
    final first = _automatic == null;
    _automatic ??= _sizeClass != GjaSizeClass.small;
    if (first) _slide.value = _expanded ? 1 : 0;
  }

  @override
  void didUpdateWidget(GjaToolPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sideExpanded != oldWidget.sideExpanded) _animate();
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _animate() {
    final theme = GjaThemeData.of(context);
    _slide.animateTo(
      _expanded ? 1 : 0,
      duration: theme.motion.long,
      curve: theme.motion.standard,
    );
  }

  void _toggle() {
    final next = !_expanded;
    if (widget.sideExpanded == null) {
      setState(() => _automatic = next);
      _animate();
    }
    widget.onSideExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final expanded = _expanded;
    final contents = widget.mainContents;
    final main = KeyedSubtree(
      key: _mainKey,
      child: contents.isEmpty
          ? const SizedBox.expand()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final content in contents) Expanded(child: content),
              ],
            ),
    );
    final sideContent = widget.sideContent;

    final Widget area;
    if (sideContent == null) {
      area = main;
    } else if (_sizeClass == GjaSizeClass.small) {
      final side = KeyedSubtree(key: _sideKey, child: sideContent);
      final rtl = Directionality.of(context) == TextDirection.rtl;
      area = ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Coberto pelo conteúdo lateral, o principal sai do foco e da
            // semântica, mas continua montado e preserva o estado.
            ExcludeSemantics(
              excluding: expanded,
              child: ExcludeFocus(excluding: expanded, child: main),
            ),
            AnimatedBuilder(
              animation: _slide,
              builder: (context, child) => Offstage(
                // `animateTo(0)` termina como `completed`, não `dismissed`.
                offstage: _slide.value == 0,
                child: FractionalTranslation(
                  translation: Offset((1 - _slide.value) * (rtl ? 1 : -1), 0),
                  child: child,
                ),
              ),
              child: ExcludeFocus(excluding: !expanded, child: side),
            ),
          ],
        ),
      );
    } else {
      area = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyedSubtree(key: _sideKey, child: sideContent),
          Expanded(child: main),
        ],
      );
    }

    final header = widget.header;
    final subHeader = widget.subHeader;
    return _GjaToolPageScope(
      expanded: expanded,
      toggle: _toggle,
      child: GjaContainer(
        surface: GjaSurface.background,
        // O cabeçalho vem por último para ser pintado sobre a área, com a
        // sombra visível; `up` o mantém no topo. Foco e semântica seguem a
        // geometria.
        child: Column(
          verticalDirection: VerticalDirection.up,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: area),
            ?subHeader,
            ?header,
          ],
        ),
      ),
    );
  }
}

class _GjaToolPageScope extends InheritedWidget {
  const _GjaToolPageScope({
    required this.expanded,
    required this.toggle,
    required super.child,
  });

  final bool expanded;
  final VoidCallback toggle;

  @override
  bool updateShouldNotify(_GjaToolPageScope oldWidget) =>
      expanded != oldWidget.expanded;
}

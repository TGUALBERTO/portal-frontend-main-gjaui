import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:gjamobile/src/features/auth/presentation/widgets/truck_painter.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Layout da tela de login: painel central com a marca e o botão da Microsoft,
/// a versão no rodapé e o caminhão na faixa de baixo.
///
/// Não conhece controller nem DI — a [LoginScreen] passa o estado de
/// carregamento e os callbacks. É o que deixa o layout testável nos dois temas
/// e em qualquer viewport sem montar o fluxo de autenticação.
class LoginView extends StatelessWidget {
  const LoginView({
    super.key,
    required this.isLoading,
    required this.onSignIn,
    this.onLogoTap,
  });

  /// Login em andamento: o botão fica desabilitado, com um spinner no lugar do
  /// logo da Microsoft. Só o botão escuta — o resto da tela não reconstrói.
  final ReadonlySignal<bool> isLoading;

  final Future<void> Function() onSignIn;

  /// Toque na logo da empresa (atalho do seletor de ambiente).
  final VoidCallback? onLogoTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isDark = context.isDarkMode;
    final horizontal = context.pagePadding;
    final vertical = context.isCompact ? AppSpacing.md : AppSpacing.lg;

    // No claro o fundo é o cinza do `surfaceContainer`, para o painel branco se
    // destacar; no escuro o `surface` já é o tom mais fundo e o painel sobe um.
    // O azul do `tertiary` puxa o fundo para o azul-marinho da marca — o
    // `primary` é o vermelho, que tingiria a tela de rosa.
    final base = isDark ? cs.surface : cs.surfaceContainer;
    final background = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(cs.tertiary.withValues(alpha: 0.04), base),
        base,
        Color.alphaBlend(cs.tertiary.withValues(alpha: 0.10), base),
      ],
      stops: const [0, 0.5, 1],
    );

    // Sem AppBar ninguém define a cor dos ícones da barra de status, e eles
    // herdariam a da tela anterior: brancos sobre o fundo claro, por exemplo.
    final statusBar = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Largura de formulário: no Android o painel ocupa a tela menos a
          // margem da página; na web para em 480 e fica centralizado.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.designTokens.maxFormWidth,
            ),
            child: _LoginPanel(
              isLoading: isLoading,
              onSignIn: onSignIn,
              onLogoTap: onLogoTap,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          const AppVersionLabel(prefix: 'Grupo José Alves'),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBar,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: background),
        // Sem AppPageScaffold: ele centraliza o conteúdo, mas não tem como
        // manter uma faixa no pé da tela que role junto quando falta altura.
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: Stack(
                  children: [
                    _CenteredAboveBand(
                      viewportHeight: constraints.maxHeight,
                      bandHeight: DrivingTruck.height,
                      centerOnViewport: context.isMobile,
                      child: content,
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: DrivingTruck.height,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IgnorePointer(child: DrivingTruck()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Posiciona o conteúdo da tela e reserva a faixa do caminhão no pé dela.
///
/// Ocupa a altura da tela, ou a do conteúdo mais a faixa se for maior, e aí a
/// tela rola: o caminhão vem depois do rodapé e nunca passa por cima do botão,
/// como acontecia com ele sobreposto (Android deitado, fonte ampliada).
///
/// Sobrando altura, o conteúdo fica centralizado:
/// - no celular ([centerOnViewport]), na tela inteira. Centralizado só no
///   espaço acima da faixa, o painel subia metade dela e ficava alto demais;
/// - na web, no espaço acima da faixa, longe do caminhão.
///
/// Em qualquer caso, o conteúdo só sobe o necessário para não invadir a faixa.
/// `Column` com `Spacer` não expressa esse limite.
class _CenteredAboveBand extends SingleChildRenderObjectWidget {
  const _CenteredAboveBand({
    required this.viewportHeight,
    required this.bandHeight,
    required this.centerOnViewport,
    super.child,
  });

  final double viewportHeight;
  final double bandHeight;
  final bool centerOnViewport;

  @override
  _RenderCenteredAboveBand createRenderObject(BuildContext context) =>
      _RenderCenteredAboveBand(
        viewportHeight: viewportHeight,
        bandHeight: bandHeight,
        centerOnViewport: centerOnViewport,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCenteredAboveBand renderObject,
  ) {
    renderObject
      ..viewportHeight = viewportHeight
      ..bandHeight = bandHeight
      ..centerOnViewport = centerOnViewport;
  }
}

class _RenderCenteredAboveBand extends RenderShiftedBox {
  _RenderCenteredAboveBand({
    required double viewportHeight,
    required double bandHeight,
    required bool centerOnViewport,
  })  : _viewportHeight = viewportHeight,
        _bandHeight = bandHeight,
        _centerOnViewport = centerOnViewport,
        super(null);

  double _viewportHeight;
  set viewportHeight(double value) {
    if (value == _viewportHeight) return;
    _viewportHeight = value;
    markNeedsLayout();
  }

  double _bandHeight;
  set bandHeight(double value) {
    if (value == _bandHeight) return;
    _bandHeight = value;
    markNeedsLayout();
  }

  bool _centerOnViewport;
  set centerOnViewport(bool value) {
    if (value == _centerOnViewport) return;
    _centerOnViewport = value;
    markNeedsLayout();
  }

  Size _sizeFor(BoxConstraints constraints, Size childSize) =>
      constraints.constrain(
        Size(
          constraints.maxWidth,
          math.max(_viewportHeight, childSize.height + _bandHeight),
        ),
      );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => _sizeFor(
        constraints,
        child?.getDryLayout(constraints.loosen()) ?? Size.zero,
      );

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = _sizeFor(constraints, Size.zero);
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = _sizeFor(constraints, child.size);

    final content = child.size.height;
    final centerArea =
        _centerOnViewport ? _viewportHeight : _viewportHeight - _bandHeight;
    // Até onde o conteúdo pode descer sem encostar na faixa.
    final maxTop = math.max<double>(0, _viewportHeight - _bandHeight - content);
    final top = ((centerArea - content) / 2).clamp(0.0, maxTop);

    (child.parentData! as BoxParentData).offset =
        Offset((size.width - child.size.width) / 2, top);
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.isLoading,
    required this.onSignIn,
    this.onLogoTap,
  });

  final ReadonlySignal<bool> isLoading;
  final Future<void> Function() onSignIn;
  final VoidCallback? onLogoTap;

  /// No painel largo a descrição ocupava a linha inteira e deixava
  /// "o aplicativo." sozinho embaixo; assim ela quebra depois de "Microsoft".
  static const double _descriptionMaxWidth = 340;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final compact = context.isCompact;
    final horizontal = compact ? AppSpacing.lg : AppSpacing.xl;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? cs.surfaceContainer
            : cs.surfaceContainerLowest,
        borderRadius: AppBorders.xl,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppShadows.elevated,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          compact ? AppSpacing.xl : AppSpacing.xxl,
          horizontal,
          compact ? AppSpacing.lg : AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _BrandLogo(onTap: onLogoTap)),
            SizedBox(height: AppSpacing.xl),
            Text(
              'ACESSO CORPORATIVO',
              textAlign: TextAlign.center,
              style: tt.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: AppSpacing.ms),
            Semantics(
              header: true,
              child: Text(
                'Boas-vindas',
                textAlign: TextAlign.center,
                style: (compact ? tt.headlineMedium : tt.headlineLarge)
                    ?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.ms),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _descriptionMaxWidth,
                ),
                child: Text(
                  'Entre com sua conta corporativa Microsoft para acessar o '
                  'aplicativo.',
                  textAlign: TextAlign.center,
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            SignalBuilder(
              builder: (context) => _MicrosoftSignInButton(
                isLoading: isLoading.value,
                onPressed: onSignIn,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Use seu e-mail corporativo.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo da empresa. Só existe a versão para fundo claro, com o nome em
/// azul-marinho, que some sobre o painel escuro. No tema escuro ela vai numa
/// placa clara, o fundo para o qual foi desenhada, em vez de ter as cores da
/// marca alteradas. Quando houver uma versão negativa da logo, ela entra aqui
/// no lugar da placa.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({this.onTap});

  final VoidCallback? onTap;

  /// Proporção do `logo.png` (800x245). Com a largura fixada, o layout não
  /// pula quando a imagem termina de carregar.
  static const double _aspectRatio = 800 / 245;

  @override
  Widget build(BuildContext context) {
    final height = context.responsive<double>(
      mobile: 64,
      tablet: 76,
      desktop: 84,
    );

    Widget logo = Image.asset(
      AppAssets.logo,
      height: height,
      width: height * _aspectRatio,
      semanticLabel: 'Grupo José Alves',
    );

    if (context.isDarkMode) {
      logo = DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorders.md,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: logo,
        ),
      );
    }

    // Os 3 toques que abrem o seletor de ambiente são um atalho escondido:
    // fora da semântica, para o leitor de tela não anunciar a logo como botão.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: logo,
    );
  }
}

class _MicrosoftSignInButton extends StatelessWidget {
  const _MicrosoftSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        // Altura mínima, não fixa: com a fonte do sistema ampliada o rótulo
        // quebra linha e o botão cresce junto, em vez de cortar o texto.
        minimumSize: const Size.fromHeight(52),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.ms,
        ),
        foregroundColor: cs.onSurface,
        // Durante o login o rótulo segue legível; o spinner é que avisa.
        disabledForegroundColor: cs.onSurfaceVariant,
        textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        shape: const RoundedRectangleBorder(borderRadius: AppBorders.md),
      ).copyWith(
        // Borda de foco forte para quem navega pelo teclado na web: o overlay
        // padrão do foco é tênue demais sobre o painel branco.
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: cs.primary, width: 2);
          }
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: cs.outlineVariant, width: 1.5);
          }
          return BorderSide(color: cs.outline, width: 1.5);
        }),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 20,
            child: AnimatedSwitcher(
              duration: AppDurations.fast,
              child: isLoading
                  ? CircularProgressIndicator(
                      key: const ValueKey('loading'),
                      strokeWidth: 2,
                      color: cs.primary,
                    )
                  : const _MicrosoftLogo(key: ValueKey('logo'), size: 20),
            ),
          ),
          SizedBox(width: AppSpacing.ms),
          // `longestLine`: com fonte ampliada o rótulo quebra em duas linhas e,
          // medido pela largura disponível, empurraria o logo para a borda.
          const Flexible(
            child: Text(
              'Entrar com Microsoft',
              textAlign: TextAlign.center,
              textWidthBasis: TextWidthBasis.longestLine,
            ),
          ),
        ],
      ),
    );
  }
}

/// Os quatro quadrados da Microsoft, nas cores da marca (iguais nos dois temas).
class _MicrosoftLogo extends StatelessWidget {
  const _MicrosoftLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    const gap = 2.0;
    final tile = (size - gap) / 2;
    Widget square(Color color) =>
        Container(width: tile, height: tile, color: color);

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              square(const Color(0xFFF25022)),
              square(const Color(0xFF7FBA00)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              square(const Color(0xFF00A4EF)),
              square(const Color(0xFFFFB900)),
            ],
          ),
        ],
      ),
    );
  }
}

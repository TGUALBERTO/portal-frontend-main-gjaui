import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../../exibicao_dados/avatar/gja_avatar.dart';
import '../title/gja_title.dart';

/// Cabeçalho de um cartão, como o `sap.f.cards.Header` do SAPUI5.
///
/// A primeira linha tem o [title] (até [titleMaxLines] linhas) e o
/// [statusText] no fim; a segunda, o [subtitle] (até [subtitleMaxLines]) e a
/// [dataTimestamp] no fim. O ícone, um `GjaAvatar` de [icon], [iconImage]
/// ou [iconInitials], fica no início, e o [toolbar], na borda final. Com
/// [onPress], o cabeçalho é um botão rotulado por título e subtítulo; o
/// título é anunciado com o `headingLevel` do `GjaCard` em que está.
///
/// ```dart
/// GjaCardHeader(
///   iconInitials: 'MB',
///   title: 'Pedidos pendentes',
///   subtitle: 'Compras',
///   statusText: '3 de 5',
///   onPress: abrirPedidos,
/// )
/// ```
class GjaCardHeader extends StatelessWidget {
  /// Cria o cabeçalho.
  const GjaCardHeader({
    this.title,
    this.titleMaxLines = 3,
    this.subtitle,
    this.subtitleMaxLines = 2,
    this.statusText,
    this.statusVisible = true,
    this.dataTimestamp,
    this.icon,
    this.iconImage,
    this.iconInitials,
    this.iconDisplayShape = GjaAvatarShape.circle,
    this.iconSize = GjaAvatarSize.s,
    this.iconAlt,
    this.iconVisible = true,
    this.toolbar,
    this.onPress,
    super.key,
  }) : assert(titleMaxLines > 0, '"titleMaxLines" deve ser maior que zero'),
       assert(
         subtitleMaxLines > 0,
         '"subtitleMaxLines" deve ser maior que zero',
       );

  /// Título, anunciado como cabeçalho.
  final String? title;

  /// Número máximo de linhas do título.
  final int titleMaxLines;

  /// Subtítulo, na segunda linha.
  final String? subtitle;

  /// Número máximo de linhas do subtítulo.
  final int subtitleMaxLines;

  /// Status no fim da primeira linha (ex.: "3 de 5").
  final String? statusText;

  /// Se mostra o [statusText].
  final bool statusVisible;

  /// Data da informação, no fim da segunda linha.
  final String? dataTimestamp;

  /// Ícone do catálogo `GjaIcons` ou da aplicação.
  final IconData? icon;

  /// Imagem do ícone.
  final ImageProvider? iconImage;

  /// Iniciais do ícone, de 1 a 3 caracteres.
  final String? iconInitials;

  /// Forma do ícone.
  final GjaAvatarShape iconDisplayShape;

  /// Tamanho do ícone.
  final GjaAvatarSize iconSize;

  /// Rótulo do ícone para leitores de tela.
  final String? iconAlt;

  /// Se mostra o ícone.
  final bool iconVisible;

  /// Barra de ferramentas na borda final, com toques próprios.
  final Widget? toolbar;

  /// Ação do cabeçalho; nula o deixa não interativo.
  final VoidCallback? onPress;

  bool get _hasIcon =>
      iconVisible &&
      (icon != null || iconImage != null || iconInitials != null);

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final typography = theme.typography;
    final colors = theme.colors;
    final level = GjaCardHeadingScope.levelOf(context);
    final title = this.title;
    final subtitle = this.subtitle;
    final status = statusVisible ? statusText : null;
    final timestamp = dataTimestamp;

    Text line(String text, TextStyle style, Color color, {int maxLines = 1}) =>
        Text(
          text,
          style: style.copyWith(color: color),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
    Widget row(Widget? main, String? end) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacing.s,
      children: [
        Expanded(child: main ?? const SizedBox.shrink()),
        if (end != null) line(end, typography.small, colors.label),
      ],
    );

    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.s,
      children: [
        row(
          title == null
              ? null
              : Semantics(
                  header: true,
                  headingLevel: level.index,
                  child: line(
                    title,
                    typography.header5,
                    colors.text,
                    maxLines: titleMaxLines,
                  ),
                ),
          status,
        ),
        if (subtitle != null || timestamp != null)
          row(
            subtitle == null
                ? null
                : line(
                    subtitle,
                    typography.base,
                    colors.label,
                    maxLines: subtitleMaxLines,
                  ),
            timestamp,
          ),
      ],
    );
    final main = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacing.m,
      children: [
        if (_hasIcon)
          GjaAvatar(
            image: iconImage,
            initials: iconInitials,
            icon: icon,
            size: iconSize,
            shape: iconDisplayShape,
            semanticLabel: iconAlt,
          ),
        Expanded(child: texts),
      ],
    );

    final onPress = this.onPress;
    final Widget header;
    if (onPress == null) {
      header = Padding(padding: EdgeInsets.all(theme.spacing.l), child: main);
    } else {
      final family = GjaControlColors.of(GjaControlFamily.list, colors);
      final label = [?title, ?subtitle].join(', ');
      // Um só nó: o botão rotulado por título e subtítulo, que também é o
      // cabeçalho do cartão com o nível do título.
      header = MergeSemantics(
        child: GjaInteractable(
          semanticLabel: label.isEmpty ? null : label,
          onPressed: onPress,
          builder: (context, states) => ColoredBox(
            color: family.resolve(states).background,
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.l),
              child: Semantics(
                header: title != null,
                headingLevel: title == null ? null : level.index,
                // O status e a data, ocultos com o resto, são lidos como valor.
                value: [?status, ?timestamp].join(', '),
                child: ExcludeSemantics(child: main),
              ),
            ),
          ),
        ),
      );
    }

    final toolbar = this.toolbar;
    if (toolbar == null) return header;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: header),
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: theme.spacing.l,
            end: theme.spacing.l,
          ),
          child: toolbar,
        ),
      ],
    );
  }
}

/// Nível do título dos cabeçalhos de cartão da subárvore.
///
/// Uso interno do framework: o `GjaCard` o coloca em volta do cabeçalho com
/// o `headingLevel` do cartão.
class GjaCardHeadingScope extends InheritedWidget {
  /// Define [level] para os cabeçalhos de [child].
  const GjaCardHeadingScope({
    required this.level,
    required super.child,
    super.key,
  });

  /// Nível do título.
  final GjaTitleLevel level;

  /// Nível do título em [context]: o do cartão, ou 3 fora de um. `auto` vale
  /// 3, como o nível padrão do `sap.f.Card`.
  static GjaTitleLevel levelOf(BuildContext context) {
    final level = context
        .dependOnInheritedWidgetOfExactType<GjaCardHeadingScope>()
        ?.level;
    return level == null || level == GjaTitleLevel.auto
        ? GjaTitleLevel.h3
        : level;
  }

  @override
  bool updateShouldNotify(GjaCardHeadingScope oldWidget) =>
      level != oldWidget.level;
}

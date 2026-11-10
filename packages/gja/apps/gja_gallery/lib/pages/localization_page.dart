import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

/// Página "Localização": textos e formatos do framework em pt-BR e en.
///
/// O idioma da página é trocado com `Localizations.override`, e todo texto
/// exibido abaixo do seletor vem de `GjaLocalizations.of(context)`.
class LocalizationPage extends StatefulWidget {
  /// Cria a página.
  const LocalizationPage({super.key});

  /// Título no índice e no cabeçalho.
  static const title = 'Localização';

  /// Rota nomeada.
  static const route = '/localization';

  /// Número de exemplo dos formatos.
  static const sampleNumber = 1234567.891;

  /// Data e hora de exemplo dos formatos.
  static final sampleDate = DateTime(2026, 3, 5, 14, 30);

  @override
  State<LocalizationPage> createState() => _LocalizationPageState();
}

class _LocalizationPageState extends State<LocalizationPage> {
  Locale _locale = GjaLocalizations.defaultLocale;

  @override
  Widget build(BuildContext context) {
    final theme = GjaTheme.of(context);
    final colors = theme.colors;
    final spacing = theme.spacing;
    final typography = theme.typography;

    Widget option(Locale locale) {
      final selected = locale == _locale;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _locale = locale),
        child: Semantics(
          button: true,
          selected: selected,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.m,
              vertical: spacing.s,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? colors.selectionBackground
                  : colors.headerBackground,
              borderRadius: BorderRadius.circular(theme.radius.button),
            ),
            child: Text(locale.toLanguageTag()),
          ),
        ),
      );
    }

    return ColoredBox(
      color: colors.base,
      child: DefaultTextStyle(
        style: typography.base.copyWith(color: colors.text),
        child: ListView(
          padding: EdgeInsets.all(spacing.pageMargin),
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Semantics(button: true, child: const Text('← Voltar')),
            ),
            SizedBox(height: spacing.stackGap),
            Text(LocalizationPage.title, style: typography.header2),
            SizedBox(height: spacing.stackGap),
            Wrap(
              spacing: spacing.s,
              children: [
                for (final locale in GjaLocalizations.supportedLocales)
                  option(locale),
              ],
            ),
            SizedBox(height: spacing.sectionGap),
            Localizations.override(
              context: context,
              locale: _locale,
              child: const _Samples(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Samples extends StatelessWidget {
  const _Samples();

  @override
  Widget build(BuildContext context) {
    final l = GjaLocalizations.of(context);
    final theme = GjaTheme.of(context);
    final when = LocalizationPage.sampleDate;

    Widget row(String name, String value) => Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.xs),
      child: Text('$name: $value'),
    );

    Widget section(String title, List<Widget> rows) => Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.typography.header3),
          SizedBox(height: theme.spacing.s),
          ...rows,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('Textos', [
          row('ok', l.ok),
          row('cancel', l.cancel),
          row('close', l.close),
          row('search', l.search),
          row('clear', l.clear),
          row('noData', l.noData),
          row('loading', l.loading),
          row('more', l.more),
          row('required', l.required),
        ]),
        section('Estados de valor', [
          for (final state in GjaValueState.values)
            row(state.name, l.valueState(state)),
        ]),
        section('Contagens', [
          for (final count in const [0, 1, 1000])
            row('$count', l.selectedItems(count)),
        ]),
        section('Formatos', [
          row('decimal', l.formatDecimal(LocalizationPage.sampleNumber)),
          row(
            'inteiro',
            l.formatInteger(LocalizationPage.sampleNumber.toInt()),
          ),
          row('data', l.formatDate(when)),
          row('hora', l.formatTime(when)),
          row('data e hora', l.formatDateTime(when)),
        ]),
      ],
    );
  }
}

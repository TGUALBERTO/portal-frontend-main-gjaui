import 'package:flutter/widgets.dart';
import 'package:gja_ui/gja_ui.dart';

import 'pages/accessibility_page.dart';
import 'pages/breakpoints_page.dart';
import 'pages/color_page.dart';
import 'pages/density_page.dart';
import 'pages/design_tokens_page.dart';
import 'pages/shadows_page.dart';
import 'pages/icons_page.dart';
import 'pages/interaction_page.dart';
import 'pages/localization_page.dart';
import 'pages/overlay_page.dart';
import 'pages/radius_page.dart';
import 'pages/gja_avatar_page.dart';
import 'pages/gja_badge_page.dart';
import 'pages/gja_bar_page.dart';
import 'pages/gja_button_page.dart';
import 'pages/gja_card_page.dart';
import 'pages/gja_container_page.dart';
import 'pages/gja_dropdown_page.dart';
import 'pages/gja_grid_page.dart';
import 'pages/gja_icon_page.dart';
import 'pages/gja_label_page.dart';
import 'pages/gja_link_page.dart';
import 'pages/gja_menu_page.dart';
import 'pages/gja_responsive_layout_page.dart';
import 'pages/gja_page_page.dart';
import 'pages/gja_popover_page.dart';
import 'pages/gja_progress_indicator_page.dart';
import 'pages/gja_hbox_vbox_page.dart';
import 'pages/gja_separator_page.dart';
import 'pages/gja_shell_bar_page.dart';
import 'pages/gja_object_status_page.dart';
import 'pages/gja_tooltip_page.dart';
import 'pages/gja_spacing_page.dart';
import 'pages/gja_text_page.dart';
import 'pages/gja_theme_page.dart';
import 'pages/gja_title_page.dart';
import 'pages/gja_tool_page_page.dart';
import 'pages/responsive_page.dart';
import 'pages/spacing_page.dart';
import 'pages/states_page.dart';
import 'pages/theme_page.dart';
import 'pages/typography_page.dart';
import 'pages/gja_check_box_page.dart';
import 'pages/gja_switch_page.dart';
import 'pages/gja_radio_button_page.dart';
import 'pages/gja_input_page.dart';
import 'pages/gja_select_page.dart';
import 'pages/gja_message_strip_page.dart';
import 'pages/gja_busy_indicator_page.dart';
import 'pages/gja_illustrated_message_page.dart';
import 'pages/gja_dialog_page.dart';
import 'pages/gja_message_toast_page.dart';
import 'pages/gja_toolbar_page.dart';
import 'pages/gja_breadcrumbs_page.dart';
import 'pages/gja_icon_tab_bar_page.dart';
import 'pages/gja_side_navigation_page.dart';
import 'pages/gja_panel_page.dart';
import 'pages/gja_form_page.dart';
import 'pages/gja_table_page.dart';
import 'pages/gja_date_picker_page.dart';

/// Inicia a galeria de componentes GJA.
void main() {
  runApp(const GjaGalleryApp());
}

/// Página da galeria: título exibido no índice e construtor da rota.
class GalleryPage {
  /// Cria a página [title], publicada em [route].
  const GalleryPage({
    required this.title,
    required this.route,
    required this.builder,
  });

  /// Título no índice.
  final String title;

  /// Rota nomeada.
  final String route;

  /// Constrói o conteúdo da página.
  final WidgetBuilder builder;
}

/// Páginas da galeria, na ordem do índice.
final galleryPages = <GalleryPage>[
  GalleryPage(
    title: DesignTokensPage.title,
    route: DesignTokensPage.route,
    builder: (_) => const DesignTokensPage(),
  ),
  GalleryPage(
    title: ColorPage.title,
    route: ColorPage.route,
    builder: (_) => const ColorPage(),
  ),
  GalleryPage(
    title: SpacingPage.title,
    route: SpacingPage.route,
    builder: (_) => const SpacingPage(),
  ),
  GalleryPage(
    title: TypographyPage.title,
    route: TypographyPage.route,
    builder: (_) => const TypographyPage(),
  ),
  GalleryPage(
    title: RadiusPage.title,
    route: RadiusPage.route,
    builder: (_) => const RadiusPage(),
  ),
  GalleryPage(
    title: BreakpointsPage.title,
    route: BreakpointsPage.route,
    builder: (_) => const BreakpointsPage(),
  ),
  GalleryPage(
    title: IconsPage.title,
    route: IconsPage.route,
    builder: (_) => const IconsPage(),
  ),
  GalleryPage(
    title: DensityPage.title,
    route: DensityPage.route,
    builder: (_) => const DensityPage(),
  ),
  GalleryPage(
    title: ShadowsPage.title,
    route: ShadowsPage.route,
    builder: (_) => const ShadowsPage(),
  ),
  GalleryPage(
    title: StatesPage.title,
    route: StatesPage.route,
    builder: (_) => const StatesPage(),
  ),
  GalleryPage(
    title: AccessibilityPage.title,
    route: AccessibilityPage.route,
    builder: (_) => const AccessibilityPage(),
  ),
  GalleryPage(
    title: ThemePage.title,
    route: ThemePage.route,
    builder: (_) => const ThemePage(),
  ),
  GalleryPage(
    title: InteractionPage.title,
    route: InteractionPage.route,
    builder: (_) => const InteractionPage(),
  ),
  GalleryPage(
    title: LocalizationPage.title,
    route: LocalizationPage.route,
    builder: (_) => const LocalizationPage(),
  ),
  GalleryPage(
    title: ResponsivePage.title,
    route: ResponsivePage.route,
    builder: (_) => const ResponsivePage(),
  ),
  GalleryPage(
    title: OverlayPage.title,
    route: OverlayPage.route,
    builder: (_) => const OverlayPage(),
  ),
  GalleryPage(
    title: GjaThemePage.title,
    route: GjaThemePage.route,
    builder: (_) => const GjaThemePage(),
  ),
  GalleryPage(
    title: GjaTitlePage.title,
    route: GjaTitlePage.route,
    builder: (_) => const GjaTitlePage(),
  ),
  GalleryPage(
    title: GjaTextPage.title,
    route: GjaTextPage.route,
    builder: (_) => const GjaTextPage(),
  ),
  GalleryPage(
    title: GjaLabelPage.title,
    route: GjaLabelPage.route,
    builder: (_) => const GjaLabelPage(),
  ),
  GalleryPage(
    title: GjaIconPage.title,
    route: GjaIconPage.route,
    builder: (_) => const GjaIconPage(),
  ),
  GalleryPage(
    title: GjaSpacingPage.title,
    route: GjaSpacingPage.route,
    builder: (_) => const GjaSpacingPage(),
  ),
  GalleryPage(
    title: GjaContainerPage.title,
    route: GjaContainerPage.route,
    builder: (_) => const GjaContainerPage(),
  ),
  GalleryPage(
    title: GjaHBoxVBoxPage.title,
    route: GjaHBoxVBoxPage.route,
    builder: (_) => const GjaHBoxVBoxPage(),
  ),
  GalleryPage(
    title: GjaSeparatorPage.title,
    route: GjaSeparatorPage.route,
    builder: (_) => const GjaSeparatorPage(),
  ),
  GalleryPage(
    title: GjaResponsiveLayoutPage.title,
    route: GjaResponsiveLayoutPage.route,
    builder: (_) => const GjaResponsiveLayoutPage(),
  ),
  GalleryPage(
    title: GjaGridPage.title,
    route: GjaGridPage.route,
    builder: (_) => const GjaGridPage(),
  ),
  GalleryPage(
    title: GjaToolPagePage.title,
    route: GjaToolPagePage.route,
    builder: (_) => const GjaToolPagePage(),
  ),
  GalleryPage(
    title: GjaShellBarPage.title,
    route: GjaShellBarPage.route,
    builder: (_) => const GjaShellBarPage(),
  ),
  GalleryPage(
    title: GjaBarPage.title,
    route: GjaBarPage.route,
    builder: (_) => const GjaBarPage(),
  ),
  GalleryPage(
    title: GjaPagePage.title,
    route: GjaPagePage.route,
    builder: (_) => const GjaPagePage(),
  ),
  GalleryPage(
    title: GjaProgressIndicatorPage.title,
    route: GjaProgressIndicatorPage.route,
    builder: (_) => const GjaProgressIndicatorPage(),
  ),
  GalleryPage(
    title: GjaTooltipPage.title,
    route: GjaTooltipPage.route,
    builder: (_) => const GjaTooltipPage(),
  ),
  GalleryPage(
    title: GjaButtonPage.title,
    route: GjaButtonPage.route,
    builder: (_) => const GjaButtonPage(),
  ),
  GalleryPage(
    title: GjaLinkPage.title,
    route: GjaLinkPage.route,
    builder: (_) => const GjaLinkPage(),
  ),
  GalleryPage(
    title: GjaBadgePage.title,
    route: GjaBadgePage.route,
    builder: (_) => const GjaBadgePage(),
  ),
  GalleryPage(
    title: GjaObjectStatusPage.title,
    route: GjaObjectStatusPage.route,
    builder: (_) => const GjaObjectStatusPage(),
  ),
  GalleryPage(
    title: GjaAvatarPage.title,
    route: GjaAvatarPage.route,
    builder: (_) => const GjaAvatarPage(),
  ),
  GalleryPage(
    title: GjaCardPage.title,
    route: GjaCardPage.route,
    builder: (_) => const GjaCardPage(),
  ),
  GalleryPage(
    title: GjaPopoverPage.title,
    route: GjaPopoverPage.route,
    builder: (_) => const GjaPopoverPage(),
  ),
  GalleryPage(
    title: GjaDropdownPage.title,
    route: GjaDropdownPage.route,
    builder: (_) => const GjaDropdownPage(),
  ),
  GalleryPage(
    title: GjaMenuPage.title,
    route: GjaMenuPage.route,
    builder: (_) => const GjaMenuPage(),
  ),
  GalleryPage(
    title: GjaCheckBoxPage.title,
    route: GjaCheckBoxPage.route,
    builder: (_) => const GjaCheckBoxPage(),
  ),
  GalleryPage(
    title: GjaSwitchPage.title,
    route: GjaSwitchPage.route,
    builder: (_) => const GjaSwitchPage(),
  ),
  GalleryPage(
    title: GjaRadioButtonPage.title,
    route: GjaRadioButtonPage.route,
    builder: (_) => const GjaRadioButtonPage(),
  ),
  GalleryPage(
    title: GjaInputPage.title,
    route: GjaInputPage.route,
    builder: (_) => const GjaInputPage(),
  ),
  GalleryPage(
    title: GjaSelectPage.title,
    route: GjaSelectPage.route,
    builder: (_) => const GjaSelectPage(),
  ),
  GalleryPage(
    title: GjaMessageStripPage.title,
    route: GjaMessageStripPage.route,
    builder: (_) => const GjaMessageStripPage(),
  ),
  GalleryPage(
    title: GjaBusyIndicatorPage.title,
    route: GjaBusyIndicatorPage.route,
    builder: (_) => const GjaBusyIndicatorPage(),
  ),
  GalleryPage(
    title: GjaIllustratedMessagePage.title,
    route: GjaIllustratedMessagePage.route,
    builder: (_) => const GjaIllustratedMessagePage(),
  ),
  GalleryPage(
    title: GjaDialogPage.title,
    route: GjaDialogPage.route,
    builder: (_) => const GjaDialogPage(),
  ),
  GalleryPage(
    title: GjaMessageToastPage.title,
    route: GjaMessageToastPage.route,
    builder: (_) => const GjaMessageToastPage(),
  ),
  GalleryPage(
    title: GjaToolbarPage.title,
    route: GjaToolbarPage.route,
    builder: (_) => const GjaToolbarPage(),
  ),
  GalleryPage(
    title: GjaBreadcrumbsPage.title,
    route: GjaBreadcrumbsPage.route,
    builder: (_) => const GjaBreadcrumbsPage(),
  ),
  GalleryPage(
    title: GjaIconTabBarPage.title,
    route: GjaIconTabBarPage.route,
    builder: (_) => const GjaIconTabBarPage(),
  ),
  GalleryPage(
    title: GjaSideNavigationPage.title,
    route: GjaSideNavigationPage.route,
    builder: (_) => const GjaSideNavigationPage(),
  ),
  GalleryPage(
    title: GjaPanelPage.title,
    route: GjaPanelPage.route,
    builder: (_) => const GjaPanelPage(),
  ),
  GalleryPage(
    title: GjaFormPage.title,
    route: GjaFormPage.route,
    builder: (_) => const GjaFormPage(),
  ),
  GalleryPage(
    title: GjaTablePage.title,
    route: GjaTablePage.route,
    builder: (_) => const GjaTablePage(),
  ),
  GalleryPage(
    title: GjaDatePickerPage.title,
    route: GjaDatePickerPage.route,
    builder: (_) => const GjaDatePickerPage(),
  ),
];

/// Aplicação da galeria.
///
/// Usa `GjaApp` como raiz, sem Material. O índice escolhe o modo de tema e a
/// densidade da galeria inteira. Cada widget implementado ganha uma página.
class GjaGalleryApp extends StatefulWidget {
  /// Cria a aplicação da galeria.
  const GjaGalleryApp({super.key});

  /// Título exibido na página inicial e na janela.
  static const title = 'GJA — Galeria';

  @override
  State<GjaGalleryApp> createState() => _GjaGalleryAppState();
}

class _GjaGalleryAppState extends State<GjaGalleryApp> {
  GjaThemeMode _themeMode = GjaThemeMode.system;
  GjaDensity? _density;

  @override
  Widget build(BuildContext context) {
    return GjaApp(
      title: GjaGalleryApp.title,
      themeMode: _themeMode,
      density: _density,
      builder: (context, child) => _GallerySettings(
        themeMode: _themeMode,
        density: _density,
        onThemeMode: (mode) => setState(() => _themeMode = mode),
        onDensity: (density) => setState(() => _density = density),
        child: child!,
      ),
      routes: {
        '/': (_) => const _GalleryIndex(),
        for (final page in galleryPages) page.route: page.builder,
      },
    );
  }
}

/// Escolhas de tema e densidade da galeria, para o índice.
class _GallerySettings extends InheritedWidget {
  const _GallerySettings({
    required this.themeMode,
    required this.density,
    required this.onThemeMode,
    required this.onDensity,
    required super.child,
  });

  final GjaThemeMode themeMode;
  final GjaDensity? density;
  final ValueChanged<GjaThemeMode> onThemeMode;
  final ValueChanged<GjaDensity?> onDensity;

  static _GallerySettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GallerySettings>()!;

  @override
  bool updateShouldNotify(_GallerySettings old) =>
      old.themeMode != themeMode || old.density != density;
}

/// Índice: escolha de tema e densidade, e um link por página.
class _GalleryIndex extends StatelessWidget {
  const _GalleryIndex();

  @override
  Widget build(BuildContext context) {
    final theme = GjaTheme.of(context);
    final settings = _GallerySettings.of(context);
    final spacing = theme.spacing;
    return ListView(
      padding: EdgeInsets.all(spacing.pageMargin),
      children: [
        Text(GjaGalleryApp.title, style: theme.typography.header2),
        SizedBox(height: spacing.stackGap),
        _Options(
          children: [
            for (final (mode, label) in const [
              (GjaThemeMode.system, 'Tema: sistema'),
              (GjaThemeMode.light, 'Tema: claro'),
              (GjaThemeMode.dark, 'Tema: escuro'),
            ])
              _Option(
                label: label,
                selected: settings.themeMode == mode,
                onPressed: () => settings.onThemeMode(mode),
              ),
          ],
        ),
        SizedBox(height: spacing.s),
        _Options(
          children: [
            for (final (density, label) in const [
              (null, 'Densidade: recomendada'),
              (GjaDensity.cozy, 'Densidade: cozy'),
              (GjaDensity.compact, 'Densidade: compacta'),
            ])
              _Option(
                label: label,
                selected: settings.density == density,
                onPressed: () => settings.onDensity(density),
              ),
          ],
        ),
        SizedBox(height: spacing.sectionGap),
        for (final page in galleryPages)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pushNamed(page.route),
            child: Semantics(
              button: true,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.m),
                child: Text(page.title),
              ),
            ),
          ),
      ],
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = GjaTheme.of(context).spacing;
    return Wrap(spacing: spacing.s, runSpacing: spacing.s, children: children);
  }
}

/// Opção selecionável do índice, com as cores da família `standard`.
class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = GjaTheme.of(context);
    return GjaInteractable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: label,
      builder: (context, states) {
        final c = GjaControlColors.of(
          GjaControlFamily.standard,
          t.colors,
        ).resolve(states);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.m,
            vertical: t.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: c.background,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(t.radius.button),
          ),
          child: Text(label, style: t.typography.base.copyWith(color: c.text)),
        );
      },
    );
  }
}

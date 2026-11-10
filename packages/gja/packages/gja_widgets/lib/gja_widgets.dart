/// Widgets públicos do framework GJA.
///
/// Cada widget vive em `lib/src/<categoria>/<widget>/` e é exportado aqui.
/// Depende de `gja_foundation` e `gja_core`.
library;

export 'src/fundacao_layout/theme/gja_theme.dart';
export 'src/fundacao_layout/app/gja_app.dart';
export 'src/fundacao_layout/text/gja_text.dart';
export 'src/fundacao_layout/title/gja_title.dart';
export 'src/fundacao_layout/label/gja_label.dart';
export 'src/fundacao_layout/bar/gja_bar.dart' hide GjaBarScope;
export 'src/fundacao_layout/card_header/gja_card_header.dart'
    hide GjaCardHeadingScope;
export 'src/fundacao_layout/shell_bar/gja_shell_bar.dart';
export 'src/fundacao_layout/tool_page/gja_tool_page.dart';
export 'src/fundacao_layout/icon/gja_icon.dart';
export 'src/fundacao_layout/spacing/gja_spacing.dart';
export 'src/fundacao_layout/container/gja_container.dart';
export 'src/fundacao_layout/flex/gja_flex_enums.dart';
export 'src/fundacao_layout/hbox/gja_hbox.dart';
export 'src/fundacao_layout/vbox/gja_vbox.dart';
export 'src/fundacao_layout/separator/gja_separator.dart';
export 'src/fundacao_layout/responsive_layout/gja_responsive_layout.dart';
export 'src/fundacao_layout/grid/gja_grid.dart';
export 'src/fundacao_layout/page/gja_page.dart';
export 'src/fundacao_layout/card/gja_card.dart';
export 'src/fundacao_layout/panel/gja_panel.dart';
export 'src/exibicao_dados/progress_indicator/gja_progress_indicator.dart';
export 'src/exibicao_dados/object_status/gja_object_status.dart';
export 'src/exibicao_dados/avatar/gja_avatar.dart';
export 'src/exibicao_dados/badge/gja_badge.dart';
export 'src/exibicao_dados/illustrated_message/gja_illustrated_message.dart';
export 'src/exibicao_dados/table/gja_table.dart';
export 'src/exibicao_dados/tooltip/gja_tooltip.dart';
export 'src/acoes_navegacao/breadcrumbs/gja_breadcrumbs.dart';
export 'src/acoes_navegacao/button/gja_button.dart';
export 'src/acoes_navegacao/icon_tab_bar/gja_icon_tab_bar.dart';
export 'src/acoes_navegacao/link/gja_link.dart';
export 'src/acoes_navegacao/menu/gja_menu.dart';
export 'src/acoes_navegacao/side_navigation/gja_side_navigation.dart';
export 'src/acoes_navegacao/toolbar/gja_toolbar.dart';
export 'src/feedback_sobreposicoes/popover/gja_popover.dart';
export 'src/feedback_sobreposicoes/busy_indicator/gja_busy_indicator.dart';
export 'src/feedback_sobreposicoes/dialog/gja_dialog.dart';
export 'src/feedback_sobreposicoes/dropdown/gja_dropdown.dart';
export 'src/feedback_sobreposicoes/message_strip/gja_message_strip.dart';
export 'src/feedback_sobreposicoes/message_toast/gja_message_toast.dart';
export 'src/formularios/check_box/gja_check_box.dart';
export 'src/formularios/input/gja_input.dart';
export 'src/formularios/radio_button/gja_radio_button.dart';
export 'src/formularios/radio_button_group/gja_radio_button_group.dart';
export 'src/formularios/date_picker/gja_date_picker.dart';
export 'src/formularios/form/gja_form.dart';
export 'src/formularios/select/gja_select.dart';
export 'src/formularios/switch/gja_switch.dart';

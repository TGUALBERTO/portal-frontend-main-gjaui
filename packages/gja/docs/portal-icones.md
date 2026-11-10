# Ícones do portal GJA no `GjaIcons`

Equivalência entre os ícones Material (`Icons.*`) usados no portal GJA
(`portal-frontend-main/lib`) e o catálogo `GjaIcons`, exportado por `package:gja_ui/gja_ui.dart`.
O portal não usa `Symbols.*` nem `IconData` próprio; os SVGs em `assets/icons` são logotipos de
login social (Apple, Facebook, Google), não ícones de interface.

Conferido em 2026-11-09: os 153 ícones distintos têm equivalente.

| Material (`Icons.`) | `GjaIcons.` |
|---|---|
| `account_tree_outlined` | `orgChart` |
| `add` | `add` |
| `add_link` | `chainLink` |
| `admin_panel_settings` | `userSettings` |
| `alt_route` | `split` |
| `apartment_outlined`, `business_outlined` | `building` |
| `apps` | `grid` |
| `arrow_back` | `navBack` |
| `arrow_downward` | `arrowBottom` |
| `arrow_upward` | `arrowTop` |
| `assignment_outlined` | `task` |
| `attach_money`, `toll_outlined` | `currency` |
| `auto_awesome`, `auto_awesome_outlined` | `ai` |
| `autorenew`, `sync`, `sync_outlined` | `synchronize` |
| `badge`, `badge_outlined` | `badge` |
| `bar_chart_outlined` | `verticalBarChart` |
| `barcode_reader` | `barCode` |
| `block` | `cancel` |
| `broken_image_outlined` | `picture` |
| `build_outlined` | `wrench` |
| `business_center_outlined` | `suitcase` |
| `calendar_month_outlined`, `event_outlined` | `appointment` |
| `calendar_today_outlined` | `calendar` |
| `calendar_view_day_outlined` | `appointment2` |
| `calendar_view_week_outlined`, `date_range` | `timesheet` |
| `cameraswitch_outlined` | `camera` |
| `category_outlined` | `product` |
| `chat_bubble_outline` | `comment` |
| `check_circle`, `check_circle_outline`, `task_alt_outlined` | `sysEnter2` |
| `check_rounded` | `accept` |
| `chevron_left` | `slimArrowLeft` |
| `chevron_right` | `slimArrowRight` |
| `clear`, `close`, `close_rounded` | `decline` |
| `cloud_done_outlined` | `cloudCheck` |
| `cloud_off_outlined` | `disconnected` |
| `cloud_sync_outlined` | `cloud` |
| `cloud_upload_outlined` | `uploadToCloud` |
| `code` | `sourceCode` |
| `confirmation_number_outlined` | `incident` |
| `contact_support_outlined` | `sysHelp` |
| `copy_outlined` | `copy` |
| `dashboard_outlined` | `overviewChart` |
| `delete_outline` | `delete` |
| `description`, `description_outlined` | `documentText` |
| `directions_car_outlined` | `carRental` |
| `dns` | `itHost` |
| `domain_disabled_outlined` | `error` |
| `download_outlined`, `system_update` | `download` |
| `dynamic_feed`, `dynamic_feed_outlined`, `queue_outlined` | `workflowTasks` |
| `edit_outlined` | `edit` |
| `engineering_outlined` | `developerSettings` |
| `error_outline`, `error_outline_rounded` | `error` |
| `event_busy_outlined` | `timeOff` |
| `event_note_outlined` | `notes` |
| `expand_less` | `slimArrowUp` |
| `expand_more` | `slimArrowDown` |
| `extension_outlined` | `puzzle` |
| `filter_alt`, `filter_alt_outlined`, `filter_list` | `filter` |
| `filter_alt_off_outlined` | `clearFilter` |
| `first_page` | `sysFirstPage` |
| `flag_outlined` | `flag` |
| `flash_on` | `accelerated` |
| `forum_outlined` | `discussion` |
| `grid_view_outlined` | `widgets` |
| `groups`, `groups_outlined` | `group` |
| `history`, `history_outlined` | `history` |
| `home_outlined` | `home` |
| `hourglass_empty` | `busy` |
| `inbox_outlined` | `inbox` |
| `info_outline` | `information` |
| `insights`, `insights_outlined` | `trendUp` |
| `inventory_2_outlined` | `inventory` |
| `last_page` | `sysLastPage` |
| `lightbulb_outline` | `lightbulb` |
| `link_off` | `brokenLink` |
| `local_shipping_outlined` | `shippingStatus` |
| `location_on_outlined` | `map` |
| `lock_open_outlined` | `unlocked` |
| `lock_outline`, `lock_outline_rounded` | `locked` |
| `login`, `login_outlined` | `journeyArrive` |
| `logout` | `log` |
| `open_in_new`, `open_in_new_rounded` | `popupWindow` |
| `payments`, `payments_outlined` | `moneyBills` |
| `person_add_alt` | `addEmployee` |
| `person_off_outlined` | `employeeRejections` |
| `person_outline` | `personPlaceholder` |
| `person_search_outlined` | `employeeLookup` |
| `phone_outlined` | `phone` |
| `picture_as_pdf_outlined` | `pdfAttachment` |
| `pin_outlined` | `numberSign` |
| `play_arrow` | `mediaPlay` |
| `qr_code_2`, `qr_code_scanner` | `qrCode` |
| `radio_button_checked` | `circleTask2` |
| `radio_button_off`, `radio_button_unchecked` | `circleTask` |
| `receipt_long_outlined` | `receipt` |
| `refresh` | `refresh` |
| `remove` | `less` |
| `remove_circle_outline` | `sysMinus` |
| `report_problem_outlined`, `warning_amber_outlined`, `warning_amber_rounded` | `warning` |
| `restart_alt` | `reset` |
| `restaurant` | `meal` |
| `save_outlined` | `save` |
| `schedule`, `schedule_outlined` | `pending` |
| `search` | `search` |
| `search_off_outlined` | `sysFind` |
| `shield_outlined` | `shield` |
| `sort` | `sort` |
| `speed_outlined` | `performance` |
| `subtitles`, `subtitles_outlined` | `text` |
| `subtitles_off_outlined` | `strikethrough` |
| `sync_alt_outlined` | `journeyChange` |
| `sync_problem_rounded` | `unsynchronize` |
| `table_view_outlined` | `tableView` |
| `timer_outlined` | `fobWatch` |
| `travel_explore`, `travel_explore_outlined` | `globe` |
| `tune` | `customize` |
| `verified_outlined` | `verified` |
| `videocam` | `video` |
| `videocam_off` | `unwired` |
| `visibility_outlined` | `show` |

## Equivalências por aproximação

Estes não têm glifo idêntico na Lucide nem nome próprio no IconPool; a escolha segue o uso no portal:

- `domain_disabled_outlined` → `error`: telas "Configuração indisponível".
- `system_update` → `download`: botão e diálogo "Atualizar app".
- `toll_outlined` → `currency`: card de resumo de custos.
- `queue_outlined` → `workflowTasks`: botão "Reenfileirar".
- `pin_outlined` → `numberSign`: campos "Matrícula" e "Código".
- `contact_support_outlined` → `sysHelp`: resultado "dados insuficientes" do KBA.

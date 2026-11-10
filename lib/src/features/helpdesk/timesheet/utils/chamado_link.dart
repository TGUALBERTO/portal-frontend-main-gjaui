/// Link do chamado na ferramenta de origem (Verdana Desk / GLPI). O portal
/// espelha os apontamentos, mas o chamado em si — descrição, acompanhamentos,
/// anexos — continua vivendo lá.
library;

const String _verdanaDeskBase = 'https://grupojosealves.verdanadesk.com';

/// Página do chamado [origemId] no Verdana Desk — o `origemId` é o número
/// mostrado no portal (`#4242`), o mesmo id do ticket no GLPI.
Uri chamadoNoVerdanaDesk(int origemId) =>
    Uri.parse('$_verdanaDeskBase/front/ticket.form.php?id=$origemId');

/// Regras de negócio da contagem cega que valem em mais de uma camada.
library;

/// Quantas contagens **divergentes** o conferente pode fazer num item antes de
/// a NF-e inteira ser marcada para devolução.
///
/// Mora no domínio, e não só no controller, porque a reidratação
/// (`rehidratar_nota.dart`) reexecuta esta mesma regra sobre o log gravado no
/// SAP. Duas cópias sairiam de sincronia na primeira mudança, e a divergência
/// apareceria como "o item voltou a ficar pendente depois de reabrir".
const int maxTentativasContagem = 3;

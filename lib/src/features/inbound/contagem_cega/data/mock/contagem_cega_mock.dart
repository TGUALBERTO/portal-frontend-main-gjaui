import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_item.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';

/// Notas de demonstração da contagem cega.
///
/// Continua sendo a **fixture oficial** dos testes de widget e de controller
/// mesmo depois da integração SAP: os valores (quantidades 2/3/4/4 e 10/6,
/// lotes `C2212026`/vazio/`L240811`/vazio) são exatamente os casos que as regras
/// de contagem precisam cobrir, incluindo o mesmo item do XML em dois lotes.
///
/// Devolve uma lista **nova** a cada chamada: a conferência muta os itens, e
/// reaproveitar instâncias faria um novo check-in começar com o estado do
/// anterior.
List<ContagemNotaFiscal> mockNotasFiscais() => [
      const ContagemNotaFiscal(
        chave: 'AUT0000000000000001',
        chaveAcesso: '52260450143483000151550020000077961000213831',
        numero: '021.383',
        fornecedor: 'TRANSPOWER IND. LTDA',
        fornecedorCodigo: '0000105432',
        serie: '002',
        modelo: '55',
        itens: [
          ContagemItem(
            itemXml: '00010',
            loteNf: 'C2212026',
            pedidos: ['4501548574 / 00010'],
            quantidadeNf: 2,
            unidade: 'PC',
            materialSap: '6000857',
            descricaoSap: 'CORREIA VA 60',
            materialXml: '20015949',
            descricaoXml: 'A60 CORREIA IND TRANSPOWER 6000857',
          ),
          ContagemItem(
            itemXml: '00020',
            loteNf: '',
            pedidos: ['4501548574 / 00020'],
            quantidadeNf: 3,
            unidade: 'PC',
            materialSap: '6007897',
            descricaoSap: 'RETENTOR 70X90X10 VITON',
            materialXml: '20009480',
            descricaoXml: '01135=54 BRG RET 70X90X10 VITON NORD 6007897',
          ),
          // Mesmo item do XML em dois lotes — cada lote é uma contagem própria.
          ContagemItem(
            itemXml: '00030',
            loteNf: 'C2212026',
            pedidos: ['4501548574 / 00030'],
            quantidadeNf: 4,
            unidade: 'PC',
            materialSap: '6007898',
            descricaoSap: 'RETENTOR 52X72X12 VITON',
            materialXml: '9646',
            descricaoXml: '6567 BRAF RET 52X72X12 VITON 6007898',
          ),
          ContagemItem(
            itemXml: '00030',
            loteNf: 'C2212027',
            pedidos: ['4501548574 / 00030'],
            quantidadeNf: 4,
            unidade: 'PC',
            materialSap: '6007898',
            descricaoSap: 'RETENTOR 52X72X12 VITON',
            materialXml: '9646',
            descricaoXml: '6567 BRAF RET 52X72X12 VITON 6007898',
          ),
        ],
      ),
      const ContagemNotaFiscal(
        chave: 'AUT0000000000000002',
        chaveAcesso: '52260450143483000151550020000077961000198472',
        numero: '019.847',
        fornecedor: 'ROLTEC ROLAMENTOS SA',
        fornecedorCodigo: '0000108811',
        serie: '002',
        modelo: '55',
        itens: [
          ContagemItem(
            itemXml: '00010',
            loteNf: 'L240811',
            pedidos: ['4501549102 / 00010'],
            quantidadeNf: 10,
            unidade: 'PC',
            materialSap: '6001204',
            descricaoSap: 'ROLAMENTO 6205 ZZ',
            materialXml: 'RL6205',
            descricaoXml: 'ROLAMENTO RIGIDO ESFERAS 6205 ZZ C3',
          ),
          ContagemItem(
            itemXml: '00020',
            loteNf: '',
            pedidos: ['4501549102 / 00020'],
            quantidadeNf: 6,
            unidade: 'UN',
            materialSap: '6003310',
            descricaoSap: 'GRAXA EP2 BALDE 20KG',
            materialXml: 'GX-EP2-20',
            descricaoXml: 'GRAXA LITIO EP2 BALDE 20KG',
          ),
        ],
      ),
    ];

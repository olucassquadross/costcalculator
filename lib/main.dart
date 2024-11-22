import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cost_calculator/login_page.dart';
import 'package:cost_calculator/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://rsuuthhutfzncdsmkekl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzdXV0aGh1dGZ6bmNkc21rZWtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjcxMzk5MjYsImV4cCI6MjA0MjcxNTkyNn0.V25pq2ve711JjKDsFW5NkA6u-lllCg2jzLLY4WqHWIc',
  );

  final session = Supabase.instance.client.auth.currentSession;
  runApp(CostCalculatorApp(session: session));
}

class CostCalculatorApp extends StatelessWidget {

  final Session? session;

  // Alterando o construtor para incluir o parâmetro key e torná-lo const
  const CostCalculatorApp({super.key, this.session});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cálculo de Custo de Produto Final',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: session != null ? MenuPage() : LoginPage(),
    );
  }

}

class CostCalculatorHomePage extends StatefulWidget {
  @override
  _CostCalculatorHomePageState createState() => _CostCalculatorHomePageState();
}

class _CostCalculatorHomePageState extends State<CostCalculatorHomePage> {
  // Definindo os controladores para os campos de texto
  final TextEditingController nomeProdutoController = TextEditingController(text: '40/20 BB 20L');
  final TextEditingController materiaPrimaController = TextEditingController(text: '31.20');
  final TextEditingController embalagemController = TextEditingController(text: '1.51');
  final TextEditingController precoVendaController = TextEditingController(text: '67.50');

  // Adicionando controladores para os novos campos
  final TextEditingController qtdeMeses100Controller = TextEditingController();
  final TextEditingController qtdeMeses40Controller = TextEditingController();
  final TextEditingController qtdeMeses60Controller = TextEditingController();

  // Variáveis para armazenar os valores calculados
  double qtMeses100Ref = 0.0;
  double qtMeses40Ref = 0.0;
  double qtMeses60Ref = 0.0;

  double custoProducaoRef = 0.0;
  double financeiroRef = 0.0;
  double impostoRef = 0.0;
  double freteRef = 0.0;
  double comissao1Ref = 0.00;
  double comissao2Ref = 0.00;


  @override
  void initState() {
    super.initState();

    // Realiza os cálculos iniciais para que os valores de referência sejam atualizados no início
    calcularCustoProducao();
    calcularQtMeses100();
    calcularQtMeses40();
    calcularQtMeses60();
    calcularImposto();
    calcularFrete();
    calcularComissao1Ref();
    calcularComissao2Ref();
    calcularPrecoVenda();  // Recalcula os valores associados ao preço de venda

    // Se houver dependência de campos do dropdown, isso pode ser incluído também
    calcularReferencias();
  }


  // Alterar a função para controlar a habilitação/desabilitação
  bool isQtdeMeses100Enabled = false;
  bool isQtdeMeses40Enabled = false;
  bool isQtdeMeses60Enabled = false;

  // Chave global para capturar o widget invisível
  GlobalKey _globalKey = GlobalKey();

  // Controlador de captura de tela
  ScreenshotController screenshotController = ScreenshotController();

  // Definindo os valores para os select/dropdown
  String tipoProduto = 'Foliar';
  String custoProducaoPercentual = '14%';
  String imposto = 'BA';
  String frete = '1.00';
  String financeiro = '3.0%';
  String comissao1 = '0%';
  String comissao2 = '0%';

  // Dados dos intervalos de seleção (baseado na descrição fornecida)
  final List<String> custoProducaoOptions = [
    '1%', '2%', '3%', '4%', '5%', '6%', '7%', '8%', '9%', '10%',
    '11%', '12%', '13%', '14%', '15%', '16%', '17%', '18%', '19%', '20%'
  ];

  final List<String> tipoProdutoOptions = ['Foliar', 'Adjuvante'];

  final List<String> impostoOptions = [
    'BA', 'EXPORT', 'AC', 'AL', 'AM', 'AP', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RN',
    'RS', 'RJ', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  final List<String> freteOptions = [
    'Grande SP', 'Centro SP', 'Interior SP', 'Nordeste', '0.00', '1.00', '2.00', '3.00', '4.00', '5.00', '6.00', '7.00'
  ];

  final List<String> financeiroOptions = [
    'Sem Financeiro', 'Safra 100%', 'Safra 40% 60%', '1.5%', '3.0%', '4.5%',
    '6.0%', '7.5%', '9.0%', '10.5%', '12.0%'
  ];

  final List<String> comissaoOptions = List.generate(21, (index) => '$index%');

  // Valida entradas para aceitar apenas porcentagem ou valores numéricos
  // bool _isValidPercentage(String value) {
  //   final regex = RegExp(r'^\d+(\.\d+)?%?$');
  //   return regex.hasMatch(value);
  // }

  bool _isValidPercentageWithComma(String value) {
    final regex = RegExp(r'^\d+(\,\d+)?%?$');
    return regex.hasMatch(value);
  }

  String _replaceCommaWithDot(String value) {
    return value.replaceAll(',', '.');
  }


  void calcularQtMeses100() {
    setState(() {
      if (_isValidPercentageWithComma(qtdeMeses100Controller.text)) {
        String porcentagemStr = _replaceCommaWithDot(qtdeMeses100Controller.text);
        double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
        double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
        // Corrigindo o cálculo para utilizar corretamente a fórmula
        qtMeses100Ref = precoVenda * porcentagem * 0.015 * 100; // Multiplicação ajustada
      } else {
        qtMeses100Ref = 0.00;
      }
    });
  }

  void calcularQtMeses40() {
    setState(() {
      if (_isValidPercentageWithComma(qtdeMeses40Controller.text)) {
        String porcentagemStr = _replaceCommaWithDot(qtdeMeses40Controller.text);
        double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
        double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
        qtMeses40Ref = (precoVenda * 0.40) * porcentagem * 0.015 * 100; // Corrigido
      } else {
        qtMeses40Ref = 0.00;
      }
    });
  }

  void calcularQtMeses60() {
    setState(() {
      if (_isValidPercentageWithComma(qtdeMeses60Controller.text)) {
        String porcentagemStr = _replaceCommaWithDot(qtdeMeses60Controller.text);
        double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
        double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
        qtMeses60Ref = (precoVenda * 0.60) * porcentagem * 0.015 * 100; // Corrigido
      } else {
        qtMeses60Ref = 0.00;
      }
    });
  }




  void onFinanceiroChanged(String? newValue) {
    setState(() {
      financeiro = newValue!;

      // Atualizar habilitação/desabilitação com base no valor selecionado
      if (financeiro == 'Safra 100%') {
        isQtdeMeses100Enabled = true;
        isQtdeMeses40Enabled = false;
        isQtdeMeses60Enabled = false;

        qtdeMeses40Controller.clear();
        qtdeMeses60Controller.clear();
        qtMeses40Ref = 0.0;
        qtMeses60Ref = 0.0;
      } else if (financeiro == 'Safra 40% 60%') {
        isQtdeMeses100Enabled = false;
        isQtdeMeses40Enabled = true;
        isQtdeMeses60Enabled = true;

        qtdeMeses100Controller.clear();
        qtMeses100Ref = 0.0;
      } else {
        isQtdeMeses100Enabled = false;
        isQtdeMeses40Enabled = false;
        isQtdeMeses60Enabled = false;

        qtdeMeses100Controller.clear();
        qtdeMeses40Controller.clear();
        qtdeMeses60Controller.clear();
        qtMeses100Ref = 0.0;
        qtMeses40Ref = 0.0;
        qtMeses60Ref = 0.0;
      }

      calcularReferencias();  // Calcula as referências ao alterar o financeiro
    });
  }

  // void calcularMateriaPrima() {
  //   setState(() {
  //     if (_isValidPercentageWithComma(materiaPrimaController.text)) {
  //       String porcentagemStr = _replaceCommaWithDot(materiaPrimaController.text);
  //       double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
  //     }
  //     // Sempre recalcular o Custo de Produção após qualquer alteração
  //     calcularCustoProducao();
  //   });
  // }

  void calcularMateriaPrima() {
    setState(() {
      // Verifica se o valor contém vírgula e substitui por ponto para cálculos
      if (_isValidPercentageWithComma(materiaPrimaController.text)) {
        String valor = _replaceCommaWithDot(materiaPrimaController.text);
        double materiaPrima = double.tryParse(valor) ?? 0.0; // Valor numérico com ponto para os cálculos
        // Aqui você pode continuar o cálculo normalmente
      }
      // Recalcular o custo de produção
      calcularCustoProducao();
    });
  }



// // Cálculo para "Embalagem"
//   void calcularEmbalagem() {
//     if (_isValidPercentageWithComma(embalagemController.text)) {
//       String porcentagemStr = _replaceCommaWithDot(embalagemController.text);
//       double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
//       // Lógica para utilizar a porcentagem no cálculo
//       setState(() {});
//     }
//   }

  void calcularEmbalagem() {
    setState(() {
      if (_isValidPercentageWithComma(embalagemController.text)) {
        String porcentagemStr = _replaceCommaWithDot(embalagemController.text);
        double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
      }
      // Recalcula o custo de produção
      calcularCustoProducao();
    });
  }


// Cálculo para "Preço Venda (Sugestão)"
//   void calcularPrecoVenda() {
//     if (_isValidPercentageWithComma(precoVendaController.text)) {
//       String porcentagemStr = _replaceCommaWithDot(precoVendaController.text);
//       double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
//       // Lógica para utilizar a porcentagem no cálculo
//       setState(() {});
//       calcularImposto();
//     }
//   }

  void calcularPrecoVenda() {
    setState(() {
      // Tenta converter o valor inserido no campo para um número decimal
      try {
        double precoVenda = double.parse(_replaceCommaWithDot(precoVendaController.text));

        // Recalcular imposto e outras variáveis que dependem do preço de venda
        calcularImposto();
        comissao1Ref = calcularComissao1Ref();
        comissao2Ref = calcularComissao2Ref();

        // Recalcular qtde meses com base no novo valor do preço de venda
        calcularQtMeses100();
        calcularQtMeses40();
        calcularQtMeses60();

      } catch (e) {
        print("Erro ao converter o preço de venda para número: $e");
      }
    });
  }


  // void onFinanceiroChanged(String? newValue) {
  //   setState(() {
  //     financeiro = newValue!;
  //
  //     // Atualizar habilitação/desabilitação com base no valor selecionado
  //     if (financeiro == 'Safra 100%') {
  //       isQtdeMeses100Enabled = true;
  //       isQtdeMeses40Enabled = false;
  //       isQtdeMeses60Enabled = false;
  //       qtdeMeses40Controller.clear();
  //       qtdeMeses60Controller.clear();
  //     } else if (financeiro == 'Safra 40% 60%') {
  //       isQtdeMeses100Enabled = false;
  //       isQtdeMeses40Enabled = true;
  //       isQtdeMeses60Enabled = true;
  //       qtdeMeses100Controller.clear();
  //     } else {
  //       isQtdeMeses100Enabled = false;
  //       isQtdeMeses40Enabled = false;
  //       isQtdeMeses60Enabled = false;
  //       qtdeMeses100Controller.clear();
  //       qtdeMeses40Controller.clear();
  //       qtdeMeses60Controller.clear();
  //     }
  //   });
  // }

  Future<void> _exportImage() async {
    try {
      setState(() {}); // Força o widget a ser atualizado

      // Adicionar um atraso para garantir que o widget esteja completamente renderizado
      await Future.delayed(Duration(milliseconds: 300));

      RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null && !boundary.debugNeedsPaint) {
        var image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        // Salvar a imagem temporariamente
        final directory = await getTemporaryDirectory();
        final imagePath = File('${directory.path}/exported_image.png');
        await imagePath.writeAsBytes(pngBytes);

        // Compartilhar a imagem usando shareXFiles
        final XFile xFile = XFile(imagePath.path);
        await Share.shareXFiles([xFile], text: 'Confira o nome do produto e preço de venda.');
      } else {
        print("Boundary não encontrado ou o widget precisa ser pintado novamente.");
      }
    } catch (e) {
      print("Erro ao capturar o widget: $e");
    }
  }

  // Função para calcular o valor da referência
  void calcularReferencias() {
    setState(() {
      // Se o campo "Financeiro" for igual a "Safra 100%" ou "Safra 40% 60%", as referências devem ser 0.00
      if (financeiro == 'Safra 100%' || financeiro == 'Safra 40% 60%') {
        qtMeses100Ref = 0.00;
        qtMeses40Ref = 0.00;
        qtMeses60Ref = 0.00;
      } else {
        // Calcula o valor para "Qtde Meses até 100%"
        if (isQtdeMeses100Enabled && _isValidPercentageWithComma(qtdeMeses100Controller.text)) {
          String porcentagemStr = _replaceCommaWithDot(qtdeMeses100Controller.text);
          double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
          double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
          qtMeses100Ref = precoVenda * porcentagem * 0.015;
        }

        // Calcula o valor para "Qtde Meses até 40%"
        if (isQtdeMeses40Enabled && _isValidPercentageWithComma(qtdeMeses40Controller.text)) {
          String porcentagemStr = _replaceCommaWithDot(qtdeMeses40Controller.text);
          double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
          double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
          qtMeses40Ref = (precoVenda * 0.40) * porcentagem * 0.015;
        }

        // Calcula o valor para "Qtde Meses até 60%"
        if (isQtdeMeses60Enabled && _isValidPercentageWithComma(qtdeMeses60Controller.text)) {
          String porcentagemStr = _replaceCommaWithDot(qtdeMeses60Controller.text);
          double porcentagem = double.parse(porcentagemStr.replaceAll('%', '')) / 100;
          double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
          qtMeses60Ref = (precoVenda * 0.60) * porcentagem * 0.015;
        }
      }
    });
  }

  void calcularImposto() {
    setState(() {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');

      if (tipoProduto == 'Foliar') {
        if (imposto == 'EXPORT') {
          // Multiplicar Preço de Venda por 8.5%
          impostoRef = precoVenda * 0.085;
        } else if (['AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'PA', 'PB', 'PE', 'PI', 'RN', 'RO', 'RR', 'TO'].contains(imposto)) {
          // Multiplicar Preço de Venda por 9.834%
          impostoRef = precoVenda * 0.09834;
        } else if (['MG', 'PR', 'RS', 'RJ', 'SC'].contains(imposto)) {
          // Multiplicar Preço de Venda por 13.644%
          impostoRef = precoVenda * 0.13644;
        } else if (imposto == 'SP') {
          // Multiplicar Preço de Venda por 4.5%
          impostoRef = precoVenda * 0.045;
        } else {
          impostoRef = 0.0; // Valor padrão caso o imposto não esteja mapeado
        }
      } else if (tipoProduto == 'Adjuvante') {
        double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');

        if (imposto == 'EXPORT') {
          impostoRef = precoVenda * 0.085;
        } else if (imposto == 'AC' || imposto == 'AL' || imposto == 'AM' ||
            imposto == 'AP' || imposto == 'BA' || imposto == 'CE' || imposto == 'DF' ||
            imposto == 'ES' || imposto == 'GO' || imposto == 'MA' || imposto == 'MT' ||
            imposto == 'MS' || imposto == 'PA' || imposto == 'PB' || imposto == 'PE' ||
            imposto == 'PI' || imposto == 'RN' || imposto == 'RO' || imposto == 'RR' ||
            imposto == 'BA' || imposto == 'TO') {
          impostoRef = precoVenda * 0.08196;
        } else if (imposto == 'MG' || imposto == 'PR' || imposto == 'RS' || imposto == 'RJ' ||
            imposto == 'SC') {
          impostoRef = precoVenda * 0.10836;
        } else if (imposto == 'SP') {
          impostoRef = precoVenda * 0.045;
        }
      }
    });
  }


  void calcularFrete() {
    setState(() {
      if (frete == 'Grande SP') {
        freteRef = 2.50;
      } else if (frete == 'Centro SP') {
        freteRef = 3.00;
      } else if (frete == 'Interior SP') {
        freteRef = 1.50;
      } else if (frete == 'Nordeste') {
        freteRef = 1.50;
      } else {
        freteRef = double.parse(frete);
      }
    });
  }


  // // Funções de cálculo
  // double calcularCustoProducao() {
  //   double custoProducaoPercent = double.parse(custoProducaoPercentual.replaceAll('%', ''));
  //   double materiaPrima = double.parse(materiaPrimaController.text != '' ? materiaPrimaController.text : '0.00');
  //   double embalagem = double.parse(embalagemController.text != '' ? embalagemController.text : '0.00');
  //   stdout.write((materiaPrima + embalagem) * (custoProducaoPercent / 100));
  //   custoProducaoRef = (materiaPrima + embalagem) * (custoProducaoPercent / 100);
  //   return custoProducaoRef;
  // }

  double calcularCustoProducao() {
    double materiaPrima = double.tryParse(materiaPrimaController.text != '' ? materiaPrimaController.text : '0.00') ?? 0.00;
    double embalagem = double.tryParse(embalagemController.text != '' ? embalagemController.text : '0.00') ?? 0.00;
    double custoProducaoPercent = double.parse(custoProducaoPercentual.replaceAll('%', ''));
    custoProducaoRef = (materiaPrima + embalagem) * (custoProducaoPercent / 100);

    // Recalcula o valor e atualiza a tela
    setState(() {});

    return custoProducaoRef;
  }


  double calcularCustoLiquido() {
    double materiaPrima = double.parse(materiaPrimaController.text != '' ? materiaPrimaController.text : '0.00');
    double embalagem = double.parse(embalagemController.text != '' ? embalagemController.text : '0.00');
    double custoProducao = calcularCustoProducao();
    return materiaPrima + embalagem + custoProducao;
  }

  // Funções de cálculo
  // double calcularComissao1Ref() {
  //   double comissao1value = double.parse(comissao1.replaceAll('%', ''));
  //   double precovenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
  //   stdout.write(precovenda * (comissao1value / 100));
  //   return precovenda * (comissao1value / 100);
  // }
  double calcularComissao1Ref() {
    double comissao1value = double.parse(comissao1.replaceAll('%', ''));
    double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
    return precoVenda * (comissao1value / 100);  // Certifique-se de que o cálculo esteja correto
  }


  // Funções de cálculo
  // double calcularComissao2Ref() {
  //   double comissao2value = double.parse(comissao2.replaceAll('%', ''));
  //   double precovenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
  //   stdout.write(precovenda * (comissao2value / 100));
  //   return precovenda * (comissao2value / 100);
  // }
  double calcularComissao2Ref() {
    double comissao2value = double.parse(comissao2.replaceAll('%', ''));
    double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
    return precoVenda * (comissao2value / 100);  // Certifique-se de que o cálculo esteja correto
  }


  double calcularCustoBruto() {
    double custoLiquido = calcularCustoLiquido();

    double totalAdicional = 0.0; // Implementar a lógica para somar os valores relacionados a E16-E22
    // double impostoRef = 0.0;
    // double freteRef = 0.0;
    // double financeiroRef = 0.0;
    // double comissao1Ref = 0.00;
    // double comissao2Ref = 0.00;
    double total = 0.0;

    if (comissao1 == '0%') {
      comissao1Ref = 0.00;
    } else {
      comissao1Ref = calcularComissao1Ref();
    }

    if (comissao2 == '0%') {
      comissao2Ref = 0.00;
    } else {
      comissao2Ref = calcularComissao2Ref();
    }

    if (financeiro == 'Sem Financeiro' || financeiro == 'Safra 100%' || financeiro == 'Safra 40% 60%') {
      financeiroRef = 0.00;
    } else if (financeiro == '1.5%') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
      if (precoVenda == 0.00) {
        financeiroRef = 0.00;
      } else {
        financeiroRef = precoVenda * 0.015;
      }
    } else if (financeiro == '3.0%') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
      if (precoVenda == 0.00) {
        financeiroRef = 0.00;
      } else {
        financeiroRef = precoVenda * 0.03;
      }
    } else if (financeiro == '4.5%') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
      if (precoVenda == 0.00) {
        financeiroRef = 0.00;
      } else {
        financeiroRef = precoVenda * 0.045;
      }
    } else if (financeiro == '6.0%') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
      if (precoVenda == 0.00) {
        financeiroRef = 0.00;
      } else {
        financeiroRef = precoVenda * 0.06;
      }
    } else if (financeiro == '7.5%') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
      if (precoVenda == 0.00) {
        financeiroRef = 0.00;
      } else {
        financeiroRef = precoVenda * 0.075;
      }
    } else if (financeiro == '9.0%') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
      if (precoVenda == 0.00) {
        financeiroRef = 0.00;
      } else {
        financeiroRef = precoVenda * 0.09;
      }
    } else if (financeiro == '10.5%') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
      if (precoVenda == 0.00) {
        financeiroRef = 0.00;
      } else {
        financeiroRef = precoVenda * 0.15;
      }
    } else if (financeiro == '12.0%') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
      if (precoVenda == 0.00) {
        financeiroRef = 0.00;
      } else {
        financeiroRef = precoVenda * 0.12;
      }
    }

    if (frete == 'Grande SP') {
      freteRef = 2.50;
    } else if (frete == 'Centro SP') {
      freteRef = 3.00;
    } else if (frete == 'Interior SP') {
      freteRef = 1.50;
    } else if (frete == 'Nordeste') {
      freteRef = 1.50;
    } else {
      freteRef = double.parse(frete);
      stdout.write(freteRef);
    }

    if (tipoProduto == 'Foliar') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');

      if (imposto == 'EXPORT') {
        // Multiplicar Preço de Venda por 8.5%
        impostoRef = precoVenda * 0.085;
      } else if (['AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'PA', 'PB', 'PE', 'PI', 'RN', 'RO', 'RR', 'TO'].contains(imposto)) {
        // Multiplicar Preço de Venda por 9.834%
        impostoRef = precoVenda * 0.09834;
      } else if (['MG', 'PR', 'RS', 'RJ', 'SC'].contains(imposto)) {
        // Multiplicar Preço de Venda por 13.644%
        impostoRef = precoVenda * 0.13644;
      } else if (imposto == 'SP') {
        // Multiplicar Preço de Venda por 4.5%
        impostoRef = precoVenda * 0.045;
      } else {
        impostoRef = 0.0; // Valor padrão caso o imposto não esteja mapeado
      }
    } else if (tipoProduto == 'Adjuvante') {
      double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');

      if (imposto == 'EXPORT') {
        impostoRef = precoVenda * 0.085;
      } else if (imposto == 'AC' || imposto == 'AL' || imposto == 'AM' ||
          imposto == 'AP' || imposto == 'BA' || imposto == 'CE' || imposto == 'DF' ||
          imposto == 'ES' || imposto == 'GO' || imposto == 'MA' || imposto == 'MT' ||
          imposto == 'MS' || imposto == 'PA' || imposto == 'PB' || imposto == 'PE' ||
          imposto == 'PI' || imposto == 'RN' || imposto == 'RO' || imposto == 'RR' ||
          imposto == 'BA' || imposto == 'TO') {
        impostoRef = precoVenda * 0.08196;
      } else if (imposto == 'MG' || imposto == 'PR' || imposto == 'RS' || imposto == 'RJ' ||
          imposto == 'SC') {
        impostoRef = precoVenda * 0.10836;
      } else if (imposto == 'SP') {
        impostoRef = precoVenda * 0.045;
      }
    }

    double precoVendaSug = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
    if (precoVendaSug <= 0) {
      return 0;
    } else {
      if (financeiro == "Safra 100%") {
        total = custoLiquido + impostoRef + freteRef + financeiroRef + qtMeses100Ref + comissao1Ref + comissao2Ref;
      } else if (financeiro == "Safra 40% 60%") {
        total = custoLiquido + impostoRef + freteRef + financeiroRef + qtMeses40Ref + qtMeses60Ref + comissao1Ref + comissao2Ref;
      } else {
        total = custoLiquido + impostoRef + freteRef + financeiroRef + comissao1Ref + comissao2Ref;
      }
    }

    return total;
  }

  double calcularMargemBruta() {
    double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
    double custoBruto = calcularCustoBruto();
    return precoVenda != 0 ? ((precoVenda - custoBruto) / precoVenda) * 100 : 0;
  }

  double calcularLucroBruto() {
    double precoVenda = double.parse(precoVendaController.text != '' ? precoVendaController.text : '0.00');
    return precoVenda - calcularCustoBruto();
  }

  void onValueChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5.0, left: 45.8), // Espaço entre a imagem e o título
              child: Container(
                width: 60,
                height: 60,
                child: Image.asset(
                  'assets/logo.png',  // Caminho da imagem
                  fit: BoxFit.cover,  // Ajusta a imagem para cobrir o espaço disponível
                ),
              ),
            ),
            // Container(
            //   width: 60,
            //   height: 60,
            //   child: Image.asset(
            //     'assets/logo.png',  // Caminho da imagem
            //     fit: BoxFit.cover,  // Ajusta a imagem para cobrir o espaço disponível
            //   ),
            // ),
            const SizedBox(width: 10), // Espaço para garantir que o texto não toque a imagem
            const Text(
              'CÁLCULO DE CUSTO \n DE PRODUTO FINAL',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 115, 31),
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ],
        ),
        toolbarHeight: 80,
        backgroundColor: Color.fromARGB(255, 241, 241, 241),
      ),
      body: Padding(
        padding: const EdgeInsets.only(right: 26.0, top: 26.0, left: 26.0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20), // Espaço entre a imagem e o título
              child: TextField(
                controller: nomeProdutoController,
                decoration: InputDecoration(
                  labelText: 'NOME PRODUTO',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Restante dos campos
            // TextField(
            //   controller: nomeProdutoController,
            //   decoration: InputDecoration(
            //     labelText: 'NOME PRODUTO',
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            SizedBox(height: 20),
            buildInputRow('Matéria Prima', materiaPrimaController, calcularMateriaPrima),
            SizedBox(height: 10),
            buildInputRow('Embalagem', embalagemController, calcularEmbalagem),
            SizedBox(height: 5),
            buildDropdownRow(
              'Custo Produção',
              custoProducaoPercentual,
                  (String? newValue) {
                setState(() {
                  custoProducaoPercentual = newValue!;
                });
              },
              custoProducaoOptions,
            ),
            Text('Referêcia \$${custoProducaoRef.toStringAsFixed(2)}'),

            SizedBox(height: 20),

            buildCalculationRow('CUSTO LÍQUIDO', calcularCustoLiquido().toStringAsFixed(2)),
            SizedBox(height: 20),
            buildInputRow('Preço Venda (Sugestão)', precoVendaController, calcularPrecoVenda),
            buildDropdownRow(
              'Tipo de Produto',
              tipoProduto,
                  (String? newValue) {
                setState(() {
                  tipoProduto = newValue!;
                });
              },
              tipoProdutoOptions,
            ),
            buildDropdownRow(
              'Imposto',
              imposto,
                  (String? newValue) {
                setState(() {
                  imposto = newValue!;
                  calcularImposto();  // Chame a função ao alterar o valor
                });
              },
              impostoOptions,
            ),
            Text('Referência: \$${impostoRef.toStringAsFixed(2)}'),

            SizedBox(height: 20),

            buildDropdownRow(
              'Frete',
              frete,
                  (String? newValue) {
                setState(() {
                  frete = newValue!;
                  calcularFrete();  // Chame a função ao alterar o valor
                });
              },
              freteOptions,
            ),
            Text('Referência: \$${freteRef.toStringAsFixed(2)}'),

            SizedBox(height: 20),

            buildDropdownRow(
              'Financeiro',
              financeiro,
              onFinanceiroChanged,
              financeiroOptions,
            ),
            Text('Referêcia: \$${financeiroRef.toStringAsFixed(2)}'),

            SizedBox(height: 20),

            // Campo "Qtde Meses até 100%"
            buildInputRow('Qtde Meses até 100%', qtdeMeses100Controller, calcularQtMeses100, enabled: isQtdeMeses100Enabled, isInteger: true),
            Text('Referência: \$${qtMeses100Ref.toStringAsFixed(2)}'),
            SizedBox(height: 20),

            // Campo "Qtde Meses até 40%"
            buildInputRow('Qtde Meses até 40%', qtdeMeses40Controller, calcularQtMeses40, enabled: isQtdeMeses40Enabled, isInteger: true),
            Text('Referência: \$${qtMeses40Ref.toStringAsFixed(2)}'),
            SizedBox(height: 20),

            // Campo "Qtde Meses até 60%"
            buildInputRow('Qtde Meses até 60%', qtdeMeses60Controller, calcularQtMeses60, enabled: isQtdeMeses60Enabled, isInteger: true),
            Text('Referência: \$${qtMeses60Ref.toStringAsFixed(2)}'),
            SizedBox(height: 20),



            buildDropdownRow(
              'Comissão 1',
              comissao1,
                  (String? newValue) {
                setState(() {
                  comissao1 = newValue!;
                  comissao1Ref = calcularComissao1Ref();  // Recalcula o valor de referência
                });
              },
              comissaoOptions,
            ),
            Text('Referência: \$${comissao1Ref.toStringAsFixed(2)}'),
            SizedBox(height: 20),

            buildDropdownRow(
              'Comissão 2',
              comissao2,
                  (String? newValue) {
                setState(() {
                  comissao2 = newValue!;
                  comissao2Ref = calcularComissao2Ref();  // Recalcula o valor de referência
                });
              },
              comissaoOptions,
            ),
            Text('Referência: \$${comissao2Ref.toStringAsFixed(2)}'),
            SizedBox(height: 20),
            buildCalculationRow('CUSTO BRUTO', calcularCustoBruto().toStringAsFixed(2)),
            // buildCalculationRow('MARGEM BRUTA', calcularMargemBruta().round().toString() + '%'),
            buildMargemBrutaRow('MARGEM BRUTA', calcularMargemBruta()),
            buildCalculationRow('LUCRO BRUTO', 'R\$ ' + calcularLucroBruto().toStringAsFixed(2)),

            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _exportImage,
              icon: Icon(Icons.share),
              label: Text('Exportar'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 255, 115, 31), // Cor do texto e ícone
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Opacity(
        opacity: 0.01, // Invisível, mas ainda renderizado
        child: RepaintBoundary(
          key: _globalKey,
          child: Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image.asset('assets/logo1.png', width: 100, height: 100),
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: 100,
                    height: 71,
                    child: Image.asset(
                      'assets/logo1.png',  // Caminho da imagem
                      fit: BoxFit.cover,  // Ajusta a imagem para cobrir o espaço disponível
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  nomeProdutoController.text,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Preço: R\$ ${precoVendaController.text}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),

      // Adicionar o BottomNavigationBar aqui
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),  // Ícone da casa
            label: 'Início',         // Texto abaixo do ícone
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),  // Ícone de menu com três barras
            label: 'Menu',           // Texto abaixo do ícone
          ),
        ],
        selectedItemColor: Color.fromARGB(255, 255, 115, 31),  // Cor dos ícones selecionados (laranja neste exemplo)
        unselectedItemColor: Colors.grey,
        currentIndex: 0,  // Define o índice atual como a página inicial
        onTap: _onItemTapped, // Função que lida com a navegação
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Navega para a página de menu substituindo a tela atual
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MenuPage()),
      );
    }
  }

  // Widget buildInputRow(String label, TextEditingController controller, Function() onChanged, {bool enabled = true, bool isInteger = false}) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: Text(
  //           label,
  //           style: TextStyle(fontSize: 16),
  //         ),
  //       ),
  //       SizedBox(width: 10),
  //       Expanded(
  //         child: TextField(
  //           controller: controller,
  //           keyboardType: TextInputType.number,
  //           enabled: enabled,
  //           inputFormatters: isInteger ? [FilteringTextInputFormatter.digitsOnly] : [], // Apenas inteiros se isInteger for true
  //           decoration: InputDecoration(
  //             border: OutlineInputBorder(),
  //             labelText: isInteger ? 'Número' : '%',  // Mostra 'Número' se for campo de inteiro
  //           ),
  //           onChanged: (value) {
  //             if (isInteger) {
  //               // Garante que apenas números inteiros sejam digitados
  //               if (int.tryParse(value) == null) {
  //                 controller.text = '';
  //               }
  //             }
  //             onChanged();
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }


  Widget buildInputRow(String label, TextEditingController controller, Function() onChanged, {bool enabled = true, bool isInteger = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            enabled: enabled,
            inputFormatters: isInteger ? [FilteringTextInputFormatter.digitsOnly] : [],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: isInteger ? 'Número' : 'Valor',
            ),
            onChanged: (value) {
              // Substitui vírgula por ponto para cálculos
              if (value.contains(',')) {
                controller.text = value.replaceAll(',', '.');
                controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
              }
              onChanged();
            },
            onSubmitted: (value) {
              // Substituir vírgula por ponto para cálculos
              controller.text = value.replaceAll(',', '.');
              onChanged();
            },
          ),
        ),
      ],
    );
  }



  Widget buildDropdownRow(String label, String value, ValueChanged<String?> onChanged, List<String> options) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget buildMargemBrutaRow(String label, double value) {
    Color color;

    if (value < 10) {
      color = Colors.red;  // Margem menor que 10, fica vermelho
    } else if (value >= 10 && value < 30) {
      color = Colors.yellow;  // Margem entre 10 e 30, fica amarelo
    } else {
      color = Colors.green;  // Margem maior que 30, fica verde
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 115, 31)),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            value.round().toString() + '%',  // Arredonda o valor e exibe como inteiro
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,  // A cor é determinada dinamicamente com base no valor
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }



  Widget buildCalculationRow(String label, String value) {
    return Row(
      children: [
      Expanded(
      child: Text(
      label,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 115, 31)
      ),
    ),
    ),
    SizedBox(width: 10),
    Expanded(
    child: Text(
      value,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
      ),
      ],
    );
  }
}

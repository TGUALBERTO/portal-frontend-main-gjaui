import 'package:gjamobile/src/imports/imports.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Abre o scanner de QR Code em tela cheia e devolve o código lido (ou `null`
/// se o usuário cancelar/fechar sem ler nada). Trata a permissão de câmera.
///
/// Só é chamado em Android/iOS — nas demais plataformas as telas nem exibem o
/// botão de scan (ver `PlatformInfo.isMobile`).
Future<String?> showQrScannerScreen(
  BuildContext context, {
  String title = 'Ler QR Code',
}) async {
  final permission = await PermissionService.instance.request(Permission.camera);
  final granted = permission.fold((status) => status.isGranted, (_) => false);
  if (!granted) {
    if (context.mounted) {
      showToast(
        context,
        message: 'Permissão de câmera negada. Habilite nas configurações do dispositivo.',
        status: 'warning',
      );
    }
    return null;
  }

  if (!context.mounted) return null;
  return Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => QrScannerScreen(title: title),
    ),
  );
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.title = 'Ler QR Code'});

  final String title;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(GjaIcons.accelerated),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(GjaIcons.camera),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: (context, error) => AppErrorWidget(
          title: 'Câmera indisponível',
          message: error.errorDetails?.message ?? error.errorCode.name,
        ),
      ),
    );
  }
}

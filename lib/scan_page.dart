import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ads.dart';
import 'history.dart';

/// Hoja con el contenido leído: copiar, abrir (si es enlace) o compartir.
Future<void> showResultSheet(BuildContext context, String text) {
  final uri = Uri.tryParse(text);
  final openable = uri != null &&
      const ['http', 'https', 'tel', 'mailto'].contains(uri.scheme);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text, style: Theme.of(ctx).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                if (openable)
                  FilledButton.icon(
                    onPressed: () => launchUrl(uri,
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir'),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Copiado')));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      SharePlus.instance.share(ShareParams(text: text)),
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.active});

  /// La cámara solo se enciende mientras esta pestaña está visible.
  final bool active;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    autoStart: false,
  );
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.start();
  }

  @override
  void didUpdateWidget(ScanPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _controller.start();
    } else if (!widget.active && old.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (_busy || value == null || value.isEmpty) return;
    _busy = true;
    HapticFeedback.mediumImpact();
    await HistoryStore.instance.add(value, scanned: true);
    if (!mounted) return;
    await showResultSheet(context, value);
    AdService.instance.maybeShowInterstitial();
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No se pudo usar la cámara. Revisa el permiso en Ajustes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: IconButton.filledTonal(
            onPressed: _controller.toggleTorch,
            icon: const Icon(Icons.flashlight_on),
            tooltip: 'Linterna',
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'ads.dart';
import 'history.dart';

enum QrKind { text, wifi, phone, email }

extension on QrKind {
  String get label => switch (this) {
        QrKind.text => 'Texto / URL',
        QrKind.wifi => 'WiFi',
        QrKind.phone => 'Teléfono',
        QrKind.email => 'Correo',
      };
}

String _escapeWifi(String s) =>
    s.replaceAllMapped(RegExp(r'([\\;,:"])'), (m) => '\\${m[1]}');

class GeneratePage extends StatefulWidget {
  const GeneratePage({super.key});

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  final _main = TextEditingController();
  final _extra = TextEditingController();
  final _qrKey = GlobalKey();
  QrKind _kind = QrKind.text;
  String _wifiSecurity = 'WPA';
  String? _data;

  @override
  void dispose() {
    _main.dispose();
    _extra.dispose();
    super.dispose();
  }

  String get _mainLabel => switch (_kind) {
        QrKind.text => 'Texto o enlace',
        QrKind.wifi => 'Nombre de la red (SSID)',
        QrKind.phone => 'Número de teléfono',
        QrKind.email => 'Correo electrónico',
      };

  String? _buildPayload() {
    final main = _main.text.trim();
    if (main.isEmpty) return null;
    return switch (_kind) {
      QrKind.text => main,
      QrKind.phone => 'tel:$main',
      QrKind.email => 'mailto:$main',
      QrKind.wifi =>
        'WIFI:T:$_wifiSecurity;S:${_escapeWifi(main)};P:${_escapeWifi(_extra.text)};;',
    };
  }

  void _generate() {
    FocusScope.of(context).unfocus();
    final payload = _buildPayload();
    if (payload == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Escribe algo primero')));
      return;
    }
    setState(() => _data = payload);
    HistoryStore.instance.add(payload, scanned: false);
    AdService.instance.maybeShowInterstitial();
  }

  Future<void> _share() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 4);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    AdService.instance.maybeShowInterstitial();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final k in QrKind.values)
              ChoiceChip(
                label: Text(k.label),
                selected: _kind == k,
                onSelected: (_) => setState(() {
                  _kind = k;
                  _data = null;
                  _main.clear();
                  _extra.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _main,
          keyboardType: _kind == QrKind.phone
              ? TextInputType.phone
              : _kind == QrKind.email
                  ? TextInputType.emailAddress
                  : TextInputType.text,
          maxLines: _kind == QrKind.text ? 3 : 1,
          decoration: InputDecoration(
              labelText: _mainLabel, border: const OutlineInputBorder()),
        ),
        if (_kind == QrKind.wifi) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _extra,
            decoration: const InputDecoration(
                labelText: 'Contraseña', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _wifiSecurity,
            decoration: const InputDecoration(
                labelText: 'Seguridad', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('Sin contraseña')),
            ],
            onChanged: (v) => setState(() => _wifiSecurity = v ?? 'WPA'),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Generar código QR'),
        ),
        if (_data != null) ...[
          const SizedBox(height: 24),
          Center(
            child: RepaintBoundary(
              key: _qrKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(data: _data!, size: 240),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share),
            label: const Text('Compartir imagen'),
          ),
        ],
      ],
    );
  }
}

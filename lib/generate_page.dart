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

IconData _kindIcon(QrKind k) => switch (k) {
      QrKind.text => Icons.link,
      QrKind.wifi => Icons.wifi,
      QrKind.phone => Icons.phone,
      QrKind.email => Icons.mail,
    };

const _qrColors = <Color>[
  Color(0xFF111827),
  Color(0xFF4F46E5),
  Color(0xFF0D9488),
  Color(0xFFE11D48),
  Color(0xFFEA580C),
  Color(0xFF7C3AED),
];

InputDecoration _fieldDec(String label) => InputDecoration(
      labelText: label,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );

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
  int _color = 0;
  bool _rounded = true;

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
    final theme = Theme.of(context);
    final qrColor = _qrColors[_color];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.qr_code_2, color: Colors.white, size: 40),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Crea códigos QR de enlaces, WiFi, teléfonos y correos en segundos.',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final k in QrKind.values)
              ChoiceChip(
                avatar: Icon(_kindIcon(k), size: 18),
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
          decoration: _fieldDec(_mainLabel),
        ),
        if (_kind == QrKind.wifi) ...[
          const SizedBox(height: 12),
          TextField(controller: _extra, decoration: _fieldDec('Contraseña')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _wifiSecurity,
            decoration: _fieldDec('Seguridad'),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('Sin contraseña')),
            ],
            onChanged: (v) => setState(() => _wifiSecurity = v ?? 'WPA'),
          ),
        ],
        const SizedBox(height: 16),
        Text('Estilo', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _qrColors.length; i++)
              GestureDetector(
                onTap: () => setState(() => _color = i),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: _qrColors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _color == i
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            FilterChip(
              label: const Text('Redondeado'),
              selected: _rounded,
              onSelected: (v) => setState(() => _rounded = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _generate,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generar código QR'),
        ),
        if (_data != null) ...[
          const SizedBox(height: 24),
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: qrColor.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: QrImageView(
                      data: _data!,
                      size: 240,
                      eyeStyle: QrEyeStyle(
                        eyeShape:
                            _rounded ? QrEyeShape.circle : QrEyeShape.square,
                        color: qrColor,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: _rounded
                            ? QrDataModuleShape.circle
                            : QrDataModuleShape.square,
                        color: qrColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _share,
            icon: const Icon(Icons.share),
            label: const Text('Compartir imagen'),
          ),
        ],
      ],
    );
  }
}

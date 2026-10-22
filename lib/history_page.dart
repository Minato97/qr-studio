import 'package:flutter/material.dart';

import 'history.dart';
import 'scan_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HistoryStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.entries.isEmpty) {
          return const Center(child: Text('Aún no hay códigos'));
        }
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: store.clear,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Borrar todo'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: store.entries.length,
                itemBuilder: (context, i) {
                  final e = store.entries[i];
                  return Dismissible(
                    key: ValueKey('${e.time.microsecondsSinceEpoch}${e.text}'),
                    onDismissed: (_) => store.remove(e),
                    background: Container(color: Colors.redAccent),
                    child: ListTile(
                      leading: Icon(e.scanned ? Icons.qr_code_scanner : Icons.qr_code_2),
                      title: Text(e.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${e.scanned ? 'Escaneado' : 'Creado'} · ${_fmt(e.time)}'),
                      onTap: () => showResultSheet(context, e.text),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

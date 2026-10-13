import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/csv_import.dart';

/// 개발자용 과거 기록 가져오기(Spec 3.7). PC에서 tools/import_statements.py로 만든 CSV를 읽는다.
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  String? _message;
  bool _busy = false;

  Future<void> _pickAndImport() async {
    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(dialogTitle: '거래 CSV 선택');
      if (file == null) return;
      if (!file.name.toLowerCase().endsWith('.csv')) {
        setState(() => _message = 'CSV 파일을 골라 주세요 (${file.name})');
        return;
      }
      final rows = parseTransactionsCsv(utf8.decode(await file.readAsBytes()));
      final result = await importTransactions(ref.read(databaseProvider), rows);
      setState(
        () => _message =
            '${file.name}\n새로 ${result.inserted}건, 이미 있던 ${result.skipped}건'
            '${result.firstDate != null ? '\n첫 기록일 ${result.firstDate!.toString().substring(0, 10)}' : ''}',
      );
    } catch (e) {
      setState(() => _message = '가져오지 못했어요: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('과거 기록 가져오기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'PC에서 tools/import_statements.py로 만든 CSV(예: transactions_v3.csv)를 폰에 옮긴 뒤 골라 주세요. '
            '같은 파일을 다시 가져와도 중복되지 않아요.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pickAndImport,
            icon: const Icon(Icons.file_open_outlined),
            label: Text(_busy ? '가져오는 중…' : 'CSV 파일 선택'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(padding: const EdgeInsets.all(16), child: Text(_message!)),
            ),
          ],
        ],
      ),
    );
  }
}

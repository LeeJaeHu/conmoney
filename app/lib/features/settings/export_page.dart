import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app_providers.dart';
import '../../data/export_repository.dart';
import '../../ui/insets.dart';

/// 데이터 내보내기: DB 전체(SQLite) 또는 거래 CSV를 폰 저장소에 저장한다. PC에서 SQL로 분석하는 용도.
class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  String? _message;
  bool _busy = false;

  String get _stamp {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save(String fileName, String mimeType, Future<Uint8List> Function(ExportRepository) build) async {
    setState(() => _busy = true);
    try {
      final bytes = await build(ExportRepository(ref.read(databaseProvider)));
      final uri = await FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: mimeType, dialogTitle: '저장할 곳 선택');
      setState(() => _message = uri == null ? '저장을 취소했어요' : '$fileName 저장했어요 (${(bytes.length / 1024).ceil()}KB)');
    } catch (e) {
      setState(() => _message = '내보내지 못했어요: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('데이터 내보내기')),
      body: ListView(
        padding: pagePadding(context),
        children: [
          Text('PC로 옮겨 SQL로 분석할 수 있게 내 기록을 파일로 저장해요.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _save(
                    'conmoney_$_stamp.sqlite',
                    'application/vnd.sqlite3',
                    (r) async => r.sqliteSnapshot(await getTemporaryDirectory()),
                  ),
            icon: const Icon(Icons.storage_outlined),
            label: const Text('DB 전체 (SQLite)'),
          ),
          const SizedBox(height: 4),
          Text('모든 테이블(거래·할부·정기 지출·예산 등). 날짜·시각 열은 유닉스 초예요.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _save('conmoney_transactions_$_stamp.csv', 'text/csv', (r) async => utf8.encode(await r.transactionsCsv())),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('거래만 (CSV)'),
          ),
          const SizedBox(height: 4),
          Text('거래 한 건이 한 줄, 카드·카테고리는 이름으로. 알림 원문은 빠져요.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_message != null) Text(_message!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Text(
            '실제 결제 내역이에요. 받은 파일은 git이나 외부 서비스에 올리지 마세요. DB 파일에는 알림 원문(가려진 이름 포함)도 들어 있어요.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

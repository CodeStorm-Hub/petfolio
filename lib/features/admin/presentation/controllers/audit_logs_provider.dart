import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/audit_log.dart';
import '../../data/repositories/admin_repository.dart';

part 'audit_logs_provider.g.dart';

@riverpod
Future<List<AuditLog>> auditLogs(Ref ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchAuditLogs(limit: 50);
}

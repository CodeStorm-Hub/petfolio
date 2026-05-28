// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(auditLogs)
final auditLogsProvider = AuditLogsProvider._();

final class AuditLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AuditLog>>,
          List<AuditLog>,
          FutureOr<List<AuditLog>>
        >
    with $FutureModifier<List<AuditLog>>, $FutureProvider<List<AuditLog>> {
  AuditLogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditLogsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditLogsHash();

  @$internal
  @override
  $FutureProviderElement<List<AuditLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AuditLog>> create(Ref ref) {
    return auditLogs(ref);
  }
}

String _$auditLogsHash() => r'746bfb3ac85a8950b5aa43fa6eeb6fbf76e29001';

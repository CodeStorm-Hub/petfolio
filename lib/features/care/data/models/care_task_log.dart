import 'care_task.dart';

extension CareTaskLogDerived on CareTask {
  bool get isLogDerived => id.startsWith('log:');
}

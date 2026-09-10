// Compatibility entry point for existing file-backed tests and legacy readers.
// Current application storage is injected into the shared domain repository.
import 'local_recurring_expense_repository.dart';
export 'local_recurring_expense_repository.dart';

typedef FileRecurringExpenseRepository = LocalRecurringExpenseRepository;

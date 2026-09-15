import 'expense_workflow_models.dart';
import 'expense_input_validation.dart';
import 'expense_editor_record_codec.dart';
import 'expense_line_draft_input.dart';

/// Recoverable expense input; the codec is independent of presentation.
class ExpenseDraftInput {
  ExpenseDraftInput({
    required this.expenseId,
    required this.receiptSourceId,
    required this.receiptSourceRevision,
    required this.receiptImageCount,
    required this.baseRecord,
    required this.baseRevision,
    required this.pendingLine,
    required this.ownerId,
    required this.ownerLabel,
    required this.jobId,
    required this.date,
    required this.category,
    required this.receiptType,
    required this.prepareMaterialsReview,
    required this.correctionReason,
    required this.vendor,
    required this.amount,
    required this.subtotal,
    required this.salesTax,
    required this.job,
    required List<ExpenseLineItem> lines,
  }) : lines = List.unmodifiable(lines);

  final String expenseId;
  final String? receiptSourceId;
  final int? receiptSourceRevision;
  final int receiptImageCount;
  final ExpenseRecord? baseRecord;
  final int? baseRevision;
  final PendingExpenseLineInput? pendingLine;
  final String ownerId;
  final String ownerLabel;
  final String? jobId;
  final DateTime date;
  final ExpenseCategory category;
  final ExpenseReceiptType receiptType;
  final bool prepareMaterialsReview;
  final String correctionReason;
  final String vendor;
  final String amount;
  final String subtotal;
  final String salesTax;
  final String job;
  final List<ExpenseLineItem> lines;

  Map<String, Object?> toPayload() => {
    'expenseId': expenseId,
    'receiptSourceId': receiptSourceId,
    'receiptSourceRevision': receiptSourceRevision,
    'receiptImageCount': receiptImageCount,
    'baseRecord': baseRecord == null
        ? null
        : encodeExpenseEditorRecord(baseRecord!),
    'baseRevision': baseRevision,
    'pendingLine': pendingLine?.toPayload(),
    'ownerId': ownerId,
    'ownerLabel': ownerLabel,
    'jobId': jobId,
    'date': date.toIso8601String(),
    'category': category.name,
    'receiptType': receiptType.name,
    'prepareMaterialsReview': prepareMaterialsReview,
    'correctionReason': correctionReason,
    'vendor': vendor,
    'amount': amount,
    'subtotal': subtotal,
    'salesTax': salesTax,
    'job': job,
    'lines': lines.map(encodeExpenseEditorLine).toList(),
  };

  factory ExpenseDraftInput.fromPayload(Map<String, Object?> value) =>
      ExpenseDraftInput(
        expenseId: value['expenseId'] as String,
        receiptSourceId: value['receiptSourceId'] as String?,
        receiptSourceRevision: value['receiptSourceRevision'] as int?,
        receiptImageCount: value['receiptImageCount'] as int? ?? 0,
        baseRecord: value['baseRecord'] == null
            ? null
            : decodeExpenseEditorRecord(
                (value['baseRecord'] as Map).cast<String, Object?>(),
              ),
        baseRevision: value['baseRevision'] as int?,
        pendingLine: value['pendingLine'] == null
            ? null
            : PendingExpenseLineInput.fromPayload(
                (value['pendingLine'] as Map).cast<String, Object?>(),
              ),
        ownerId: value['ownerId'] as String,
        ownerLabel: value['ownerLabel'] as String,
        jobId: value['jobId'] as String?,
        date: DateTime.parse(value['date'] as String),
        category: ExpenseCategory.values.byName(value['category'] as String),
        receiptType: ExpenseReceiptType.values.byName(
          value['receiptType'] as String,
        ),
        prepareMaterialsReview: value['prepareMaterialsReview'] as bool,
        correctionReason: value['correctionReason'] as String? ?? '',
        vendor: value['vendor'] as String? ?? '',
        amount: value['amount'] as String? ?? '',
        subtotal: value['subtotal'] as String? ?? '',
        salesTax: value['salesTax'] as String? ?? '',
        job: value['job'] as String? ?? '',
        lines: (value['lines'] as List)
            .map(
              (line) => decodeExpenseEditorLine(
                (line as Map).cast<String, Object?>(),
              ),
            )
            .toList(),
      );

  ExpenseRecord confirmedRecord() {
    if ((receiptType == ExpenseReceiptType.basic
                ? validateOptionalExpenseMoney(amount)
                : validateRequiredExpenseMoney(amount)) !=
            null ||
        validateOptionalExpenseMoney(subtotal) != null ||
        validateOptionalExpenseMoney(salesTax) != null) {
      throw StateError('Complete valid expense amounts before confirmation.');
    }
    if (pendingLine != null) {
      throw StateError('Finish or discard the unfinished item.');
    }
    if (receiptType == ExpenseReceiptType.detailed && lines.isEmpty) {
      throw StateError('A detailed receipt requires at least one item.');
    }
    double? money(String value) => value.trim().isEmpty
        ? null
        : double.tryParse(value.replaceAll(',', '').trim());
    final total = money(amount);
    final sub =
        money(subtotal) ??
        lines.fold<double>(0, (sum, line) => sum + line.total);
    final tax = money(salesTax) ?? 0;
    if ((receiptType == ExpenseReceiptType.detailed && vendor.trim().isEmpty) ||
        (receiptType == ExpenseReceiptType.detailed && total == null) ||
        (total != null && (!total.isFinite || total < 0)) ||
        !sub.isFinite ||
        !tax.isFinite ||
        sub < 0 ||
        tax < 0) {
      throw StateError(
        'Expense amounts and vendor must be valid before confirmation.',
      );
    }
    final jobLabel = job.trim().isEmpty ? null : job.trim();
    final base = baseRecord;
    if (base != null) {
      return base.copyWith(
        date: date,
        vendor: vendor.trim(),
        category: category,
        amount: total,
        job: jobLabel,
        receiptType: receiptType,
        lineItems: lines,
        receiptSubtotal: sub > 0 ? sub : null,
        salesTax: tax,
        prepareMaterialsReview:
            receiptType == ExpenseReceiptType.detailed &&
            prepareMaterialsReview,
        requiresSubmitterAttention: false,
        submitterAttentionReason: null,
        receiptStatus: base.requiresSubmitterAttention
            ? 'Receipt reviewed'
            : base.receiptStatus,
      );
    }
    return ExpenseRecord(
      id: expenseId,
      vendor: vendor.trim(),
      category: category,
      amount: total,
      date: date,
      owner: ownerLabel,
      paidByEmployeeId: ownerId,
      job: jobLabel,
      jobId: jobId,
      receiptStatus: receiptImageCount > 0
          ? 'Receipt attached'
          : 'No receipt attached',
      receiptType: receiptType,
      receiptImageCount: receiptImageCount,
      lineItems: lines,
      receiptSubtotal: sub > 0 ? sub : null,
      salesTax: tax,
      prepareMaterialsReview: prepareMaterialsReview,
    );
  }
}

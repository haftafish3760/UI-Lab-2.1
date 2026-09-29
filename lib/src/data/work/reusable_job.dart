import '../storage/local_record_identity.dart';
import 'models/work_models.dart';
import 'work_record_detail_codec.dart';

/// Common work, deliberately without a customer, schedule or document lifecycle.
class ReusableJob {
  ReusableJob({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.pricing,
    required List<WorkLineItem> items,
  }) : items = List.unmodifiable(items.map((item) => _copyItem(item, item.id)));

  final String id, ownerId, title, description;
  final WorkPricingModel pricing;
  final List<WorkLineItem> items;

  factory ReusableJob.fromWork(WorkRecord record, {required String ownerId}) {
    final id = newLocalRecordIdentity('reusable-job');
    return ReusableJob(
      id: id,
      ownerId: ownerId,
      title: record.title,
      description: record.detail,
      pricing: record.pricing,
      items: [
        if (record.items.isEmpty && record.total > 0)
          WorkLineItem(
            id: '$id-service-price',
            type: WorkLineItemType.service,
            name: record.title,
            description: record.detail,
            quantity: 1,
            unit: 'job',
            customerPrice: record.total,
          ),
        for (var i = 0; i < record.items.length; i++)
          _copyItem(record.items[i], '$id-item-$i'),
      ],
    );
  }

  List<WorkLineItem> itemsForNewJob(String jobId) => List.unmodifiable([
    for (var i = 0; i < items.length; i++)
      _copyItem(items[i], '$jobId-item-$i'),
  ]);

  Map<String, Object?> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'title': title,
    'description': description,
    'pricing': pricing.name,
    'items': items.map(encodeWorkLineItem).toList(),
  };

  factory ReusableJob.fromJson(Map<String, Object?> data) {
    final items = (data['items'] as List)
        .map(
          (item) => decodeWorkLineItem(Map<String, Object?>.from(item as Map)),
        )
        .toList();
    final value = ReusableJob(
      id: data['id'] as String,
      ownerId: data['ownerId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      pricing: WorkPricingModel.values.byName(data['pricing'] as String),
      items: items,
    );
    if (value.id.trim().isEmpty ||
        value.ownerId.trim().isEmpty ||
        value.title.trim().isEmpty ||
        items.map((i) => i.id).toSet().length != items.length ||
        items.any(
          (i) =>
              i.id.isEmpty ||
              i.name.trim().isEmpty ||
              !i.quantity.isFinite ||
              i.quantity <= 0 ||
              i.workerCount < 1 ||
              !i.customerPrice.isFinite ||
              i.customerPrice < 0 ||
              !i.total.isFinite,
        )) {
      throw const FormatException(
        'Enter a reusable job name and valid item prices.',
      );
    }
    return value;
  }
}

WorkLineItem _copyItem(WorkLineItem item, String id) => WorkLineItem(
  id: id,
  type: item.type,
  name: item.name,
  description: item.description,
  quantity: item.quantity,
  workerCount: item.workerCount,
  unit: item.unit,
  customerPrice: item.customerPrice,
);

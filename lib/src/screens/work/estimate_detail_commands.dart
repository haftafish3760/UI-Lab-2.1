part of 'estimate_detail_screen.dart';

extension _EstimateDetailCommands on _EstimateDetailScreenState {
  Future<void> _editItems() async {
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    if (work != null) {
      final result = await Navigator.of(context).push<List<WorkLineItem>>(
        MaterialPageRoute(
          builder: (_) => StoredEstimateItemsEditor(
            record: _record,
            work: work,
            editingFromReview: true,
          ),
        ),
      );
      if (!mounted || result == null) return;
      final saved = work.records
          .where((record) => record.id == _record.id)
          .firstOrNull;
      if (saved != null) await _update(saved);
      return;
    }

    final items = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => EstimateItemsScreen(
          initialItems: _record.items,
          editingFromReview: true,
          pricing: _record.pricing,
          selectedDay: _record.estimateDates?.createdOn ?? _record.createdOn,
        ),
      ),
    );
    if (!mounted || items == null) return;
    await _update(_record.reviseItems(items, changedOn: DateTime.now()));
  }

  Future<void> _editEstimate({EstimateReviewSection? section}) async {
    final updated = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateEditorScreen(
          initialDay:
              _record.estimateDates?.createdOn ??
              _record.createdOn ??
              DateTime.now(),
          initialRecord: _record,
          initialSection: section,
        ),
      ),
    );
    if (mounted && updated != null) await _update(updated);
  }

  Future<void> _preview() async {
    final action = await Navigator.of(context).push<WorkDocumentPreviewAction>(
      MaterialPageRoute(
        builder: (_) => WorkDocumentPreviewScreen(
          record: _record,
          canDeliverCustomerCopy:
              widget.permissions.canSend &&
              _record.companyReviewAllowsCustomerApproval,
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case WorkDocumentPreviewAction.createJob:
        widget.onCreateJob(_record);
      case WorkDocumentPreviewAction.deliver:
        await _prepareDelivery();
    }
  }

  Future<void> _prepareDelivery() async {
    if (!_record.companyReviewAllowsCustomerApproval) {
      _showCompanyReviewRequired();
      return;
    }
    final delivery = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateDeliveryScreen(record: _record),
      ),
    );
    if (!mounted || delivery == null) return;
    await _update(delivery);
  }

  Future<void> _recordCustomerApproval({bool createJobAfter = false}) async {
    if (_saving || !widget.permissions.canRecordCustomerApproval) return;
    if (!_record.companyReviewAllowsCustomerApproval) {
      _showCompanyReviewRequired();
      return;
    }
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    if (work != null && !work.permissions.canRecordCustomerApproval) return;
    final approved = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) => EstimateApprovalScreen(record: _record),
      ),
    );
    if (!mounted || approved == null) return;
    await _update(approved);
    if (mounted && createJobAfter && _record.hasCurrentCustomerApproval) {
      widget.onCreateJob(_record);
    }
  }

  Future<void> _createApprovedJob() async {
    if (_record.hasCurrentCustomerApproval &&
        _record.resolvedEstimateStage == EstimateStage.approved) {
      widget.onCreateJob(_record);
    } else {
      await _recordCustomerApproval(createJobAfter: true);
    }
  }

  Future<void> _collectSignature({bool forBusiness = false}) async {
    final access = PrototypeOperationsScope.maybeOf(
      context,
    )?.workSession?.permissions;
    if (_saving ||
        (forBusiness
            ? !widget.permissions.canEditItems
            : (!widget.permissions.canCollectSignature ||
                  (access != null && !access.canCollectSignature)))) {
      return;
    }
    if (!forBusiness && !_record.companyReviewAllowsCustomerApproval) {
      _showCompanyReviewRequired();
      return;
    }
    final signed = await Navigator.of(context).push<WorkRecord>(
      MaterialPageRoute(
        builder: (_) =>
            EstimateSignatureScreen(record: _record, forBusiness: forBusiness),
      ),
    );
    if (!mounted || signed == null) return;
    await _update(signed);
  }

  Future<void> _update(WorkRecord record) async {
    if (_saving || identical(record, _record)) return;
    final work = PrototypeOperationsScope.maybeOf(context)?.workSession;
    if (work == null) {
      _refreshActions(() => _record = record);
      widget.onUpdated(record);
      return;
    }
    _refreshActions(() => _saving = true);
    final current = work.records
        .where((item) => item.id == record.id)
        .firstOrNull;
    if (current == null ||
        current.kind != WorkRecordKind.estimate ||
        record.id != _record.id) {
      _refreshActions(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This estimate is no longer available.')),
      );
      return;
    }
    final alreadySaved =
        canonicalJson(encodeWorkRecord(current)) ==
        canonicalJson(encodeWorkRecord(record));
    final saved =
        alreadySaved ||
        await work.save(
          records: [record],
          expectedStorageRevisions: {record.id: _baseStorageRevision},
        );
    if (!mounted) return;
    _refreshActions(() {
      _saving = false;
      if (saved) {
        _record = record;
        _baseStorageRevision = work.storageRevisionFor(record.id);
      }
    });
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            work.failureMessage ??
                'The estimate was not saved. Previous values remain active.',
          ),
        ),
      );
    }
  }
}

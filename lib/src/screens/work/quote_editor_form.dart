part of 'quote_editor_screen.dart';

extension _QuoteEditorForm on _QuoteEditorScreenState {
  Widget _buildForm() => guardDraftNavigation(
    Scaffold(
      key: const ValueKey('quote-editor'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: insets.copyWith(top: 10, bottom: 32),
              children: [
                WorkDetailHeader(
                  label: _base == null ? 'New quote' : 'Edit quote',
                  selectedDay: widget.initialDay,
                  onBack: leaveDraftRoute,
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (!_ready && _error == null) const LinearProgressIndicator(),
                if (_ready) ...[
                  EditorDraftStatus(
                    state: navigationDraft!.state,
                    onRetry: navigationDraft!.retry,
                  ),
                  DocumentFormOverview(
                    groups: [
                      [
                        DocumentFormSection(
                          title: 'Client information',
                          summary: _client ?? 'Select or add a client',
                          icon: Icons.person_outline,
                          onTap: _clientPicker,
                        ),
                        TextField(
                          key: const ValueKey('quote-number'),
                          controller: _number,
                          readOnly: _base != null,
                          decoration: const InputDecoration(
                            labelText: 'Quote number',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey('quote-title'),
                          controller: _title,
                          decoration: const InputDecoration(
                            labelText: 'Job title',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey('quote-description'),
                          controller: _description,
                          minLines: 3,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Description of work',
                          ),
                        ),
                      ],
                      [
                        if (canUseWorkServicePrice(_id, _items))
                          DocumentAmountField(
                            key: const ValueKey('quote-price'),
                            label: 'Fixed price',
                            controller: _price,
                          ),
                        TextButton.icon(
                          onPressed: _editItems,
                          icon: const Icon(Icons.list_alt_outlined),
                          label: Text(
                            _pendingItems != null
                                ? 'Finish quote items'
                                : _items.isEmpty
                                ? 'Add itemized prices (optional)'
                                : 'Edit items (${_items.length})',
                          ),
                        ),
                        if (!canUseWorkServicePrice(_id, _items))
                          Text(
                            'Items total: \$${_items.fold<double>(0, (sum, item) => sum + item.total).toStringAsFixed(2)}',
                          ),
                        DocumentAmountField(
                          label: 'Discount',
                          controller: _discount,
                        ),
                        const SizedBox(height: 12),
                        DocumentAmountField(label: 'Tax', controller: _tax),
                      ],
                      [
                        TextField(
                          key: const ValueKey('quote-terms'),
                          controller: _terms,
                          minLines: 3,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Terms and exclusions',
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: _chooseExpiry,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(
                                _expires == null
                                    ? 'Add expiration date (optional)'
                                    : 'Valid until ${MaterialLocalizations.of(context).formatMediumDate(_expires!)}',
                              ),
                            ),
                            if (_expires != null)
                              TextButton(
                                onPressed: () {
                                  _clearExpiry();
                                },
                                child: const Text('Clear date'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  ListenableBuilder(
                    listenable: Listenable.merge(_fields.toList()),
                    builder: (context, _) => Text(
                      'Quote total: ${_money((_subtotal - (double.tryParse(_discount.text) ?? 0) + (double.tryParse(_tax.text) ?? 0)).clamp(0, double.infinity))}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.icon(
                      key: const ValueKey('save-quote'),
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Save quote'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

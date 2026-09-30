part of 'estimate_editor_screen.dart';

extension _EstimateValidity on _EstimateEditorScreenState {
  String get _validityDescription {
    if (_validityDays == null) {
      return _expiresOn == null
          ? 'Not selected — choose a validity period.'
          : 'Valid through ${_date(context, _expiresOn!)}';
    }
    final sent = _sentOn;
    final period =
        'Price guaranteed for $_validityDays days from the date sent';
    if (sent == null) return '$period. Date sent not recorded.';
    final end = DateTime(sent.year, sent.month, sent.day + _validityDays!);
    return '$period. Valid through ${_date(context, end)}.';
  }

  Future<void> _chooseCustomValidity() async {
    final controller = TextEditingController(
      text: _validityDays?.toString() ?? '',
    );
    final form = GlobalKey<FormState>();
    final days = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Custom validity period'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of days'),
            validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
                ? null
                : 'Enter a whole number greater than zero.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialog, int.parse(controller.text));
              }
            },
            child: const Text('Use period'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (mounted && days != null) {
      _changeEstimateInput(() {
        _validityDays = days;
        _expiresOn = null;
      });
    }
  }
}

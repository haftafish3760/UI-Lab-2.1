/// Sections that can be opened directly from an estimate review.
enum EstimateReviewSection {
  customer('Customer information'),
  work('Work details'),
  dates('Estimate dates'),
  items('Labor and materials'),
  terms('Service terms and deposit'),
  pricing('Discount and tax'),
  photos('Estimate photos');

  const EstimateReviewSection(this.label);
  final String label;
  String get editingTitle => 'Editing ${label.toLowerCase()}';
}

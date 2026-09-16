const inventoryTradeAssets = <String, String>{
  'Plumbing': 'plumbing',
  'Electrical': 'electrical',
  'HVAC': 'hvac',
  'Carpentry': 'carpentry',
  'Drywall': 'drywall',
  'Painting': 'painting',
  'Roofing': 'roofing',
  'Tile': 'tile',
  'Insulation': 'insulation',
  'Fencing': 'fencing',
  'Masonry and Concrete': 'masonry_concrete',
  'Landscaping': 'landscaping',
  'Low Voltage and Data': 'low_voltage_data',
  'Tools and Safety': 'tools_safety',
};

String? inventoryTradeImage(String trade) {
  final name = inventoryTradeAssets[trade];
  return name == null ? null : 'assets/inventory/trades/$name.png';
}

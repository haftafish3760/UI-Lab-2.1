class WorkSupplyLocalePack {
  const WorkSupplyLocalePack({
    required this.id,
    required this.languageCode,
    required this.countryCodes,
    required this.label,
    required this.measurementSystem,
    required this.receiptLanguage,
  });

  final String id;
  final String languageCode;
  final List<String> countryCodes;
  final String label;
  final String measurementSystem;
  final String receiptLanguage;
}

const workSupplyLocalePackEnUsId = 'en-US';
const workSupplyLocalePackEnUsCountryCodes = ['US'];

const workSupplyLocalePackEnUs = WorkSupplyLocalePack(
  id: workSupplyLocalePackEnUsId,
  languageCode: 'en',
  countryCodes: workSupplyLocalePackEnUsCountryCodes,
  label: 'English - United States',
  measurementSystem: 'us-customary',
  receiptLanguage: 'english',
);

const workSupplyLocalePackEsUs = WorkSupplyLocalePack(
  id: 'es-US',
  languageCode: 'es',
  countryCodes: ['US', 'PR'],
  label: 'Spanish - United States',
  measurementSystem: 'us-customary',
  receiptLanguage: 'spanish',
);

const workSupplyLocalePackEnCa = WorkSupplyLocalePack(
  id: 'en-CA',
  languageCode: 'en',
  countryCodes: ['CA'],
  label: 'English - Canada',
  measurementSystem: 'metric-with-trade-imperial',
  receiptLanguage: 'english',
);

const workSupplyLocalePackFrCa = WorkSupplyLocalePack(
  id: 'fr-CA',
  languageCode: 'fr',
  countryCodes: ['CA'],
  label: 'French - Canada',
  measurementSystem: 'metric-with-trade-imperial',
  receiptLanguage: 'french',
);

const workSupplyPriorityLocalePacks = [
  workSupplyLocalePackEnUs,
  workSupplyLocalePackEsUs,
  workSupplyLocalePackEnCa,
  workSupplyLocalePackFrCa,
];

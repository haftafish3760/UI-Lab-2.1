# Language and Measurement Blueprint

Status: confirmed cross-cutting product contract 0.1  
Last updated: 2026-09-01  
Applies to: onboarding, every screen, receipts, materials, inventory, Work,
documents, reports, search, storage, import/export, and later 5.7 integration

## 1. First-run contract

Authority clarification: multilingual operation, regional variants and metric/
U.S. measurements including parsing are ACCEPTED/CANONICAL (D11). The exact
launch locale list, onboarding order and fallback below are an existing PLANNED
configuration pending evidence/decision U06; current catalog implementation is
not owner approval or full translation coverage.

The first onboarding question is:

> Choose a language

The three release-one choices are:

- **English** (`en-US`);
- **Español** (`es-US`, U.S. Spanish suitable for service-business users);
- **Français** (`fr-CA`, Canadian French).

The choice must be understandable before an account exists, work offline, and
change the remainder of onboarding immediately. The organization may provide a
default, but each authorized person keeps a personal display-language
preference. Changing display language never changes stored business truth,
permissions, or another person's preference.

The first-run measurement question uses only these plain-language choices:

- **U.S. — miles, feet, inches, gallons, and quarts**;
- **Metric — kilometers, meters, centimeters, liters, and milliliters**.

Customer-facing UI must not call the first choice `Imperial`. Language,
measurement system, currency, tax rules, date format, and document locale are
separate preferences. A U.S. company may choose Metric and a Canadian company
may retain a supplier's U.S. package measurement.

## 2. Localization architecture

- User-facing strings live in one shared Flutter localization catalog, with
  English, U.S. Spanish, and Canadian French resources. Screens do not create
  private translation maps or persist translated labels as record identity.
- Stable codes own statuses, permissions, categories, units, and actions.
  Localized labels are display projections of those codes.
- The selected locale controls ordinary dates, times, number separators,
  currency display, pluralization, address presentation, and PDF labels.
- Original customer, vendor, receipt, part, and user-entered text remains
  exactly as entered. Translation never silently rewrites evidence.
- Search indexes original text plus safe normalized aliases. Search does not
  reveal records or fields the person lacks permission to view.
- English is the offline fallback for a genuinely missing translation. A
  missing key is a test/release defect; it is not permission to ship a screen
  partially translated without notice.
- Spanish and French wording must be reviewed as service-business language,
  not accepted solely because a machine translation produced it.

### Current UI Lab implementation boundary — 2026-09-01

- `lib/l10n/` is the one generated Flutter catalog. It currently contains the
  release-one regional locales plus their required base-language fallbacks.
  The generated `app_localizations*.dart` outputs are reproducible build
  artifacts and are the sole exception to the authored 500-line source guard;
  they are never manually split or edited. The ARB catalogs and handwritten
  localization extensions remain subject to normal review and size limits.
- `AppPreferencesController` owns stable `AppLanguage` and
  `AppMeasurementSystem` values. The development default remains English/U.S.;
  onboarding and durable preference persistence are intentionally still
  deferred.
- The app shell, bottom/desktop navigation, prototype advertisement labels,
  and shared calendar controls, weekdays, record kinds, dates, and semantics
  now read from the catalog. Every module receives this calendar localization
  through the one shared calendar component.
- The shared operational header now projects Technician/Admin, View,
  Employee/Vehicle/Active Vehicle, and Company/Fleet Overview from stable enum
  identities. Dynamic employee names and vehicle names remain unchanged user
  data. Module-specific header titles, settings labels, context details, and
  primary-action text remain part of the unfinished screen-body catalog pass.
- Shared Dashboard date orientation, previous/next-day controls, return-to-today
  behavior, notification attention semantics, and the reusable Needs Attention
  heading/actions now use locale-aware dates and catalog strings. Attention
  record titles and reasons remain source-record projections and must localize
  from stable status/action codes in their owning module rather than being
  translated inside the shared panel.
- `lib/src/shared/localized_date.dart` now owns the four operational date
  densities used by current Dashboard, Expenses, and Inventory headings,
  records, editors, evidence, and day routes. It uses locale date skeletons for
  full date, weekday without year, date without weekday, and month/day only;
  screens may choose a documented density but may not maintain English month or
  weekday tables. This display-only projection does not alter a record's stored
  date, time zone, ownership, or identity.
- The same shared date utility owns locale-ordered compact dates and inclusive
  date ranges used by planned/recurring Expenses and Reports. Report-period
  identities remain stable enum values while their English, U.S. Spanish, and
  Canadian French labels come from the shared catalog; range calculations keep
  their existing calendar/rolling semantics and only localize presentation.
- The remaining screen body strings, forms, statuses, categories, reports,
  documents, search aliases, and exports are not yet fully catalog-backed.
  This foundation must not be described as complete product localization.
- The U.S./Metric preference code exists, but measurement models, conversion,
  source-value preservation, and receipt/package adapters remain future
  bounded slices. No conversion is inferred by the current preference alone.

## 3. Measurement truth

Every measured value retains:

1. stable unit code;
2. exact source value and source unit;
3. normalized value only when a defined conversion exists;
4. display value and display unit selected for the current user;
5. conversion and rounding policy/version;
6. actor and confirmation state when a person corrected an inferred unit.

Conversion changes presentation, not the source evidence. Do not convert
counts, money, ambiguous package sizes, or an unconfirmed receipt unit. Do not
round a stored source value merely to make a display shorter.

Supported release-one measurement families include:

- distance/odometer: mile and kilometer;
- length: inch, foot, yard, millimeter, centimeter, and meter;
- area: square foot and square meter;
- volume: fluid ounce, quart, gallon, milliliter, and liter;
- mass: ounce, pound, gram, and kilogram;
- count/package: each, pair, pack, box, case, bag, bucket, roll, spool, tube,
  cartridge, and other user-confirmed package style;
- time: minute and hour, which are locale-formatted but not U.S./Metric.

Unit labels and abbreviations localize without changing their stable codes.
Forms show the full unit name where ambiguity is possible and may use a common
abbreviation after the selection is clear.

## 4. Receipt and package form contract

Each detailed receipt/material line can record and edit independently:

- description as printed and corrected description;
- packages purchased;
- package style;
- amount contained in one package;
- contained unit, such as each, foot, meter, quart, gallon, liter, or
  milliliter;
- total contained quantity;
- price for one purchased package;
- extended line total;
- derived price per contained item or measure;
- source unit, proposed unit, confidence, and user-confirmed unit.

Examples include `2 boxes × 10 fittings`, `1 roll × 100 ft`, `1 container ×
5 gal`, and `2 bottles × 1 L`. The parser or Receipt Assistant may propose
these values, but unknown package contents stay **Needs confirmation**. It must
never invent a conversion, divide by an assumed count, or replace the original
printed unit.

Basic receipt entry may retain vendor, category, date, subtotal, tax, total,
and evidence without itemizing every line. Detailed receipt entry retains the
editable package fields above. The user chooses the workflow; Receipt Assistant
remains optional.

## 5. Layout and accessibility

- English, Spanish, and French use the same shared layout engine and component
  hierarchy. A translated screen does not receive a private breakpoint.
- Primary labels, names, dates, money, units, and state never use ellipsis.
  Controls wrap, reflow, or use a clearer shorter translation.
- Directional padding and focus order remain correct even though the first
  three supported locales are left-to-right.
- Screen-reader semantics speak the localized value and unit together.
- Locale or unit changes refresh visible projections without duplicating or
  mutating source records.

## 6. Permission, sync, and audit boundaries

- Language and measurement preferences cannot grant access to a record, field,
  action, export, or sync payload.
- Organization defaults and personal overrides sync as settings with stable
  revisions. Confirmed business values keep stable unit/currency codes.
- Offline edits retain the preference and source unit used at entry time.
  Conflicts never resolve by discarding the original value or unit.
- PDFs, exports, and customer documents record the locale, currency, unit
  presentation, and template/version used to render that exact document.

## 7. Required regression coverage

Before release, tests prove:

1. language selection is the first onboarding question;
2. all three languages can complete onboarding offline;
3. the choice survives restart and can be changed later;
4. U.S. and Metric are the visible measurement labels;
5. dates, money, decimals, pluralization, and units localize correctly;
6. receipt package quantity and size work for count, length, volume, and mass;
7. unconfirmed package contents never produce per-piece cost;
8. unit conversion preserves source value, unit, and audit evidence;
9. 320-LP phone through resizable desktop layouts do not clip translated text;
10. text scales 1.0, 1.3, 1.5, and 2.0 remain usable;
11. switching locale/unit does not change permissions, record identity, totals,
    source evidence, or sync ownership;
12. PDFs and exports reproduce the selected locale/unit presentation while
    retaining stable underlying codes.

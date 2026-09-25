# Owner-provided catalog, inventory and parser requirements — verbatim record

Recorded on the HP Windows computer, September 18, 2026.

This document preserves the supplied passages, not a summary or implementation report. Section headings and this introductory notice are archival metadata added by Codex. The passages below retain the wording available in this conversation, including voice transcription errors. The complete typed specification in section 2 resolves the earlier truncated voice delivery. Do not treat the act of recording these requirements as permission to implement them: implementation is paused pending the owner's go-ahead. No delegation is authorized. Read this whole document when resuming the inventory/catalog/parser discussion after context compression, together with the current owner messages and the owning inventory rebuild plan. Preserve the quoted record; record later corrections separately rather than rewriting the original passages.

## 1. Earlier source-safety and provenance passage supplied through voice

The beginning of this passage was truncated in the received transcript. The available wording is preserved below without reconstructing missing text. The owner explicitly endorsed these requirements even though they originated in a separate ChatGPT conversation.

…rmation, independently researched, user created data, properly licensed third party material, and third-party copyrighted material that we're not allowed to redistribute That way, this isn't merely a policy somebody remembers. We can actually test the catalog for violations. And there's one more rule I'd make very explicit: five point seven gets no grandfather clause. If five point seven contains a manufacturer description, image, specification, logo, part number, or anything else, its presence there proves absolutely nothing about whether it's accurate or whether we have the right to ship it. The new harness, independently validates both the data and, where relevant, its source provenance

A few important things. The biggest missing piece is provenance. Every manufacturer specific fact we add should ideally record where it came from, when it was verified, and enough source information that we can audit it later. If two sources disagree, the system shouldn't silently choose whichever value it happened to encounter first. I'd also add a hard distinction between generic catalog items and manufacturer specific products. Generic things such as copper tees, PVC elbows, wire sizes, filters, fasteners, and so forth, should not acquire manufacturer merely because one manufacturer's website was used to verify that the item exists. Manufacturer attribution belongs only on an actual manufacturer specific product. Another big one is identifiers, manufacturer part numbers, model numbers, UPCs, GTINs, SKUs, and similar identifiers should be stored as identifiers, not treated as product descriptions, and retailer SKUs need to stay separate, from manufacturer part numbers. A Home Depot or Lowe's stock number, for example, isn't necessarily the manufacturer's identifier. We also need a rule against invented specifications. If we know something is a three quarter inch copper tee, but cannot reliably establish another attribute, that field stays unknown. The harness should actually flag unsupported or suspiciously inferred specifications, rather than letting AI fill in a plausible answer. And then there's standards and certifications. Things like UL, CSA, ASTM, ANSI, NSF, and similar names are certification claims shouldn't be casually assigned, because products of that general type, commonly carry them. If the catalog says a particular product has a certification or conforms to a standard, we need reliable evidence for that specific claim. Finally, I'd add a licensing source classification to the harness itself. It should know the difference between our own generated structured data, factual information, independently researched, user created data, properly licensed third party material, and third-party copyrighted material that we're not allowed to redistribute That way, this isn't merely a policy somebody remembers. We can actually test the catalog for violations. And there's one more rule I'd make very explicit: five point seven gets no grandfather clause. If five point seven contains a manufacturer description, image, specification, logo, part number, or anything else, its presence there proves absolutely nothing about whether it's accurate or whether we have the right to ship it. The new harness, independently validates both the data and, where relevant, its source provenance

But just because Chat GPT said it, doesn't mean it isn't true. I agree cold heartedly with, what it's been saying. I mean wholeheartedly, whatever it is, Completely agree with it

## 2. Complete typed specification supplied by the owner — unabridged

Yes. What you're asking for is not “write some tests around the catalog.” You're asking for a quality-control system whose job is to try to prove the catalog wrong before customers ever see it.

And since the project files don't document this harness specification yet, what follows is the architecture I think you should give Codex. Five point seven can be raw reference material, but absolutely none of its old tests, passing results, counts, classifications, or assumptions constitute proof.

I would tell Codex this:

“The inventory and catalog validation harness must be designed as an independent, commercial-grade verification system. Its purpose is not to prove that the new catalog matches five point seven. Its purpose is to independently determine whether the new catalog is structurally valid, internally consistent, factually defensible, legally/source-safe, usable, complete enough for its stated scope, and correctly integrated with Inventory.

Five point seven is untrusted input. Existing tests and previous passing results are untrusted evidence. Data copied or derived from five point seven must pass the same independent validation as newly created data. Never write a test whose expected answer is simply taken from the data being tested. That is circular validation.

The harness must distinguish errors, warnings, and items requiring human review. A passing harness means all release-blocking checks actually passed. It must never convert unknowns into passes merely because it found no obvious error.

Every canonical catalog item needs a stable identity independent of where it appears in navigation. Identity should be determined from the attributes that actually define that kind of item: product/fitting type, material, dimensions, connection types, ratings, specifications, manufacturer and manufacturer part number where applicable, and other family-specific attributes.

Duplicate detection must operate on canonical identity, not display name alone. It must catch exact duplicates, normalized duplicates, formatting differences, abbreviation differences, unit-equivalent duplicates, reordered attributes, and likely near-duplicates requiring review.

At the same time, cross-trade applicability must never be mistaken for duplication. One canonical item may legitimately belong to Plumbing and HVAC, for example. That should ordinarily remain one item with multiple trade/category associations. Inventory quantity belongs to that canonical physical item. If the user owns ten, Plumbing and HVAC may both expose that item, but the user does not magically own twenty.

The harness must test the hierarchy as a graph, not merely inspect individual rows. Every child must have a valid parent. There can be no orphan categories, unreachable items, accidental cycles, broken navigation paths, duplicate branches representing the same concept, impossible category relationships, or items that exist in the database but can never be reached through the UI or search.

It must validate trade classification independently. Items can be single-trade, multi-trade, or genuinely universal. It should detect suspicious classifications rather than assuming the supplied classification is correct.

Product families need family-specific validation. A copper elbow does not have the same defining attributes as a reducing tee, electrical breaker, wire, HVAC filter, roofing product, fastener, or piece of lumber. The harness must understand required and optional attributes by product family instead of imposing one generic schema and declaring everything valid.

Dimensional validation needs to understand semantics, not just whether a size field contains text. For a tee, for example, the harness needs to know which dimensions represent the run and branch, what ordering convention the catalog uses, which combinations are physically meaningful, and whether the display representation corresponds to the stored dimensions. Equivalent representations such as fractional versus decimal measurements must normalize correctly without destroying meaningful distinctions.

Units need their own validation. Inches, feet, gauges, nominal pipe sizes, actual dimensions, volts, amps, BTUs, PSI, horsepower and other units cannot simply be arbitrary strings. The harness should detect missing units, impossible values, incompatible unit types, malformed fractions, inconsistent normalization, and conversions that accidentally change product identity.

Search must be tested independently from navigation. Every intended catalog item should be discoverable through reasonable terminology, abbreviations, sizes, common trade language, manufacturer part numbers where applicable, and relevant synonyms without returning completely unrelated products. Search tests should include misspellings and formatting variations where the product design intends to support them.

Catalog-to-Inventory integration needs full end-to-end tests. Adding an item must create or reference the correct canonical inventory identity. Adding the same item through another trade path must not create another inventory item. Quantity changes must persist. Removing inventory must not delete the underlying catalog definition. Custom user-created items must remain distinguishable from catalog items. Catalog updates must not corrupt existing user inventory.

Updates deserve their own migration harness. If catalog pack version two replaces version one, existing inventory must still point to the correct things. Renaming a display label cannot create a new physical item. Moving something between categories cannot lose inventory. Splitting or merging canonical items requires explicit migration rules. IDs must never be casually regenerated in a way that disconnects customers' existing data.

The harness must validate provenance. Manufacturer-specific factual claims should retain enough provenance to determine where the information came from and when it was verified. Conflicting sources must be surfaced rather than silently resolved. Unsupported fields remain unknown rather than being invented.

Generic products and manufacturer-specific products must remain distinct concepts. Researching a manufacturer's site to verify that three-quarter-inch copper tees exist does not make that generic catalog item a product of that manufacturer.

Manufacturer names, model numbers, manufacturer part numbers, UPCs, GTINs, retailer SKUs and other identifiers must occupy the correct fields. A retailer's SKU must not silently become a manufacturer part number.

No AI-generated factual value should pass merely because it sounds plausible. Where a claim requires external factual verification, the harness must distinguish verified, unverified, conflicting, and unknown information.

Certification and standards claims require especially strict validation. UL, CSA, NSF, ASTM, ANSI and similar claims must not be inferred from the general product category. If the catalog makes a product-specific certification or compliance claim, that claim needs appropriate supporting evidence.

Source safety needs validation too. Manufacturer photographs, logos, drawings, diagrams, manuals, written descriptions, catalog pages and other third-party creative content must not silently enter the distributable catalog. Publicly accessible does not mean licensed for redistribution. The harness should be capable of identifying records containing third-party asset references or copied material that require licensing review.

The harness needs statistical and anomaly detection in addition to hard rules. If one category suddenly has ten thousand items when comparable categories have hundreds, investigate it. If ninety-nine percent of one manufacturer's products have exactly the same specification, investigate it. If a size series unexpectedly skips common sizes or contains bizarre outliers, flag it. These aren't necessarily failures, but they're reasons to review the data.

Counts are useful as regression signals, but counts are never proof of correctness. ‘There were seventeen hundred galvanized tees before and there are seventeen hundred now’ proves almost nothing by itself. Seventeen hundred wrong records are still wrong.

The harness must deliberately test bad data. Build known-invalid fixtures containing duplicate items, orphan nodes, invalid dimensions, contradictory units, missing required attributes, malformed identifiers, cross-trade items incorrectly duplicated, unsupported manufacturer claims, broken provenance, invalid migrations and corrupted records. A validator that has only ever been shown good data has not demonstrated that it can catch bad data.

There should also be mutation testing of the validator itself where practical. Deliberately alter valid catalog data in controlled ways and verify that the appropriate test fails. If changing a tee dimension, deleting a parent, duplicating a canonical item, or breaking a trade association still produces green results, the harness is defective.

Testing must be deterministic. Running the same harness against the same catalog version must produce the same result. Internet availability, AI responses or changing manufacturer websites cannot determine whether a release build passes. External research can feed a reviewed data-verification process, but release validation needs reproducible evidence.

Every failure needs to be actionable. The report should identify the catalog item or category, stable ID, trade paths involved, exact rule that failed, actual value, expected constraint, severity, and enough provenance to investigate it. ‘Catalog validation failed’ is useless.

The harness should produce a machine-readable report as well as a human-readable summary. That allows CI, release tooling and future catalog-pack generation to block releases automatically when critical invariants fail.

Performance itself must be tested at realistic scale. Do not test only with fifty sample records and assume one hundred thousand or several hundred thousand records behave the same way. Measure catalog loading, indexing, search, drill-down navigation, pack installation, database migration, inventory lookup, startup impact, memory consumption and storage consumption with realistic catalog sizes and deliberately oversized stress datasets.

Low-memory and interruption conditions matter. Catalog installation or updating must be tested for interrupted downloads, truncated files, insufficient disk space, corrupted packages, failed verification, process termination and restart. A failed catalog update must not destroy the last known-good catalog.

Catalog packs need integrity validation before installation. Version, schema compatibility, expected metadata, hashes or equivalent integrity mechanisms, and internal database consistency should be checked before the app trusts a downloaded pack.

Security testing belongs here too. A catalog package is external input. The importer must reject malformed or malicious data, unexpected paths, absurd field lengths, pathological nesting, invalid encodings and anything capable of escaping the intended catalog storage boundary.

The UI needs its own tests rather than assuming database correctness means the product works. Test representative simple and complex families on actual supported screen sizes. Test deep drill-down paths, back navigation, rotation where applicable, accessibility scaling, long names, fractional dimensions, empty categories, enormous categories, search results, universal items, custom items and inventory entry.

For complicated fittings such as tees, the eventual visual dimension interface must be tested against the canonical dimensional representation. If the diagram says three-quarter by half by three-quarter, the highlighted openings and stored product identity must agree. The visual representation cannot merely look plausible.

Accessibility needs validation too: labels, screen-reader semantics, focus order, touch targets, text scaling and any diagram-based dimension selector need an accessible nonvisual interpretation. A diagram cannot be the only way someone can understand which dimension is which.

Then there needs to be release gating. Define which failures absolutely prevent a catalog pack from shipping. True duplicate canonical identities, corrupt hierarchy, invalid migrations, missing required identifiers, broken inventory references, integrity failures and known unsafe source material should not be ‘warnings’ somebody can ignore to make the build green.

Warnings and human-review queues are appropriate for things such as unusual but potentially legitimate dimensions, classification uncertainty, conflicting external factual sources or statistical anomalies.

Finally, the harness itself is production infrastructure. Its tests need tests. Its rules need versioning. Changes to validation rules need review. Historical reports should be retained so we can determine why something passed one catalog release and failed another.

And the definition of done cannot be ‘all tests pass.’ The definition is: we have demonstrated that the tests cover the requirements, deliberately proved that they fail when representative defects are introduced, exercised the system at production scale, independently validated high-risk factual and structural assumptions, and have no unresolved release-blocking failures.

The house analogy applies exactly: you shouldn't have to tell the builder that a house requires plumbing, electrical service, structural support, waterproofing, ventilation and a way to get into the damn bedroom. Likewise, you should not have to enumerate every individual defect this harness should detect. Codex needs to treat this as quality engineering for a commercial data product, actively search for entire classes of failure we haven't thought of, document those classes, build tests for them, and prove those tests can actually fail before claiming the catalog is ready.”

That's the level I'd set. And I would explicitly tell it that this specification is a floor, not a ceiling. If Codex identifies additional credible failure modes while building the harness, it's supposed to add coverage or bring the design decision to you—not ignore them because they weren't literally named in the prompt.

## 3. Owner's explicit preservation instructions — verbatim

Uh, well, hold on, let me see what, let me see what else I can get chat GPT to say. Give me a minute. I need you to be writing down all this stuff. You need to write every last bit of this down so you do not forget it when you compress. See what'll happen is you'll wind up compressing your, Uh, whatever it is, you know what I mean. When it compresses context

Are you adding all of that stuff to the blueprint?

I need for you to add. Just copy and paste everything that ChatGPT has told you from, like, the past three or four messages. All of that crap needs to be added. Yeah, I can see, um, at least one, two, three. But, I mean, everything. Just copy and paste all of it that we've talked about in the past, like, five messages. The really long messages is what you need to be copying and pasting word for word. I don't want you summarizing it. Just copy and paste into somewhere you will read it later.

## 4. Additional verification specification — voice portions received, verbatim

Update: The complete typed addition is preserved in section 5 below. It closes the gaps in this earlier voice record. Retain both as received; use the complete typed version for the requirements.

Archival note added by Codex: This addition was received with a truncated beginning and a missing middle. The first received portion starts with “from the same logic” and ends with “manufacturer discontinue…”. The second starts with “…reclassified”. Both are preserved exactly below. No missing wording has been invented. A complete typed copy is still needed to close this gap. These are additional requirements, not implementation results or permission to resume implementation.

### First received portion

from the same logic, same source file, same transformation, or same AI reasoning. That produces a beautiful green test suite that proves almost nothing. For important invariants, the expected result needs to come from an independently defined rule, independently curated fixture, independent calculation, or separately verified source. The harness should explicitly detect circular testing wherever possible. Also require coverage accounting, not just code coverage, catalog coverage. At the end of a run, the harness should be able to say how many trades were tested. How many categories, product families, canonical items, variants, dimensional patterns, cross trade associations, manufacturer specific records, generic records, inventory paths, migrations, searches, and UI routes were actually exercised. Anything not tested needs to be visible. All tests passed means nothing if forty percent of the catalog was never examined. Then I’d add completeness testing against the declared scope. That’s different from correctness. A catalog containing ten perfectly valid plumbing fittings can be one hundred percent correct and still be useless. For every trade pack, we need a declared scope, describing what product families we claim to cover. The harness then verifies that those families actually exist and aren’t accidentally missing. It should detect an entire missing branch, not merely malformed records inside branches that happen to exist. There also needs to be negative space testing. Ask not only what exists, but what should not exist. Plumbing shouldn’t suddenly contain roofing shingles, and nominal pipe size field shouldn’t appear on products where that concept doesn’t apply. An HVAC only attribute shouldn’t silently become required for a generic plumbing fitting. Invalid relationships need explicit rejection tests. Another big one is semantic contradiction detection. Individual fields can each be syntactically valid while the record as a whole is impossible. A product might claim one material in its title and another in its attributes. A tee might have dimensions that don’t match its generated display name. A wire record might have incompatible gauge and description. A fitting could say threaded in one field and solder in another. The harness needs cross-field rules, not just field validators. I’d add bidirectional round trip tests. If structured attributes generate a human-readable description. Parsing or selecting that description, must resolve back to the same canonical item where the system supports that behavior. If the UI says three quarter by half by three quarter reducing tee, the underlying dimensions, diagram, search indexing, inventory identity, and exported representation all need to describe the same object. Then, there’s canonicalization stability. Normalization rules themselves need tests. Three quarter inch, three quarters, the fraction three quarter, decimal zero point seven five where appropriate, and equivalent normalized forms must not randomly generate separate products, but normalization also must not collapse genuinely different things. This is one of the places where aggressive deduplication can destroy a catalog. I’d require deterministic stable ID tests. Rebuilding the same catalog from unchanged verified source material should produce the same canonical identities. Reordering source rows, changing capitalization, or changing irrelevant metadata should not generate new IDs. Conversely, changing an identity defining attribute must not accidentally retain an identity that now means something different. Then we need referential integrity beyond inventory. Anything eventually referencing catalog items, estimates, invoices, jobs, common jobs, material usage, purchase history, favorites, saved lists, barcode mappings, vendor mappings, must survive catalog updates, even if some of those features aren’t built yet. The identity architecture must leave room for them We also need lifecycle state testing. Products can be active, deprecated, superseded, unavailable, manufacturer discontinue…

### Missing middle — not received

Subsequently supplied in full in section 5.

### Second received portion

…reclassified, identity changed, specification changed, trade association changed, provenance changed. A hundred thousand record database shouldn’t be a black box where we only know the file hash changed. High-risk changes should trigger stronger review. Changing punctuation in a description is not equivalent to changing voltage, pressure rating, fitting dimensions, certification, canonical identity, or trade applicability. The harness should classify change risk. Golden data sets are useful, but they must be independently curated. Build small authoritative reference sets for difficult families tees, reducers, wire, breakers, filters, whatever, and use them as regression anchors. They cannot simply be snapshots copied from five point seven. Cross-source corroboration can be required for particularly consequential manufacturer specific facts. But again, that needs a policy. Not every trivial dimension needs two sources, while safety critical ratings deserve stronger evidence. There also needs to be stale data detection. Provenance dates allow us to flag manufacturer specific records that haven’t been reverified for a long period, especially products whose specifications or availability can change. The harness should detect suspicious mass changes. If a generator update suddenly changes forty thousand canonical IDs, stops assigning HVAC to thousands of universal items, or reduces plumbing by sixty percent, the build should stop even if every individual row technically satisfies its schema. That’s called blast radius protection. And I absolutely want it here. Another important thing No automatic fixing of ambiguous errors during validation. The harness should diagnose, a separate reviewed repair process should modify the catalog. Otherwise, the validator can hide defects by changing the evidence while testing it. Test failures must also be reproducible. If Codex says item forty seven thousand three hundred twelve failed a generated property test, the report needs the random seed or fixture necessary to reproduce that exact failure, then CI needs tiers. Very fast structural checks can run on every catalog change. Deeper semantic property tests can run before merging. Full production scale migration performance, fuzz, security, and UI validation can run before publishing a pack. But the final release gate must include all mandatory tiers. And I would add, independent post-build validation. Generate the catalog, close the generator, then have a separate validation process open the finished artifact as an external consumer would. Don’t let successful generation itself count as successful validation. Finally and this is probably the most important addition to everything I’ve said, the harness needs a requirements traceability matrix. Every catalog requirement should map to one or more tests, every release blocking test should map back to the requirement it protects. If we decide, one canonical physical item may have multiple trade associations, we should be able to point directly to the tests proving duplicate detection, inventory quantity sharing, search visibility, navigation visibility, migration behavior, and update behavior for that requirement. That prevents the exact Codex problem you’re describing. Nobody explicitly told me to test that particular thing. So no, the previous answer wasn’t everything. Combined with this answer, we’re getting much closer to what I’d call a serious commercial grade verification specification, but I would still tell Codex one final thing explicitly. It is responsible for performing a formal failure mode analysis of the catalog system itself before finalizing the harness. It should inspect the actual implementation and ask, component by component, how can this fail, how would we detect it, how would we reproduce it, what damage could it cause, and which automated test proves we’re protected? Any credible failure mode without a corresponding test becomes unfinished harness work. That’s how you get away from having to personally remember every damn receptacle in the house

## 5. Complete typed addition supplied by the owner — unabridged

That covered a lot, but no, I would not call it complete yet. There are several entire classes of failure I would add before calling this an enterprise-grade catalog/inventory verification harness.

The first major addition is independence of the oracle. This is critical. Codex cannot generate a catalog record and then generate the expected test result from the same logic, same source file, same transformation, or same AI reasoning. That produces a beautiful green test suite that proves almost nothing. For important invariants, the expected result needs to come from an independently defined rule, independently curated fixture, independent calculation, or separately verified source. The harness should explicitly detect circular testing wherever possible.

I'd also require coverage accounting. Not just code coverage. Catalog coverage. At the end of a run, the harness should be able to say how many trades were tested, how many categories, product families, canonical items, variants, dimensional patterns, cross-trade associations, manufacturer-specific records, generic records, inventory paths, migrations, searches, and UI routes were actually exercised. Anything not tested needs to be visible. “All tests passed” means nothing if forty percent of the catalog was never examined.

Then I'd add completeness testing against the declared scope. That's different from correctness. A catalog containing ten perfectly valid plumbing fittings can be one hundred percent correct and still be useless. For every trade pack, we need a declared scope describing what product families we claim to cover. The harness then verifies that those families actually exist and aren't accidentally missing. It should detect an entire missing branch, not merely malformed records inside branches that happen to exist.

There also needs to be negative-space testing. Ask not only “What exists?” but “What should not exist?” Plumbing shouldn't suddenly contain roofing shingles. A nominal pipe-size field shouldn't appear on products where that concept doesn't apply. An HVAC-only attribute shouldn't silently become required for a generic plumbing fitting. Invalid relationships need explicit rejection tests.

Another big one is semantic contradiction detection. Individual fields can each be syntactically valid while the record as a whole is impossible. A product might claim one material in its title and another in its attributes. A tee might have dimensions that don't match its generated display name. A wire record might have incompatible gauge and description. A fitting could say threaded in one field and solder in another. The harness needs cross-field rules, not just field validators.

I'd add bidirectional round-trip tests. If structured attributes generate a human-readable description, parsing or selecting that description must resolve back to the same canonical item where the system supports that behavior. If the UI says “three-quarter by half by three-quarter reducing tee,” the underlying dimensions, diagram, search indexing, inventory identity, and exported representation all need to describe the same object.

Then there is canonicalization stability. Normalization rules themselves need tests. “Three-quarter inch,” “three quarters,” the fraction three-quarter, decimal zero-point-seven-five where appropriate, and equivalent normalized forms must not randomly generate separate products. But normalization also must not collapse genuinely different things. This is one of the places where aggressive deduplication can destroy a catalog.

I'd require deterministic stable-ID tests. Rebuilding the same catalog from unchanged verified source material should produce the same canonical identities. Reordering source rows, changing capitalization, or changing irrelevant metadata should not generate new IDs. Conversely, changing an identity-defining attribute must not accidentally retain an identity that now means something different.

Then we need referential integrity beyond Inventory. Anything eventually referencing catalog items—estimates, invoices, jobs, common jobs, material usage, purchase history, favorites, saved lists, barcode mappings, vendor mappings—must survive catalog updates. Even if some of those features aren't built yet, the identity architecture must leave room for them.

We also need lifecycle-state testing. Products can be active, deprecated, superseded, unavailable, manufacturer-discontinued, or removed from a newer catalog pack. Removing something from the current browsing catalog must not erase historical business records that used it. A five-year-old invoice must still be intelligible even if that product no longer exists in today's catalog.

That leads to historical snapshot semantics. If an invoice used an item when its description or manufacturer part number was different, later catalog updates shouldn't rewrite history. The harness needs to verify which data remains linked dynamically and which business records preserve a historical snapshot.

Another missing area is user customization. Suppose the user takes a catalog item and gives it their own nickname, cost, selling price, quantity, preferred vendor, bin location, reorder threshold, notes, barcode, or tax treatment. A catalog update must not overwrite those user-owned fields. The harness should deliberately update the underlying catalog and prove user customization survives.

Custom-to-catalog reconciliation needs testing too. A user might create a custom “three-quarter copper ninety” before downloading the Plumbing pack. Later the official catalog contains that item. The system needs a safe way to recognize a potential match without silently merging records and corrupting history or quantity. The harness should test those situations.

Barcode behavior deserves its own suite if you're ever going there. UPC, EAN, GTIN and manufacturer codes can have formatting and check-digit rules. One barcode may identify a packaged quantity rather than an individual unit. Multiple package configurations can represent the same underlying item. Don't bake “one barcode equals one canonical inventory item” into the architecture without testing those realities.

Packaging and units-of-measure need deeper treatment as well. One fitting, a bag of ten fittings, a box of fifty, one foot of wire, a two-hundred-fifty-foot coil, one sheet, one bundle, one gallon, one case—those are not automatically separate physical product identities, but they may represent different purchasing units. The harness needs to distinguish item identity, stocking unit, purchasing unit, package quantity, and conversion rules.

Money needs exact tests. Costs and prices should never suffer floating-point rounding errors. Test zero, very large values, fractional quantities where allowed, currency precision, tax calculations where catalog data interacts with pricing, and unit-cost conversions from packages.

Localization and internationalization are another whole area. Even if you're launching in the United States first, don't let the catalog architecture permanently assume every measurement is imperial, every decimal separator is a period, every currency is dollars, every electrical standard is American, or every trade uses identical terminology worldwide. The harness should at least prove that the data model doesn't make future localization impossible.

Text itself needs abuse testing. Unicode, apostrophes, quotation marks used for inches, fraction characters, superscripts, trademark symbols, ampersands, slashes, parentheses, extremely long manufacturer names, unusual model numbers, emoji accidentally entering user fields, right-to-left text, and malformed Unicode should not break search, storage, export, or UI.

Sort order deserves tests. Fractional sizes are notorious here. Lexicographical sorting can put one-inch, one-and-a-quarter-inch, one-half-inch and three-quarter-inch into nonsense order. Sizes should sort according to their actual semantic values where appropriate. Gauge systems may sort in the opposite numerical direction. Family-specific sorting matters.

Then I'd require combinatorial testing. You cannot manually write a test for every one of potentially hundreds of thousands of variants. Property-based testing can generate large numbers of valid and invalid combinations from the family rules and verify invariants. That is especially useful for things like tees with three dimensions.

Boundary-value testing needs to accompany it. Smallest supported size, largest supported size, one step below and above boundaries, zero, negative values, absurdly large dimensions, empty strings, maximum field lengths, maximum category depth, maximum variant count, and maximum package size.

Fuzz testing belongs here too. Feed malformed catalog packages and bizarre values into parsers and importers and make sure the app rejects them safely rather than crashing, hanging, consuming enormous memory, or partially installing garbage.

Then concurrency. What happens if the user searches Inventory while a catalog pack is being installed? What if the app is killed during an update? What if two processes or asynchronous operations try to update indexes? What if inventory is being edited while a catalog version changes? The harness should deliberately exercise those race conditions.

Transactional installation is essential. A catalog pack either becomes completely installed and valid, or the previous known-good version remains active. There should never be a half-old, half-new catalog. Test failures at multiple points in the transaction.

Rollback needs to be proven, not assumed. Install version one, populate inventory, install version two, deliberately discover a problem, roll back to version one, and verify the user's inventory and references remain intact. Then test moving forward again.

Backward and forward compatibility need matrices. Older app with newer pack: reject safely if incompatible. Newer app with older pack: migrate or support according to explicit rules. Unknown schema version: don't guess.

Download behavior needs network chaos testing if these packs are downloaded. No connection, slow connection, cellular handoff, Wi-Fi loss, server timeout, duplicate chunks, truncated download, wrong content length, corrupted bytes, retry after restart, insufficient storage, and repeated user taps must all behave predictably.

Your abuse concern from earlier belongs directly in this system too. Repeated catalog downloads should not create duplicate local packs, consume unlimited storage, or bypass whatever device-level download controls you eventually establish. Server-side controls and client behavior should be tested separately.

There should be resource-budget gates. Decide what is acceptable for startup time, search latency, memory usage, database size, index size, installation time, and temporary disk usage. Then fail performance regressions when they cross meaningful thresholds instead of merely printing timing numbers nobody reads.

Long-duration testing is another missing piece. Populate the app, modify inventory, install catalog updates, restart it hundreds of times, search repeatedly, add and remove items, and run the equivalent of months or years of catalog evolution. Some problems only appear after accumulated state.

Database integrity should be checked after stress tests. Don't merely verify that the UI didn't crash. Run integrity checks and verify every reference and invariant afterward.

Disaster recovery should be tested. Copy or restore user inventory onto a fresh installation with the appropriate catalog version missing. The system needs a defined behavior: recover the required catalog references, preserve historical snapshots, or otherwise remain intelligible without inventing data.

Privacy needs a boundary too. The downloadable generic catalog should contain no user information. User inventory should never accidentally be included when generating or publishing a catalog pack. Build a test specifically for that separation.

Supply-chain security deserves attention. Whatever process generates catalog packs should produce a manifest identifying generator version, schema version, catalog version, creation time, source/provenance summary, record counts, integrity hashes and whatever signing mechanism you ultimately choose. The app shouldn't blindly trust “some SQLite file downloaded from the server.”

Reproducible builds would be valuable. Given the same approved inputs and generator version, the catalog build should produce semantically identical output. If it doesn't, we should know why.

Then auditability. When a record changes between catalog releases, produce a meaningful diff: added, removed, renamed, reclassified, identity changed, specification changed, trade association changed, provenance changed. A hundred-thousand-record database shouldn't be a black box where we only know the file hash changed.

High-risk changes should trigger stronger review. Changing punctuation in a description is not equivalent to changing voltage, pressure rating, fitting dimensions, certification, canonical identity, or trade applicability. The harness should classify change risk.

Golden datasets are useful, but they must be independently curated. Build small authoritative reference sets for difficult families—tees, reducers, wire, breakers, filters, whatever—and use them as regression anchors. They cannot simply be snapshots copied from five point seven.

Cross-source corroboration can be required for particularly consequential manufacturer-specific facts. But again, that needs a policy: not every trivial dimension needs two sources, while safety-critical ratings deserve stronger evidence.

There also needs to be stale-data detection. Provenance dates allow us to flag manufacturer-specific records that haven't been reverified for a long period, especially products whose specifications or availability can change.

The harness should detect suspicious mass changes. If a generator update suddenly changes forty thousand canonical IDs, stops assigning HVAC to thousands of universal items, or reduces Plumbing by sixty percent, the build should stop even if every individual row technically satisfies its schema.

That's called blast-radius protection, and I absolutely want it here.

Another important thing: no automatic “fixing” of ambiguous errors during validation. The harness should diagnose. A separate reviewed repair process should modify the catalog. Otherwise the validator can hide defects by changing the evidence while testing it.

Test failures must also be reproducible. If Codex says item forty-seven-thousand-three-hundred-twelve failed a generated property test, the report needs the random seed or fixture necessary to reproduce that exact failure.

Then CI needs tiers. Very fast structural checks can run on every catalog change. Deeper semantic/property tests can run before merging. Full production-scale, migration, performance, fuzz, security and UI validation can run before publishing a pack. But the final release gate must include all mandatory tiers.

And I would add independent post-build validation. Generate the catalog, close the generator, then have a separate validation process open the finished artifact as an external consumer would. Don't let successful generation itself count as successful validation.

Finally—and this is probably the most important addition to everything I've said—the harness needs a requirements traceability matrix. Every catalog requirement should map to one or more tests. Every release-blocking test should map back to the requirement it protects. If we decide “one canonical physical item may have multiple trade associations,” we should be able to point directly to the tests proving duplicate detection, inventory quantity sharing, search visibility, navigation visibility, migration behavior and update behavior for that requirement.

That prevents the exact Codex problem you're describing: “Nobody explicitly told me to test that particular thing.”

So, no, the previous answer wasn't everything. Combined with this answer, we're getting much closer to what I'd call a serious commercial-grade verification specification.

But I would still tell Codex one final thing explicitly: it is responsible for performing a formal failure-mode analysis of the catalog system itself before finalizing the harness. It should inspect the actual implementation and ask, component by component, “How can this fail, how would we detect it, how would we reproduce it, what damage could it cause, and which automated test proves we're protected?” Any credible failure mode without a corresponding test becomes unfinished harness work.

That's how you get away from having to personally remember every damn receptacle in the house.

## 6. Catalog-generation framework addition supplied by the owner — unabridged

You don't want twenty-one completely separate generators. You want one catalog-generation framework with trade-specific and product-family-specific rule modules.

The core engine should handle the things every trade shares: canonical IDs, hierarchy, aliases, units, provenance, source records, deduplication, cross-trade associations, staging, versioning, manifests, and handing the output to the independent validator.

Then each trade gets a trade definition. Plumbing defines its families and terminology. HVAC defines its own. Electrical defines breakers, conductors, boxes, fittings, devices, and so forth. Roofing, masonry, carpentry, automotive, welding—each gets its own declared scope instead of inheriting assumptions from Plumbing.

Below that are the really important pieces: product-family definitions. That's where the intelligence belongs. A tee family knows it has three openings and what those dimensions mean. Wire knows gauge, conductor count, insulation, material and relevant ratings. Filters know length, width, depth and other defining attributes. Fasteners know diameter, length, thread characteristics, head style and material. Those aren't twenty-one generators; they're reusable family modules.

And families can be shared across trades. That's how we solve your universal-item problem correctly. Copper tubing doesn't need a Plumbing generator and a duplicate HVAC generator. There is one tubing family capable of associating appropriate canonical products with Plumbing, HVAC, or both.

The generation engine then needs multiple ways of producing candidates because not everything can come from the same method. Some families can generate variants from verified dimensional rules. Some require imported factual datasets. Manufacturer-specific products require verified manufacturer facts. Some things may need curated records because no trustworthy deterministic rule exists. The engine needs to support all of those without pretending they're equivalent.

Before generating a trade, Codex should effectively conduct a discovery phase: determine the trade's product families, determine which already exist as shared families, identify genuinely new families, define their schemas and identity rules, define valid variant-generation rules, identify acceptable factual sources, and establish what “coverage” means for that trade.

Then run a small representative build first. Don't unleash it on one hundred thousand records. Generate difficult examples, deliberately include reducing products, cross-trade products, weird dimensional combinations, manufacturer-specific items, and ordinary products. Let the validator beat the hell out of that.

Once the family rules survive, scale that family. Then move to the next family. Eventually the trade becomes a collection of independently proven families rather than one giant AI-generated blob.

And I'd make the generator declarative wherever possible. In other words, the knowledge of “what makes a tee a tee” shouldn't be buried in thousands of lines of custom Dart or Python. It should live in version-controlled family definitions that describe identity attributes, dimensions, allowed relationships, aliases, units, sorting, generation rules, and applicability. The engine interprets those definitions.

That gives you something extremely important later: if we discover the tee rules are wrong, we correct the tee definition and regenerate. We don't hunt through seventeen hundred hand-created records.

So the hierarchy becomes something like this conceptually: one Catalog Engineering Engine at the top; underneath it, twenty-one trade definitions; underneath those, reusable product-family definitions; underneath those, verified rules and factual source data; then candidate records; then staging; then the completely independent validation harness; then approved catalog packs.

And I would make Codex prove the architecture with perhaps three deliberately different areas before expanding all twenty-one. Plumbing gives us horrible dimensional complexity. Electrical gives us ratings and specifications. Another trade with substantially different products gives us a third stress case. If the same framework handles all three cleanly without stuffing trade-specific hacks into the core engine, then we've got evidence that the architecture is actually general.

Most importantly, five point seven never becomes the generator. It can tell us, “Hey, you apparently had this category or product family before; investigate whether it belongs.” It cannot tell the new engine, “These seventeen hundred records passed before, therefore reproduce them.”

That's how I'd build the damn thing: not twenty-one little AI factories, but one controlled catalog factory whose knowledge comes from explicit, reviewable family and trade definitions.

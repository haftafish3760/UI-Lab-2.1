# Retailer provenance and intellectual-property review

September 15, 2026. Preliminary findings; not legal clearance.

## Owner requirement

### Latest clarification: retain merchant recognition

The owner clarified the broad removal statement: the app must still recognize
Lowe's as a merchant on a user's receipt. Do not remove basic merchant
identification merely because it contains the retailer's name. The owner rejects
Lowe's training data and any infringement involving retailer material; review
the actual source data and intended uses rather than treating merchant-name
recognition, test fixtures and model training as interchangeable. This
clarification supersedes the assistant's proposed blanket removal of recognition
rules and all named examples. It does not establish legal clearance for any
specific use. No code or datasets were removed before this clarification.

The owner requires scrutiny of Lowe's-related source material and how previous
agents developed or allegedly trained the receipt/inventory parser. Review
copyright, trademarks, patents, website/data terms, source permissions and
legally uncertain uses. The owner does not want questionable retailer material
migrated or shipped. If a problematic dependency is established, identify its
scope and replacement/removal path before implementation. No files have been
removed, and the protected 5.7 source remains untouched.

## Evidence inspected

- The Lowe's entry in `expense_receipt_merchant_material_profiles.dart` is a
  name-matching rule and default receipt category, not a trained model.
- `tool/work_supply_parser_qa_generate_fixtures.dart` builds synthetic receipt
  fixtures from local recipes and merchant shapes, including a Lowe's shape.
  Its manifest reports no parser calls or live-service use. Inspected generator
  and recipe files did not show retailer fetching. This does not establish the
  origin or rights of every recipe, catalog term, prior prompt or historical input.
- A tracked-filename search found no `.tflite`, `.onnx`, `.safetensors`, `.pt`
  or `.ckpt` files in the selected legacy repository. This is not proof that no
  external model, hosted training job or untracked model artifact was used.
- Legacy specifications explicitly prohibit retailer scraping and require
  provenance for official identifiers. Such policies are not execution evidence.
- Catalog intelligence includes the source-confidence label
  `auto-derived-from-catalog-fields`. That label does not establish upstream
  provenance, copyright ownership or permission to redistribute source material.
- Some legacy policies accept public or manually reviewed source confidence.
  Public accessibility or manual review alone does not document a license or
  otherwise establish a sufficient legal basis for the intended use.

Legacy evidence is under `C:/Users/noneya/Documents/Maintainiac 5.7 copy`:
`lib/screens/expenses/data/expense_receipt_merchant_material_profiles.dart`,
`tool/work_supply_parser_qa_generate_fixtures.dart`,
`tool/work_supply_parser_qa_fixture_recipes.dart`,
`lib/screens/work_supplies/data/work_supply_catalog_intelligence.dart`,
`docs/work_supplies_spec.md`, `docs/inventory_catalog_expansion_backlog.md`,
and `docs/inventory_parser_release1_acceptance_scorecard.md`.

## Current official source context

[Lowe's website terms](https://www.lowes.com/l/about/terms-and-conditions-of-use),
reviewed September 15, reserve rights in site content and restrict reuse; they
also state approval requirements for commercial use of Lowe's marks. They do
not themselves establish infringement by this app. Their application depends
on what was obtained, how, applicable terms at acquisition, and intended use.

[USPTO patent guidance](https://www.uspto.gov/patents/basics/manage) explains that
infringement analysis compares patent claims with a product or process. A
code keyword search or removing merchant names cannot provide patent clearance.

## Unresolved questions and migration boundary

1. Trace source and permission evidence for catalog fields, fixtures, receipt
   examples, merchant aliases, images/logos and any copied descriptions.
2. Distinguish internal identification of a merchant on a user's receipt from
   retailer branding, affiliation claims, marketing or redistributed assets.
   No trademark-use clearance has been established.
3. Determine whether any past web collection, external training or third-party
   dataset was involved. The limited source and commit inspection did not
   establish that history.
4. Obtain appropriate legal review for unresolved rights and any required
   patent freedom-to-operate assessment for the intended release jurisdictions.

No infringement or scraping has been established by this preliminary review.
Neither has complete rights clearance. Synthetic labeling, absent scraping
code, privacy redaction and passing legal-policy tests are insufficient proof.
Unresolved retailer material is not approved for migration or release. Preserve
evidence; propose precisely scoped replacement/removal rather than assuming
all generic receipt processing or the entire inventory engine must be deleted.

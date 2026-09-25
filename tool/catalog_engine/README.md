# Catalog engineering foundation

Development-only Python 3 standard-library tools on the HP. SQLite is the staging
format. Nothing here changes the app's packaged catalog, user stock, parser,
Firebase, branding or 5.7. This is the first engineering slice, not the completed
commercial verification system and not a verified product catalog.

## Run from the UI Lab repository root

```powershell
python -m unittest discover -s tool/catalog_engine/tests -v
python -m tool.catalog_engine.generate --definitions tool/catalog_engine/definitions/families.json --candidates tool/catalog_engine/fixtures/candidates.json --output build/catalog_engine/candidates.sqlite
python -m tool.catalog_engine.validate build/catalog_engine/candidates.sqlite --report build/catalog_engine/validation.json
python -m tool.catalog_engine.validate build/catalog_engine/candidates.sqlite --report build/catalog_engine/release-check.json --release
python -m tool.catalog_engine.check_mutations --report build/catalog_engine/mutations.json
```

Generation refuses an existing output. Choose a fresh output filename for another
run. The release command **must exit 1**: fixtures are unverified and required gates
remain unfinished. The normal validator exit 0 means only its implemented
structural checks passed. JSON and Markdown reports distinguish that from release.

## Contract and boundaries

- `definitions/families.json` is declarative generation knowledge. Currently only
  pressure tees, conductors and filters have engineering fixture definitions.
- `fixtures/candidates.json` supplies explicit candidates, never a Cartesian product
  asserted to be manufactured. Six inputs deliberately collapse to five identities.
  Values including voltage and ratings are synthetic, not factual specifications.
- IDs use canonical identity version 1 and SHA-256. Labels, aliases, evidence and
  navigation are excluded; material/system, full ports and family attributes matter.
  A pressure tee's complete run ports can exchange places; the branch cannot.
  This symmetry must not be extended blindly to sanitary or directional fittings.
- Three named trade roots share associations to identities. There is no stock table;
  shared identity is demonstrated, shared *inventory saving* is not implemented.
- Builder closes SQLite before independent validation. The validator does not import
  the builder, its normalizer or its definitions. It independently encodes a limited
  acceptance policy. It does not establish human or externally verified oracle
  independence merely by residing in a different file.
- Tests include literal expected dimensional signatures from the owner's examples,
  fixed-seed reversal properties and damaged SQLite artifacts. Targeted mutation
  checks disable validator rules in disposable copies and require assertion failures.
- The validator opens read-only, limits artifact size and SQL work, rejects extra
  schema objects and does not repair data. Full hostile-input, process isolation and
  production-size security validation remain open.
- Factual evidence is never approved by this slice. A changed `verified` flag fails.
  Missing, conflicting and licensing evidence need a later reviewed evidence pipeline.
- Inch fractions and decimal equivalents normalize exactly. Nominal/actual distinction
  is retained. Cross-unit conversions, international nominal systems, translated
  aliases, manufacturer identities, packaging and dimensional display remain pending.
- Input fingerprints are provenance pointers, not signatures or legal permissions.
  Signed manifests, atomic app installation, updates and recovery are not implemented.

See `docs/inventory_migration/CATALOG_ENGINEERING_CHECKPOINT_2026_09_18.md`
for failure analysis, reuse assessment, traceability and remaining release work.
# Continuing QA and artifact comparisons

`python -m tool.catalog_engine.exercise_pipeline --output-directory build/catalog_engine/pipeline-NEW`
runs the actual generator and validator as separate processes. It retains the
SQLite output, exported item records, validation reports, four deliberately damaged
copies, and process results. Literal owner tee examples check the finished rows.
The new output directory must not already exist. Authored fixture data remains
unverified product data; this operational exercise does not approve release.

`python -m tool.catalog_engine.manifest ARTIFACT.sqlite --output ARTIFACT.manifest.json`
creates a staging-only integrity manifest alongside an independently validated
artifact. Counts, schema, source IDs, input fingerprints, byte length and SHA-256
are verified. A hash is not a publisher signature; authentication is still open.

`python -m tool.catalog_engine.verify_release ARTIFACT.sqlite --report RELEASE.json`
evaluates the artifact against `acceptance/release_policy.json`. That reviewed-code
boundary is separate from untrusted pack metadata. The current draft policy has
20 mandatory gate groups; structural evidence alone cannot pass. Reports missing
inventory, parser, factual, recovery or other mandatory evidence remain blocked.
Policy subjects are presently pack-level placeholders; per-item/per-path coverage
is still required before policy approval. This is not complete atomic traceability.

`python -m tool.catalog_engine.run_qa --report build/catalog_engine/qa-RUN.json`
runs the development suite and records actual test outcomes, source fingerprints,
and partial/missing requirement evidence. Use a new report name for each run;
existing reports are protected. Skips, absent tests, ambiguous test names and
expected failures are not passes. Paragraph mappings are not full acceptance.

`python -m tool.catalog_engine.compare BEFORE.sqlite AFTER.sqlite --report DIFF.json`
compares independently validated staging artifacts. Identity removals require
explicit migrations; the tool never guesses replacements or merges inventory.
Lost trade applicability and excessive removals block automatic acceptance.

`python -m tool.catalog_engine.stress --count 100000 --report build/catalog_engine/stress-RUN.json`
runs a separate synthetic volume check with enforced development-tool budgets.
It does not run every test against every item. Fictional stress records never
establish real product availability, family coverage or app responsiveness.

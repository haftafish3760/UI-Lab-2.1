# Inventory rebuild — September 16, 2026

Owner-authorized work in this task only. No delegation. Maintainiac 5.7 Copy
and Active are read-only. Preserve unrelated working-tree changes and business
records. The retained trade-selection screen is the starting point; rebuild
everything beneath a selected trade, rather than patching misleading pack names.

## Order and acceptance

1. Record and audit the rejected export, then remove it from the application.
2. Rebuild category navigation as compact, image-free grids. Preserve trade
   artwork and counts where truthful. Use shared responsive layout primitives,
   bounded desktop content, full labels, accessibility scaling, and one-level
   Back. Verify phone first, then portrait/landscape tablet and wide windows.
3. Inspect each trade's actual source hierarchy. Plumbing's material/type/size
   example is not a universal hierarchy. Reach the exact item, including ordered
   connection sizes, material/system, connection distinctions, unit and aliases.
4. Reuse suitable parts of the substantial 5.7 harness. A passing legacy test
   is NOT evidence that its expectation is correct. Review assertions and add
   independent expectations and negative cases before trusting a migrated batch.
5. Migrate very small category batches, one trade at a time, to SQLite. Preserve
   complete source payloads and provenance. Check every row after reopening;
   detect duplicates, incomplete paths, lost aliases and unsupported variants.
   Do not invent all size permutations or silently present unreviewed packs as
   finished categories. Clearly distinguish incomplete coverage from zero stock.
6. Support manual addition from the catalog without a receipt. Existing temporary
   stock must not be represented as durable. Durable authorized atomic stock,
   cost, location, receipt and Job workflows require their own validation.
7. Adapt and validate the receipt parser after its prerequisites. Preserve valid
   aliases and matching behavior; independently evaluate errors rather than
   trusting either app's existing harness.

## Parser evidence

The owner requires at least 90–95 percent accuracy, with a higher result desired.
Define denominators before reporting accuracy: exact item/variant matching,
quantity and package interpretation, price extraction, and complete-receipt
success separately. Report abstentions, incorrect confident matches and coverage.
No single percentage or passing smoke suite establishes production readiness.

The separate Receipt Generator application provides fictional-store synthetic
receipts and separate expected answers. Inspect its data and independence before
reuse. Never feed the answer file to OCR/parser inference. Keep evaluation cases
separate from tuning cases. Synthetic text tests do not establish camera/OCR
accuracy; image and real-device checks remain separate gates. Do not introduce
unauthorized real receipts or assume unknown source permissions are cleared.

## Progress and limits

- Plan recorded before the new implementation.
- Rejected browse export: compressed JSON, omitted aliases and metadata, fixed
  four-level navigation. It is not the earlier three-trade SQLite reference.
- Source inspection found generated pack labels inside 5.7 category definitions;
  their presence in source does not make them appropriate browsing categories.
- Stock persistence, parser accuracy and owner visual acceptance are unproven.
- Continue recording exact completed batches, tests, failures and next steps.
  Do not stop merely because the layout portion is done; progress through the
  authorized sequence without claiming unfinished work is complete.

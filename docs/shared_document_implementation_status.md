# Shared document implementation status — September 14, 2026

This is implementation evidence and remaining work, not release certification.
Product ownership remains in Work lifecycle and Receipt/material intake.

## Boundary and reuse

The existing SQLite attachment manifest, content hash verification, company
directory, active-session permissions, bundled fonts, pdf/printing/pdfx packages,
and receipt viewer were reused. The earlier customer renderer mixed Work content
and shared mechanics; its content now belongs to `screens/work/documents`.
Maintainiac 5.7 remains read-only reference material.

`shared/documents/pdf` owns rendering, page configuration, fonts, optional image
resolution, pagination, repeating headers/footers, tables, serialization, native
export, and the PDF reader. Builders supply explicit content; the engine does not
retrieve records or branch on Invoice, Estimate or Expense. Work owns document
validation, quantities, prices, totals, customer-safe fields and template designs.
Expense evidence relationships stay with Expenses. Expense and Inventory UI are
outside this slice.

Company branding is a projection of the existing company directory profile.
Optional logo references use its existing scoped attachment store. Company profile
upload consumes PNG/JPEG, validates size/decode, retains original bytes and previews
the image. Rendering bounds a derived image without stretching it. Missing/corrupt
optional logos fall back to company text. No invoice-specific logo settings exist.

Uploaded originals bypass generation. `DocumentSource` requires the caller's
existing authorization before and after reading; `retainedDocumentSource` uses
company/owner manifest filtering and hash verification. The renderer does not
persist files. Generated drafts are produced on demand.

## Current verification

- Flutter analyzer: no issues after removing an unsupported PDF constructor
  parameter, correcting FilePicker usage and fixing required braces.
- Android debug APK and Windows debug executable both build successfully.
- Windows executable launched and its process reported responding.
- Five generation tests cover both orientations, all ten Work template variants,
  optional/corrupt/oversized logos, image aspect ratio and snapshot detachment.
- Four storage/access tests cover authorization before/after loading, exact byte
  preservation across reopen, wrong company/owner, tampering and failed manifests.
- `tool/verify_shared_pdf.py` independently reopens twelve generated fixtures with
  PyMuPDF and checks all row/end markers, long-text boundaries, repeated table
  headers, page numbering, page geometry and bounded logo aspect ratios.
- Artifact PNG inspection supplements those checks; it is not owner acceptance
  or physical-device testing. Output is under `output/pdf`.

## Remaining release gates

The PDF foundation is not yet complete or certified production-ready. In
particular:

- Landscape customer templates need composition refinement: the representative
  short estimate currently spans two pages. The gallery now creates preview
  readers lazily by visible rows; native memory/performance verification remains.
- Work currently builds from live company/customer inputs. The detached
  `GeneratedDocumentSnapshot` envelope permits versioned issuance and an exact
  retained artifact reference/hash, but issuance persistence is not yet wired.
  Do not claim old documents regenerate identically after company/customer edits.
- Invoice payment/balance presentation, Quote integration, independent Expense
  report composition, localization/font coverage, native viewer failure/reopen
  interaction tests and native share/print tests remain to be completed.
- Android's pdfx plugin currently emits a future Kotlin migration warning; it does
  not prevent this build. Package/native compatibility needs a release review.
- No cloud portal has been deployed or verified. The customer portal is optional:
  PDF preview/save/share/print must work without it. Portal enablement must not be
  required to create or deliver a document. No demo link is proof of delivery.
- An earlier Android APK installation succeeded on the connected Galaxy S24 Ultra
  (SM-S928U); the activity launch returned Status: ok and a running process ID.
  This establishes that earlier launch, not installation of subsequent Work
  repairs or complete device interaction acceptance.

All new shared PDF production files are below 500 lines. Generated localization
and database code exceed that size; unrelated existing layout/Expense files near
500 lines were not altered for this infrastructure pass.

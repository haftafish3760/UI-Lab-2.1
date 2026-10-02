# Estimate usability audit — October 1, 2026

This is an audit and proposed correction sequence, not implementation or release
acceptance. Current owner instructions take precedence over earlier designs.
No application source changes were made during this audit. Existing dirty work
was preserved. No estimate was sent, approved, deleted, or converted during the
inspection. Opening editors can retain recoverable draft state.

## Verdict

The current flow does not meet the owner's first-time-user standard. Individual
forms have useful labels, but the complete workflow lacks a consistent starting
decision, document identity, section hierarchy, and next action. The owner should
not have to explain the difference between saving, sending, approving, and booking
because the screens failed to do so.

This assessment uses the connected Galaxy S24 Ultra, model SM-S928U, and current
source. It does not infer current behavior from the owner's old screenshots.
Device captures and UI trees are in
`output/verification/estimate-ux-audit-2026-10-01/`.

## Coverage and evidence boundaries

- Live: estimate landing/drafts, recovered empty estimate, company editor,
  customer selector, description editor, labor/material list and individual entry
  forms, pricing editor, terms/deposit editor, approval entry/footer, generated
  PDF, template thumbnail, and landscape editor. Returned device to its original
  portrait rotation setting (accelerometer rotation 0, user rotation 0).
- Source: new-estimate routes, document number allocation, draft recovery and
  exit guards, confirmation/readiness, dates/validity, item calculations, revision
  invalidation, signature/manual approval, delivery/export, portal integration,
  customer document projection, and saved-record actions/conversion.
- Not established: real customer receipt, signature submission, portal deployment
  and response round trip, physical printing, all installed messaging apps,
  restart/low-storage/concurrent edits, every PDF template, large populated jobs
  on this phone, TalkBack, large accessibility text, tablet/desktop composition,
  and all saved/approved/declined/expired/converted state transitions.
- Existing tests are evidence of intended contracts, not first-time-user
  acceptance. No fresh test/build run was needed to establish these observed UX
  defects; neither a complete regression nor end-to-end certification is claimed.

## Findings and recommendations

| Priority / area | Evidence and consequence | Recommended correction |
| --- | --- | --- |
| P1 — Starting decision | Live new-estimate route opens editor directly. `estimate_workspace_screen.dart::_createEstimate` and other fresh entry routes push `EstimateEditorScreen`; the requested pricing choice is absent. | First screen: Flat rate — enter one price for the described work; Time and materials — enter labor hours/rates and materials, and calculate the estimate. Recovered drafts retain their selection. Both routes share the document screen. |
| P1 — Numbering | `work_document_numbering.dart` starts at 1 and returns `Estimate N`. It is a saved company sequence, not draft-list position. `_numericSuffix` parses only digits after the last dash, so merely formatting `100-000` would break sequence allocation. | Use `100-000`, `100-001`, etc., consistently. Migrate existing drafts with collision checks; preserve record IDs, links, issued records and history. Fix allocation/parsing together. Never change the number merely because content was revised. |
| P1 — Editing identity | `estimate_editor_sections.dart` makes number read-only for an existing record, including saved drafts. Recovered drafts and saved-record drafts do not have identical edit behavior. | Provide a clearly labeled Document number control for eligible drafts, explain locking when issued, and validate uniqueness at save. |
| P1 — Header/status | Live editor, item editors, simple section forms and draft list have different headers. Status follows company information instead of leading the document. | Reuse the Dashboard header contract across Work; preserve meaningful route titles and Back behavior. Put Estimate status directly beneath the header, before company/document content. |
| P1 — Location within workflow | Nested forms often say only Price summary or Work description. Item forms say Back to Work although returning to the estimate's item list. | Show the current task and parent estimate/customer context. Back labels must describe the actual destination. |
| P1 — Customer labels | Live screen says Prepared for → Add customer → Client information → Saved clients. | Use Customer information consistently, with Add customer before selection and Edit after selection. Keep the summary compact and readable. |
| P1 — Financial hierarchy | Item amounts have right alignment in the new `EstimateDocumentItems`, but separate tables and nested materials padding do not establish one shared amount column with the overall summary. Compact items repeat three rows, increasing scroll length. | Use a common trailing amount alignment across labor, materials, subtotal, discount, tax and total. Keep names/details left. Keep the bounded material list and its existing editor; make total visually strongest without shrinking terms. Validate populated long-name cases. |
| P1 — Pricing controls | Live empty estimate has both section Edit and Edit pricing. Item-based estimates still render Edit pricing; source conditionally hides only the flat-price input. Discount/Tax fields do not clearly say amount versus percentage. | After the initial choice, show the relevant price controls only. Item prices change through their entries; explicitly labeled tax/discount controls remain available. Distinguish dollars and percentages wherever supported. |
| P1 — Validity contradiction | `estimate_editor_validity.dart` and `work_customer_document.dart` say Price guaranteed while default terms say price can rise or fall. The conflict reaches the customer copy. | Owner decision needed on the exact promise. Recommendation: Estimate valid for N days from sending, with a separate prominent explanation of whether the agreed scope has a fixed price or an estimated amount. Never silently equate validity with a price guarantee. |
| P1 — Approval | Main button still says Get customer approval and calls confirmation/save before opening embedded approval. Existing approval UI offers acknowledgment, signature and manual approval paths rather than the requested direct customer Accept/Decline experience. | Separate customer review/Accept/Decline from staff recording approval received elsewhere. Customer sees exact work, total, deposit, payment timing and terms before deciding. Preserve which revision was accepted. |
| P1 — Share/portal | Editor routes through `EstimateDeliveryScreen`, a separate delivery-method/recipient/review form, not the requested bottom drawer. Local PDF export exists. Portal gateway and web code exist, but no `customerPortal:` wiring was found in current lib startup callers; a live connected portal is not proven. | One Share drawer with honest available formats and native app chooser. Local PDF/print must not depend on portal sign-in. Enable link sharing only with configured, verified online service. Opening another app must not mark the document delivered. |
| P1 — Customer copy fidelity | Live PDF renders old Estimate 3 / Revision 1, Prepared for and draft placeholders. `workCustomerDocument` uses current company profile and chooses issued/created date, not sent date, for document date. | Match approved customer language and date semantics across screen/PDF/portal. Preserve exact issued company/customer/document snapshot so later profile edits cannot rewrite an old customer copy. |
| P2 — Terms scannability | Live terms are a single similarly weighted paragraph; deposit appears below it. At phone page-fit PDF scale the terms are small. A readable app paragraph does not establish a readable PDF or portal. | Use visible headings for Price changes, Deposit, Payment due and Other terms, with full readable text. No hidden important conditions, forced small type, or checkbox presented as proof of understanding. Use a readable customer screen alongside printable pages. |
| P2 — Labor guidance | Live form has generic Labor name, number of workers, hours and price per hour. No guided worker-type, diagnostics/repair, or included service-call-time controls were found in this entry flow. | Plain worker-type examples (Technician, Helper), hours/rate with visible calculation; separate service-call fee/included time and additional hours where applicable. Do not require assigning a named employee merely to estimate. |
| P2 — Material markup | Material entry exposes customer unit price and private unit cost, but no explicit markup field. Import/link expense options sit under More item options. | Clearly separate What you paid from Customer price, with optional markup and transparent result. Keep receipt/inventory integration a separate validated slice; do not imply owned stock or consume stock while estimating. |
| P2 — Dates overload | Created, Date finished, Sent, validity, follow-up and proposed service options are presented together. Latest request defines customer document date by sending; source still retains independent editable dates. | Show customer-relevant dates prominently; keep Last edited and actor/history accessible as internal activity. Distinguish proposed service options from a confirmed booking. Leave dates unchanged until the owner resolves the wording/semantics. |
| P2 — Draft identification | The live recovery list had several nearly identical Untitled estimate rows, distinguished mainly by edit time. Saved-record rows have richer data in source; recoverable rows are weaker. | Each row should identify customer or Customer not selected, document number, work summary when present, amount when entered, and last edit time. No fabricated business data. |
| P2 — Footer hierarchy | Live Customer document paragraph precedes Template/Preview/Send in wrapping rows, with Save/Cancel/Delete further down. Buttons lack a coherent order and prominence. | Keep Save draft and Preview customer copy clearly grouped. Put sharing/printing/template selection in the appropriate document actions. Separate Delete draft from everyday completion actions. |
| P2 — Responsive layout | Live landscape remains one stretched paragraph column; ads/navigation consume substantial vertical room. Editor uses shared form width but no task-specific wide composition. | Compose sections using available logical width and text scale. On wider layouts use purposeful information/price-review lanes with bounded reading widths. Keep primary actions reachable. Test keyboard, rotation and nested materials scrolling together. |
| P2 — Accessibility | UI tree exposes many Edit buttons with no section-specific name and blank text-field nodes; the main document is largely one merged text node. This raises navigation concerns but is not a completed TalkBack test. | Give Edit controls section-specific semantics and fields persistent accessible labels. Verify reading order, focus, large text, contrast and error announcements on device. |
| P2 — Validation/readiness | `buildConfirmedEstimate` silently clamps negative totals from excessive discount to zero. Customer readiness also depends on title, although the UI direction deemphasizes/removes title. | Explicitly explain invalid discount/amount combinations near their fields. Remove hidden readiness requirements or show them clearly. Use an actionable missing-information summary before sharing/approval. |
| P2 — Company setup | Company editor is available, but the inspected estimate still has no saved company; the requested sample company has not been completed. Partial address entry requires street/city/state/ZIP. | Finish the separately authorized editable sample setup transparently. Real users should see one clear setup action; do not ship fake company records. Do not claim sample setup done. |

## Existing behavior worth retaining

- Section summaries open the owning entry form directly. Description entry has a
  clear Work to be completed label. Labor/material entry returns to the estimate.
- Terms editor supports reusable selections, custom text and a deposit control
  that explicitly distinguishes a requirement from payment received.
- Validity editor contains 7/30/90/365/custom options; this inspected draft starts
  unselected. Proposed dates support multiple entries, duplicate detection and
  explicitly do not book work.
- Back/Cancel source has Save changes / Discard changes / Keep editing. Preserve
  the durable draft mechanism and verify all entry routes, including navigation
  tabs; do not replace it with a second local state store.
- Source invalidates current approval after customer-visible changes and retains
  prior revision history. Preserve that protection while simplifying the screens.
- Local PDF preview and the first template thumbnail rendered successfully on
  this phone. The earlier missing/damaged PDF error was not reproduced on this
  draft. This does not prove every template, export or recipient app works.
- Export code distinguishes handoff from delivery; approval/job conversion has
  separate checks. Retain those distinctions in plain UI language.

## Recommended correction order — proposals, not another wholesale redesign

1. Entry and identity: pricing choice, Dashboard header reuse, top status,
   numbering including draft migration, consistent Customer information wording.
2. Document readability: compact identity/customer area, work, common amount
   column, bounded materials, prominent total, readable terms and deposit.
3. Entry completeness: worker types/service call, material markup, explicit
   financial fields and useful validation. Preserve existing durable workflows.
4. Review/approval/delivery: one clear customer review, Accept/Decline, signature,
   Share drawer and native chooser; verify exact document consistency end to end.
5. State acceptance: empty/partial/full/long estimate, saved/reopened/changed,
   approved/revised/declined/expired/converted, offline and failure cases. Inspect
   portrait, landscape, larger text and desktop before declaring the slice done.

For each correction, trace owner requirement → route/state → implementation →
focused test → actual rendered workflow. Tests alone cannot close a visual or
first-time-user requirement. Keep a specific incomplete item open rather than
presenting the entire estimate as finished.

## Additional owner requirement captured during this audit

Subscription cancellation must be as easy to find and complete as signup. Do not
hide cancellation, add unnecessary steps, or use visual hierarchy to conceal it.
This is owner direction for the subscription workflow, not a claim that a
subscription system was inspected or implemented in this estimate audit.

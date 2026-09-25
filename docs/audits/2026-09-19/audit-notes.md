# Whole-app audit — September 19, 2026

Status: in progress; audit only. Implementation changes are paused.
Audience: small businesses generally; contractors are a major target audience, not the product boundary.
Owner explicitly authorized launching the app and screenshots of every screen.

## Coverage method

screen-coverage.csv starts with 91 screen-named source files. This is an initial inventory, not proof of 91 distinct reachable routes or complete coverage. Add dialogs, sheets, startup, shared module homes and state variants as discovered. Record navigation, code, owning blueprint, wide/phone screenshots, enlarged text, keyboard/accessibility, permissions, persistence and error/recovery evidence. Never mark an unvisited screen passed.

Existing September 14 readiness audit is a historical starting point. Revalidate findings against current code; do not repeat old release-blocker claims without checking.

## Confirmed baseline from current task

- Windows debug build succeeds. This does not establish visual correctness.
- Inventory UI explicitly warns changes are not saved after closing; PrototypeOperationsStore holds stock/categories in memory. Separate ledger implementation is not wired to this UI.
- App startup connects SQLite-backed work, directory, workday, notes, expenses and receipt drafts. Persistence is mixed, not wholly absent.
- Receipt evidence review supports ordering and preview; complete overlapping-photo long-receipt capture/alignment remains unfinished.
- Current docs entry point contains dated and conflicting catalog-first/deferred notices. Latest owner scope defers catalog expansion and prioritizes whole-app audit.
- S24 upgrade remains blocked by signing-certificate mismatch; no uninstall/data erasure authorized or performed. Phone screenshots must identify the actual installed build, not pretend it is the new Windows build.

## Session log

- Loaded Computer Use skill and Windows API instructions. Initial window enumeration showed UI Lab was not running; launching the existing debug executable for inspection.
- No production source changes in this audit phase. Existing dirty implementation changes predate the audit authorization.

## Owner-expanded comparison scope

Compare current verified capabilities with Housecall Pro, Jobber, and the intended Service Pro product (name currently ambiguous). Use current official product documentation; marketing claims are not hands-on verification. Exclude tax preparation, QuickBooks integration, and regulated accounting/legal-service features. Do not promise competitive parity from a checklist. Compare complete workflows, usability, resilience, permissions, portability and practical value for small businesses. No arbitrary one-hour completion claim; coverage determines audit completion.

## Captured evidence

001-dashboard-wide.png and its accessibility text are retained under screenshots/. Initial window approximately 1268 by 714 screenshot pixels. Voice overlay partly obscures header; capture an unobscured replacement later. Dashboard currently includes mandatory-looking vehicle/technician framing and Field records subtitle: review fit for non-field small businesses. This is a product-fit question, not permission to redesign accepted dashboard now. Attempted navigation used an expired accessibility index and failed; no navigation result claimed. Reobserve before further action.

## Dashboard direct inspection — current wide window

Captured screenshots/002-dashboard-wide-unobscured.png using Computer Use. Observed approximately 1268 x 714 screenshot pixels; do not equate these with measured Flutter logical content width.

- Current view is Technician, with active vehicle and odometer prominent. This alone does not show whether Admin/general-business alternatives are adequate; inspect those separately.
- Large empty Today's Plan panel occupies about 600 pixels width, while most remaining space below it is blank. Empty state repeats No stops planned and Nothing is scheduled for this day without a visible contextual next action. Recommendation: evaluate useful empty-state action and vertical density without discarding accepted full-card color language.
- Calendar and summary cards use noticeably different visual treatments: heavily shaded gray calendar and shadowed text versus flatter colored summaries and blue plan. Consistency finding; preserve owner-approved palette pending blueprint reconciliation.
- Calendar bottom extends below initial viewport. Scroll reachability is unverified: attempted scroll was blocked because fresh user input changed window state. Do not mark this as clipping or inaccessible until actual scroll behavior is tested.
- Summary labels Payments, Expenses and Work do not themselves specify a date range. Header date may supply context, but inspect query interval and drill-down agreement before calling totals wrong.
- This is direct visual evidence of one wide empty dashboard state only. No full width sweep, populated-state review or native phone acceptance established.

## Expense setup: owner-led inspection

Captured 003-expense-setup-wide.png and accessibility tree. Basic selected; Detailed alternative; Continue. Approximately 760 screenshot-pixel-wide centered choices and full-width action in 1268-wide window. Much horizontal space for two choices; evaluate side-by-side alternatives at adequate local width and a bounded action against owning blueprint and owner feedback. No observed text clipping in this state. Accessibility tree reports buttons but does not expose selected state for Basic in its text; verify semantics implementation before logging a confirmed accessibility defect. Owner explicitly said not to delete demo data yet. No clicks or record mutations performed.

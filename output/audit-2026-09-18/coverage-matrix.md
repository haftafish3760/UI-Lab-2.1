# Audit coverage and remaining proof

This maps the audit, not a declaration that every workflow passed. Exact current failures and skips are in `test-failures.json`. Native integration files were inventoried but not executed on devices during this audit.

| Area | Inspected / exercised now | Proof still missing |
|---|---|---|
| Startup | Main, SQLite loader, account scope, initialization; independent debug-data-loss probe | Safe real first-run onboarding and separation from review installations |
| Identity/privacy | Firebase gateway, session grants, operational view, directory and expense permissions | Authenticated employee/company isolation, offline revocation, account switching and restricted exports |
| Employee creation | Stable profile ID, SQLite commit/revision checks, directory editor/drafts | New-profile-to-active-account/timekeeping connection, field-level compensation access |
| Employee Hours | Precise stored workday duration/pause model and fixed access set | Weekly timesheet UI, salary/hourly rate history, corrections/approval, earnings, export |
| Storage | Connection pragmas, integrity, revisions, atomic command/outbox, draft consumption, installation guard, restore code; full existing tests invoked | Future schema upgrade, replacement-device restore, hardware power loss, shared free-space policy |
| Expenses | Categories, picker, persistence bridge, report projection, amount summary, receipt transitions | Custom category persistence/search/report agreement, final user-reviewed category coverage |
| Receipt/evidence | Retention/hash/flush code, native-media boundaries, text draft editor; regression tests invoked | Physical camera/provider failures and full optional receipt-to-stock confirmation |
| Work | Record and financial models, persistence validation, assignments, schedules, lifecycle | Cancel/void/refund/credit lifecycle, final schedule availability rules, native complete workflow |
| Customers | Directory IDs and Work/PDF consumers | Stable customer/site linkage, duplicate-name and rename behavior in actual UI |
| Documents | PDF delivery authorization, current directory rendering, export audit, unused snapshot type; PDF tests and macOS build | Exact historical issued artifact, physical Windows/iOS/Android share and receipt acknowledgment |
| Reports | Independent partial-payment, same-name employee and EV category probes | Correct shared balances, as-of aging, complete labor/overhead/job-cost basis |
| Inventory | Current item/count/group mutations; independent SQLite close/reopen probe | Durable movement ledger and all stock/job/expense transaction boundaries |
| Reference catalog | Read-only counts for bundled browse DB and retained core packs; existing conversion tests invoked | Authoritative semantic validation of every field; owner decision about keeping catalog |
| Inventory parser | Isolated legacy test identified and compilation failure retained | Production parser implementation, complete recovered corpus and adversarial accuracy; separate owner-assigned effort |
| Maintenance | Normal shell destination and canned module page | Real vehicle/equipment service records, intervals, reminders and repair history |
| Backup/sync | Lower-level snapshot/restore code, global settings tile, account-only Firebase wiring | Real user backup/restore, cloud record transport/rules/conflicts and desktop account connection |
| Layout/accessibility | Shared layout engine and key screens; existing widget suite invoked | Owner visual acceptance, actual screen-reader/keyboard/physical-device review; failed fixtures cannot certify layout |
| Notifications | Native gateway setup, permission handling and test wording failures | Authorized final recipients, correct deep links/revocation, OS lifecycle/timing acceptance |
| Internationalization | Localization files, preferences and remaining literal/currency/unit boundaries | All visible form/search/error text and numeric input round trips in supported locales |
| QA infrastructure | Read storage test implementations; 22 Python harness tests passed; independent falsification probes | Repair stale fixtures, retain unsolved behavior failures, meaningful native and multi-account acceptance |

No test count establishes complete application coverage. A test that cannot find its target widget does not verify what happens after that widget is used. Source files listed in the manifest were inventoried, not all individually line-reviewed.

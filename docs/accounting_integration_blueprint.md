# Maintainiac Accounting Integration Blueprint

Status: explicitly deferred future architecture; no connector work is in the
current UI Lab or release-one scope, and no connector is implemented or
enabled.  
Purpose: keep Maintainiac easy to connect to QuickBooks or another accounting
provider later without making daily operations, local records, or the UI depend
on that provider.

## 1. Product boundary

Maintainiac is the source of truth for its operational records: customers and
service sites, estimates, jobs, issued invoices, recorded payments, business
expenses, receipt evidence, material cost history, schedules, assignments, and
audit history. An accounting product is a connected destination or explicitly
configured secondary source for accounting fields. It never becomes the owner
of Maintainiac's job workflow, photos, permissions, inventory certainty,
customer signature, or calendar.

Release one does not require an accounting account, network connection, provider
SDK, OAuth session, or successful export. Local create, edit, review, approval,
and correction continue to work when no connector exists or a connector is
offline.

QuickBooks is only a possible future adapter, not a current accommodation or a
schema embedded throughout the app. Until the product owner explicitly starts
a bounded accounting-integration slice, screens, records, workflows, storage,
tests, and release-one acceptance criteria must not be expanded for QuickBooks.
If that future slice is approved, the domain and UI use
`AccountingConnector` language; QuickBooks names, IDs, sync tokens, request
shapes, and error codes stay inside its adapter and mapping records.

## 2. Required architecture

```text
confirmed Maintainiac record
          |
          v
provider-neutral accounting command/outbox
          |
          v
AccountingConnector port
          |
          +---- QuickBooks adapter (later)
          +---- another provider adapter (optional later)
          |
          v
mapping + delivery result + audit evidence
```

Screens call Maintainiac application services. They do not import a QuickBooks
SDK, construct provider payloads, refresh provider credentials, or decide retry
policy. The adapter receives an immutable, versioned accounting command only
after the source record has passed its normal permission, validation, review,
and approval rules.

The future connector has six cohesive responsibilities:

1. translate a confirmed provider-neutral command into the provider contract;
2. resolve configured customer, vendor, item/service, account, tax, class, and
   location mappings;
3. authenticate through a separately stored connection;
4. submit or retrieve permitted accounting data;
5. normalize provider results and conflicts without leaking provider types into
   domain records; and
6. durably record mapping, outcome, retry state, and audit evidence.

## 3. Canonical records and field authority

Maintainiac records keep stable organization-scoped IDs, explicit revisions,
decimal-safe money, ISO currency codes, local and UTC times where appropriate,
and append-only audit links. Provider IDs are never used as Maintainiac primary
keys.

| Record or field | Default authority | Later connector behavior |
| --- | --- | --- |
| Customer/site identity used by Work | Maintainiac | map to or create an authorized accounting customer; never merge silently |
| Estimate and customer approval | Maintainiac | optional non-posting export of an exact approved/sent revision |
| Job status, assignment, photos, time, and material use | Maintainiac | not accounting records and not imported as provider truth |
| Issued Invoice revision and line calculation | Maintainiac | export only an authorized issued revision; mapping cannot rewrite the historical document |
| Recorded Payment | Maintainiac unless an owner enables a documented inbound payment policy | export or import through explicit deduplication and review rules |
| Business Expense and its approval state | Maintainiac | export only confirmed/approved records allowed by owner policy |
| Receipt image and reviewed line evidence | Maintainiac/Document Intake | never uploaded merely because the Expense is exported; evidence export is a separate permission and choice |
| Account, tax code, class, and provider location | configured per connection | selected through mapping; no guessed posting account |
| Provider reconciliation/closing state | accounting provider | can be displayed as provider status; cannot rewrite operational history |

Every bidirectional field needs a written field-authority rule before it is
enabled. Timestamp-based last-write-wins is prohibited for money, customer
identity, document status, approval, payment, tax, and account mapping.

## 4. External mapping contract

Provider mapping is separate infrastructure, not a field sprinkled into each
business object. A mapping record contains at minimum:

- organization ID and connection ID;
- provider key and provider company/realm identifier;
- Maintainiac record type, stable record ID, and mapped revision;
- provider entity type and opaque provider entity ID;
- provider concurrency token/version when the provider supplies one;
- mapping status: active, unresolved, conflicted, disconnected, or retired;
- last attempted and last successful synchronization times;
- last normalized outcome/error category, without secrets or excessive
  customer data; and
- audit references for who created, changed, confirmed, or retired the mapping.

Two Maintainiac records cannot silently claim the same provider entity, and one
record cannot silently switch provider entities. A proposed duplicate customer,
vendor, item, or account mapping is shown for an authorized human to resolve.

## 5. Durable outbox and idempotency

An export request first commits locally as an immutable accounting command. It
contains the organization, connection, source type, stable source ID, exact
source revision, requested operation, schema version, normalized payload hash,
requesting actor, permission revision, and creation time.

Its idempotency identity is derived from:

```text
organization + connection + source type + source ID + source revision + operation
```

Retries reuse that identity. A crash, timeout, duplicate tap, reconnect, or
process restart cannot create a second accounting transaction. Reusing the same
identity with different source content is a conflict, not an update.

Outbox states are `queued`, `sending`, `succeeded`, `retryable failure`,
`action required`, and `cancelled before send`. A provider timeout with an
unknown result enters reconciliation; it is not blindly created again. Provider
success stores the mapping and provider response evidence atomically with the
local completion state as far as the storage technology permits.

## 6. Direction, corrections, and conflicts

The first connector slice should default to deliberate one-way export from
confirmed Maintainiac records. Bidirectional import is added only record by
record after ownership and conflict rules are approved.

- A changed draft produces no accounting command.
- An issued document exports its exact immutable revision.
- A corrected issued Invoice produces an explicit update, void, credit, or
  replacement command according to approved accounting policy; it never edits
  history invisibly.
- Deleting a screen row never deletes a provider transaction.
- Provider-side edits are detected and shown as a conflict or provider status.
- Closed-period, reconciled, tax, duplicate, missing-mapping, validation, auth,
  rate-limit, and transport failures are normalized into actionable categories.
- Conflict resolution records the prior state, proposed result, actor, time,
  permission revision, and provider evidence.

## 7. Security and permissions

Connection and export authority are independent capabilities, including:

- `accounting.connection.view` and `accounting.connection.manage`;
- `accounting.mapping.view` and `accounting.mapping.manage`;
- `accounting.export.invoice`, `accounting.export.payment`, and
  `accounting.export.expense`;
- `accounting.sync.retry` and `accounting.conflict.resolve`; and
- separate permission to export receipt/document evidence.

Navigation, query/count, route, action, export, and background sync all recheck
organization membership, connection scope, capability, record scope, source
revision, and current permission revision. Hiding an integration button is not
authorization.

OAuth access/refresh credentials belong in approved secure credential storage
or a server-side secret boundary, never in business records, SQLite/Hive boxes,
analytics, logs, crash messages, source control, or exported backups. Each
connection is bound to one Maintainiac organization and one exact provider
company/realm. Disconnect revokes future use while retaining minimum audit and
mapping history required to explain prior exports.

## 8. UI and ordinary-language behavior

Accounting setup belongs under global **Settings > Connections**, not inside a
daily Invoice or Expense form and not behind every screen's contextual gear.
The future setup flow uses plain language:

1. Connect accounting software.
2. Choose the company.
3. Match customers, income/expense accounts, tax codes, services/items, classes,
   and locations that the chosen export types actually require.
4. Review what will be shared and who may send it.
5. Send a clearly labeled test record in the provider sandbox/test environment.
6. Turn on only the approved manual or automatic export policies.

Daily records show a compact status only when a connection is enabled and the
viewer is authorized: **Not sent**, **Queued**, **Sent**, **Needs mapping**,
**Connection required**, or **Could not send**. The exact source record remains
usable. A retry opens the exact failed command and does not create a new record.
Provider terminology can appear on the integration detail screen, but routine
Work and Expense UI remains provider-neutral.

## 9. Audit, privacy, and observability

Audit evidence includes source record/revision, command/schema version,
connection/provider company, operation, actor, permission revision, attempt
times, normalized request hash, outcome, provider entity mapping, conflict, and
resolution. Raw credentials are never audited. Full provider payloads are kept
only when an approved minimum-necessary retention policy requires them.

Operational telemetry may count success/failure categories and latency without
copying receipt images, line descriptions, customer contact data, or document
contents into analytics. Provider health cannot be reported as healthy solely
because the local queue accepted a command.

## 10. Implementation sequence and acceptance

No QuickBooks implementation or accommodation begins without a new, explicit
product-owner authorization after the source Customer, Invoice, Payment, and
Expense schemas and their permission/audit contracts are stable. If that
bounded integration slice is authorized later, it proceeds:

1. characterize the confirmed Maintainiac records and their revisions;
2. implement and test the provider-neutral command, mapping, and outbox ports;
3. add an in-memory/fake accounting adapter for deterministic failure and
   recovery tests;
4. add the QuickBooks adapter behind the same port;
5. use the provider's sandbox and current official API contract;
6. complete privacy, security, authorization, duplicate, conflict, reconnect,
   expiry, partial-failure, and accessibility review; and
7. expose the connection UI only after the entire route is auditable.

Required regression scenarios include duplicate submission, crash after remote
success but before local acknowledgment, expired/revoked credential, wrong
company/realm, missing customer/item/account mapping, provider-side edit,
offline queue/restart, permission revocation while queued, record revision while
queued, rate limit, partial batch failure, and two Maintainiac organizations
connected to different accounting companies.

Success means Maintainiac works fully without the connector, one confirmed
record cannot be posted twice, failures are recoverable and understandable, no
unauthorized data crosses the boundary, and a different accounting provider can
be added without changing operational screen models.

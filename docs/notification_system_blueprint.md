# Maintainiac Notification System Blueprint

Status: engineering foundation, Dashboard in-app binding, and the bounded
recurring-Expense native scheduling adapter are implemented; physical-device
delivery evidence and rendered owner acceptance remain incomplete.

Purpose: define one permission-scoped, offline-first notification system for
Dashboard, Work, Expenses, Materials, and later Maintenance/Repairs without
turning notifications into a second business-record store.

## 1. Product boundary

September 14 owner requirement (planning, not implementation evidence): provide
Android system notification categories so each device user can choose sounds,
vibration or silence by category. Alert settings should link to the appropriate
system category settings. Keep stable channel identities and respect user changes;
do not recreate channels to override a user's choices. Business urgency and
approval rules remain separate from device sound preferences. Exact category
names/grouping remain to be settled, including distinguishing urgent alerts
from routine updates. iOS must use its supported notification controls; its
action categories are not equivalent to Android's per-channel sound settings.

A notification reports a reminder or committed record change to one stable
employee recipient. It never owns the Job, Estimate, Invoice, Payment, Expense,
Material, Maintenance record, or approval decision that caused it.

Three systems remain deliberately separate:

1. **Notifications:** reminders and updates, unread/read/dismissed state, and
   optional in-app/push/sound delivery.
2. **Needs Attention:** decisions and exceptions requiring an authorized action,
   such as approving, declining, correcting, accepting, or resolving a record.
3. **Record activity and notes:** operational context attached to an exact
   business record. Release one does not include unrestricted employee chat.

Customer-facing payment-plan reminders are a fourth, separately governed
outbound-document communication. They are not employee notifications and never
appear in an employee unread count. The Invoice owns the plan and balance; a
customer consent record controls each email, SMS/text, or browser-push channel.
The outbound scheduler may reuse proven platform delivery adapters, retry
primitives, and failure codes, but it cannot reuse employee read scope,
read/dismissed state, or the Dashboard notification repository as customer
authority. `work_lifecycle_blueprint.md` owns the payment-plan and portal flow.

Reading or dismissing a notification cannot approve, decline, pay, skip,
reschedule, edit, or delete its source record. A notification may open only the
exact source route, where the owning module reauthorizes the current actor and
loads current business truth.

## 2. Source and migration decision

Maintainiac 5.7 does not provide an accepted app-wide notification engine. Its
known recurring-expense reminder store is behavior evidence for cadence only;
it is not copied into UI Lab and cannot become the shared owner.

UI Lab owns a new module-neutral foundation under
`lib/src/data/notifications/`. Dashboard notification items, unread count,
read-state mutation, localization, and the exact recurring-Expense route now
cross that authorized boundary together. The former prototype notification
center has been removed rather than retained as a competing visible store.

No screen imports a file repository or chooses a storage directory. App startup
opens private Application Support/app data, creates one
`AuthorizedNotificationService`, and injects an authorized controller beneath
the shell. Tests and isolated demonstrations may inject the same repository
behavior without persistence. The current source adapter publishes recurring-
Expense reminders only after the authorized recurring projection loads or
commits a data revision. Loading, pending-button, and failure-only controller
notifications do not republish or reread notification state. Work, Materials,
and later Maintenance/Repair event publishers remain separate bounded slices.

## 3. Durable event contract

Every notification event retains:

- stable notification ID and organization-scoped deduplication key;
- stable organization and recipient employee IDs;
- category and event kind;
- exact source module, source record type, source record ID, and optional child
  record ID;
- localizable title/message keys plus typed string arguments rather than an
  English-only stored sentence;
- scheduled UTC time and optional expiry time;
- requested in-app, push, and/or sound channels;
- unread, read, or dismissed state;
- revision, created/updated UTC times, actor, permission revision, action, and
  optional audit note.

An event is per recipient. A company-wide update creates deterministic events
for each currently eligible recipient; it does not expose one mutable global
read flag. Permission changes are reevaluated at query, count, route, action,
export, and sync boundaries.

## 4. Delivery contract

In-app visibility is event state, not proof that the operating system delivered
anything. Push and sound each receive a stable delivery record containing:

- stable delivery and notification IDs;
- organization and recipient IDs;
- channel and scheduled UTC time;
- pending, scheduled, delivered, failed, or cancelled state;
- attempt count, last-attempt UTC time, optional adapter reference, and stable
  failure code;
- independent revision and audit trail.

Valid delivery transitions are:

- pending → scheduled, failed, or cancelled;
- scheduled → delivered, failed, or cancelled;
- failed → scheduled or cancelled;
- delivered and cancelled are terminal.

Retrying the same notification/delivery definition is idempotent. Reusing its
ID or deduplication key for different content is a conflict, not an overwrite.

The current recurring-Expense adapter compiles for Android, iOS, macOS, and
Windows and owns permission-state checks, explicit permission requests,
inexact future scheduling, cancellation, restart reconciliation, generic
localized lock-screen copy, and ID-only tap payloads. Push plus sound on the
same event produces one operating-system notification while retaining separate
audited channel rows. Web and Linux honestly report this scheduling capability
as unsupported.

The app never asks for notification permission at startup. A labeled Enable
action in the planned-Expense workflow is the only current permission trigger.
Recurring reminders default to 9:00 AM local time instead of midnight, and
opening a native reminder reloads and reauthorizes the exact source record
before navigation. These are implementation and automated-test claims only.
Native delivery remains unaccepted until each supported platform independently
proves permission, scheduling, cancellation, restart, time-zone, foreground,
background, and tap behavior on a real runtime. A preference toggle, compile,
scheduled row, or queued request is not delivery evidence.

## 5. Privacy and localization

- Lock-screen content defaults to privacy-preserving generic copy. Showing a
  customer, vendor, amount, address, or work description requires an explicit
  account/device preview policy.
- Opening a notification requires app authentication and current owning-record
  authorization. A push payload is never authority.
- English, U.S. Spanish, and Canadian French render from message keys at the
  presentation or native-adapter boundary.
- Notification arguments are display input, not business truth. Amounts, dates,
  and names are reloaded from the authorized source record when opened.
- Exports and sync include only events and delivery data the active permission
  scope permits.

## 6. Authorization

The authorized service evaluates:

1. active organization and actor employee ID;
2. permission revision;
3. own, team, or company read scope;
4. target recipient scope;
5. publish capability for source/application services;
6. own or explicitly granted other-recipient read-state mutation;
7. platform-delivery management capability for trusted adapters.

Hiding a bell, count, row, or route is not enforcement. Denied events cannot
affect unread counts, category counts, reminders, Dashboard badges, deep-link
previews, exports, or sync payloads.

## 7. Offline storage and recovery

This is a historical local implementation checkpoint, not a global cloud-authority
decision. `data_storage_sync_contract.md` owns future category policy; U02 must
distinguish recipient-local read state, team events and backup.

The local repository uses serialized mutations and a checksummed two-slot JSON
snapshot in private Application Support/app data. It never writes business data
into Documents.

- A successful mutation survives restart.
- A failed write preserves the prior in-memory and on-disk snapshot.
- A damaged newest slot falls back to the prior valid slot and reports recovery.
- Two damaged slots produce an explicit corruption state; demo notifications
  never replace missing user data.
- Optional cloud sync later mirrors committed local state through an idempotent
  outbox. Network loss cannot prevent local read-state changes.

## 8. Source publication rules

An owning module publishes only after its source transaction commits. The
notification deduplication key includes the stable source event/revision,
recipient, kind, and scheduled occurrence where applicable.

Examples:

- a recurring Expense occurrence schedules one reminder event per recipient
  and reminder offset;
- a Job assignment publishes after the assignment revision commits;
- an Estimate or Invoice submission publishes to the specific authorized
  reviewer without becoming the approval itself;
- a Payment notification references the Payment/Invoice source and cannot
  alter the balance;
- a Materials warning references the exact material/location record and cannot
  adjust stock.

Source changes may cancel obsolete pending deliveries and publish a new event
with a new deduplication key. Previously delivered/read audit history remains.

## 9. Presentation contract

- The selected-date bell opens **Reminders and updates**; it never opens Needs
  Attention.
- Rows use the shared operations workspace, semantic state colors, bounded
  record containers, accessible text reflow, and exact-record navigation.
- Unread emphasis is visible without relying on color alone.
- Filters may expose permitted categories and unread/read history without a
  horizontal-scrolling control strip.
- Mark read, Mark unread, Dismiss, and Restore affect notification state only.
- An empty state says no reminders or updates are currently available; it does
  not claim the underlying modules have no work.

Visible binding requires one atomic replacement of prototype items, count,
mark-read behavior, and routing. Partial durable writes beside prototype reads
are prohibited. Dashboard completed that replacement for recurring-Expense
in-app reminders. The bounded native scheduling adapter now consumes the same
authorized events; it does not create a competing reminder source. This is
automated implementation evidence, not rendered owner acceptance or physical-
device delivery proof.

## 10. Deferred messaging boundary

Release one may support required reasons and record-attached notes for actions
such as Send back for correction, schedule changes, and work instructions.
General employee-to-employee chat remains deferred because it requires separate
retention, deletion, export, privacy, moderation, attachment, terminated-user,
sync, and legal-discovery policies. Notification records cannot be repurposed
as chat messages. Customer reminder consent and short structured document
responses likewise cannot be repurposed as a conversation thread.

## 11. Verification gate

- exact event and delivery identity survive restart;
- publish retry is idempotent and conflicting reuse is rejected;
- own/team/company scope excludes denied records from lists and counts;
- read/dismiss/restore is revisioned and cannot mutate source truth;
- exact source route survives persistence and reauthorizes on open;
- delivery transitions, attempts, failures, retry, cancellation, and terminal
  states are tested;
- expiry removes events from active unread counts while retaining history;
- failed writes and damaged-newest recovery preserve the last valid state;
- no production screen imports concrete/private notification repositories;
- localization, accessibility, narrow/wide layout, and privacy previews pass;
- native delivery claims require platform evidence;
- full analysis, tests, Android build, and macOS build pass;
- rendered owner acceptance remains separate from automated verification.

Company form follow-up, 2026-09-24

Implemented:
- Phone keyboard and shared US ten-digit input formatter; email and URL keyboards.
- Inline company-name, phone, and email validation.
- Back prompts Save changes / Discard changes / Keep editing for edited fields or logo.
- No-change Back discards only unnecessary editor recovery input and leaves saved profile intact.
- Recovery input survives interruption and failed saves. Unchanged explicit Save works.
- Parent Save/navigation blocked during logo import.
- Plain-language logo picker, saved logo displayed on profile, broader decoded image support.
- Removed full-form enclosing card and visible company payment-terms field; stored prior terms preserved.

Verification:
- 11 focused tests passed across company form navigation, company draft recovery, US phone formatter and company directory.
- Expanded company recovery test also passed after adding unchanged explicit Save coverage.
- Scoped analysis of six changed production files: no issues.
- Android debug build succeeded; adb install -r succeeded on S24 SM-S928U.
- Idle Gradle daemon stopped.
- Did not switch foreground from user's active ChatGPT Voice session.
- Physical device form walkthrough, iOS gesture verification and broader layout audit remain pending. No claim of complete app-wide audit or completed template work.

Follow-up: structured address and revised form
- Added persistent street, unit, city, state and ZIP parts to company profile and recovery payloads; existing formatted address remains available for document consumers.
- Recognizable legacy US addresses are split; unrecognized legacy text is preserved without guessing.
- Business category retained. Compact logo remains near top; address precedes contact information.
- Removed employee/view selectors from company editor header.
- Added explicit section shadows in both themes without changing unrelated SectionCard defaults.
- Fixed save action area and first-invalid-field focus/scroll.
- Latest run: 9 focused address/navigation/recovery tests passed; 8-file analysis clean; Android build and S24 installation succeeded.
- Inspected S24 screenshots /tmp/company-final-top.png and /tmp/company-final-address.png: separate address fields visible in intended order, saved logo and recovered phone present, Save changes remains visible.
- Light/dark narrow-screen large-text widget tests passed. Physical iOS and physical dark-mode appearance remain unverified.
- User deferred QR/CRM work and estimate return until company form review.

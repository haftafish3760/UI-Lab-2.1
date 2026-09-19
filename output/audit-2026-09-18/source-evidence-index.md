# Source evidence index

References are current implementation evidence, not product acceptance.

## AUD-01 — Critical: login does not establish business authority

- [lib/src/data/work/work_ui_lab_bootstrap.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/work_ui_lab_bootstrap.dart)
- [lib/src/data/work/directory_ui_lab_bootstrap.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/directory_ui_lab_bootstrap.dart)
- [lib/src/screens/expenses/expense_permissions.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/expenses/expense_permissions.dart)
- [lib/src/data/account/account_gateway.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/account/account_gateway.dart)

## AUD-02 — Critical: inventory additions are not durable

- [lib/src/data/prototype_operations_store.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/prototype_operations_store.dart)
- [lib/src/screens/inventory/inventory_item_entry_screen.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/inventory/inventory_item_entry_screen.dart)

## AUD-03 — Critical for affected debug installations: review loader deletes Work data

- [lib/src/startup/open_ui_lab_application.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/startup/open_ui_lab_application.dart)
- [lib/src/data/work/work_review_examples.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/work_review_examples.dart)

## AUD-04 — High: report outstanding amounts ignore partial payments

- [lib/src/data/prototype_report_projection.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/prototype_report_projection.dart)
- [lib/src/screens/expenses/reports_lanes.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/expenses/reports_lanes.dart)

## AUD-05 — High: names still act as record relationships

- [lib/src/data/prototype_report_projection.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/prototype_report_projection.dart)
- [lib/src/screens/work/customer_detail_screen.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/work/customer_detail_screen.dart)
- [lib/src/screens/work/work_pdf_delivery.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/work/work_pdf_delivery.dart)

## AUD-06 — High: category search and reporting disagree

- [lib/src/data/expenses/expense_category.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/expenses/expense_category.dart)
- [lib/src/screens/expenses/receipt_category_picker_screen.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/expenses/receipt_category_picker_screen.dart)
- [lib/src/data/prototype_report_projection.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/prototype_report_projection.dart)

## AUD-07 — High: employee profiles are not an earnings system

- [lib/src/data/work/employee_directory_profile.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/employee_directory_profile.dart)
- [lib/src/data/workday/workday_ui_lab_bootstrap.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/workday/workday_ui_lab_bootstrap.dart)
- [lib/src/data/workday/stored_workday_record.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/workday/stored_workday_record.dart)

## AUD-08 — High: backup/restore services are not a usable backup product

- [lib/src/shell/operations_menu_screen.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/shell/operations_menu_screen.dart)
- [lib/src/data/storage/local_restore_workflow.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/storage/local_restore_workflow.dart)
- [lib/src/data/account/firebase_account_gateway.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/account/firebase_account_gateway.dart)

## AUD-09 — High: issued document history can change when directory data changes

- [lib/src/screens/work/work_pdf_delivery.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/work/work_pdf_delivery.dart)
- [lib/src/screens/work/work_customer_document.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/work/work_customer_document.dart)
- [lib/src/shared/documents/generated_document_snapshot.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/shared/documents/generated_document_snapshot.dart)

## AUD-10 — High: financial lifecycle is incomplete

- [lib/src/data/prototype_financial_models.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/prototype_financial_models.dart)
- [lib/src/data/work/work_persistence_session.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/work_persistence_session.dart)
- [lib/src/data/work/models/work_models.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/models/work_models.dart)

## AUD-11 — High: receipt-to-inventory is not complete

- [lib/src/data/expenses/expense_ui_repository_bridge.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/expenses/expense_ui_repository_bridge.dart)
- [lib/src/data/work/job_materials_draft_workflow.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/job_materials_draft_workflow.dart)

## AUD-12 — High: low-storage admission and receipt-file collision safety remain gaps

- [lib/src/data/receipts/local_receipt_draft_repository.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/receipts/local_receipt_draft_repository.dart)
- [lib/src/data/storage/local_attachment_store.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/storage/local_attachment_store.dart)
- [lib/src/data/device_capabilities/device_workload_service.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/device_capabilities/device_workload_service.dart)

## AUD-13 — High: current regression baseline is failing

- [test/inventory_legacy_parser_contract_test.dart](/Volumes/AppleWork/UI-Lab-2.1/test/inventory_legacy_parser_contract_test.dart)
- [test/prototype_report_projection_test.dart](/Volumes/AppleWork/UI-Lab-2.1/test/prototype_report_projection_test.dart)
- [test/local_database_interruption_test.dart](/Volumes/AppleWork/UI-Lab-2.1/test/local_database_interruption_test.dart)

## AUD-14 — Maintenance/repair

- [lib/src/shell/app_shell.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/shell/app_shell.dart)
- [lib/src/screens/modules/module_home_screen.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/modules/module_home_screen.dart)

## AUD-15 — Scheduling/calendar

- [lib/src/data/work/job_schedule_draft_workflow.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/job_schedule_draft_workflow.dart)
- [lib/src/data/work/work_assignment_validation.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/work_assignment_validation.dart)

## AUD-16 — Quotes

- [lib/src/data/work/models/work_models.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/work/models/work_models.dart)

## AUD-17 — Localization/accessibility/layout

- [lib/src/layout/app_layout_engine.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/layout/app_layout_engine.dart)
- [test/expense_record_card_accessibility_test.dart](/Volumes/AppleWork/UI-Lab-2.1/test/expense_record_card_accessibility_test.dart)

## AUD-18 — Device support

- [ios/Runner.xcodeproj/project.pbxproj](/Volumes/AppleWork/UI-Lab-2.1/ios/Runner.xcodeproj/project.pbxproj)
- [android/app/build.gradle.kts](/Volumes/AppleWork/UI-Lab-2.1/android/app/build.gradle.kts)

## AUD-19 — Scale/performance

- [lib/src/data/storage/sqlite_domain_snapshot_store.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/storage/sqlite_domain_snapshot_store.dart)
- [lib/src/screens/inventory/catalog/inventory_catalog_database.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/screens/inventory/catalog/inventory_catalog_database.dart)

## AUD-20 — Notifications

- [lib/src/data/notifications/flutter_local_notification_gateway.dart](/Volumes/AppleWork/UI-Lab-2.1/lib/src/data/notifications/flutter_local_notification_gateway.dart)

## AUD-21 — Reference catalog

- [assets/inventory/browse_batch.sqlite](/Volumes/AppleWork/UI-Lab-2.1/assets/inventory/browse_batch.sqlite)
- [test/inventory_catalog_conversion_test.dart](/Volumes/AppleWork/UI-Lab-2.1/test/inventory_catalog_conversion_test.dart)
- [test/inventory_batch_verification_test.dart](/Volumes/AppleWork/UI-Lab-2.1/test/inventory_batch_verification_test.dart)

#!/bin/zsh

set -euo pipefail

source_root="${MAINTAINIAC_5_7_SOURCE_ROOT:-/Users/rbbie/Documents/Maintainiac_5.7_Active}"
scope="${1:-help}"

usage() {
  print -r -- 'Usage: tool/audit_maintainiac_5_7_source.sh <scope>'
  print -r -- 'Scopes: expenses, receipts, inventory, qa, all'
  print -r -- 'The command is read-only and writes its manifest to standard output.'
}

if [[ "$scope" == 'help' || "$scope" == '--help' || "$scope" == '-h' ]]; then
  usage
  exit 0
fi

if [[ ! -d "$source_root/.git" ]]; then
  print -u2 -r -- "Protected 5.7 source is unavailable: $source_root"
  exit 2
fi

typeset -a roots
case "$scope" in
  expenses)
    roots=(
      'lib/screens/expenses/data'
      'lib/shared/records'
      'lib/shared/storage'
      'lib/shared/profiles/user_permissions.dart'
      'lib/shared/profiles/user_profile_models.dart'
      'lib/shared/profiles/employee_permission_pack_store.dart'
    )
    ;;
  receipts)
    roots=(
      'lib/shared/receipts'
      'lib/shared/widgets/receipt_capture'
      'test/fixtures/receipt_qa'
      'test/helpers'
    )
    ;;
  inventory)
    roots=(
      'lib/screens/work_supplies/data'
      'test/fixtures/work_supply_parser'
      'test/support/work_supply_parser_qa'
    )
    ;;
  qa)
    roots=(
      'test/support/qa_harness'
      'tool/maintainiac_qa_backbone.dart'
      'docs/inventory_parser_qa_harness_contract_completion_checklist.md'
      'docs/maintainiac_operating_directive.md'
    )
    ;;
  all)
    roots=(
      'lib/screens/expenses/data'
      'lib/screens/work_supplies/data'
      'lib/shared/receipts'
      'lib/shared/widgets/receipt_capture'
      'lib/shared/records'
      'lib/shared/storage'
      'lib/shared/profiles/user_permissions.dart'
      'lib/shared/profiles/user_profile_models.dart'
      'lib/shared/profiles/employee_permission_pack_store.dart'
      'test/fixtures/receipt_qa'
      'test/fixtures/work_supply_parser'
      'test/helpers'
      'test/support/qa_harness'
      'test/support/work_supply_parser_qa'
      'tool/maintainiac_qa_backbone.dart'
      'docs/inventory_parser_qa_harness_contract_completion_checklist.md'
      'docs/maintainiac_operating_directive.md'
    )
    ;;
  *)
    print -u2 -r -- "Unknown audit scope: $scope"
    usage >&2
    exit 2
    ;;
esac

cd "$source_root"

print -r -- "scope\t$scope"
print -r -- "sourceRoot\t$source_root"
print -r -- "branch\t$(git branch --show-current)"
print -r -- "head\t$(git rev-parse HEAD)"
print -r -- "statusSha256\t$(git status --porcelain=v1 | shasum -a 256 | awk '{print $1}')"
print -r -- 'sha256\tbytes\tlines\tpath'

for root in "${roots[@]}"; do
  if [[ ! -e "$root" ]]; then
    print -u2 -r -- "Mapped source is missing: $root"
    exit 3
  fi

  if [[ -f "$root" ]]; then
    files=("$root")
  else
    files=("${(@f)$(find "$root" -type f \( \
      -name '*.dart' -o \
      -name '*.json' -o \
      -name '*.md' -o \
      -name '*.sh' \
    \) | LC_ALL=C sort)}")
  fi

  for file in "${files[@]}"; do
    [[ -n "$file" ]] || continue
    checksum="$(shasum -a 256 "$file" | awk '{print $1}')"
    bytes="$(stat -f '%z' "$file")"
    lines="$(wc -l < "$file" | tr -d ' ')"
    print -r -- "$checksum\t$bytes\t$lines\t$file"
  done
done

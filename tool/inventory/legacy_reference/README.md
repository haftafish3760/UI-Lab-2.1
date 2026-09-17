# Unaccepted legacy QA reference

This dependency-closed snapshot exists so checked-in characterization tests and
export tooling do not depend on disposable build output. It is NOT imported by
application code and is NOT evidence of catalog accuracy or parser acceptance.
No Hive persistence is introduced. Only Dart libraries and crypto are imported.

`manifest.json` records every original file hash and the earlier Windows export
hash. Capture verified all files against that export, allowing only LF/CRLF
line-ending differences. Source bytes were preserved. The protected source was
not changed or executed. Capture tooling lives in `tooling/inventory_qa`.

Retain legacy assertions as characterization, never as automatic desired behavior.
Review and port the larger QA corpus separately. Do not edit this snapshot to make
legacy expectations pass; put corrected production behavior behind new domain
interfaces and test independently. Legacy generated/large source files retain
original boundaries for provenance; they are not new production Dart files.

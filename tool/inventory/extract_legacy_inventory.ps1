param(
  [string]$SourceRoot = 'C:\Users\noneya\Documents\Maintainiac_5.7_Active'
)
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$source = (Resolve-Path (Join-Path $SourceRoot 'lib/screens/work_supplies/data')).Path
$destination = Join-Path $workspace 'build/inventory_migration/source'
if (Test-Path -LiteralPath $destination) {
  throw 'Extraction already exists. Preserve it and use a fresh workspace for another source snapshot.'
}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$manifest = @()
foreach ($file in (Get-ChildItem -LiteralPath $source -Recurse -File | Sort-Object FullName)) {
  $relative = $file.FullName.Substring($source.Length + 1)
  $target = Join-Path $destination $relative
  New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
  $before = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
  Copy-Item -LiteralPath $file.FullName -Destination $target
  $after = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
  $copied = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
  if ($before -ne $after -or $before -ne $copied) { throw "Source changed: $relative" }
  $manifest += [ordered]@{path=$relative.Replace('\','/'); sha256=$before.ToLower(); bytes=$file.Length}
}
$evidence = Join-Path $workspace 'docs/inventory_migration'
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
[ordered]@{
  sourceRoot=$SourceRoot
  sourceHead=(& git -C $SourceRoot rev-parse HEAD)
  sourceStatus=(@(& git -C $SourceRoot status --porcelain -- lib/screens/work_supplies/data))
  scope='lib/screens/work_supplies/data only; not complete OCR or UI dependency graph'
  files=$manifest
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidence 'source_manifest.json') -Encoding utf8
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'export_core_catalog.dart.template') -Destination (Join-Path $workspace 'build/inventory_migration/export_core_catalog.dart')
Write-Output "Extracted $($manifest.Count) verified files. Protected source was read only."
$dartCommand = (Get-Command dart).Source
$directSdk = Join-Path (Split-Path $dartCommand) 'cache/dart-sdk/bin/dart.exe'
if (Test-Path -LiteralPath $directSdk) { $dartCommand = $directSdk }
Push-Location -LiteralPath $workspace
try {
  & $dartCommand "--packages=$workspace/.dart_tool/package_config.json" (Join-Path $workspace 'build/inventory_migration/export_core_catalog.dart')
  if ($LASTEXITCODE -ne 0) { throw 'Core export failed; snapshot retained for diagnosis.' }
} finally { Pop-Location }

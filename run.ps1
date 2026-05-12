# Convenience launcher. Reads credentials from supabase.json in the project root.
# Pass any extra args through, e.g. `.\run.ps1 -d chrome` or `.\run.ps1 --release`.

param(
  [string]$ConfigFile = "supabase.json",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ExtraArgs
)

if (-not (Test-Path $ConfigFile)) {
  Write-Error "Config file '$ConfigFile' not found. Create it with SUPABASE_URL and SUPABASE_ANON_KEY."
  exit 1
}

flutter run --dart-define-from-file=$ConfigFile @ExtraArgs

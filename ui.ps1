# Kosika Designs: design any screen from one sentence.
#
#   .\ui.ps1 "a landing page for a quiet coffee shop"
#   .\ui.ps1 "a dark agent window for my research assistant"
#   .\ui.ps1 "a phone app for learning Japanese" -Out japanese.html
#
# A free Groq model writes what the screen says and which blocks it holds;
# kosika/std/designs_ui.kos checks it and draws every block in one calm,
# minimal design system (websites, phone screens, agent windows, artifacts).
# With no key, or if the model fails, Kosika lays the screen out itself.
# Needs GROQ_API_KEY as a user environment variable. Opens the page when done.
param(
  [Parameter(Mandatory = $true)][string]$Prompt,
  [string]$Model = "openai/gpt-oss-120b",
  [string]$ModelUrl = "https://api.groq.com/openai/v1",
  [string]$Out = "ui.html",
  [string]$Kosika = "kosika"
)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$kosikaHome = if ($env:KOSIKA_HOME) { $env:KOSIKA_HOME } else { Join-Path $here "..\kosika" }
$module = Join-Path $kosikaHome "kosika\std\designs_ui.kos"
$work = Join-Path ([IO.Path]::GetTempPath()) "kosika-designs"
New-Item -ItemType Directory -Force $work | Out-Null
$env:KOSIKA_MODEL_API_KEY = [Environment]::GetEnvironmentVariable("GROQ_API_KEY", "User")

@{ ask = @{ text = $Prompt; target = ""; theme = ""; accent = "" } } | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $work "ui-ask.json")
$said = & $Kosika run $module --workflow design_ui --input (Join-Path $work "ui-ask.json") `
  --model $Model --model-url $ModelUrl --model-protocol openai --model-timeout 400 --max-output-tokens 8000 | Out-String
$record = ($said -split "`nTrace:")[0]
if (-not $record.TrimStart().StartsWith("{")) { throw $record.Trim() }
$result = $record | python -c "import ast, json, sys; print(json.dumps(ast.literal_eval(sys.stdin.read())))" | ConvertFrom-Json
[IO.File]::WriteAllText((Join-Path (Get-Location) $Out), $result.page)
Write-Host "Designed: $($result.title) ($($result.target)), $($result.fixed.Count) things fixed by Kosika"
Start-Process (Join-Path (Get-Location) $Out)

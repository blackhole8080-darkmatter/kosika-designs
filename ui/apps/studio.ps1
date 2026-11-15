# Designs Studio: draws its own window with Kosika Designs, serves it, and opens it.
#   .\ui\apps\studio.ps1            (dark)      .\ui\apps\studio.ps1 -Theme light
# Needs kosika-native on PATH and GROQ_API_KEY as a user environment variable.
param([string]$Theme = "dark", [string]$Port = "8790", [string]$Kosika = "kosika-native")
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$app = Join-Path $here "studio.kos"
$work = Join-Path ([IO.Path]::GetTempPath()) "kosika-designs"
New-Item -ItemType Directory -Force $work | Out-Null
@{ w = @{ theme = $Theme } } | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $work "studio-win.json")
$drawn = (& $Kosika run $app --workflow studio_window --input (Join-Path $work "studio-win.json") --json | Select-Object -First 1) | ConvertFrom-Json
$page = Join-Path $work "studio.html"
[IO.File]::WriteAllText($page, $drawn.page)
$env:KOSIKA_MODEL_API_KEY = [Environment]::GetEnvironmentVariable("GROQ_API_KEY", "User")
Start-Process "http://127.0.0.1:$Port/"
& $Kosika serve $app --page $page --port $Port --model openai/gpt-oss-120b --model-url https://api.groq.com/openai/v1 --model-protocol openai --model-timeout 400 --max-output-tokens 8000

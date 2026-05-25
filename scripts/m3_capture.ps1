param([string]$Name)
$root = "g:\GitHub\petfolio\docs\automation\m3_redesign_review_2026-05-25"
$png = Join-Path $root "screenshots\$Name.png"
$xml = Join-Path $root "ui-dumps\$Name.xml"
cmd /c "adb exec-out screencap -p > `"$png`""
adb shell uiautomator dump /sdcard/ui.xml 2>$null | Out-Null
adb pull /sdcard/ui.xml $xml 2>$null | Out-Null
if ((Get-Item $png -ErrorAction SilentlyContinue).Length -lt 1000) { throw "bad png $Name" }

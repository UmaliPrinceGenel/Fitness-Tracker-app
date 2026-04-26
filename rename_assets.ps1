$baseDir = "d:\Fitness App\Fitness-Tracker-app"
$assetsDir = Join-Path $baseDir "assets\Fitness Journey"

# 1. Rename files and directories bottom-up
Get-ChildItem -Path $assetsDir -Recurse | Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true} | Where-Object {$_.Name -match ' '} | Rename-Item -NewName {$_.Name -replace ' ', '_'}

# 2. Rename the base folder itself
$oldAssetsDir = Join-Path $baseDir "assets\Fitness Journey"
$newAssetsDir = Join-Path $baseDir "assets\Fitness_Journey"
if (Test-Path $oldAssetsDir) {
    Rename-Item -Path $oldAssetsDir -NewName "Fitness_Journey"
}

# 3. Update pubspec.yaml
$pubspecPath = Join-Path $baseDir "pubspec.yaml"
$pubspecContent = Get-Content -Path $pubspecPath -Raw
# Replace " " with "_" for lines starting with "- assets/Fitness Journey/"
$pubspecLines = $pubspecContent -split "`n"
for ($i = 0; $i -lt $pubspecLines.Length; $i++) {
    if ($pubspecLines[$i] -match "^\s*-\s*assets/Fitness Journey/") {
        $pubspecLines[$i] = $pubspecLines[$i] -replace ' ', '_'
    }
}
$pubspecLines -join "`n" | Set-Content -Path $pubspecPath

# 4. Update video_mapping_service.dart
$dartPath = Join-Path $baseDir "lib\services\video_mapping_service.dart"
$dartContent = Get-Content -Path $dartPath -Raw

# Replace using regex evaluating replacing spaces within 'assets/Fitness Journey/...'
$dartContent = [regex]::Replace($dartContent, "'assets/Fitness Journey/[^']+'", {
    param($match)
    $match.Value -replace ' ', '_'
})

$dartContent | Set-Content -Path $dartPath

Write-Host "Renaming and updating complete!"

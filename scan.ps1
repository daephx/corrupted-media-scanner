param (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$dir,
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [Int]$threads = 4
)

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$handbrakePath = $scriptPath + "\HandBrakeCLI.exe"

if (!(Test-Path $handbrakePath)) {
    Write-Output "`nYou need to download HandBrakeCLI.exe and place it in the same directory as this script. `nDownload link: https://handbrake.fr/downloads2.php `nPress N to close the script or Y to open the above link to download."
    do {
        $keyPress = [System.Console]::ReadKey()
    }
    until ($keyPress.Key -eq "Y" -or $keyPress.Key -eq "N")
    if ($keyPress.Key -eq "Y") {
        Start-Process 'https://handbrake.fr/downloads2.php'
        Write-Output "`n"
        exit
    } else {
        Write-Output "`n"
        exit
    }
}

if ($threads -gt 4) {
    Write-Output "`nWARNING: Selecting more than 4 threads may lock up your computer. Press N to set threads to 4 or press Y to continue..."
    do {
        $keyPress = [System.Console]::ReadKey()
    }
    until ($keyPress.Key -eq "Y" -or $keyPress.Key -eq "N")
    if ($keyPress.Key -eq "N") {
        $threads = 4
    }
}

$startTime = Get-Date
$currentDirectory = $dir
Write-Output "`nScanning $currentDirectory..."

$errorLogPath = $scriptPath + "\error.log"
$goodLogPath = $scriptPath + "\good.log"

if (!(Test-Path $goodLogPath)) {
    New-Item -path $scriptPath -name good.log -type "file"
    Write-Output "Created good log file"
}
else {
    Write-Output "`ngood.log file exists. Overwrite? Press N to append to existing file or Y to clear file."
    do {
        $keyPress = [System.Console]::ReadKey()
    }
    until ($keyPress.Key -eq "Y" -or $keyPress.Key -eq "N")
    if ($keyPress.Key -eq "Y") {
        Clear-Content $goodLogPath
    }
}

if (!(Test-Path $errorLogPath)) {
    New-Item -path $scriptPath -name error.log -type "file"
    Write-Output "Created error log file"
}
else {
    Write-Output "`nerror.log file exists. Overwrite? Press N to append to existing file or Y to clear file."
    do {
        $keyPress = [System.Console]::ReadKey()
    }
    until ($keyPress.Key -eq "Y" -or $keyPress.Key -eq "N")
    if ($keyPress.Key -eq "Y") {
        Clear-Content $errorLogPath
    }
}

Write-Output "`nCounting items..."

$files = (Get-ChildItem "$currentDirectory" *.* -R -File).FullName
$totalItems = $files.Count
Write-Output "$totalItems items to scan"
$completedItems = 0
Write-Output "Scanning in progress..."

$scriptBlock = {
    Param($file, $handbrake, $errorLog, $goodLog)
    $emtx = new-object System.Threading.Mutex($false, "ErrorLogFileAccessMTX")
    $gmtx = new-object System.Threading.Mutex($false, "GoodLogFileAccessMTX")
    $result = &$handbrake -i $file --scan 2>&1 | Out-String
    if ($result.Contains("EBML header parsing failed")) {
        $emtx.WaitOne(5000)
        "$file | EBML header parsing failed (highly likely won't play)" >> "$errorLog"
        $emtx.ReleaseMutex()
    }
    elseif ($result.Contains("Read error at pos. 1 (0x1)")) {
        $emtx.WaitOne(4000)
        "$file | Read error at pos. 1 (0x1) (highly likely won't play)" >> "$errorLog"
        $emtx.ReleaseMutex()
    }
    elseif ($result.Contains("Read error")) {
        $emtx.WaitOne(3000)
        "$file | Read error (usually will still play)" >> "$errorLog"
        $emtx.ReleaseMutex()
    }
    else {
        $gmtx.WaitOne(100)
        "$file OK!" >> "$goodLog"
        $gmtx.ReleaseMutex()
    } 
}

$files | ForEach-Object {
    $completedItems++
    $running = @(Get-Job | Where-Object { $_.State -eq 'Running' })
    if ($running.Count -ge $threads) {
        $running | Wait-Job -Any | Out-Null
    }

    Start-Job -Scriptblock $scriptblock -ArgumentList @($_, $handbrakePath, $errorLogPath, $goodLogPath) | Out-Null
    if ($totalItems -ne 0) {
        Write-Progress -Activity "Scan" -Status "Progress($completedItems/$totalItems) - $_" -PercentComplete ($completedItems / $totalItems * 100)
    }
}

# Wait for all jobs to complete and results ready to be received
Wait-Job * | Out-Null

Write-Progress -Activity "Scan" -Status "Progress($completedItems/$totalItems):" -Completed
$totalErrors = (Get-Content $errorLogPath | Measure-Object -Line).Lines
$finishTime = Get-Date
$timeTaken = $finishTime - $startTime

Remove-Job -State Completed

Write-Output "Scan took $($timeTaken.Days) Days $($timeTaken.Hours) Hours $($timeTaken.Minutes) Minutes $($timeTaken.Seconds) Seconds"
Write-Output "$($totalErrors) files with problems. Refer to error.log for a list of problem files and good.log for good files."
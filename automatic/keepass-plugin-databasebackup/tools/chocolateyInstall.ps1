﻿$packageName = '{{PackageName}}'
$typName = 'dbBackup.plgx'
$packageSearch = 'KeePass Password Safe'
$url = '{{DownloadUrl}}'
$checksum = '{{Checksum}}'
$checksumType = 'sha1'
try {
# search registry for location of installed KeePass
$regPath = Get-ItemProperty -Path @('HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                                    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                                    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*') `
                            -ErrorAction:SilentlyContinue `
           | Where-Object {$_.DisplayName -like "$packageSearch*" `
                           -and `
                           $_.DisplayVersion -ge 2.27 `
                           -and `
                           $_.DisplayVersion -lt 3.0 } `
           | ForEach-Object {$_.InstallLocation}
$installPath = $regPath
# search $env:ChocolateyBinRoot for portable install
if (! $installPath) {
  Write-Verbose "$($packageSearch) not found installed."
  $binRoot = Get-BinRoot
  $portPath = Join-Path $binRoot "keepass"
  $installPath = Get-ChildItem -Directory $portPath* -ErrorAction SilentlyContinue
}
if (! $installPath) {
  Write-Verbose "$($packageSearch) not found in $($env:ChocolateyBinRoot)"
  throw "$($packageSearch) location could not be found."
}
$pluginPath = (Get-ChildItem -Directory $installPath\Plugin*).FullName
if ($pluginPath.Count -eq 0) {
  $pluginPath = Join-Path $installPath "Plugins"
  [System.IO.Directory]::CreateDirectory($pluginPath)
}
# download and extract PLGX file into Plugins dir
Install-ChocolateyZipPackage -PackageName "$packageName" `
                             -Url "$url" `
                             -UnzipLocation "$pluginPath" `
                             -Checksum "$checksum" `
                             -ChecksumType "$checksumType"
# rename PLGX file so it is clear which plugins are managed via choco
$typPlugin = Join-Path $pluginPath $typName
$chocoPlugin = Join-Path $pluginPath "$($packageName).plgx"
Move-Item -Path $typPlugin -Destination $chocoPlugin -Force
if ( Get-Process -Name "KeePass" `
                 -ErrorAction SilentlyContinue ) {
  Write-Warning "$($packageSearch) is currently running. Plugin will be available at next restart of $($packageSearch)." 
} else {
  Write-Host "$($packageName) will be loaded the next time KeePass is started."
  Write-Host "Please note this plugin may require additional configuration. Look for a new entry in KeePass' Menu>Tools"
}} catch {
  throw $_.Exception
}
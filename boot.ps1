$avd_name = "pixel_root"
$avd_path = "E:\shrek\.android\avd\Pixel_5_API_30.avd"

Write-Host "[*] Clearing trash..."
netsh interface portproxy reset
taskkill /IM "adb.exe" /F
taskkill /IM "qemu-system-x86_64.exe" /F
Remove-Item -Force $avd_path"/*.lock"
Write-Host "Done.`n"

Write-Host "[*] Looking for inactive port..."
$ANDROID_SERIAL="emulator-5554"
$ADB_SERVER_PORT=Get-InactiveTcpPortNumber
Write-Host "$ADB_SERVER_PORT`n"

Write-Host "[*] Determining IP address..."
$ADB_SERVER_ADDR=(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Беспроводная сеть").IPAddress
Write-Host "$ADB_SERVER_ADDR`n"

while ($true) {
    $is_coldboot=Read-Host -Prompt "Do you want to perform coldboot? [Y/n]"
    if ($is_coldboot -match "y|Y|") {
        $coldboot_status = "coldboot"
        $emulator_argument_list = "@pixel_root -no-snapshot-load -writable-system"
    } elseif ($is_coldboot -match "n|N") {
        $coldboot_status = "no coldboot"
        $emulator_argument_list = "@pixel_root"
    } else {
        continue
    }
    break
}
Write-Host "`n[*] Starting emulator ($coldboot_status)...`n"
Start-Process emulator -ArgumentList "$emulator_argument_list" -WindowStyle Hidden

Write-Host "[*] Starting adb server on port $ADB_SERVER_PORT...`n"
Start-Process adb -ArgumentList "-a -P $ADB_SERVER_PORT nodaemon server" -WindowStyle Hidden

Write-Host "[*] Connecting adb server to adb daemon..."
while ($true) {
    $adb_connect_status=(adb -P $ADB_SERVER_PORT connect 5555)
    if ($adb_connect_status -match "connected to") {
        Write-Host "Connected.`n"
        break
    }
    Write-Host "Not connected.`n"
    Timeout /T 1
}

Write-Host "[*] Saving adb port and IP address to memory shared with kali..."
$ADB_SERVER_PORT | Out-File -FilePath "E:\projects\security\kali_shared\messenger\adb_port"
$ADB_SERVER_ADDR | Out-File -FilePath "E:\projects\security\kali_shared\messenger\ip_addr"
Write-Host "Done.`n"

Read-Host -Prompt "Press Enter to exit"

<#
Following is supposed to be done on kali side

Write-Host "[*] Exposing port $ADB_SERVER_PORT to external network..."
# netsh interface portproxy add v4tov4 listenport=$ADB_SERVER_PORT listenaddress='127.0.0.1' connectport=$ADB_SERVER_PORT connectaddress='0.0.0.0'
Write-Host "Done.`n"

$DROZER_AGENT_PORT=31415

Write-Host "[*] Forwarding $DROZER_AGENT_PORT to drozer agent server port $DROZER_AGENT_PORT on emulator..."
while ($true) {
    adb -P $ADB_SERVER_PORT -s $ANDROID_SERIAL forward tcp:$DROZER_AGENT_PORT tcp:$DROZER_AGENT_PORT
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$DROZER_AGENT_PORT -> $DROZER_AGENT_PORT success`n"
        break
    }
    Timeout /T 1
}
# netsh interface portproxy add v4tov4 listenport=$DROZER_AGENT_PORT listenaddress='127.0.0.1' connectport=$DROZER_AGENT_PORT connectaddress='0.0.0.0'

$FRIDA_SERVER_PORT=27042
Write-Host "[*] Forwarding $FRIDA_SERVER_PORT to frida server port $FRIDA_SERVER_PORT on emulator..."
while ($true) {
    adb -P $ADB_SERVER_PORT -s $ANDROID_SERIAL forward tcp:$FRIDA_SERVER_PORT tcp:$FRIDA_SERVER_PORT
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$FRIDA_SERVER_PORT -> $FRIDA_SERVER_PORT success`n"
        break
    }
    Timeout /T 1
}
# netsh interface portproxy add v4tov4 listenport=$FRIDA_SERVER_PORT listenaddress='127.0.0.1' connectport=$FRIDA_SERVER_PORT connectaddress='0.0.0.0'

#>
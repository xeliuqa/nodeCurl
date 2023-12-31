$host.UI.RawUI.WindowTitle = "Node Curl"
Write-Host -ForegroundColor Green "
	----------------------------------------
	        Welcome to nodeCurl
	----------------------------------------"
function main {

    while ($selection -ne 'Q') {
        Clear-Host
        #Main Menu
        $ip = Read-Host -Prompt "Please select IP Address (default 127.0.0.1)"
        if ([string]::IsNullOrWhiteSpace($ip)) { $ip = "127.0.0.1" }
        Write-Host $ip -ForegroundColor Green

        $port1 = Read-Host -Prompt "Please select Port 1 (default 9092)"
        if ([string]::IsNullOrWhiteSpace($port1)) { $port1 = "9092" }
        Write-Host $port1 -ForegroundColor Green

        $port2 = Read-Host -Prompt "Please select Port 2 (default 9093)"
        if ([string]::IsNullOrWhiteSpace($port2)) { $port2 = "9093" }
        Write-Host $port2 -ForegroundColor Green

        Write-Host -ForegroundColor Yellow "
    ------------------------------
    |         Main Menu          |
    ------------------------------"
        $MenuOptions = @'
	"Press '0' - Restart (Change Ports)"
	"Press '1' - Events Stream"
	"Press '2' - Check Node status"
	"Press '3' - Node Version"
	"Press '4' - Smesh Service"
	"Press '5' - Highest ATX"
	"Press '6' - Node ID"
	"Press '7' - PoST Status"
	"Press '8' - Check if banned"
	"Press 'Q' - Quit."
'@

        "`n$MenuOptions"

        :selectionLoop while (($selection = Read-Host -Prompt "`nSelect a option") -ne 'Q') {
            Clear-Host

            "`n$MenuOptions"

            switch ( $selection ) {
                0 { break selectionLoop }
                1 {
                    write-host "`n"
                    write-host "Please wait ..." 
                    $job = Start-Job -ScriptBlock {
                        param($ip, $port2)
                        ./grpcurl.exe -plaintext "$($ip):$($port2)" "spacemesh.v1.AdminService.EventsStream"
                    } -ArgumentList $ip, $port2
                    Wait-Job -Timeout 2 -Job $job
                    Receive-Job -Job $job
                    Remove-Job -Job $job -Force
                }
                #1 { ./grpcurl.exe -plaintext "$($ip):$($port2)" "spacemesh.v1.AdminService.EventsStream"}
                2 { ./grpcurl.exe -plaintext "$($ip):$($port1)" "spacemesh.v1.NodeService.Status" }
                3 { ./grpcurl.exe -plaintext "$($ip):$($port1)" "spacemesh.v1.NodeService.Version" }
                4 { ./grpcurl.exe -plaintext "$($ip):$($port2)" "spacemesh.v1.SmesherService.IsSmeshing" }
                5 {
                    write-host "`n" 
                    write-host "Please wait ..." 
                    ./grpcurl.exe -plaintext -max-time '60' "$($ip):$($port1)" "spacemesh.v1.ActivationService.Highest"
                }
                #6 { ./grpcurl.exe -plaintext "$($ip):$($port2)" "spacemesh.v1.SmesherService.SmesherID"}
                6 {
                    Write-Host "Node ID: " -ForegroundColor Cyan
                    Write-Host "Hex    = " -ForegroundColor Yellow -NoNewline; $publicKey = ((Invoke-Expression ("./grpcurl.exe --plaintext -max-time 3 $($ip):$($port2) spacemesh.v1.SmesherService.SmesherID")) | ConvertFrom-Json).publicKey 2>$null
                    B64_to_Hex -id2convert $publicKey 
                    Write-Host "Base64 = " -ForegroundColor Yellow -NoNewline; $publicKey = ((Invoke-Expression ("./grpcurl.exe --plaintext -max-time 3 $($ip):$($port2) spacemesh.v1.SmesherService.SmesherID")) | ConvertFrom-Json).publicKey 2>$null
                    $publicKey 
                }
                7 { ./grpcurl.exe -plaintext "$($ip):$($port2)" "spacemesh.v1.SmesherService.PostSetupStatus" }
                8 {
                    write-host "`n" 
                    write-host "Please wait ..."
                    $publicKey = ((Invoke-Expression ("./grpcurl.exe --plaintext -max-time 3 $($ip):$($port2) spacemesh.v1.SmesherService.SmesherID")) | ConvertFrom-Json).publicKey 2>$null
                    if ($null -ne $publicKey) {
                        $publicKey = (B64_to_Hex -id2convert $publicKey)
                        $publicKeylow = $publicKey.ToLower()
                        $job = Start-Job -ScriptBlock {
                            param($ip, $port1)
                            ./grpcurl.exe -plaintext "$($ip):$($port1)" "spacemesh.v1.MeshService.MalfeasanceStream"
                        } -ArgumentList $ip, $port1
                        Wait-Job -Timeout 2 -Job $job
                        $response = Receive-Job -Job $job
                        Remove-Job -Job $job -Force
                        if ($response -match $publicKeylow) {
                            write-host "`n"
                            write-host "Your node ID is: " -NoNewline
                            Write-Host $publicKey -ForegroundColor Yellow
                            write-host "The node has been banned" -ForegroundColor Yellow
                        }
                        else {
                            write-host "`n"
                            write-host "Your node ID is:" -NoNewline
                            Write-Host $publicKey -ForegroundColor Yellow
                            write-host "It looks alright"
                        }
                    }
                    else {
                        write-host "`n"
                        write-host "The node is offline or you're trying to probe Smapp"
                    }
                }
                Q { 'Quit' }
                default { 'Invalid entry' }
            }
        }
    }
}

function B64_to_Hex {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$id2convert
    )
    [System.BitConverter]::ToString([System.Convert]::FromBase64String($id2convert)).Replace("-", "")
}

main
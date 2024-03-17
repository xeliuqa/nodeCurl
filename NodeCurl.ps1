<#  -----------------------------------------------------------------------------------------------
.VERSION 1.18
.AUTHOR
.PROJECTURI https://github.com/xeliuqa/nodeCurl

Get grpcurl here: https://github.com/fullstorydev/grpcurl/releases
-------------------------------------------------------------------------------------------- #>

$host.UI.RawUI.WindowTitle = "Node Curl"
$grpcurl = $PSScriptRoot + "\grpcurl.exe"
Write-Host -ForegroundColor Green "
$ErrorActionPreference = 'SilentlyContinue' # 'Inquire', 'SilentlyContinue'
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
	"Press '5' - Highest ATX" (Might take up to 5 minutes)
	"Press '6' - Smesher IDs"
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
                        param($ip, $port2, $grpcurl)
                        & $grpcurl "-plaintext" "$($ip):$($port2)" "spacemesh.v1.AdminService.EventsStream"
                    } -ArgumentList $ip, $port2, $grpcurl
                    Wait-Job -Timeout 3 -Job $job
                    Receive-Job -Job $job
                    Remove-Job -Job $job -Force
                }
                #1 { ./grpcurl.exe -plaintext "$($ip):$($port2)" "spacemesh.v1.AdminService.EventsStream"}
                2 { & $grpcurl -plaintext "$($ip):$($port1)" "spacemesh.v1.NodeService.Status" }
                3 { & $grpcurl -plaintext "$($ip):$($port1)" "spacemesh.v1.NodeService.Version" }
                4 { & $grpcurl -plaintext "$($ip):$($port2)" "spacemesh.v1.SmesherService.IsSmeshing" }
                5 {
                    write-host "`n" 
                    write-host "Please wait ..." 
                    & $grpcurl -plaintext "$($ip):$($port1)" "spacemesh.v1.ActivationService.Highest"
                }
                #6 { ./grpcurl.exe -plaintext "$($ip):$($port2)" "spacemesh.v1.SmesherService.SmesherIDs"}
                6 {
					$Keys = ((Invoke-Expression ("$($grpcurl) --plaintext -max-time 3 $($ip):$($port2) spacemesh.v1.SmesherService.SmesherIDs")) | ConvertFrom-Json) 2>$null
                    write-host "Node IDs: " -ForegroundColor Cyan
					foreach ($id in $Keys.publicKeys) {
						write-host "Hex    = " -ForegroundColor Yellow -NoNewline; B64_to_Hex -id2convert $id
						write-host "Base64 = " -ForegroundColor Yellow -NoNewline; $id
						write-host "`n"
					}
				}
                7 { & $grpcurl -plaintext "$($ip):$($port2)" "spacemesh.v1.SmesherService.PostSetupStatus" }
                8 {
                    write-host "`n" 
                    write-host "Please wait ..."
                    $Keys = ((Invoke-Expression ("$($grpcurl) --plaintext -max-time 3 $($ip):$($port2) spacemesh.v1.SmesherService.SmesherIDs")) | ConvertFrom-Json) 2>$null
					
                    if ($null -ne $Keys) {
						foreach ($id in $Keys.publicKeys) {
                        $publicKey = (B64_to_Hex -id2convert $id)
                        $publicKeylow = $publicKey.ToLower()
                        $job = Start-Job -ScriptBlock {
                            param($ip, $port1, $grpcurl)
                            & $grpcurl "-plaintext" "$($ip):$($port1)" "spacemesh.v1.MeshService.MalfeasanceStream" 2>$null
                        } -ArgumentList $ip, $port1, $grpcurl
                        Wait-Job -Timeout 3 -Job $job | Out-Null
                        $response = Receive-Job -Job $job
                        Remove-Job -Job $job -Force
						if ($null -ne $response) {
							if ($response -match $publicKeylow) {
								write-host "`n"
								write-host "Your Smesher ID is: " -NoNewline
								Write-Host $publicKey -ForegroundColor Yellow
								write-host "This Smesher ID has been banned" -ForegroundColor Yellow
							}
							else {
								write-host "`n"
								write-host "Your Smesher ID is:" -NoNewline
								Write-Host $publicKey -ForegroundColor Yellow
								write-host "It looks alright"
							}
						} else {
							write-host "`n"
							write-host "Something went wrong" -ForegroundColor Red
						}
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
    [System.BitConverter]::ToString([System.Convert]::FromBase64String($id2convert)).Replace("-", "").ToLower()
}

main

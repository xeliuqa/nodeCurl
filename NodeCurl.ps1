$host.UI.RawUI.WindowTitle = "Node Curl"
Write-Host -ForegroundColor Green "
	----------------------------------------
	        Welcome to Node Curl
	----------------------------------------"
#Main Menu
$port1 = Read-Host -Prompt "Please select Port 1 (default 9092)"

$port2 = Read-Host -Prompt "Please select Port 2 (default 9093)"

Write-Host -ForegroundColor Yellow "
    ------------------------------
    |         Main Menu          |
    ------------------------------"
    Write-Host ""
$MenuOptions = @'
"Press '1' for Eligible Layers"
"Press '2' to Check node status"
"Press '3' for Node Version"
"Press '4' for Smesh Service"
"Press '5' for Highest ATX"
"Press '6' for Network Status"
"Press '7' for PoST Status"
"Press 'Q' to quit."
Write-Host ""
'@

"`n$MenuOptions"

while(($selection  = Read-Host -Prompt "`nSelect a option") -ne 'Q')
{
    Clear-Host

    "`n$MenuOptions"

    switch( $selection )
    {
        1 { .\grpcurl --plaintext 0.0.0.0:$port2 spacemesh.v1.AdminService.EventsStream}
        2 { .\grpcurl --plaintext -d "{}" localhost:$port1 spacemesh.v1.NodeService.Status}
        3 { .\grpcurl --plaintext -d "{}" localhost:$port1 spacemesh.v1.NodeService.Version}
        4 { .\grpcurl --plaintext -d "{}" localhost:$port2 spacemesh.v1.SmesherService.IsSmeshing}
        5 { .\grpcurl --plaintext -d "{}" localhost:$port1 spacemesh.v1.ActivationService.Highest}
        6 { .\grpcurl --plaintext 127.0.0.1:$port1 spacemesh.v1.DebugService.NetworkInfo}
        7 { .\grpcurl --plaintext -d "{}" localhost:$port2 spacemesh.v1.SmesherService.PostSetupStatus}
        Q { 'Quit' }
        default {'Invalid entry'}
    }
}

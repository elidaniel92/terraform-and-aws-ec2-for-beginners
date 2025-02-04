Write-Host "Running ./ssh-config/windows.tpl"

Write-Host "Add host to $HOME\.ssh\config"

$addHost = @'

Host ${hostname}
  HostName ${hostname}
  User ${user}
  IdentityFile ${identityfile}
'@

Write-Host $addHost

if (!(Test-Path -Path "$HOME\.ssh\config")) {
    New-Item -ItemType File -Path "$HOME\.ssh\config" -Force
}

Add-Content -path "$HOME\.ssh\config" -value $addHost
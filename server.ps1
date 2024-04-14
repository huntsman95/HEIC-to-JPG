<#
.SYNOPSIS
    Server entrypoint for Pode App
#>

Add-Type -Path '.\lib\Handlebars.dll'

Import-Module -Name Pode

# $PID | Out-File .\pid.lock -Force #Uncomment to help in identifying the PID of the pwsh process hosting this website.

$threads = (Get-PodeConfig).Threads

Start-PodeServer -FilePath './router.ps1' -Threads $threads -EnablePool Schedules
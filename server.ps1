<#
.SYNOPSIS
    Server entrypoint for Pode App
#>

using assembly .\lib\Handlebars.dll

Import-Module -Name Pode

$PID | Out-File .\pid.lock -Force

$threads = (Get-PodeConfig).Threads

Start-PodeServer -FilePath './router.ps1' -Threads $threads -EnablePool Schedules
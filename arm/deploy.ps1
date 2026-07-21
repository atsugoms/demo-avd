param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "at-avd-armtest-rg",

    [Parameter(Mandatory = $false)]
    [string]$Location = "japaneast",

    [Parameter(Mandatory = $false)]
    [string]$DeploymentName = "avd-arm-$(Get-Date -Format 'yyyyMMddHHmmss')"
)

$ErrorActionPreference = "Stop"

function Invoke-AzCli {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    az @Args
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: az $($Args -join ' ')"
    }
}

$mainTemplatePath = Join-Path $PSScriptRoot "azuredeploy.json"
$parametersPath = Join-Path $PSScriptRoot "azuredeploy.parameters.json"
$tempCompiledTemplatePath = Join-Path $env:TEMP ("azuredeploy.compiled.{0}.json" -f ([guid]::NewGuid().ToString("N")))

$moduleMap = @{
    network      = "modules/network.json"
    nsg          = "modules/nsg.json"
    monitor      = "modules/monitor.json"
    avdCore      = "modules/avd-core.json"
    storage      = "modules/storage.json"
    sessionHosts = "modules/session-hosts.json"
}

$mainTemplate = Get-Content -Path $mainTemplatePath -Raw | ConvertFrom-Json

foreach ($resource in $mainTemplate.resources) {
    if ($resource.type -ne "Microsoft.Resources/deployments") {
        continue
    }

    $resourceName = [string]$resource.name
    if (-not $moduleMap.ContainsKey($resourceName)) {
        continue
    }

    $modulePath = Join-Path $PSScriptRoot $moduleMap[$resourceName]
    $moduleTemplate = Get-Content -Path $modulePath -Raw | ConvertFrom-Json

    if ($resource.properties.PSObject.Properties.Name -contains "templateLink") {
        $resource.properties.PSObject.Properties.Remove("templateLink")
    }

    $resource.properties | Add-Member -MemberType NoteProperty -Name template -Value $moduleTemplate -Force
}

$mainTemplate | ConvertTo-Json -Depth 100 | Set-Content -Path $tempCompiledTemplatePath -Encoding UTF8

try {
    Invoke-AzCli -Args @("account", "set", "--subscription", $SubscriptionId, "--output", "none")
    Invoke-AzCli -Args @("group", "create", "--name", $ResourceGroupName, "--location", $Location, "--output", "none")
    Invoke-AzCli -Args @(
        "deployment", "group", "create",
        "--resource-group", $ResourceGroupName,
        "--name", $DeploymentName,
        "--template-file", $tempCompiledTemplatePath,
        "--parameters", "@$parametersPath",
        "--output", "none"
    )

    Write-Host "Deployment succeeded: $DeploymentName"
    Write-Host "Resource group: $ResourceGroupName"
}
finally {
    if (Test-Path $tempCompiledTemplatePath) {
        Remove-Item $tempCompiledTemplatePath -Force
    }
}

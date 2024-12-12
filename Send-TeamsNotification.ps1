# Updated Send-TeamsNotification.ps1

param (
    [string]$Environment,
    [string]$ReleaseVersion,
    [string]$ReleaseName
)

# Get the WebhookUri from the environment variable
$WebhookUri = $env:WEBHOOK_URI
if (-not $WebhookUri) {
    Write-Error "Webhook URI is not set in the environment variable 'WEBHOOK_URI'."
    exit 1
}

# Assign default values if environment variables are not set
if (!$ReleaseName) {
    $ReleaseName = $env:RELEASE_RELEASENAME
    if (!$ReleaseName) {
        $ReleaseName = "$(Release.ReleaseName)"
    }
}

if (!$ReleaseVersion) {
    $ReleaseVersion = $env:RELEASE_RELEASEVERSION
    if (!$ReleaseVersion) {
        $ReleaseVersion = "$(Release.ReleaseVersion)"
    }
}

if (!$Environment) {
    $Environment = $env:RELEASE_ENVIRONMENTNAME
    if (!$Environment) {
        $Environment = "$(Release.EnvironmentName)"
    }
}

# Notification payload
$payload = @{
    text = "Deployment notification"
    facts = @(
        @{ name = "Environment"; value = $Environment },
        @{ name = "Release Name"; value = $ReleaseName },
        @{ name = "Release Version"; value = $ReleaseVersion }
    )
}

# Convert payload to JSON
$jsonPayload = $payload | ConvertTo-Json -Depth 3

# Send notification to webhook
Invoke-RestMethod -Uri $WebhookUri -Method Post -Body $jsonPayload -ContentType "application/json"

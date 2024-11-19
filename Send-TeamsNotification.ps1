#some comment here 
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$WebhookUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$Status
)

try {
    # Get pipeline variables
    $ReleaseName = if ($env:RELEASE_RELEASENAME) { $env:RELEASE_RELEASENAME } else { "Unknown Release" }
    $EnvironmentName = if ($env:RELEASE_ENVIRONMENTNAME) { $env:RELEASE_ENVIRONMENTNAME } else { "Unknown Environment" }
    $RequestedBy = if ($env:RELEASE_REQUESTEDFOR) { $env:RELEASE_REQUESTEDFOR } else { "Unknown User" }
    $ProjectName = if ($env:SYSTEM_TEAMPROJECT) { $env:SYSTEM_TEAMPROJECT } else { "Unknown Project" }
    $ReleaseUrl = if ($env:RELEASE_RELEASEWEBURL) { $env:RELEASE_RELEASEWEBURL } else { "" }

    # Create Teams message payload
    $payload = @{
        text = "Release notification: $ReleaseName deployed to $EnvironmentName. $Status."
        summary = "Azure DevOps Release Notification"
        sections = @(
            @{
                activityTitle = "Release: $ReleaseName"
                activitySubtitle = "Environment: $EnvironmentName"
                facts = @(
                    @{ name = "Status"; value = $Status }
                    @{ name = "Triggered by"; value = $RequestedBy }
                    @{ name = "Project"; value = $ProjectName }
                )
                markdown = $true
            }
        )
    }

    # Add release URL if available
    if ($ReleaseUrl) {
        $payload.sections[0].Add("potentialAction", @(
            @{
                "@type" = "OpenUri"
                name = "View Release"
                targets = @(
                    @{ os = "default"; uri = $ReleaseUrl }
                )
            }
        ))
    }

    # Convert to JSON
    $jsonPayload = $payload | ConvertTo-Json -Depth 10

    Write-Output "Sending notification to Teams..."
    Write-Output "Payload: $jsonPayload"

    # Send to Teams
    $result = Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType 'application/json' -Body $jsonPayload
    Write-Output "Successfully sent Teams notification"
    
    if ($result) {
        Write-Output "Teams response: $result"
    }
}
catch {
    Write-Error "Failed to send Teams notification: $_"
    throw
}

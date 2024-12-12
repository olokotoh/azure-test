[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$WebhookUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$CustomMessage,
    
    [Parameter(Mandatory=$false)]
    [string]$Status = "Deployment Completed",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Success", "Warning", "Error")]
    [string]$NotificationType = "Success",
    
    [Parameter(Mandatory=$true)]
    [string]$ReleaseName,

    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,

    [Parameter(Mandatory=$true)]
    [string]$RequestedBy,

    [Parameter(Mandatory=$true)]
    [string]$ProjectName,

    [Parameter(Mandatory=$true)]
    [string]$ReleaseUrl
)

# Function to get color based on notification type
function Get-ThemeColor {
    param([string]$Type)
    
    switch ($Type) {
        "Success" { return "00ff00" }
        "Warning" { return "ffff00" }
        "Error" { return "ff0000" }
        default { return "0078D7" }
    }
}

# Function to create Teams message payload
function New-TeamsPayload {
    param(
        [string]$ReleaseName,
        [string]$EnvironmentName,
        [string]$RequestedBy,
        [string]$ProjectName,
        [string]$ReleaseUrl,
        [string]$Status,
        [string]$CustomMessage
    )
    
    $defaultMessage = "Release notification: $ReleaseName deployed to $EnvironmentName. $Status."
    $messageText = if ($CustomMessage) { $CustomMessage } else { $defaultMessage }
    
    return @{
        type = "message"
        attachments = @(
            @{
                contentType = "application/vnd.microsoft.card.adaptive"
                content = @{
                    type = "AdaptiveCard"
                    version = "1.2"
                    body = @(
                        @{
                            type = "TextBlock"
                            text = $messageText
                            wrap = $true
                            weight = "bolder"
                            size = "medium"
                        }
                        @{
                            type = "FactSet"
                            facts = @(
                                @{ title = "Status"; value = $Status }
                                @{ title = "Environment"; value = $EnvironmentName }
                                @{ title = "Triggered by"; value = $RequestedBy }
                                @{ title = "Project"; value = $ProjectName }
                            )
                        }
                    )
                    actions = @(
                        @{
                            type = "Action.OpenUrl"
                            title = "View Release"
                            url = $ReleaseUrl
                        }
                    )
                }
            }
        )
    }
}

# Main execution
try {
    Write-Host "Starting Teams notification script..."
    
    # Create payload
    $payload = New-TeamsPayload -ReleaseName $ReleaseName -EnvironmentName $EnvironmentName -RequestedBy $RequestedBy `
                                -ProjectName $ProjectName -ReleaseUrl $ReleaseUrl -Status $Status `
                                -CustomMessage $CustomMessage
    $jsonPayload = $payload | ConvertTo-Json -Depth 10 -Compress
    
    # Log payload for troubleshooting (mask webhook URL)
    $logPayload = $jsonPayload -replace $WebhookUrl, "WEBHOOK_URL_REDACTED"
    Write-Host "Payload: $logPayload"
    
    # Send notification
    $result = Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType 'application/json' -Body $jsonPayload
    Write-Host "Successfully sent Teams notification"
    Write-Host "Response: $result"
}
catch {
    Write-Error "Failed to send Teams notification: $_"
    throw
}

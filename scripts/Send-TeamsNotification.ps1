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
    [string]$NotificationType = "Success"
)

# Function to get Azure DevOps pipeline variables
function Get-PipelineVariables {
    return @{
      

        ReleaseName = if ($env:RELEASE_RELEASENAME) { $env:RELEASE_RELEASENAME } else { "$(Release.ReleaseName)" }
        EnvironmentName = if ($env:RELEASE_ENVIRONMENTNAME) { $env:RELEASE_ENVIRONMENTNAME } else { "$(Release.EnvironmentName)" }
        RequestedBy = if ($env:RELEASE_REQUESTEDFOR) { $env:RELEASE_REQUESTEDFOR } else { "$(Release.RequestedFor)" }
        ProjectName = if ($env:SYSTEM_TEAMPROJECT) { $env:SYSTEM_TEAMPROJECT } else { "$(System.TeamProject)" }
        ReleaseUrl = if ($env:RELEASE_RELEASEWEBURL) { $env:RELEASE_RELEASEWEBURL } else { "$(Release.ReleaseWebURL)" }

    }
}

# Function to get color based on notification type 1
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
        [hashtable]$Variables,
        [string]$Status,
        [string]$CustomMessage,
        [string]$NotificationType
    )
    
    $defaultMessage = "Release notification: $($Variables.ReleaseName) deployed to $($Variables.EnvironmentName). $Status."
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
                                @{
                                    title = "Status"
                                    value = $Status
                                }
                                @{
                                    title = "Environment"
                                    value = $Variables.EnvironmentName
                                }
                                @{
                                    title = "Triggered by"
                                    value = $Variables.RequestedBy
                                }
                                @{
                                    title = "Project"
                                    value = $Variables.ProjectName
                                }
                            )
                        }
                    )
                    actions = @(
                        @{
                            type = "Action.OpenUrl"
                            title = "View Release"
                            url = $Variables.ReleaseUrl
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
    
    # Get pipeline variables
    $variables = Get-PipelineVariables
    
    # Create and convert payloads
    $payload = New-TeamsPayload -Variables $variables -Status $Status -CustomMessage $CustomMessage -NotificationType $NotificationType
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
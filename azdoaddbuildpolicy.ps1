# Function to Get Repository ID based on Repository Name
function Get-RepositoryId {
    param (
        [string]$organization,
        [string]$project,
        [string]$repositoryName,
        [string]$pat
    )

    
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

    $repoUri = "https://dev.azure.com/$organization/$project/_apis/git/repositories?api-version=7.1-preview.1"
    
    $repoResponse = Invoke-RestMethod -Uri $repoUri -Method Get -Headers @{Authorization = "Basic $base64AuthInfo"}

    
    $repository = $repoResponse.value | Where-Object { $_.name -eq $repositoryName }

   
    if ($repository) {
        return $repository.id
    } else {
        Write-Host "Repository with name '$repositoryName' not found."
        return $null
    }
}

function Get-BuildDefinitionId {
    param (
        [string]$organization,
        [string]$project,
        [string]$buildPipelineName,
        [string]$pat
    )

    
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

    
    $buildUri = "https://dev.azure.com/$organization/$project/_apis/build/definitions?api-version=6.0"
    
    
    $buildResponse = Invoke-RestMethod -Uri $buildUri -Method Get -Headers @{Authorization = "Basic $base64AuthInfo"}

    
    $buildDefinition = $buildResponse.value | Where-Object { $_.name -eq $buildPipelineName }


    if ($buildDefinition) {
        return $buildDefinition.id
    } else {
        Write-Host "Build pipeline with name '$buildPipelineName' not found."
        return $null
    }
}


function Add-BuildValidationPolicy {
    param (
        [string]$organization,
        [string]$project,
        [string]$repositoryName,
        [string]$buildPipelineName,
        [string]$refName,
        [string]$pat
    )

    
    $repositoryId = Get-RepositoryId -organization $organization -project $project -repositoryName $repositoryName -pat $pat
    if (-not $repositoryId) { return }

    $buildDefinitionId = Get-BuildDefinitionId -organization $organization -project $project -buildPipelineName $buildPipelineName -pat $pat
    if (-not $buildDefinitionId) { return }

   
    $policyBody = @{
        "type" = @{
            "id" = "0609b952-1397-4640-95ec-e00a01b2c241"  # Build Validation policy ID
        }
        "isenabled" = $true
        "isblocking" = $true   # This will block the PR if the build fails
        "settings" = @{
            "scope" = @(
                @{
                    "refName" = $refName
                    "matchKind" = "exact"
                    "repositoryId" = $repositoryId
                }
            )
            "buildDefinitionId" = $buildDefinitionId  # Build Definition ID to validate
        }
        
    } | ConvertTo-Json -Depth 10

   
    $uri = "https://dev.azure.com/$organization/$project/_apis/policy/configurations?api-version=7.1-preview.1"

    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Basic $base64AuthInfo"} -Body $policyBody -ContentType "application/json"

    
    Write-Host "New Build Validation Policy added successfully: $($response.id)"
}

# Sample Execution
$organization = "yourOrganization"    
$project = "yourProject"              
$repositoryName = "yourRepositoryName"  
$buildPipelineName = "yourBuildPipeline" 
$refName = "refs/heads/main"            
$pat = "yourPersonalAccessToken"       


Add-BuildValidationPolicy -organization $organization -project $project -repositoryName $repositoryName -buildPipelineName $buildPipelineName -refName $refName -pat $pat

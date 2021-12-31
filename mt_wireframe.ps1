<#
  .SYNOPSIS
    Processes all items.

  .DESCRIPTION
    Processes items in parallel to speed up the processing.

  .INPUTS
    None. You cannot pipe anything to this script.

  .OUTPUTS
    None
  
  .PARAMETER listOfItemsToWorkOn
    The local folder with datasets in subfolders, from which you like to store all DICOM instances
    Default: '{ "This", "is", "multi-threading", "in", "Powershell" }'

  .PARAMETER threads
    The number of threads to use 
    Default: equal to the number of CPU cores of the machine

  .EXAMPLE
    PS> .\mt_wireframe.ps1

  .EXAMPLE
    PS> .\mt_wireframe.ps1 -listOfItemsToWorkOn "item1","item2","item3" -threads 3
#>
param(
    [parameter(Mandatory = $false)]
    [string[]]$listOfItemsToWorkOn = @("This", "is", "multi-threading", "in", "Powershell"),
    
    [parameter(Mandatory = $false)]
    [int]$threads = ((Get-WmiObject -class Win32_processor).NumberOfLogicalProcessors | foreach-object -begin {$t=0} -process { $t += $_ } -end { $t })
    # For the task(s) ahead try and figure out where the performance bottleneck is and chose a method of determining the most suitable number of threads
    # In this example we're assuming CPU is the bottleneck so (as a crude estimation) we don't need more processes than we have CPU cores
    )

Write-Progress -Activity "Processing items" -Status "Initializing..." -PercentComplete 0
$global:exitCode = 0
$global:done = 0;
$total = $listOfItemsToWorkOn.Count

if($total -eq 0){ echo "No work items found to work on"; exit 1 }

function Write-MtProgress {
    param ([string]$threadOutput = $(Receive-Job $_ -AutoRemoveJob -Wait))
    $dt = $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    echo "$dt $threadOutput"
    $perc = [math]::round(($global:done/$total*100),2)
    Write-Progress -Activity "Processing items" -Status "$perc% complete ($global:done/$total)" -PercentComplete $perc
    }

function CheckForCompletedJobs {
    Get-Job -State Completed | % { 
        $global:done++
        Write-MtProgress 
    }
    Start-Sleep -m 200
}

Write-MtProgress -threadOutput "Starting work on the items..."
foreach ($item in $listOfItemsToWorkOn)
{
    Start-Job -Name "Process_$item" -ScriptBlock {
        $napTime = Get-Random -Minimum 1 -Maximum 5
        Start-Sleep -s $napTime
        # do something to $item here that takes a while
        if ($LASTEXITCODE -gt 0) { 
            $global:exitCode = $LASTEXITCODE # forward exit code to the main script if there is a problem
            $threadResult = "There was a problem processing $using:item!"
        }
        else { $threadResult = "I've slept $napTime seconds and then processed '$using:item'!" }
        echo $threadResult # this will go into $threadOutput    
    } | Out-Null
    While($(Get-Job -State Running).Count -ge $threads) { CheckForCompletedJobs }
    
}
While ($(Get-Job -State Running).Count -ne 0) { CheckForCompletedJobs }
CheckForCompletedJobs

exit $global:exitCode
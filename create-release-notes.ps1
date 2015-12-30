<#
    .SYNOPSIS
      Displays a list of work items that have been associated to a given branch
    .EXAMPLE
     create-release-notes.ps1 -tfsUserName me@hotmail.com -tfsAccount myTfs -oldBranch release/2015.11.10 -newBranch release/2015.11.24 
     This command will look in all the commits that are unique to the release/2015.11.24 branch and find the "Related Work Items: " message that TFS adds. 
	 It will then take all those work items and use the Visual Studio online API to fetch them and present them as a Release Note.
#>
  
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
  [string]$tfsUserName,

  [Parameter(Mandatory=$True,Position=2)]
  [string]$tfsAccount,
  
  [Parameter(Mandatory=$True, Position=3)]
  [string]$oldBranch,
     
  [Parameter(Mandatory=$True, Position=4)]
  [string]$newBranch,
  
  [Parameter(Mandatory=$False, Position=5, ValueFromRemainingArguments=$true)]
  [string[]]$acceptedWorkItemTypes = @("Bug", "User Story")
)

$branches = $oldBranch + ".." + $newBranch
$log = git log --date=relative $branches
$items = New-Object System.Collections.ArrayList

ForEach($item in [regex]::matches($log, "Related Work Items: #(\d{4})")) {
  $x = $items.Add($item.Groups[1].Value)
}

if($items.Count -gt 0) {
  $response = Read-host "Alternate Authentication Password:" -AsSecureString
  $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($response))

  $basicAuth = ("{0}:{1}" -f $tfsUserName,$password)
  $basicAuth = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
  $basicAuth = [System.Convert]::ToBase64String($basicAuth)
  $headers = @{Authorization=("Basic {0}" -f $basicAuth)}

  #https://www.visualstudio.com/en-us/integrate/api/wit/work-items  For help on the API
  
  $url = "https://" + $tfsAccount + ".visualstudio.com/DefaultCollection/_apis/wit/workitems?fields=System.Title,System.WorkItemType,System.State&ids=" + $($items -join ",")
  
  $result = Invoke-RestMethod -Uri $url -Method Get -headers $headers  
  $workItems = @{} 
  ForEach($item in $result.value) {
    if($acceptedWorkItemTypes.IndexOf($item.fields.'System.WorkItemType') -gt -1) {
	  if(-Not ($workItems.Contains($item.fields.'System.WorkItemType'))) {	    
		$temp = New-Object System.Collections.ArrayList
	    $workItems.Set_Item($item.fields.'System.WorkItemType', $temp)
	  }
	  $workItems.Get_Item($item.fields.'System.WorkItemType').Add($item) | Out-Null
	}
  }
  
  ForEach($workItemType in $workItems.GetEnumerator()) {
    Write $workItemType.Name
    Write ("-" * $workItemType.Name.length)
    ForEach($item in $workItemType.Value) {
      $item.id.ToString().PadRight(5) + ": " + $item.fields.'System.State'.PadRight(10) + ": " + $item.fields.'System.Title'
    }
    Write ""
    Write ""
  }
}
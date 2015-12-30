# TfsGitReleaseNotes
A Powershell script for generating release notes from TFS Git.

This assumes that you are associating work items with your Git commits.

# Example
```
create-release-notes.ps1 -tfsUserName me@hotmail.com -tfsAccount myTfs -oldBranch release/2015.11.10 -newBranch release/2015.11.24 
```
This command will look in all the commits that are unique to the release/2015.11.24 branch and find the "Related Work Items: " message that TFS adds. 
It will then take all those work items and use the Visual Studio online API to fetch them and present them as a Release Note.

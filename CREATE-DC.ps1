#Script to turn a regular Win 2k12 box into an AD Domain Controller, add some vulnerable software and weak users/passwords
<#
Version    Date        Area Changed         Comment
0.0.0      02/09/16    Main Body            Official start of script writing
0.0.1      02/09/16    Main Body            Laid in adding the windows feature but it requires a restart to promote it to DC of a new forest
0.0.2      02/09/16    Main Body            Implemented a job system will may allow it to reboot and restart the script
0.1.0      02/09/16    Main Body            Concerted to using workflows for better disaster recovery and persistence
0.1.1      02/09/16    Workflow             Implemented persistence for local machine
0.1.2      02/10/16    Main body            Tidied up the script block converted different format to improve persistance
0.1.3      02/10/16    Workflow             Added Sequence, even though powershell claims it is already sequenced, it appears to be trying to run parallel
0.1.4      02/10/16    Workflow             Added in a restart after the rename
1.0.0      02/11/16    Main Body            Task generation element in place, script can survive both required reboots and is officially an AD DC by the end
1.0.1      02/12/16    Main Body            Added several additional comments
1.1.0      02/23/16    Main Body            Added in script clean up. Cleans up task as well as all jobs.
#>

Import-Module PSWorkflow

$Password = "P@ssword1"
$SafeModePassword =  ConvertTo-SecureString -AsPlainText $Password -Force


workflow Create-DC($SMPass)
{
    sequence {
        # Add AD Domain Services
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

        # Rename the host and Restart PC (1/2)
        Rename-Computer -NewName "FreeCandy" -Force -PassThru
        Restart-Computer -Wait

        # Upgrade to AD DC
        (InlineScript { 
        Import-Module ADDSDeployment 
        Import-Module PSWorkflow
        Install-ADDSForest `
        -DomainName "HackMe.local" `
        -InstallDNS:$true `
        -DatabasePath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -SafeModeAdministratorPassword $Using:SMPass `
        -NoRebootOnCompletion `
        -Confirm:$false
        })

        # Restart Computer (2/2)
        Restart-Computer -Wait
    
        #Add weak users/passwords
        (InlineScript {
        New-ADUser MalcolmReynolds `
            -Enabled:$true `
            -AccountPassword (ConvertTo-SecureString -AsPlainText "Firefly15" -Force)

        New-ADUser HobanWashburne `
            -Enabled:$true `
            -AccountPassword (ConvertTo-SecureString -AsPlainText "LeafOnTheWind15" -Force)

        New-ADUser RiverTam `
            -Enabled:$true `
            -AccountPassword (ConvertTo-SecureString -AsPlainText "Miranda1" -Force)
        
        #Add some vulnerable software
        
        # Tidy Up a bit, looks to see if the job is completed, if so it removes the job and removes the task
            Disable-ScheduledTask -TaskName CreateDC -ErrorAction SilentlyContinue 
            Unregister-ScheduledTask -TaskName CreateDC -ErrorAction SilentlyContinue -Confirm:$false
        })
    }
}

# Creates a scheduled task that will launch at startup, look for and resume the script if it has not completed
$actionscript = '-NonInteractive -WindowStyle Normal -NoLogo -NoProfile -NoExit -Command "&Import-Module PSWorkflow; Get-Job -Name NewCreateDC | Resume-Job; Wait-Job -Name NewCreateDC -Force; Get-Job -Name NewCreateDC -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Remove-Job -Confirm:$false"'
$pstart = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
Get-ScheduledTask -TaskName CreateDC -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
$act = New-ScheduledTaskAction -Execute $pstart -Argument $actionscript
$trig = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -TaskName CreateDC -Action $act -Trigger $trig -RunLevel Highest -ErrorAction SilentlyContinue

# Launches the workflow (works pretty much like launching a function)
Create-DC($SafeModePassword) -AsJob -JobName NewCreateDC > $null 2>&1

Wait-Job -Name NewCreateDC -Force
Get-Job -Name NewCreateDC -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Remove-Job -Confirm:$false

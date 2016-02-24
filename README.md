# Create-DC
PowerShell script designed to promote fresh Windows 2k12 Server into an AD DC  
Written for the book: "Mastering Nexpose and Metasploit: A Lab-Based Approach to Mastery"

Before running the script you'll need to run the following PowerShell command:  
*Set-ExecutionPolicy -Scope CurrentUser -f Unrestricted*  
  
__PLEASE NOTE:__ This script installs intentionally vulnerable software meant to be compromised as part of a lab exercise.  

During the course of the script the server will restart twice. You will need to log back in with the same credentials each time, but you will not have to worry about restarting the script it will restart itself upon login.

At the end of the script it should clean up all the tasks and jobs it had to create while it ran, but may leave a PowerShell window open, it should be fine to close it.

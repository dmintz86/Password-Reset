# Password Reset. 
This script was designed to be used in a Self Service policy to allow users to Change their local password and keep their keychain and Filevault passwords in sync. 

Requirements:
* If using Filevault then the management account in the JSS must be enabled for Filevault on the machine. 
Written By: Daniel Mintz | Professional Services Engineer | Jamf

Created On: 13th July, 2017.

The script needs to use $4 & $5 variables in the JSS. 
These should be set as the management account and the password. This is needed in the section which syncs the Filevault password for the user. 

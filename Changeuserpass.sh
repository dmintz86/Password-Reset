#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
# Copyright (c) 2017 Jamf.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the Jamf nor the names of its contributors may be
#                 used to endorse or promote products derived from this software without 
#                 specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
##############################################################################################################
#Variables. ICON TO BE SET BEFORE RUNNING SCRIPT.
##############################################################################################################
user=`ls -l /dev/console | awk '/ / { print $3 }'`
icon=''

##############################################################################################################

# check that script is run as root user

if [ $EUID -ne 0 ]
then
    >&2 /bin/echo $'\nThis script must be run as the root user!\n'
    exit
fi

# capture user input name First Time

while true
do
passa=$(osascript -e 'Tell application "System Events" to display dialog "Please enter your new password" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null)
    if [ $? -ne 0 ]     
    then # user cancel
        exit
    elif [ -z "$passa" ]
    then # loop until input or cancel
        osascript -e 'Tell application "System Events" to display alert "Please enter a name or select Cancel... Thanks!" as warning'
    else [ -n "$passa" ] # user input
        break
    fi
done

# capture user input name Second Time

while true
do
passb=$(osascript -e 'Tell application "System Events" to display dialog "Please re-enter your password to validate it" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null)
    if [ $? -ne 0 ]     
    then # user cancel
        exit
    elif [ -z "$passb" ]
    then # loop until input or cancel
        osascript -e 'Tell application "System Events" to display alert "Please enter a name or select Cancel... Thanks!" as warning'
    else [ -n "$passb" ] # user input
        break
    fi
done

#Compare passa and passb
if 
	[ "$passa" = "$passb" ]

then


#Change Password

dscl . passwd /Users/$user $passb

#Display Dialog to user saying its now time to change keychain password. 
 
#Message to send to User
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "Login Keychain Password Reset" -icon "$icon" -heading "Your Login Keychain password will be updated to match your new password." -description "In a moment you will be asked for your old password to update your keychain. Please enter this correctly." -iconSize 100 &

#Wait 7 Seconds
sleep 7

#kill image helper
/usr/local/bin/jamf killJAMFHelper

# capture old password for keychain reset.

while true
do
oldpass=$(osascript -e 'Tell application "System Events" to display dialog "Please enter your old login password" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null)
    if [ $? -ne 0 ]     
    then # user cancel
        exit
    elif [ -z "$oldpass" ]
    then # loop until input or cancel
        osascript -e 'Tell application "System Events" to display alert "Please enter a name or select Cancel... Thanks!" as warning'
    else [ -n "$oldpass" ] # user input
        break
    fi
done

#Update Keychain Password.
security set-keychain-password -o $oldpass -p $passb /Users/$user/Library/Keychains/login.keychain


## Remove User from Filevault. This is done because the filevault password will get out of sync and removing the user then re adding is the best way to re sync.
	/usr/bin/fdesetup remove -user $user
	# Wait 5 seconds.
	sleep 5
	

# Re add the user to filevault. This is done using a plist which is written to /tmp. The plist is called fvenable.plist.It contains the username and password for an admin account which is enabled for Filevault.This can be done using $4 & $5 in the JSS variables ( Typically the management account which is enabled for filevault). 
	echo '<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
	<key>Username</key>
	<string>'$4'</string>
	<key>Password</key>
	<string>'$5'</string>
	<key>AdditionalUsers</key>
	<array>
	    <dict>
	        <key>Username</key>
	        <string>'$user'</string>
	        <key>Password</key>
	        <string>'$passb'</string>
	    </dict>
	</array>
	</dict>
	</plist>' > /tmp/fvenable.plist  ### you can place this file anywhere just adjust the fdesetup line below

	# now enable FileVault using the plist.
		fdesetup add -i < /tmp/fvenable.plist

#Display Dialog to user letting them know that the password reset process is complete. 
 
#Message to send to User
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "Process Complete." -icon "$icon" -heading "Your Password has now been changed and your Keychain and Filevault are in sync." -description "Have a nice Day." -iconSize 100 &
 
sleep 5

#kill image helper
/usr/local/bin/jamf killJAMFHelper



else 
	
	#Display Dialog to user saying Exit 
 
	#Message to send to User
	/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "Passcodes Dont Match" -icon "$icon" -heading "" -description "The Passcodes you entered dont match.Please re run the password reset from Self Service." -iconSize 100 &
 
	sleep 5

	#kill image helper
	/usr/local/bin/jamf killJAMFHelper
	
fi
	
	exit
#!/bin/sh

# Script Name: installHomebrew.sh
# Function: Deploy Homebrew (brew.sh) to the first user added to a new Mac during the post-DEP enrollment DEPNotify run
# Requirements: DEP, Jamf

# Get the currently logged-in user
ConsoleUser="$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,\"\"][username in [u\"loginwindow\", None, u\"\"]]; sys.stdout.write(username + \" \");')"

# Check if Xcode Command Line Tools are already installed
checkForXcode=$(pkgutil --pkgs | grep com.apple.pkg.CLTools_Executables | wc -l | awk '{ print $1 }')

# Install Command Line Tools if Xcode is missing
if [[ "$checkForXcode" != 1 ]]; then
    # Save current IFS state
    OLDIFS=$IFS
    IFS='.'
    read osvers_major osvers_minor osvers_dot_version <<< "$(sw_vers -productVersion)"
    IFS=$OLDIFS

    cmd_line_tools_temp_file="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

    # Install the latest Xcode command line tools on macOS 10.9.x or higher
    if [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -ge 9 ) || ( ${osvers_major} -eq 11 && ${osvers_minor} -ge 0 ) ]]; then
        # Create the placeholder file for softwareupdate tool
        touch "$cmd_line_tools_temp_file"

        # Identify the correct update in the Software Update feed
        if [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -ge 15 ) || ( ${osvers_major} -eq 11 && ${osvers_minor} -ge 0 ) ]]; then
            cmd_line_tools=$(softwareupdate -l | awk '/\* Label: Command Line Tools/ { $1=$1;print }' | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 9-)
        elif [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -gt 9 ) ]] && [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -lt 15 ) ]]; then
            cmd_line_tools=$(softwareupdate -l | awk '/\* Command Line Tools/ { $1=$1;print }' | grep "$macos_vers" | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 2-)
        elif [[ ( ${osvers_major} -eq 10 && ${osvers_minor} -eq 9 ) ]]; then
            cmd_line_tools=$(softwareupdate -l | awk '/\* Command Line Tools/ { $1=$1;print }' | grep "Mavericks" | sed 's/^[[ \t]]*//;s/[[ \t]]*$//;s/*//' | cut -c 2-)
        fi

        # Install the Command Line Tools
        softwareupdate -i "$cmd_line_tools"
        rm "$cmd_line_tools_temp_file"
    fi
fi

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Verify installation
if command -v brew &> /dev/null; then
    echo "Homebrew installed successfully!"
else
    echo "Homebrew installation failed."
fi

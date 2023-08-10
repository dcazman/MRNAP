<#
.SYNOPSIS
Prompts the user for an email address and validates its format.

.DESCRIPTION
This function prompts the user to enter an email address and validates whether the entered email address follows a valid format. It uses regular expressions to check if the entered email address is in the correct format (name@domain.com). If the entered email address is not valid or if the user presses Enter without input, the function provides appropriate messages and exits.

.PARAMETER Prompt
Specifies the text that will be displayed as the prompt when asking the user to enter an email address. If not provided, the default prompt "EmailAddress" is used.

.EXAMPLE
Prompt4Email -Prompt "User Email"

.EXAMPLE
Prompt4Email
#>
function Prompt4Email {
    #Requires -Version 5.1
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $False, HelpMessage = "Text for prompt.")][string]$Prompt
    )

    # Set the default prompt text if not provided
    If ([string]::IsNullOrWhiteSpace($Prompt)) {
        $Prompt = 'EmailAddress'
    }

    # Initalize emailaddress
    $EmailAddress = $null

    # Validate the entered email address using regular expressions
    while ($EmailAddress -notmatch ("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")) {
        Write-Host "Hit enter to return." -ForegroundColor Blue
        Write-Host "Enter the $Prompt (e.g., name@domain.com)." -ForegroundColor Green -NoNewline
        $EmailAddress = Read-Host " ?"

        # If the entered email address is empty or enter key, exit the function
        if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
            Write-Warning "Enter or space was inputted. Exiting"
            exit
        }
    }
    
    # Return the validated email address
    return $EmailAddress
}

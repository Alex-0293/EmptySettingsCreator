######################### Script params #########################
    [array] $global:FoldersToApplyPath    = @()         # Folders where searching for Var*.ps1 files.
    [array] $global:IgnoreFolders         = @()         # Ignored folders names.

######################### no replacement ########################
    [string]$global:NewFileNameEnd        = "-empty.ps1"                                      # End of the new file name.
    [string]$global:NoReplacementSection  = "######### no replacement #########"              # Copy as is below this line.
    [string]$global:LocalSection          = "######### local section  #########"              # Skip below this line.


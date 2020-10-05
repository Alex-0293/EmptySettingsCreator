# Rename this file to Settings.ps1
######################### no replacement ########################
    [array] $global:IgnoreFolders                    = @("*.vscode")         # Ignored folders names.
    [array] $global:FoldersToApplyPath               = @($Global:gsProjectsFolderPath, $Global:gsProjectServicesFolderPath)         # Folders where searching for Setting*.ps1 files.
    [string]$global:NewFileNameEnd                   = "-empty.ps1"                                      # End of the new file name.
    [string]$global:NoReplacementSection             = "# no replacement #"                              # Copy as is below this line.
    [string]$global:LocalSection                     = "# local section #"                               # Skip below this line.
    [string]$global:ValueReplacementSection          = "# value replacement #"                           # Replace values to null below this line.
    [string]$global:EmptySettingsStub                = "# Rename this file to Settings.ps1"
    
    [bool]  $Global:LocalSettingsSuccessfullyLoaded  = $true

# Error trap
trap {
    $Global:LocalSettingsSuccessfullyLoaded = $False
    exit 1
}

# Rename this file to Settings.ps1
######################### value replacement #####################
    [array] $global:FoldersToApplyPath    = @()         # Folders where searching for Setting*.ps1 files.
    [array] $global:IgnoreFolders         = @()         # Ignored folders names.

######################### no replacement ########################

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

<#
    .SYNOPSIS 
        Creator
        dd.MM.yyyy
        Ver
    .DESCRIPTION
    .PARAMETER
    .EXAMPLE
#>
$ImportResult = Import-Module AlexkUtils  -PassThru
if ($null -eq $ImportResult) {
    Write-Host "Module 'AlexkUtils' does not loaded!" -ForegroundColor Red
    exit 1
}
else {
    $ImportResult = $null
}
#requires -version 3

#########################################################################
function Get-WorkDir () {
    if ($PSScriptRoot -eq "") {
        if ($PWD -ne "") {
            $MyScriptRoot = $PWD
        }        
        else {
            Write-Host "Where i am? What is my work dir?"
        }
    }
    else {
        $MyScriptRoot = $PSScriptRoot
    }
    return $MyScriptRoot
}
Function Initialize-Script   () {
    [string]$Global:MyScriptRoot = Get-WorkDir
    [string]$Global:GlobalSettingsPath = "C:\DATA\Projects\GlobalSettings\SETTINGS\Settings.ps1"

    Get-SettingsFromFile -SettingsFile $Global:GlobalSettingsPath
    if ($GlobalSettingsSuccessfullyLoaded) {    
        Get-SettingsFromFile -SettingsFile "$ProjectRoot\$($Global:SETTINGSFolder)\Settings.ps1"
        if ($Global:LocalSettingsSuccessfullyLoaded) {
            Initialize-Logging   "$ProjectRoot\$LOGSFolder\$ErrorsLogFileName" "Latest"
            Write-Host "Logging initialized."            
        }
        Else {
            Add-ToLog -Message "[Error] Error loading local settings!" -logFilePath "$(Split-Path -path $Global:MyScriptRoot -parent)\$LOGSFolder\$ErrorsLogFileName" -Display -Status "Error" -Format 'yyyy-MM-dd HH:mm:ss'
            Exit 1 
        }
    }
    Else { 
        Add-ToLog -Message "[Error] Error loading global settings!" -logFilePath "$(Split-Path -path $Global:MyScriptRoot -parent)\LOGS\Errors.log" -Display -Status "Error" -Format 'yyyy-MM-dd HH:mm:ss'
        Exit 1
    }
}
# Error trap
trap {
    Get-ErrorReporting $_    
    exit 1
}
#########################################################################
Clear-Host
Initialize-Script

Add-ToLog -Message "Empty settings creator started." -logFilePath $ScriptLogFilePath -display -status "Info"
foreach ($Folder in $FoldersToApplyPath){
    $Projects = Get-ChildItem  -path $Folder -Directory
    foreach($Project in $Projects){
        if (!($IgnoreFolders -contains $Project.Name)) {
            $SettingsFilePath = "$($Project.FullName)\$SETTINGSFolder"
            if (Test-Path $SettingsFilePath){
                $Settings = Get-ChildItem -path $SettingsFilePath -File -Filter "Settings*.ps1"
                Foreach($Setting in $Settings){
                    if (!($Setting.FullName.contains("-empty") -or $Setting.FullName.contains("-test"))) {
                        Add-ToLog -Message "Processing file [$($Setting.FullName)]." -logFilePath $ScriptLogFilePath -display -status "Info"
                        [array]$Content = Get-Content -path $Setting.FullName -Encoding utf8BOM
                        [array]$NewContent = @()
                        $LineType = ""
                        ForEach($Line in $Content){                            
                            If (($Line.Contains($global:NoReplacementSection)) -and ($Line.substring(1,1) -eq "#")) {
                                $LineType = "NoReplacement"
                            }
                            If (($Line.Contains($global:LocalSection)) -and ($Line.substring(1, 1) -eq "#")) {
                                $LineType = "LocalSection"
                            }
                            switch ($LineType) {
                                "NoReplacement" { $NewContent += $Line }
                                "LocalSection" { }
                                Default {
                                    if($Line.Contains("=")){
                                        $Array = @($Line.split("="))
                                        if($Array.count -eq 2){
                                            $NewLine = ""
                                            if ($Array[1].Contains("`"")){
                                                $ZeroType = "`"`""
                                            }
                                            if ($Array[1].Contains(" @")) {
                                                $ZeroType = "@()"
                                            }
                                            if($Array[1].Contains("#")){
                                                $Array1 = @($Array[1].split("#"))
                                                if($Array1.count -eq 2){
                                                    if ($Array1[0].Contains("`"")) {
                                                        $ZeroType = "`"`" "
                                                    }
                                                    if ($Array1[0].Contains(" @")) {
                                                        $ZeroType = "@()"
                                                    }
                                                    $Comment = "# " + $Array1[1].trim()
                                                }
                                                Else {
                                                    Add-ToLog -Message "Line [$Line] contain error, numbers of '#' more then one." -logFilePath $ScriptLogFilePath -display -status "Error"
                                                }
                                            }
                                            Else {
                                                $Comment = ""
                                            }
                                           
                                            $NewLine = $Array[0] + "= $ZeroType         " + $Comment
                                            $NewContent += $NewLine
                                        }
                                        Else {
                                            Add-ToLog -Message "Line [$Line] contain error, numbers of '=' more then one." -logFilePath $ScriptLogFilePath -display -status "Error"
                                        }
                                    }
                                    else {
                                        $NewContent += $Line
                                    }
                                }
                            } 
                            
                        }
                        Set-Content -path "$SettingsFilePath\$($Setting.BaseName)$NewFileNameEnd" -Value $NewContent -Force
                    }
                }
            }
        }
    }

}

Add-ToLog -Message "Empty settings creator completed." -logFilePath $ScriptLogFilePath -display -status "Info"
<#
    .SYNOPSIS 
        .AUTOR
        .DATE
        .VER
    .DESCRIPTION
    .PARAMETER
    .EXAMPLE
#>
Param (
    [Parameter( Mandatory = $false, Position = 0, HelpMessage = "Initialize global settings." )]
    [bool] $InitGlobal = $true,
    [Parameter( Mandatory = $false, Position = 1, HelpMessage = "Initialize local settings." )]
    [bool] $InitLocal = $true   
)

$Global:GlobalSettingsSuccessfullyLoaded = $false
$Global:ScriptInvocation = $MyInvocation
if ($env:AlexKFrameworkInitScript){. "$env:AlexKFrameworkInitScript" -MyScriptRoot (Split-Path $PSCommandPath -Parent) -InitGlobal $InitGlobal -InitLocal $InitLocal} Else {Write-host "Environmental variable [AlexKFrameworkInitScript] does not exist!" -ForegroundColor Red; exit 1}
if ($LastExitCode) { exit 1 }
# Error trap
trap {
    if (get-module -FullyQualifiedName AlexkUtils) {
       Get-ErrorReporting $_

        . "$GlobalSettings\$SCRIPTSFolder\Finish.ps1"  
    }
    Else {
        Write-Host "[$($MyInvocation.MyCommand.path)] There is error before logging initialized. Error: $_" -ForegroundColor Red
    }   
    exit 1
}
################################# Script start here #################################

foreach ($Folder in $FoldersToApplyPath){
    $Projects = Get-ChildItem  -path $Folder -Directory
    foreach($Project in $Projects){
        if (-not ($Project.Name -like $IgnoreFolders)) {
            $SettingsFilePath = "$($Project.FullName)\$SETTINGSFolder"
            if (Test-Path $SettingsFilePath){
                $Settings = Get-ChildItem -path $SettingsFilePath -File -Filter "Settings*.ps1"
                Foreach($Setting in $Settings){
                    if (!($Setting.FullName.contains("-empty") -or $Setting.FullName.contains("-test"))) {
                        Add-ToLog -Message "Processing file [$($Setting.FullName)]." -logFilePath $ScriptLogFilePath -display -status "Info" -level ($ParentLevel + 1)
                        [array]$Content = Get-Content -path $Setting.FullName
                        [array]$NewContent = @()
                        if ($Content[0] -ne $global:EmptySettingsStub) {
                            $NewContent += $global:EmptySettingsStub
                        }
                        $LineType = ""
                        ForEach($Line in $Content){                            
                            If (($Line.Contains($global:NoReplacementSection)) -and ($Line.substring(1,1) -eq "#")) {
                                $LineType = "NoReplacement"
                            }
                            If (($Line.Contains($global:LocalSection)) -and ($Line.substring(1, 1) -eq "#")) {
                                $LineType = "LocalSection"
                            }
                            If (($Line.Contains($global:ValueReplacementSection)) -and ($Line.substring(1, 1) -eq "#")) {
                                $LineType = "ValueReplacement"
                            }                          
                            switch ($LineType) {
                                "NoReplacement" { $NewContent += $Line }
                                "LocalSection" { }
                                Default {
                                    if($Line.Contains("=")){
                                        $Array = @($Line.split("="))
                                        
                                        if($Array.count -ne 2){
                                            Add-ToLog -Message "Line [$Line] contain error, numbers of '=' more then one." -logFilePath $ScriptLogFilePath -display -status "Error" -level ($ParentLevel + 1)
                                            $Array[1] = ($Array | Select-Object -last ($Array.count - 1)) -join "="
                                        }

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
                                                Add-ToLog -Message "Line [$Line] contain error, numbers of '#' more then one." -logFilePath $ScriptLogFilePath -display -status "Error" -level ($ParentLevel + 1)
                                            }
                                        }
                                        Else {
                                            $Comment = ""
                                        }
                                        
                                        $NewLine = $Array[0] + "= $ZeroType         " + $Comment
                                        $NewContent += $NewLine
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

################################# Script end here ###################################
. "$GlobalSettingsPath\$SCRIPTSFolder\Finish.ps1"
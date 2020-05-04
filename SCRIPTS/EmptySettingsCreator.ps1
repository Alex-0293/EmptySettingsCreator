<#
    .SYNOPSIS 
        .AUTOR
        .DATE
        .VER
    .DESCRIPTION
    .PARAMETER
    .EXAMPLE
#>
$MyScriptRoot     = "C:\DATA\ProjectServices\EmptySettingsCreator\SCRIPTS"
$InitScript       = "C:\DATA\Projects\GlobalSettings\SCRIPTS\Init.ps1"

. "$InitScript" -MyScriptRoot $MyScriptRoot
# Error trap
trap {
    if ($Global:Logger) {
        Get-ErrorReporting $_ 
    }
    Else {
        Write-Host "There is error before logging initialized." -ForegroundColor Red
    }   
    exit 1
}
################################# Script start here #################################
Clear-Host

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
                        $NewContent += $global:EmptySettingsStub
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

################################# Script end here ###################################
. "$GlobalSettings\$SCRIPTSFolder\Finish.ps1"
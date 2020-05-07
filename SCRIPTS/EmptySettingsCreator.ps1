<#
    .SYNOPSIS 
        .AUTOR
        .DATE
        .VER
    .DESCRIPTION
    .PARAMETER
    .EXAMPLE
#>
Clear-Host
$Global:ScriptName = $MyInvocation.MyCommand.Name
$InitScript = "C:\DATA\Projects\GlobalSettings\SCRIPTS\Init.ps1"
if (. "$InitScript" -MyScriptRoot (Split-Path $PSCommandPath -Parent) -force ) { exit 1 }
# Error trap
trap {
    if ($Global:Logger) {
       Get-ErrorReporting $_
        . "$GlobalSettings\$SCRIPTSFolder\Finish.ps1"  
    }
    Else {
        Write-Host "There is error before logging initialized." -ForegroundColor Red
    }   
    exit 1
}
################################# Script start here #################################

foreach ($Folder in $FoldersToApplyPath){
    $Projects = Get-ChildItem  -path $Folder -Directory
    foreach($Project in $Projects){
        if (!($IgnoreFolders -contains $Project.Name)) {
            $SettingsFilePath = "$($Project.FullName)\$SETTINGSFolder"
            if (Test-Path $SettingsFilePath){
                $Settings = Get-ChildItem -path $SettingsFilePath -File -Filter "Settings*.ps1"
                Foreach($Setting in $Settings){
                    if (!($Setting.FullName.contains("-empty") -or $Setting.FullName.contains("-test"))) {
                        Add-ToLog -Message "Processing file [$($Setting.FullName)]." -logFilePath $ScriptLogFilePath -display -status "Info" -level ($ParentLevel + 1)
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
. "$GlobalSettings\$SCRIPTSFolder\Finish.ps1"
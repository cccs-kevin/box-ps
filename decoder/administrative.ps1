# using namespaces to find the necessary types of the parameters generated for the overrides
using namespace System.Management.Automation
using namespace System.IO
using namespace System.Text
using namespace Microsoft.PowerShell.Commands
using namespace System.Diagnostics
using namespace System.Collections

class Action <# lawsuit... I'll be here all week #> {

    [String[]] $Behaviors
    [String] $Actor
    [String] $FullActor
    [String] $Line
    [hashtable] $BehaviorProps
    [hashtable] $BoundParams
    [String[]] $UnboundParams
    [String[]] $Switches

    Action ([String[]] $Behaviors, [String] $FullActor, [hashtable] $BehaviorProps,
        [InvocationInfo] $Invocation) {

        $this.Behaviors = $Behaviors
        $this.FullActor = $FullActor
        $this.Actor = $this.GetShortActor($FullActor)

        Write-Host $this.Actor

        $this.BehaviorProps = $BehaviorProps
        $this.Line = $Invocation.Line.Trim()

        $paramsSplit = $this.SplitParams($Invocation)

        $this.BoundParams = $paramsSplit["bound"]
        $this.UnboundParams = $paramsSplit["unbound"]
        $this.Switches = $paramsSplit["switches"]
    }

    # for class members
    #   These are guaranteed not to have unbound or switches, and the MyInvocation variable does not
    #   contain boundparameters, so callers need to be able to pass the PSBoundParameters variable
    # e.g. System.Net.WebClient.DownloadFile
    Action ([String[]] $Behaviors, [String] $FullActor, [hashtable] $BehaviorProps, 
        [hashtable] $BoundParams, [String] $Line) {

        $this.Behaviors = $Behaviors
        $this.FullActor = $FullActor
        $this.Actor = $this.GetShortActor($FullActor)
        $this.BehaviorProps = $BehaviorProps
        $this.BoundParams = $BoundParams
        $this.Line = $Line.Trim()
        $this.UnboundParams = @()
        $this.Switches = @()
    }

    <#
    linear walk through all parameters rebuilding bound params and switches. Unbound arguments are, 
    for some reason, not present in MyCommand.Parameters (thanks for the help, pwsh)
    #>
    [hashtable] SplitParams([InvocationInfo] $Invocation) {

        $allParams = $Invocation.MyCommand.Parameters

        $bound = @{}
        $localSwitches = @() # not allowed to name this $switches (thanks for the help, pwsh)
        
        foreach ($paramName in $allParams.Keys) {

            <#
            for some reason, all common parameters are in MyCommand.Parameters even if they are not
            given explicitely and don't even have default values (thanks for the help, pwsh)
            #>
            if ($allParams[$paramName].SwitchParameter -and $Invocation.BoundParameters.Keys -eq `
                    $paramName) {

                $localSwitches += $paramName
            }
            elseif ($Invocation.BoundParameters.Keys -eq $paramName) {
                $bound[$paramName] = $Invocation.BoundParameters[$paramName]
            }
        }

        return @{
            "bound" = $bound;
            "unbound" = $Invocation.UnboundArguments;
            "switches" = $localSwitches
        }
    }

    [string] GetShortActor([string] $FullActor) {
        # commandlet notation
        if ($FullActor.Contains("\")) {
            return $FullActor.Split("\")[-1]
        }
        # class member notation
        else {
            return $FullActor.Split(".")[-1]
        }
    }
}


# Write out JSON representation of the arguments this function is given to the output file
# ACTIONS_OUTFILE_PLACEHOLDER will be replaced with the real value by box-ps.ps1
function RecordAction {

    param(
        [Action] $Action
    )

    Write-Host $Action.Actor
    Write-Host $Action.Behaviors
    $actionsOutFile = "ACTIONS_OUTFILE_PLACEHOLDER"

    $json = $Action | ConvertTo-Json -Depth 10
    ($json + ",") | Out-File -Append $actionsOutFile
}

# placeholder will be replaced with the real value by box-ps.ps1
function RecordLayer {
    param(
        [String]$layer
    )

    $layersOutFile = "LAYERS_OUTFILE_PLACEHOLDER"

    $output = ("LAYERDELIM" + $layer + "LAYERDELIM")
    $output | Out-File -Append $layersOutFile
}

function RedirectObjectCreation {

    param(
        [string] $TypeName
    )

    return Microsoft.PowerShell.Utility\New-Object -TypeName "BoxPS$($TypeName.Split(".")[-1])"
}

function GetOverridedClasses {
    $config = Microsoft.PowerShell.Management\Get-Content .\config.json | ConvertFrom-Json -AsHashtable
    return $config["classes"].Keys | % { $_.ToLower() }
}

<# 
process objects make the output huge and it's not that useful
just keep the string representation
#> 
function FlattenProcessObjects {

    param(
        [System.Diagnostics.Process[]] $ProcessList
    )

    $strings = @()

    $count = 0;
    while ($count -lt $ProcessList.Count) {
        $strings += $ProcessList[$count].ProcessName
        $count++
    }

    return $strings
}
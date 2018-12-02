
Param(
    [string] $panofile
)

. "$PSScriptRoot\generatePtguiProjectsExposures.ps1"

$ptgui = "$env:programfiles\ptgui\ptgui.exe"

# liste des suffixes fichiers et leur expo correspondantes
$expos = @(
    @{ suffix = "0000.tif"; expo = "+0" },
    @{ suffix = "0001.tif"; expo = "-0.7" },
    @{ suffix = "0002.tif"; expo = "+0.7" },
    @{ suffix = "0003.tif"; expo = "-1.3" },
    @{ suffix = "0004.tif"; expo = "+1.3" } )

# Génération des projets ptgui
$projects = GeneratePtguiProjectsExposures $panofile $expos

# Génération du batch file ptgui
$batchFile = SaveBatchList  $projects

$batchFile = ($batchFile | Resolve-Path)
$batchFile

# Création des panorames
& "$ptgui"  "$batchFile"



. "$PSScriptRoot\getFolderFilesMetadata.ps1"

<#
.SYNOPSIS
Generate a new panorama for each exposure configured above in $expos
suffix is the last part of the image in the $panofile
at least one expos.expo must be in the name of file $panofile

.DESCRIPTION
Long description

.EXAMPLE
GeneratePtguiProjectsExposures '.\Erdre Gandonnière +0.pts' 
GeneratePtguiProjectsExposures '.\Erdre Gandonnière -0.7.pts'

.NOTES
The images with suffixes "0001.tif", "0002.tif".. must exist in the same 
folder as the images in the $panofile
#>
Function GeneratePtguiProjectsExposures
{
    param(
        [string] $panofile,
        [object[]] $expos
    )
    
    if ( ! $panofile ) {
        echo "Renseigner le nom du fichier Ptgui .pts en paramètre"
        exit( 0 );
    }
    
    $allProjects = @()
    $allProjects += $panofile

    # on retrouve l'exposition du fichier passée en paramètre
    $exporef = $expos.Where( { $panofile -like '*' + $_.expo + '.pts' } ) 
    
    # on liste les expos à générer
    $expos2generate = $expos.Where( {  $panofile -notlike '*' + $_.expo + '.pts' } )
    
    # creation d'un nouveau pano pour chaque expo
    foreach( $newExpo in $expos2generate ) {
    
        # creation d'un nouveau nom de fichier de pano pour l'expo.
        [string] $newPano = $panofile.Replace( $exporef.expo, $newExpo.expo )
    
        Write-Host "$panofile > $newPano"
    
        # lecture du projet ptGui 
        $ptGuiPano = Get-Content -Path $panofile | ConvertFrom-Json 
    
        # ensure the genarated output file is same the project filename
        $ptGuiPano.project.projectsettings.defaultfilenaming.defaultpanoramafilenamemode = "sameasproject"
    
        # listing des images et remplacement des nom de fichiers d'images
        $projectImages = $ptGuiPano.project.imagegroups.images 
        $projectImages | ForEach-Object -Process { $_.filename = $_.filename -replace $exporef.suffix, $newExpo.suffix } 
  
        # recuperation des metadatas des images
        $imgMetadatasList = GetFilesMetadata ($projectImages | Select-Object -ExpandProperty filename)
      
        # remplacement des propriétés par les données en metadata
        foreach( $image in $projectImages )
        {
            $filename = $image.filename
            $foundMetadata = $imgMetadatasList."$filename"
            $imgMeta = $image.metadata
            $imgMeta.aperture = Invoke-Expression ( $foundMetadata."F-stop" -replace "[^\d.]", "" )
            $imgMeta.exposuretime = Invoke-Expression ( $foundMetadata."Exposure time" -replace "[^\d/.]", "" )
            $imgMeta.iso = Invoke-Expression ( $foundMetadata."ISO speed" -replace "[^\d]", "" )
            $imgMeta.filesize = $null
            $imgMeta.filetimestamp = $null
        }
        
        # creation d'un nouveau pano
        $ptGuiPano | ConvertTo-Json -Depth 100 | Set-Content -Path $newPano
        $allProjects += $newPano
    }
    return $allProjects
}

<#
.SYNOPSIS
Generate a Ptgui batch list
.PARAMETER panoFiles
List of panoramas to add to the batch list
.EXAMPLE
SaveBatchList @( ./panoExpo+1.pts, ./panoExpo+0.pts, ./panoExpo-1.pts )
.NOTES
Paths are resolved to theit absolute path file
#>
Function SaveBatchList
{
    Param (
        [string[]] $panoFiles
    )

    [xml] $doc = New-Object System.Xml.XmlDocument
    [string] $ptguiBatchFile  =  ($panoFiles[0] -replace " [+-][0-9](.[0-9]+)?.pts", "") + ".ptgbatch"
    $doc.AppendChild($doc.CreateXmlDeclaration("1.0","UTF-8",$null))
    $root = $doc.CreateNode("element", "PTGuiBatchList", $null)
    $doc.AppendChild($root)
    
    foreach( $panoFile in $panoFiles )
    {
        Write-Host "Adding $panoFile to batch file"
        $project = $doc.CreateElement("element", "Project", $null)
        $project.SetAttribute( "FileName",  ($panoFile | Resolve-Path ) )
        $project.SetAttribute( "Enabled", "true")
        $project.SetAttribute( "DeleteWhenDone", "false" )
        $root.AppendChild( $project )
    }
    
    $savePath = (Get-Item -Path ".\").FullName + "\$ptguiBatchFile"
    Write-Host "Saving the ptgui batch file to > $savePath" -ForegroundColor Green
    $doc.Save( $savePath ) | Out-Null

    echo $ptguiBatchFile
    return $ptguiBatchFile
}



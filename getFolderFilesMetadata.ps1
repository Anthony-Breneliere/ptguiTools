$objShell = New-Object -ComObject Shell.Application

# Retourne toutes les propriétées de metadata gérées par le système pour le dossier $folderPath
Function GetMetadataProperties
{
    Param (
        [string] $folderPath
    )

    $folderPropList =  New-Object System.Collections.ArrayList
    $resolvedPath = Resolve-Path -Path $folderPath

    if ( ! $resolvedPath ) {
        throw [System.Exception] "Dossier $folderPath non trouvé"
    }
    else 
    {
        $objFolder = $objShell.NameSpace( $resolvedPath.Path )
        for ( $i = 0 ; $i -lt 400; $i++ ) 
        {
            $prop = $objFolder.GetDetailsOf( $objFolder, $i )
            if ( $prop )
            {
                $folderPropList.Add( @{Id = $i; Name = $prop } ) | Out-Null
            }
        }
    }
    return $folderPropList
}


<#
.SYNOPSIS
Retourne les propriétés de metadata de chaque fichier dans $fileList

.PARAMETER fileList
$fileList : liste des fichiers, leur chemin peut être relatif ou absolu

.EXAMPLE
GetFilesMetadata @( "toto.tif, "c:\tata.tif" )

.NOTES
General notes
#>
Function GetFilesMetadata
{
    Param (
        [string[]] $fileList
    )

    $filesMetadatas =  New-Object System.Collections.ArrayList

    if ( $fileList )
    {
        # listing de la liste complètes des propriétés de metadonnées
        if ( ! $metaDataProperties )
        {
            $filePath = Split-Path -Parent ( $fileList | Select-Object -First 1 )
            $metaDataProperties = GetMetadataProperties -folderPath $filePath 
        }
        
        # parcours de la liste des fichiers pour lire les metadonnées
        foreach ( $file in $fileList )
        {
            $fileMetadata = New-Object psobject

            # conversion du chemin relatif $file en objet FolderItem ($objItem)
            $resolvedfile = $file | Resolve-Path | Select-Object -Property Path
            if ( ! $resolvedfile ) { throw [System.Exception] "Fichier $file non trouvé" } 
            $folder = $resolvedfile | Split-Path -Parent
            $objFolder = $objShell.NameSpace( $folder )
            $objItem = $objFolder.Items() | Where-Object { $_.Path -eq $resolvedfile.Path }
            if ( ! $objItem ) { throw [System.Exception] "Resolution de $resolvedfile impossible dans $folder" } 

            # parcrous de l'ensemble des metadonnees
            foreach ( $prop in $metaDataProperties )
            {
                $propValue = $objFolder.GetDetailsOf( $objItem, $prop.Id )

                # si la propriété a une valeur, on l'ajoute au membre
                if ( $propValue )
                {
                    $member = @{ $prop.Name = $propValue }
                    $fileMetadata | Add-Member $member
                }
            }
    
            $filesMetadatas.Add( @{  $file = $fileMetadata } ) | Out-Null
        }
    }
    
    return $filesMetadatas
}


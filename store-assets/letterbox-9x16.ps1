# Pipeline grafica de store (E7), pasul de rezerva pentru capturi:
# aduce capturile de telefon (ex. 19.5:9) la raportul 9:16 cerut de
# Play Console prin LETTERBOX pe fundalul brandului (#F3F0E8) --
# continutul NU se decupeaza si NU se deformeaza, doar primeste benzi
# laterale. Se ruleaza DOAR daca Play Console refuza capturile la upload.
#
# Folosire (PowerShell, din radacina repo-ului):
#   .\store-assets\letterbox-9x16.ps1 -Sursa C:\calea\catre\capturi
# Rezultatele apar langa originale, cu sufixul "-9x16.png".

param(
    [Parameter(Mandatory = $true)]
    [string]$Sursa
)

Add-Type -AssemblyName System.Drawing
$fundal = [System.Drawing.Color]::FromArgb(255, 243, 240, 232)  # #F3F0E8

$fisiere = Get-ChildItem -Path $Sursa -File |
    Where-Object { $_.Extension -match '^\.(png|jpg|jpeg)$' -and $_.BaseName -notmatch '-9x16$' }
if (-not $fisiere) { Write-Output "Nicio imagine gasita in $Sursa"; exit 1 }

foreach ($fisier in $fisiere) {
    $img = [System.Drawing.Image]::FromFile($fisier.FullName)

    # Canvas 9:16 (portret): pastram inaltimea si largim cu benzi laterale;
    # daca imaginea e mai LATA decat 9:16 (peisaj), pastram latimea si
    # adaugam benzi sus/jos.
    $latimeNoua = [int][math]::Round($img.Height * 9.0 / 16.0)
    if ($latimeNoua -ge $img.Width) {
        $cw = $latimeNoua; $ch = $img.Height
    } else {
        $cw = $img.Width; $ch = [int][math]::Round($img.Width * 16.0 / 9.0)
    }

    $bmp = New-Object System.Drawing.Bitmap $cw, $ch, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear($fundal)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $x = [int](($cw - $img.Width) / 2)
    $y = [int](($ch - $img.Height) / 2)
    $g.DrawImage($img, $x, $y, $img.Width, $img.Height)
    $g.Dispose(); $img.Dispose()

    $tinta = Join-Path $fisier.DirectoryName ($fisier.BaseName + '-9x16.png')
    $bmp.Save($tinta, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()

    $verif = [System.Drawing.Image]::FromFile($tinta)
    Write-Output ("{0} -> {1} ({2}x{3})" -f $fisier.Name, (Split-Path $tinta -Leaf), $verif.Width, $verif.Height)
    $verif.Dispose()
}

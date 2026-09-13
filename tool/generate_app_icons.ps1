$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$navy = [System.Drawing.ColorTranslator]::FromHtml('#18233D')
$teal = [System.Drawing.ColorTranslator]::FromHtml('#35C7B0')
$paper = [System.Drawing.ColorTranslator]::FromHtml('#F7F9FC')

function New-IconBitmap {
    param(
        [int]$Size,
        [bool]$TransparentBackground,
        [bool]$Monochrome = $false,
        [double]$SymbolScale = 1.0
    )

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    if (-not $TransparentBackground) {
        $radius = $Size * 0.22
        $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $diameter = $radius * 2
        $bounds = [System.Drawing.RectangleF]::new($Size * 0.025, $Size * 0.025, $Size * 0.95, $Size * 0.95)
        $path.AddArc($bounds.Left, $bounds.Top, $diameter, $diameter, 180, 90)
        $path.AddArc($bounds.Right - $diameter, $bounds.Top, $diameter, $diameter, 270, 90)
        $path.AddArc($bounds.Right - $diameter, $bounds.Bottom - $diameter, $diameter, $diameter, 0, 90)
        $path.AddArc($bounds.Left, $bounds.Bottom - $diameter, $diameter, $diameter, 90, 90)
        $path.CloseFigure()
        $brush = [System.Drawing.SolidBrush]::new($navy)
        $graphics.FillPath($brush, $path)
        $brush.Dispose()
        $path.Dispose()
    }

    $offset = (1.0 - $SymbolScale) * $Size / 2
    function Point([double]$x, [double]$y) {
        return [System.Drawing.PointF]::new(
            [float]($offset + $x * $Size * $SymbolScale),
            [float]($offset + $y * $Size * $SymbolScale)
        )
    }

    $mark = if ($Monochrome) { [System.Drawing.Color]::White } else { $paper }
    $markBrush = [System.Drawing.SolidBrush]::new($mark)
    $leftPage = [System.Drawing.PointF[]]@(
        (Point 0.20 0.31), (Point 0.47 0.39), (Point 0.47 0.72), (Point 0.20 0.62)
    )
    $rightPage = [System.Drawing.PointF[]]@(
        (Point 0.53 0.39), (Point 0.80 0.31), (Point 0.80 0.62), (Point 0.53 0.72)
    )
    $graphics.FillPolygon($markBrush, $leftPage)
    $graphics.FillPolygon($markBrush, $rightPage)

    $checkColor = if ($Monochrome) { [System.Drawing.Color]::White } else { $teal }
    $pen = [System.Drawing.Pen]::new($checkColor, [float]($Size * 0.095 * $SymbolScale))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $graphics.DrawLines($pen, [System.Drawing.PointF[]]@(
        (Point 0.30 0.55), (Point 0.45 0.69), (Point 0.73 0.42)
    ))

    $pen.Dispose()
    $markBrush.Dispose()
    $graphics.Dispose()
    return $bitmap
}

function Save-Png {
    param([System.Drawing.Bitmap]$Bitmap, [string]$Path)
    $directory = Split-Path -Parent $Path
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Bitmap.Dispose()
}

$brandingRoot = Join-Path $projectRoot 'assets\branding'
Save-Png (New-IconBitmap -Size 1024 -TransparentBackground $false) (Join-Path $brandingRoot 'mission_book_icon_master.png')
Save-Png (New-IconBitmap -Size 1024 -TransparentBackground $true -SymbolScale 0.66) (Join-Path $brandingRoot 'mission_book_icon_foreground.png')

$androidRoot = Join-Path $projectRoot 'android\app\src\main\res'
$densities = @{
    'mdpi' = 48
    'hdpi' = 72
    'xhdpi' = 96
    'xxhdpi' = 144
    'xxxhdpi' = 192
}
$adaptiveSizes = @{
    'mdpi' = 108
    'hdpi' = 162
    'xhdpi' = 216
    'xxhdpi' = 324
    'xxxhdpi' = 432
}

foreach ($density in $densities.Keys) {
    $legacyPath = Join-Path $androidRoot "mipmap-$density\ic_launcher.png"
    Save-Png (New-IconBitmap -Size $densities[$density] -TransparentBackground $false) $legacyPath

    $foregroundPath = Join-Path $androidRoot "mipmap-$density\ic_launcher_foreground.png"
    Save-Png (New-IconBitmap -Size $adaptiveSizes[$density] -TransparentBackground $true -SymbolScale 0.66) $foregroundPath

    $notificationPath = Join-Path $androidRoot "drawable-$density\ic_notification.png"
    Save-Png (New-IconBitmap -Size $densities[$density] -TransparentBackground $true -Monochrome $true -SymbolScale 0.82) $notificationPath
}

$icoSizes = @(16, 24, 32, 48, 64, 128, 256)
$pngFrames = [System.Collections.Generic.List[byte[]]]::new()
foreach ($size in $icoSizes) {
    $bitmap = New-IconBitmap -Size $size -TransparentBackground $false
    $stream = [System.IO.MemoryStream]::new()
    $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngFrames.Add($stream.ToArray())
    $stream.Dispose()
    $bitmap.Dispose()
}

$icoPath = Join-Path $projectRoot 'windows\runner\resources\app_icon.ico'
$output = [System.IO.File]::Create($icoPath)
$writer = [System.IO.BinaryWriter]::new($output)
$writer.Write([uint16]0)
$writer.Write([uint16]1)
$writer.Write([uint16]$pngFrames.Count)
$offset = 6 + 16 * $pngFrames.Count
for ($index = 0; $index -lt $pngFrames.Count; $index++) {
    $size = $icoSizes[$index]
    $encodedSize = if ($size -eq 256) { 0 } else { $size }
    $writer.Write([byte]$encodedSize)
    $writer.Write([byte]$encodedSize)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]32)
    $writer.Write([uint32]$pngFrames[$index].Length)
    $writer.Write([uint32]$offset)
    $offset += $pngFrames[$index].Length
}
foreach ($frame in $pngFrames) {
    $writer.Write($frame)
}
$writer.Dispose()
$output.Dispose()

Write-Output 'Mission Book icons generated.'

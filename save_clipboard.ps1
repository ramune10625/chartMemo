param([string]$filePath)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$image = [System.Windows.Forms.Clipboard]::GetImage()

if ($image -ne $null) {
    # Ensure the directory exists before saving
    $directory = [System.IO.Path]::GetDirectoryName($filePath)
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
    $image.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
}

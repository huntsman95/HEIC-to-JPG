{
    Import-PodeModule -Path .\lib\Handlebars.dll
    Import-PodeModule -Path .\lib\netstandard20\Magick.NET.Core.dll
    Import-PodeModule -Path .\lib\netstandard20\Magick.NET-Q16-HDRI-x64.dll
    Import-PodeModule -Path .\pode_modules\SearchBinary\SearchBinary.psm1

    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging
    Write-PodeHost 'Pode is starting...'

    $port = (Get-PodeConfig).Port
    Add-PodeEndpoint -Address * -Port $port -Protocol Http

    function Register-HandlebarsTemplate {
        param (
            $Name,
            $TemplatePath
        )
        $TemplateData = Get-Content -Path $TemplatePath -Raw
        [HandlebarsDotNet.Handlebars]::RegisterTemplate($Name, $TemplateData)
    }

    Set-PodeViewEngine -Type hbs -ScriptBlock {
        param($path, $data)
        $template = [HandlebarsDotNet.Handlebars]::Compile((Get-Content -Path $path -Raw -Force))
        $TemplateData = [System.Dynamic.ExpandoObject]::new()
        $TemplateData.Config = (Get-PodeState -Name Config)
        $TemplateData.Username = $WebEvent.Auth.User.Name
        $TemplateData.YearNow = (Get-Date).Year
        $TemplateData.Data = $data
        $TemplateData.Version = (Get-PodeConfig).Version
        if (-not($env:ThemeColor)) {
            $env:ThemeColor = (Get-PodeConfig).ThemeColor
        }
        $TemplateData.ThemeColor = $env:ThemeColor
        return ($template.Invoke($TemplateData))
    }

    Get-ChildItem -Path './views/templates' | ForEach-Object {
        Register-HandlebarsTemplate -Name $_.BaseName -TemplatePath $_.FullName
    }

    Add-PodeRoute -Method Get, Post -Path '/' -ScriptBlock {
        if ($WebEvent.Method -eq 'POST') {
            $FileName = $WebEvent.Data['file']
            [byte[]]$FileBytes = $WebEvent.Files[$FileName].Bytes

            #check if file is HEIC using magic number
            
            $magicNumber = @(0x66, 0x74, 0x79, 0x70)
            $fTypeMagicStrings = @(
                'ftypmif1'
                'ftypmsf1'
                'ftypheic'
                'mif1heic'
            )
            [bool]$isHEIC = $false
            $fTypeMagicStrings | ForEach-Object { 
                if (Search-Binary -ByteArray $FileBytes -Pattern $magicNumber -First) {
                    $isHEIC = $true
                }
            }
            if (-not ($isHEIC)) {
                Write-PodeViewResponse -Path 'index' -Data @{
                    FileName = 'Input file is not HEIC'
                }
                return
            }

            $image = [ImageMagick.MagickImage]::new(([byte[]]($FileBytes)))
            $image.Format = [ImageMagick.MagickFormat]::JPG
            $image.Quality = 70

            $OutStream = New-Object System.IO.MemoryStream
            $image.Write($OutStream)
            $OutStream.Position = 0
            $image = [ImageMagick.MagickImage]::new($OutStream)
            $OutStream.Close()
            $NewFileName = $FileName -replace '\.heic$', '.jpg'
            Add-PodeHeader -Name 'Content-disposition' -Value "attachment; filename=$NewFileName"
            Write-PodeTextResponse -Bytes $OutStream.ToArray() -Cache -MaxAge 1 -ContentType 'application/octet-stream'
            return
        }
        else {
            $FileName = $null
        }
        Write-PodeViewResponse -Path 'index' -Data @{
            FileName = $FileName
        }
    }
}
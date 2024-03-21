using module .\lib\netstandard20\Magick.NET.Core.dll
using module .\lib\netstandard20\Magick.NET-Q16-HDRI-x64.dll

$image = [ImageMagick.MagickImage]::new('G:\Users\thehuntzman\Downloads\sample1.heic')
$image.Format = [ImageMagick.MagickFormat]::JPG
$image.Quality = 70
$image.Write('G:\Users\thehuntzman\Downloads\sample1.jpg')


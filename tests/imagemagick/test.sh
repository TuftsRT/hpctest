#!/bin/bash
#@ description: ImageMagick creates, resizes, composites and identifies PNG images
#@ param imagemagick = imagemagick
#@ param magick = magick
#@ modules: ${imagemagick}
#@ ntasks: 1
#@ time: 5
#@ tags: tool media

# ImageMagick 6 has no "magick" command: set magick= (empty) to use convert/identify.
convert=${magick:+$magick }convert; identify=${magick:+$magick }identify
[ -n "$magick" ] && convert=$magick
$convert -size 200x100 xc:red red.png
$convert red.png -resize 50% small.png
$convert -size 100x50 xc:blue small.png -gravity center -compose over -composite combo.png
$identify -format '%f %wx%h %m\n' red.png small.png combo.png
$convert combo.png -format 'mean red %[fx:mean.r] blue %[fx:mean.b]\n' info:

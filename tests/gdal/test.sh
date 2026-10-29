#!/bin/bash
#@ description: GDAL/OGR/PROJ: create, warp and describe a GeoTIFF; reproject points
#@ param gdal = gdal
#@ modules: ${gdal}
#@ ntasks: 1
#@ time: 5
#@ tags: lib geo

# PROJ modules often still set the deprecated PROJ_LIB; PROJ warns about it on stderr.
[ -n "$PROJ_LIB" ] && [ -z "$PROJ_DATA" ] && export PROJ_DATA=$PROJ_LIB
unset PROJ_LIB

gdal_create -of GTiff -outsize 20 10 -bands 1 -ot Float32 -burn 7.5 \
    -a_srs EPSG:4326 -a_ullr -10 50 10 40 r.tif
gdalinfo -stats r.tif | grep -E '^Driver|^Size|STATISTICS_MEAN'
echo "10 50" | gdaltransform -s_srs EPSG:4326 -t_srs EPSG:3857 -output_xy |
    awk '{printf "EPSG:3857 x=%.2f y=%.2f\n", $1, $2}'
gdalwarp -q -t_srs EPSG:3857 r.tif warped.tif
gdalinfo warped.tif | grep -q 'ID\["EPSG",3857\]\]' && echo "warp ok"
printf 'id,wkt\n1,"POINT (10 50)"\n2,"POINT (11 51)"\n' > pts.csv
ogr2ogr -f GeoJSON -a_srs EPSG:4326 pts.geojson pts.csv
ogrinfo -so -al pts.geojson | grep -E '^Geometry|^Feature Count'

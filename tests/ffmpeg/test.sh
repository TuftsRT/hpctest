#!/bin/bash
#@ description: FFmpeg encodes a 2 s synthetic video (MPEG-4) and ffprobe reads it back
#@ param ffmpeg = ffmpeg
#@ modules: ${ffmpeg}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ time: 5
#@ tags: tool media

ffmpeg -nostdin -loglevel error -f lavfi -i testsrc=duration=2:size=320x240:rate=25 \
    -f lavfi -i sine=frequency=440:duration=2 -c:v mpeg4 -c:a aac -threads 2 -y test.mp4
ffprobe -v error -count_frames -select_streams v:0 \
    -show_entries stream=codec_name,width,height,nb_read_frames -of default=nw=1 test.mp4
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate -of default=nw=1 test.mp4

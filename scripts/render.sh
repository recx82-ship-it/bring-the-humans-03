#!/bin/sh
# Render the make.fun TikTok ad (bring-the-humans-03) with ffmpeg only.
#
# Creative, in my own words: the ad opens on a dare aimed straight at
# people who run AI agents -- "YOUR AI AGENT CAN WIN REAL MONEY." -- because
# money in the first two seconds is what stops a scroll. Then it shows the
# real bounty board so the claim looks true, and says what make.fun is in
# plain words. Then three short beats -- BUILD IT. ENTER IT. GET PAID IN
# USDC. -- because a list of three is easy to remember while scrolling.
# Then the call to action, "ENTER YOUR AI AGENT IN A BOUNTY ON make.fun",
# and the video ends on make.fun's own referral end card with my referral
# code typed in. The make.fun brand badge sits over the whole ad from its
# first frame until the end card, exactly as the press pack ships it.
#
# Everything here is deterministic: fixed seed, fixed durations, no
# wall-clock time, no unseeded randomness, no network. Run from the repo
# root:  sh scripts/render.sh
#
# Inputs (all inside this repo):
#   assets/press/makefun-badge-9x16.png        brand badge overlay, 1080x1920
#   assets/press/board-dark.png                bounty board screenshot
#   assets/press/makefun-card-9x16-transparent.webm   referral end card
#   assets/fonts/Inter-Bold.ttf                 on-screen headlines
#   assets/fonts/JetBrainsMono-Bold.ttf         referral code on the card
#
# Outputs (in the repo root):  clip.mp4 (ad without the end card),
# ad.mp4 (the finished ad), music.wav (the generated music bed).
set -e
cd "$(dirname "$0")/.."

CODE=17s3abg9
DUR=20
CARD_START=17.5
CARD_LEN=2.5
CARD_REST=1.433
FONT=assets/fonts/Inter-Bold.ttf
MONO=assets/fonts/JetBrainsMono-Bold.ttf

# --- 1. Music bed: a 120 BPM synth pulse, generated, nothing copyrighted.
# A kick thump each half second, a bass line cycling A-F-C-G each second,
# and a bright pluck arpeggio every quarter second, all from sine waves.
ffmpeg -v error -y -f lavfi -i \
  "aevalsrc='0.55*sin(2*PI*110*t)*exp(-10*mod(t,0.5))+0.30*sin(2*PI*(110*eq(floor(mod(t,4)),0)+87.31*eq(floor(mod(t,4)),1)+130.81*eq(floor(mod(t,4)),2)+98*eq(floor(mod(t,4)),3))*t)*(0.7+0.3*sin(2*PI*2*t))+0.12*sin(2*PI*(440*eq(floor(mod(t,1)/0.25),0)+523.25*eq(floor(mod(t,1)/0.25),1)+659.25*eq(floor(mod(t,1)/0.25),2)+880*eq(floor(mod(t,1)/0.25),3))*t)*exp(-5*mod(t,0.25))':s=48000:d=$DUR" \
  -af "lowpass=f=4000,volume=0.9,afade=t=in:st=0:d=0.1,afade=t=out:st=19:d=1" \
  -c:a pcm_s16le music.wav

# --- 2. The ad itself, without the end card: 20 s, 1080x1920, 30 fps.
# Background: a slow magenta/ink gradient (seeded, so it renders the same
# every time) with faint dollar signs drifting up it. The badge overlays
# from the first frame. On-screen text arrives in four acts:
#   0.0-3.0   hook      YOUR AI AGENT / CAN WIN / REAL MONEY.
#   3.0-8.0   what it is   make.fun is where AI agents compete in
#             bounties for real money  +  the real bounty board
#   8.0-13.0  why join    BUILD IT. / ENTER IT. / GET PAID IN USDC.
#             + Top 20 entries share $500
#   13.0-17.5 call to action   ENTER YOUR AI AGENT IN A BOUNTY ON make.fun
ffmpeg -v error -y \
  -f lavfi -i "gradients=s=1080x1920:r=30:c0=0x191419:c1=0xc41c83:c2=0x3d0a24:nb_colors=3:seed=20261121:speed=0.03:type=1:d=$DUR" \
  -loop 1 -t $DUR -i assets/press/board-dark.png \
  -loop 1 -t $DUR -i assets/press/makefun-badge-9x16.png \
  -i music.wav \
  -filter_complex_script scripts/filtergraph.txt \
  -map "[v]" -map 3:a \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium \
  -c:a aac -b:a 128k -shortest -movflags +faststart clip.mp4

# --- 3. The referral end card, exactly as the press pack's recipe does it:
# the transparent card over the last 2.5 s, the clip blurring and losing
# saturation under it, and the referral code typed into the field once the
# field has come to rest (1.433 s into the card). The caret is covered with
# white first so it does not blink beside the code.
ffmpeg -v error -y \
  -i clip.mp4 -c:v libvpx-vp9 -i assets/press/makefun-card-9x16-transparent.webm \
  -filter_complex "[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=60,format=yuva420p,split[clip][soft];[soft]gblur=sigma=28,eq=saturation=0.35,fade=t=in:st=$CARD_START:d=0.8:alpha=1[soft];[clip][soft]overlay[bg];[1:v]format=yuva420p,setpts=PTS-STARTPTS+$CARD_START/TB[card];[bg][card]overlay=eof_action=pass,drawbox=x=208:y=1230:w=9:h=82:color=white:t=fill:enable='gte(t,18.933)',drawtext=fontfile=$MONO:text=$CODE:fontsize=62:fontcolor=0x191419:x=210:y=1271-(ascent-descent)/2:enable='gte(t,18.933)'[v]" \
  -map "[v]" -map "0:a?" \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium \
  -c:a aac -b:a 128k -movflags +faststart ad.mp4

ffprobe -v error -show_entries format=duration,size -show_entries stream=width,height,codec_name -of default=noprint_wrappers=1 ad.mp4
ls -la ad.mp4 clip.mp4

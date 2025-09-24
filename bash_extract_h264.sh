#!/bin/bash
# Script de recuperación automática de videos corruptos
WORKDIR="/home/piero/video/intento02"
HEALTHY="${WORKDIR}/0.mp4"

# 1️⃣ Extraer framerate del video sano
FR=$(ffprobe -v error -select_streams v:0 \
     -show_entries stream=r_frame_rate \
     -of default=noprint_wrappers=1:nokey=1 "$HEALTHY")
FR_DEC=$(echo "$FR" | awk -F/ '{printf "%.2f", $1/$2}')
echo "Framerate detectado del video sano: $FR_DEC fps"

# 2️⃣ Generar healthy.h264 (Annex-B)
HEALTHY_H264="${WORKDIR}/healthy.h264"
ffmpeg -y -i "$HEALTHY" -map 0:v:0 -c:v copy -bsf:v h264_mp4toannexb "$HEALTHY_H264"

# 3️⃣ Extraer SPS+PPS del healthy.h264
SPSPPS="${WORKDIR}/spspps.bin"
python3 - <<EOF
import sys
infile = "$HEALTHY_H264"
outfile = "$SPSPPS"
data = open(infile,"rb").read()
sc4 = b"\x00\x00\x00\x01"
pos = data.find(sc4)
if pos==-1:
    sc3=b"\x00\x00\x01"
    pos=data.find(sc3)
    if pos==-1:
        print("No se encontraron start codes en healthy.h264")
        sys.exit(1)
i=pos
have_sps=False
have_pps=False
out=bytearray()
def nal_type(byte):
    return byte & 0x1F
while i < len(data)-4 and not (have_sps and have_pps):
    next4=data.find(sc4,i+4)
    next3=data.find(b"\x00\x00\x01",i+3)
    candidates=[x for x in (next4,next3) if x!=-1 and x>i]
    next_pos=min(candidates) if candidates else -1
    if next_pos==-1:
        nal=data[i:]
        i=len(data)
    else:
        nal=data[i:next_pos]
        i=next_pos
    out.extend(nal)
    if nal.startswith(sc4):
        header=nal[4]
    elif nal.startswith(b"\x00\x00\x01"):
        header=nal[3]
    else:
        continue
    t=nal_type(header)
    if t==7: have_sps=True
    if t==8: have_pps=True
if not (have_sps and have_pps):
    print("No se extrajeron ambos SPS y PPS. Abortando.")
    sys.exit(1)
open(outfile,"wb").write(out)
print(f"SPS+PPS guardados en {outfile} ({len(out)} bytes)")
EOF

# 4️⃣ Procesar videos 1–20
for i in {2..2}; do
    INPUT="${WORKDIR}/${i}.mp4"
    H264="${WORKDIR}/${i}_converted.h264"
    PREPENDED="${WORKDIR}/${i}_prepended.h264"
    RECOVERED="${WORKDIR}/${i}_recovered.mp4"
    FINAL="${WORKDIR}/${i}_final.mp4"

    echo "🔹 Procesando $INPUT ..."

    if [[ ! -f "$INPUT" ]]; then
        echo "❌ $INPUT no existe, saltando..."
        continue
    fi

    # 4a️⃣ Convertir length-prefixed NALs a Annex-B
    python3 - <<EOF
import struct
INFILE="$INPUT"
OUTFILE="$H264"
data=open(INFILE,"rb").read()
out=bytearray()
i=0
found=0
Lmax=5_000_000
N=len(data)
while i+4<N:
    L=struct.unpack(">I",data[i:i+4])[0]
    if 0<L<Lmax and i+4+L<=N:
        nal0=data[i+4]
        nal_type=nal0&0x1F
        if nal_type in (1,5,7,8):
            out+=b"\x00\x00\x00\x01"
            out+=data[i+4:i+4+L]
            found+=1
            i+=4+L
            continue
    i+=1
if found==0:
    print("No se detectaron NALs length-prefixed plausibles en $INPUT")
    sys.exit(1)
open(OUTFILE,"wb").write(out)
print(f"$OUTFILE creado; NALs detectados: {found}; tamaño {len(out)} bytes")
EOF

    # 4b️⃣ Prepend SPS+PPS
    cat "$SPSPPS" "$H264" > "$PREPENDED"

    # 4c️⃣ Remuxar a MP4 usando framerate detectado
    ffmpeg -y -r "$FR_DEC" -f h264 -i "$PREPENDED" -c:v copy "$RECOVERED"

    # 4d️⃣ Re-encode para corregir errores y generar timestamps consistentes
    ffmpeg -y -err_detect ignore_err -fflags +genpts -probesize 100M -analyzeduration 100M \
        -i "$RECOVERED" \
        -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
        -movflags +faststart \
        "$FINAL"

    echo "✅ $i.mp4 procesado: $FINAL"
done

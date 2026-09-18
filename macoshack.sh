#!/bin/bash
set -e

echo "=================================================================="
echo "      🚀 MENYIAPKAN CONTAINER TUWILIYT/MACOSHACK DI COLAB"
echo "=================================================================="

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends curl wget net-tools psmisc python3-pip

# 1. Install Cloudflared jika belum ada
if ! command -v cloudflared &>/dev/null; then
    echo "Menginstal Cloudflared Tunnel..."
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cf.deb
    dpkg -i /tmp/cf.deb && rm -f /tmp/cf.deb
fi

# 2. Siapkan Mount Volume (Google Drive & Workspace)
VOLUME_FLAGS=""
if [ -d "/content/drive/MyDrive" ]; then
    echo "Folder Google Drive terdeteksi, menghubungkan ke /config/GoogleDrive..."
    VOLUME_FLAGS="-v /content/drive/MyDrive:/config/GoogleDrive -v /content:/content"
elif [ -d "/content" ]; then
    VOLUME_FLAGS="-v /content:/content"
fi

# 3. Jalankan Container (Docker / udocker fallback untuk Colab)
pkill -f "cloudflared.*3000" 2>/dev/null || true

if command -v docker &>/dev/null && docker info &>/dev/null; then
    echo "Menggunakan Docker Engine..."
    docker rm -f macoshack 2>/dev/null || true
    docker run -d --name macoshack --net=host $VOLUME_FLAGS tuwiliyt/macoshack:latest
else
    echo "Menyiapkan udocker (engine container user-space untuk Google Colab)..."
    pip install -q udocker
    udocker --allow-root install &>/dev/null || true
    
    echo "Mengunduh image tuwiliyt/macoshack:latest (bisa butuh 1-2 menit)..."
    udocker --allow-root pull tuwiliyt/macoshack:latest
    
    echo "Menjalankan container tuwiliyt/macoshack..."
    udocker --allow-root rm -f macoshack 2>/dev/null || true
    udocker --allow-root create --name=macoshack tuwiliyt/macoshack:latest
    
    mkdir -p /var/log/remote-desktop
    nohup udocker --allow-root run $VOLUME_FLAGS macoshack > /var/log/remote-desktop/macoshack.log 2>&1 &
fi

# 4. Tunggu port 3000 aktif
echo "Menunggu web interface aktif pada port 3000..."
for i in {1..50}; do
    if netstat -tlpn 2>/dev/null | grep -E ':3000\b' > /dev/null; then
        echo "Layanan aktif di port 3000!"
        break
    fi
    sleep 2
done

# 5. Hubungkan dengan Cloudflare Tunnel
echo "Membuka tunnel publik Cloudflare..."
mkdir -p /var/log/remote-desktop
nohup cloudflared tunnel --url http://127.0.0.1:3000 > /var/log/remote-desktop/cloudflared-macos.log 2>&1 &

URL=""
for i in {1..35}; do
    URL=$(grep -o 'https://[-a-zA-Z0-9@:%._\+~#=]*\.trycloudflare\.com' /var/log/remote-desktop/cloudflared-macos.log 2>/dev/null | tail -n 1 || true)
    [ -n "$URL" ] && break
    sleep 1
done

echo ""
echo "=================================================================="
echo "          🎉 MACOSHACK DESKTOP BERHASIL AKTIF! 🎉"
echo "=================================================================="
if [ -n "$URL" ]; then
    echo " Link Akses Browser : $URL"
else
    echo " Catatan: Tunnel sedang dibuat, cek link via:"
    echo " cat /var/log/remote-desktop/cloudflared-macos.log"
fi
echo " Image              : tuwiliyt/macoshack:latest"
echo " Port Internal      : 3000 (HTTP Web GUI)"
if [ -d "/content/drive/MyDrive" ]; then
    echo " Google Drive       : Terhubung (/config/GoogleDrive)"
fi
echo "=================================================================="

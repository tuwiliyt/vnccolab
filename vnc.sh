#!/bin/bash
set -e

USER_NAME="$(whoami)"
HOME_DIR="$HOME"
VNC_PASS="${1:-vncpass123}"

echo "=== [1/5] Memeriksa & Menginstal Paket Desktop & VNC ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    tigervnc-standalone-server \
    tigervnc-tools \
    novnc \
    websockify \
    dbus-x11 \
    x11-xserver-utils \
    curl \
    wget \
    net-tools \
    psmisc

echo "=== [2/5] Memeriksa & Menginstal Cloudflared & Google Chrome ==="
if ! command -v cloudflared &>/dev/null; then
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cloudflared.deb
    dpkg -i /tmp/cloudflared.deb
    rm -f /tmp/cloudflared.deb
fi

if ! command -v google-chrome &>/dev/null; then
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
    apt-get install -y /tmp/chrome.deb
    rm -f /tmp/chrome.deb
fi

# Izinkan Chrome berjalan sebagai root (--no-sandbox)
if [ -f /usr/share/applications/google-chrome.desktop ]; then
    sed -i 's|/usr/bin/google-chrome-stable|/usr/bin/google-chrome-stable --no-sandbox|g' /usr/share/applications/google-chrome.desktop
fi

echo "=== [3/5] Mengonfigurasi VNC & Tampilan Desktop ==="
mkdir -p "$HOME_DIR/.vnc"
echo "$VNC_PASS" | vncpasswd -f > "$HOME_DIR/.vnc/passwd"
chmod 600 "$HOME_DIR/.vnc/passwd"

cat << 'XSTARTUP' > "$HOME_DIR/.vnc/xstartup"
#!/bin/bash
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=XFCE
exec dbus-launch --exit-with-session startxfce4
XSTARTUP
chmod +x "$HOME_DIR/.vnc/xstartup"

# Shortcut Desktop
mkdir -p "$HOME_DIR/Desktop"
cp /usr/share/applications/google-chrome.desktop "$HOME_DIR/Desktop/" 2>/dev/null || true
cp /usr/share/applications/xfce4-terminal.desktop "$HOME_DIR/Desktop/" 2>/dev/null || true
chmod +x "$HOME_DIR/Desktop/"*.desktop 2>/dev/null || true

# Shortcut Google Drive & Workspace jika ada di Colab
if [ -d "/content/drive/MyDrive" ]; then
    ln -sf "/content/drive/MyDrive" "$HOME_DIR/Desktop/Google Drive"
elif [ -d "/content/drive" ]; then
    ln -sf "/content/drive" "$HOME_DIR/Desktop/Google Drive"
fi

if [ -d "/content" ]; then
    ln -sf "/content" "$HOME_DIR/Desktop/Colab Workspace"
fi

# noVNC index
ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

echo "=== [4/5] Memulai Layanan Desktop ==="
pkill -f "cloudflared.*tunnel" 2>/dev/null || true
pkill -f "websockify.*6080" 2>/dev/null || true
vncserver -kill :1 2>/dev/null || true
sleep 1

vncserver :1 -geometry 1280x720 -depth 24
websockify --web=/usr/share/novnc 6080 localhost:5901 -D

mkdir -p /var/log/remote-desktop
nohup cloudflared tunnel --url http://127.0.0.1:6080 > /var/log/remote-desktop/cloudflared.log 2>&1 &

echo "=== [5/5] Menghubungkan ke Cloudflare ==="
URL=""
for i in {1..35}; do
    URL=$(grep -o 'https://[-a-zA-Z0-9@:%._\+~#=]*\.trycloudflare\.com' /var/log/remote-desktop/cloudflared.log 2>/dev/null | tail -n 1 || true)
    [ -n "$URL" ] && break
    sleep 1
done

echo ""
echo "=================================================================="
echo "          🎉 REMOTE DESKTOP BERHASIL DIAKTIFKAN! 🎉"
echo "=================================================================="
[ -n "$URL" ] && echo " Link Akses Browser : $URL/vnc.html?autoconnect=true&resize=scale"
echo " Password VNC       : $VNC_PASS"
echo " User               : $USER_NAME"
if command -v nvidia-smi &>/dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "Terdeteksi")
    echo " Akselerasi GPU     : Aktif ($GPU_NAME)"
else
    echo " Akselerasi GPU     : Mode CPU (Standar)"
fi
if [ -d "/content/drive/MyDrive" ]; then
    echo " Google Drive       : Terhubung (/content/drive/MyDrive)"
fi
echo "=================================================================="

#!/bin/bash
set -e

USER_NAME="$(whoami)"
HOME_DIR="$HOME"
VNC_PASS="${1:-vncpass123}"

echo "=================================================================="
echo "          🍎 MEMULAI SETUP MACOS HACK (COLAB EDITION) 🍎"
echo "=================================================================="

# 1. Update & Pasang Paket Esensial
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
    psmisc \
    plank \
    git

# 2. Pasang Cloudflared Tunnel
if ! command -v cloudflared &>/dev/null; then
    echo "Menginstal Cloudflared..."
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cf.deb
    dpkg -i /tmp/cf.deb && rm -f /tmp/cf.deb
fi

# 3. Pasang Google Chrome
if ! command -v google-chrome &>/dev/null; then
    echo "Menginstal Google Chrome..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
    apt-get install -y /tmp/chrome.deb
    rm -f /tmp/chrome.deb
fi

if [ -f /usr/share/applications/google-chrome.desktop ]; then
    sed -i 's|/usr/bin/google-chrome-stable|/usr/bin/google-chrome-stable --no-sandbox|g' /usr/share/applications/google-chrome.desktop
fi

# 4. Pasang Tema macOS WhiteSur & Icon
echo "Mengonfigurasi tema macOS (WhiteSur & Plank Dock)..."
if [ ! -d "/usr/share/themes/WhiteSur-Dark" ]; then
    rm -rf /tmp/whitesur-theme
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/whitesur-theme
    /tmp/whitesur-theme/install.sh -d /usr/share/themes -t all -s all -c Dark > /dev/null 2>&1 || true
    rm -rf /tmp/whitesur-theme
fi

# 5. Konfigurasi VNC Password & xstartup
mkdir -p "$HOME_DIR/.vnc"
echo "$VNC_PASS" | vncpasswd -f > "$HOME_DIR/.vnc/passwd"
chmod 600 "$HOME_DIR/.vnc/passwd"

cat << 'XSTARTUP' > "$HOME_DIR/.vnc/xstartup"
#!/bin/bash
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=XFCE

# Terapkan tema macOS & tombol jendela di kiri atas
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark" --create -t string 2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark" --create -t string 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark" --create -t string 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/button_layout -s "CHM|" --create -t string 2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "WhiteSur-cursors" --create -t string 2>/dev/null || true

# Jalankan macOS Plank Dock
plank &

exec dbus-launch --exit-with-session startxfce4
XSTARTUP
chmod +x "$HOME_DIR/.vnc/xstartup"

# Shortcut Desktop
mkdir -p "$HOME_DIR/Desktop"
cp /usr/share/applications/google-chrome.desktop "$HOME_DIR/Desktop/" 2>/dev/null || true
cp /usr/share/applications/xfce4-terminal.desktop "$HOME_DIR/Desktop/" 2>/dev/null || true
chmod +x "$HOME_DIR/Desktop/"*.desktop 2>/dev/null || true

# Hubungkan Google Drive jika tersedia di Colab
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

# 6. Jalankan Service Desktop & Cloudflare Tunnel
echo "Menyalakan TigerVNC & noVNC..."
pkill -f "cloudflared.*tunnel" 2>/dev/null || true
pkill -f "websockify.*6080" 2>/dev/null || true
vncserver -kill :1 2>/dev/null || true
sleep 1

vncserver :1 -geometry 1280x720 -depth 24
websockify --web=/usr/share/novnc 6080 localhost:5901 -D

mkdir -p /var/log/remote-desktop
nohup cloudflared tunnel --url http://127.0.0.1:6080 > /var/log/remote-desktop/cloudflared-macos.log 2>&1 &

# 7. Dapatkan Link Akses
echo "Menghubungkan ke Cloudflare Edge..."
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
[ -n "$URL" ] && echo " Link Akses Browser : $URL/vnc.html?autoconnect=true&resize=scale"
echo " Password VNC       : $VNC_PASS"
echo " User               : $USER_NAME"
if command -v nvidia-smi &>/dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "Terdeteksi")
    echo " Akselerasi GPU     : Aktif ($GPU_NAME)"
else
    echo " Akselerasi GPU     : Mode CPU"
fi
if [ -d "/content/drive/MyDrive" ]; then
    echo " Google Drive       : Terhubung (/content/drive/MyDrive)"
fi
echo "=================================================================="

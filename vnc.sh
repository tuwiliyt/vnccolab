#!/bin/bash
set -e

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

echo "=== [3/5] Mengonfigurasi Pengguna & Desktop XFCE ==="
if ! id -u ubuntu &>/dev/null; then
    useradd -m -s /bin/bash -G sudo ubuntu
fi
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
chmod 0440 /etc/sudoers.d/ubuntu

# noVNC default index
ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# VNC Password
VNC_PASS="${1:-vncpass123}"
mkdir -p /home/ubuntu/.vnc
echo "$VNC_PASS" | vncpasswd -f > /home/ubuntu/.vnc/passwd
chmod 600 /home/ubuntu/.vnc/passwd

# Xstartup
cat << 'EOF' > /home/ubuntu/.vnc/xstartup
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x /home/ubuntu/.vnc/xstartup

# Desktop shortcuts
mkdir -p /home/ubuntu/Desktop
cp /usr/share/applications/google-chrome.desktop /home/ubuntu/Desktop/ 2>/dev/null || true
cp /usr/share/applications/xfce4-terminal.desktop /home/ubuntu/Desktop/ 2>/dev/null || true
chmod +x /home/ubuntu/Desktop/*.desktop 2>/dev/null || true
chown -R ubuntu:ubuntu /home/ubuntu

echo "=== [4/5] Memulai Layanan VNC, WebSockify, & Cloudflare Tunnel ==="
# Bersihkan proses lama jika ada
pkill -f "cloudflared.*tunnel" 2>/dev/null || true
pkill -f "websockify.*6080" 2>/dev/null || true
su - ubuntu -c "vncserver -kill :1 2>/dev/null || true"
sleep 1

# Jalankan VNC
su - ubuntu -c "vncserver :1 -geometry 1280x720 -depth 24"

# Jalankan WebSockify (noVNC bridge)
websockify --web=/usr/share/novnc 6080 localhost:5901 -D

# Jalankan Cloudflare Tunnel
mkdir -p /var/log/remote-desktop
nohup cloudflared tunnel --url http://127.0.0.1:6080 > /var/log/remote-desktop/cloudflared.log 2>&1 &

echo "=== [5/5] Mendapatkan Tautan Remote Desktop ==="
echo "Menghubungkan ke Cloudflare Edge Network..."
URL=""
for i in {1..35}; do
    URL=$(grep -o 'https://[-a-zA-Z0-9@:%._\+~#=]*\.trycloudflare\.com' /var/log/remote-desktop/cloudflared.log 2>/dev/null | tail -n 1 || true)
    if [ -n "$URL" ]; then
        break
    fi
    sleep 1
done

echo ""
echo "=================================================================="
echo "          🎉 REMOTE DESKTOP BERHASIL DIAKTIFKAN! 🎉"
echo "=================================================================="
if [ -n "$URL" ]; then
    echo " Link Akses Browser : $URL/vnc.html?autoconnect=true&resize=scale"
else
    echo " Catatan: Tunnel sedang dibuat, cek link via: cat /var/log/remote-desktop/cloudflared.log"
fi
echo " Password VNC       : $VNC_PASS"
echo " User OS            : ubuntu"
echo "=================================================================="

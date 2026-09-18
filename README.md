# 🖥️ Google Colab Remote Desktop (VNC)

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/tuwiliyt/vnccolab/blob/main/VNC_Colab.ipynb)

One-shot script untuk menjalankan Remote Desktop (XFCE4 + noVNC + Cloudflare Tunnel) di Google Colab atau Linux Server.

---

## ⚡ Cara Jalankan di Google Colab:
Klik tombol badge **Open In Colab** di atas atau buka notebook [`VNC_Colab.ipynb`](https://github.com/tuwiliyt/vnccolab/blob/main/VNC_Colab.ipynb) dan jalankan cell code berikut:

```python
#@title 🚀 Jalankan Remote Desktop
Password = "vncpass123" #@param {type:"string"}

!curl -sL https://raw.githubusercontent.com/tuwiliyt/vnccolab/main/vnc.sh | bash -s -- "$Password"
```

---

## 💻 Jalankan via Terminal / SSH:
```bash
curl -sL https://raw.githubusercontent.com/tuwiliyt/vnccolab/main/vnc.sh | bash
```

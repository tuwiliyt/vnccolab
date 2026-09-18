# 🖥️ Remote Desktop & macOS Hack di Google Colab

Koleksi script one-shot dan notebook Google Colab untuk menjalankan desktop GUI dan container Docker dengan tunneling instan tanpa ribet.

---

## 📌 Pilihan Layanan:

### 1. 🍎 macOS Hack (`tuwiliyt/macoshack`)
Jalankan image Docker [`tuwiliyt/macoshack`](https://hub.docker.com/r/tuwiliyt/macoshack) langsung di Google Colab dengan akses GUI web browser dan integrasi Google Drive.

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/tuwiliyt/vnccolab/blob/main/MacOS_Hack_Colab.ipynb)

* **Jalankan via Cell Colab:**
  ```python
  from google.colab import drive
  drive.mount('/content/drive')
  !curl -sL https://raw.githubusercontent.com/tuwiliyt/vnccolab/main/macoshack.sh | bash
  ```
* **Jalankan via Terminal:**
  ```bash
  curl -sL https://raw.githubusercontent.com/tuwiliyt/vnccolab/main/macoshack.sh | bash
  ```

---

### 2. ⚡ Linux Desktop XFCE4 (T4 GPU + Google Drive)
Desktop Linux ringan responsif berbasis XFCE4 + noVNC + Cloudflare Tunnel dengan integrasi GPU T4 dan shortcut Google Drive di Desktop.

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/tuwiliyt/vnccolab/blob/main/VNC_Colab.ipynb)

* **Jalankan via Cell Colab:**
  ```python
  #@title 🚀 Jalankan Remote Desktop
  Password = "vncpass123" #@param {type:"string"}
  !curl -sL https://raw.githubusercontent.com/tuwiliyt/vnccolab/main/vnc.sh | bash -s -- "$Password"
  ```
* **Jalankan via Terminal:**
  ```bash
  curl -sL https://raw.githubusercontent.com/tuwiliyt/vnccolab/main/vnc.sh | bash
  ```

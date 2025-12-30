## 🔧 Installation and Configuration

<p align="center">
  <img src="https://github.com/user-attachments/assets/c5eb4cc1-0c3d-497d-9422-1614651a84ab" alt="thumbnail_IMG_0546" width="98">
</p>

## 📚 Table of Contents

- [Prerequisites](#-prerequisites)
- [Quick Install](#-quick-install)
- [Manual Install](#-manual-install)
- [Configuration](#-configuration)
- [Testing](#-testing)
- [License](#-license)

---

## 📌 Prerequisites

### Hardware Requirements

| Component | Requirement |
|-----------|-------------|
| **Board** | Orange Pi Zero 2W |
| **RAM** | 1GB minimum, 4GB recommended |
| **Storage** | 16GB+ microSD (Class 10) |
| **Display** | 2.13-inch e-Paper HAT (V2/V3/V4) or 2.7-inch |

### Software Requirements

| Component | Requirement |
|-----------|-------------|
| **OS** | Debian 12 (bookworm) or Armbian |
| **Kernel** | Linux 6.1.31-sun50iw9 or compatible |
| **Python** | Python 3.10+ |

**Download OS Images:**
- [Official Orange Pi Debian](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-Zero-2W.html)
- [Armbian for Orange Pi Zero 2W](https://www.armbian.com/orange-pi-zero-2w/) (Recommended)

---

## ⚡ Quick Install

The fastest way to install Bjorn:

```bash
# Download and run the installer
wget https://raw.githubusercontent.com/VibeDevOpsing/Bjorn-Fork-OPI-Zero2w/refs/heads/main/install_bjorn.sh
sudo chmod +x install_bjorn.sh
sudo ./install_bjorn.sh

# Follow the prompts:
# 1. Choose option 1 for automatic installation
# 2. Select your e-Paper display version (V2, V3, V4, or 2.7")
# 3. Wait for installation to complete
# 4. Reboot when prompted
```

---

## 🧰 Manual Install

### Step 1: Enable SPI & I2C

#### Option A: Using orangepi-config
```bash
sudo orangepi-config
# Navigate to: System > Hardware
# Enable: spi-spidev, i2c1
# Reboot
```

#### Option B: Manual Configuration
```bash
# Edit boot environment
sudo nano /boot/orangepiEnv.txt

# Add or modify:
overlays=spi-spidev i2c1
param_spidev_spi_bus=1

# Save and reboot
sudo reboot
```

### Step 2: System Dependencies

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install required packages
sudo apt install -y \
    python3-pip python3-dev python3-venv \
    build-essential gcc make cmake \
    libjpeg-dev zlib1g-dev libpng-dev libopenjp2-7 \
    libgpiod-dev libgpiod2 gpiod python3-libgpiod \
    libi2c-dev i2c-tools spi-tools \
    nmap libssl-dev libffi-dev \
    libopenblas-dev libatlas-base-dev \
    bluez bluez-tools bridge-utils \
    network-manager wget curl lsof git

# Update Nmap scripts database
sudo nmap --script-updatedb
```

### Step 3: Bjorn Installation

```bash
# Clone the Bjorn repository
cd /home/bjorn
git clone https://github.com/VibeDevOpsing/Bjorn-Fork-OPI-Zero2w.git
cd Bjorn

# Install Python dependencies
sudo pip3 install -r requirements.txt --break-system-packages
```

### Step 4: Configure E-Paper Display Type

Choose your e-Paper HAT version:

```bash
sudo nano /home/bjorn/Bjorn/config/shared_config.json
```

Set the `epd_type` value:
- For 2.13 V1: `"epd_type": "epd2in13"`
- For 2.13 V2: `"epd_type": "epd2in13_V2"`
- For 2.13 V3: `"epd_type": "epd2in13_V3"`
- For 2.13 V4: `"epd_type": "epd2in13_V4"`
- For 2.7 inch: `"epd_type": "epd2in7"`

### Step 5: Configure File Descriptor Limits

```bash
# Add to /etc/security/limits.conf
sudo tee -a /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

# Configure systemd limits
echo "DefaultLimitNOFILE=65535" | sudo tee -a /etc/systemd/system.conf
echo "DefaultLimitNOFILE=65535" | sudo tee -a /etc/systemd/user.conf

# Configure sysctl
echo "fs.file-max = 2097152" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Step 6: Reload Systemd

```bash
sudo systemctl daemon-reload
```

### Step 7: Configure PAM

```bash
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session-noninteractive
```

### Step 8: Configure Bjorn Service

Create the service file:

```bash
sudo nano /etc/systemd/system/bjorn.service
```

Add:

```ini
[Unit]
Description=Bjorn Service
DefaultDependencies=no
Before=basic.target
After=local-fs.target network.target

[Service]
ExecStartPre=/home/bjorn/Bjorn/kill_port_8000.sh
ExecStart=/usr/bin/python3 /home/bjorn/Bjorn/Bjorn.py
WorkingDirectory=/home/bjorn/Bjorn
StandardOutput=inherit
StandardError=inherit
Restart=always
RestartSec=10
User=root
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Enable the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable bjorn.service
```

### Step 9: USB Gadget Configuration (Optional)

For USB networking:

```bash
sudo tee -a /etc/network/interfaces << EOF
allow-hotplug usb0
iface usb0 inet static
    address 172.20.2.1
    netmask 255.255.255.0
EOF
```

### Step 10: Reboot

```bash
sudo reboot
```

---

## ⚙️ Configuration

### shared_config.json

Key configuration options in `/home/bjorn/Bjorn/config/shared_config.json`:

```json
{
    "epd_type": "epd2in13_V4",
    "manual_mode": false,
    "websrv": true,
    "scan_interval": 120,
    "nmap_scan_aggressivity": "-T3",
    "startup_delay": 10
}
```

### Recommended Settings for 4GB RAM

```json
{
    "nmap_scan_aggressivity": "-T3",
    "scan_interval": 120,
    "scan_vuln_interval": 600,
    "failed_retry_delay": 300
}
```

---

## 🧪 Testing

Run the test suite to verify your installation:

```bash
cd /home/bjorn/Bjorn

# Install test dependencies
pip3 install pytest pytest-timeout --break-system-packages

# Run all tests
python3 -m pytest tests/test_orangepi_migration.py -v
```

### Quick Hardware Test

```bash
# Test SPI device
ls -la /dev/spidev*

# Test I2C
sudo i2cdetect -y 0

# Test GPIO
ls -la /dev/gpiochip*

# Test e-Paper module
python3 -c "from resources.waveshare_epd import epdconfig; print('OK')"
```

---

## 🔗 PC Configuration (USB Gadget)

If using USB gadget mode, configure your PC:

| Setting | Value |
|---------|-------|
| IP Address | 172.20.2.2 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 172.20.2.1 |
| DNS Servers | 8.8.8.8, 8.8.4.4 |

---

## 📜 License

2024 - Bjorn is distributed under the MIT License. For more details, please refer to the [LICENSE](LICENSE) file included in this repository.

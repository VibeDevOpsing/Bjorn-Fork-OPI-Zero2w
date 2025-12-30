# 🍊 Bjorn - Orange Pi Zero 2W Migration Guide

<p align="center">
  <img src="https://github.com/user-attachments/assets/c5eb4cc1-0c3d-497d-9422-1614651a84ab" alt="Bjorn Logo" width="150">
</p>

This guide provides comprehensive instructions for migrating Bjorn from Raspberry Pi Zero W/W2 to **Orange Pi Zero 2W**.

## 📋 Table of Contents

- [Overview](#-overview)
- [Hardware Comparison](#-hardware-comparison)
- [Prerequisites](#-prerequisites)
- [Quick Installation](#-quick-installation)
- [Manual Installation](#-manual-installation)
- [GPIO Pin Mapping](#-gpio-pin-mapping)
- [Configuration Changes](#-configuration-changes)
- [Testing](#-testing)
- [Troubleshooting](#-troubleshooting)
- [Performance Optimizations](#-performance-optimizations)

---

## 📄 Overview

### Target Hardware
- **Board**: Orange Pi Zero 2W
- **SoC**: Allwinner H618 (Quad-core Cortex-A53)
- **RAM**: 4GB DDR4
- **Architecture**: ARM64 (aarch64)

### Target Operating System
- **OS**: Debian GNU/Linux 12 (bookworm)
- **Kernel**: Linux 6.1.31-sun50iw9

### Key Differences from Raspberry Pi

| Feature | Raspberry Pi Zero W | Orange Pi Zero 2W |
|---------|--------------------|--------------------|
| CPU | BCM2835 (1GHz ARM11) | H618 (1.5GHz Cortex-A53) |
| Architecture | armhf (32-bit) | aarch64 (64-bit) |
| RAM | 512MB | 1GB/1.5GB/2GB/4GB |
| GPIO Library | RPi.GPIO | OPi.GPIO / gpiod |
| SPI Bus | spidev0.0 | spidev1.0 |
| Boot Config | /boot/firmware/config.txt | /boot/orangepiEnv.txt |

---

## 💻 Hardware Comparison

### Performance Improvements

With the Orange Pi Zero 2W 4GB variant, you gain:

- **8x RAM**: 4GB vs 512MB allows for:
  - More concurrent scanning threads
  - Larger network knowledge base caching
  - Faster data processing
  
- **~4x CPU Performance**: Quad-core Cortex-A53 vs single-core ARM11
  - Faster vulnerability scanning
  - Better web interface responsiveness
  - Parallel action execution

### Recommended Configuration Updates

```json
{
  "nmap_scan_aggressivity": "-T3",  // Can increase from -T2
  "scan_interval": 120,              // Reduce from 180
  "comment_delaymin": 10,            // Reduce from 15
  "scan_vuln_interval": 600          // Reduce from 900
}
```

---

## 📌 Prerequisites

### Hardware Requirements
- Orange Pi Zero 2W (any RAM variant, 4GB recommended)
- 2.13-inch e-Paper HAT (Waveshare V2/V3/V4 or compatible)
- MicroSD card (16GB minimum, Class 10)
- Power supply (5V/3A USB-C)

### Software Requirements
- Debian 12 (bookworm) or Armbian for Orange Pi Zero 2W
- Python 3.10 or later
- Root access (sudo)

### Download OS Image
- **Official Debian**: [Orange Pi Downloads](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-Zero-2W.html)
- **Armbian** (recommended): [Armbian for Orange Pi Zero 2W](https://www.armbian.com/orange-pi-zero-2w/)

---

## ⚡ Quick Installation

The fastest way to install Bjorn on Orange Pi Zero 2W:

```bash
# Download the Orange Pi installation script
wget https://raw.githubusercontent.com/infinition/Bjorn/orangepizero2w-optimization/install_bjorn_orangepi.sh

# Make it executable and run
sudo chmod +x install_bjorn_orangepi.sh
sudo ./install_bjorn_orangepi.sh

# Follow the prompts:
# 1. Select "Full installation"
# 2. Choose your e-Paper display version
# 3. Wait for installation to complete
# 4. Reboot when prompted
```

---

## 🧰 Manual Installation

### Step 1: System Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Set hostname (optional but recommended)
sudo hostnamectl set-hostname bjorn
```

### Step 2: Enable SPI and I2C

#### Option A: Using orangepi-config (if available)
```bash
sudo orangepi-config
# Navigate to: System > Hardware
# Enable: spi-spidev, i2c1
```

#### Option B: Manual Configuration
```bash
# Edit boot environment
sudo nano /boot/orangepiEnv.txt

# Add or modify the overlays line:
overlays=spi-spidev i2c1
param_spidev_spi_bus=1

# Save and exit (Ctrl+X, Y, Enter)

# Load modules
echo "spidev" | sudo tee -a /etc/modules
echo "i2c-dev" | sudo tee -a /etc/modules

# Reboot for changes to take effect
sudo reboot
```

### Step 3: Install System Dependencies

```bash
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
```

### Step 4: Clone and Setup Bjorn

```bash
# Create bjorn user if needed
sudo adduser --disabled-password --gecos "" bjorn

# Clone repository
cd /home/bjorn
sudo -u bjorn git clone https://github.com/infinition/Bjorn.git
cd Bjorn

# Switch to Orange Pi branch
git checkout orangepizero2w-optimization

# Install Orange Pi e-Paper configuration
sudo cp resources/waveshare_epd/epdconfig_orangepi.py resources/waveshare_epd/epdconfig.py

# Install Python dependencies
sudo pip3 install -r requirements_orangepi.txt --break-system-packages

# Set permissions
sudo chown -R bjorn:bjorn /home/bjorn/Bjorn
sudo chmod -R 755 /home/bjorn/Bjorn
```

### Step 5: Configure e-Paper Display

Edit the configuration file:
```bash
sudo nano /home/bjorn/Bjorn/config/shared_config.json
```

Set your e-Paper display version:
```json
{
    "epd_type": "epd2in13_V4"  // Change to your version
}
```

Available options:
- `epd2in13` - Version 1
- `epd2in13_V2` - Version 2
- `epd2in13_V3` - Version 3
- `epd2in13_V4` - Version 4
- `epd2in7` - 2.7 inch display

### Step 6: Configure System Limits

```bash
# Add file descriptor limits
sudo tee -a /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

# Configure systemd limits
echo "DefaultLimitNOFILE=65535" | sudo tee -a /etc/systemd/system.conf
echo "DefaultLimitNOFILE=65535" | sudo tee -a /etc/systemd/user.conf

# Apply sysctl optimizations
sudo tee -a /etc/sysctl.conf << EOF
fs.file-max = 2097152
vm.swappiness = 10
net.core.somaxconn = 1024
EOF

sudo sysctl -p
```

### Step 7: Create Systemd Service

```bash
sudo tee /etc/systemd/system/bjorn.service << EOF
[Unit]
Description=Bjorn Service (Orange Pi Zero 2W)
After=local-fs.target network.target

[Service]
ExecStartPre=/home/bjorn/Bjorn/kill_port_8000.sh
ExecStart=/usr/bin/python3 /home/bjorn/Bjorn/Bjorn.py
WorkingDirectory=/home/bjorn/Bjorn
Restart=always
RestartSec=10
User=root
Environment=PYTHONUNBUFFERED=1
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Enable service
sudo systemctl daemon-reload
sudo systemctl enable bjorn.service
```

### Step 8: Reboot and Test

```bash
sudo reboot

# After reboot, check service status
sudo systemctl status bjorn.service

# View logs
sudo journalctl -u bjorn.service -f
```

---

## 🔌 GPIO Pin Mapping

### e-Paper HAT Connection (Orange Pi Zero 2W)

| e-Paper Pin | Function | Physical Pin | GPIO |
|-------------|----------|--------------|------|
| VCC | Power 3.3V | Pin 1 | - |
| GND | Ground | Pin 6 | - |
| DIN | SPI MOSI | Pin 19 | SPI1_MOSI |
| CLK | SPI SCLK | Pin 23 | SPI1_SCLK |
| CS | Chip Select | Pin 24 | SPI1_CS |
| DC | Data/Command | Pin 22 | PC14 |
| RST | Reset | Pin 11 | PC7 |
| BUSY | Busy Status | Pin 18 | PC6 |

### Orange Pi Zero 2W 26-Pin Header

```
                    +-----+
      3.3V     1    |o   o|    2    5V
   I2C0_SDA    3    |o   o|    4    5V
   I2C0_SCL    5    |o   o|    6    GND
      PC12     7    |o   o|    8    UART0_TX
       GND     9    |o   o|   10    UART0_RX
       PC7    11    |o   o|   12    PC9
      PC10    13    |o   o|   14    GND
      PC11    15    |o   o|   16    PC15
      3.3V    17    |o   o|   18    PC6
  SPI1_MOSI   19    |o   o|   20    GND
  SPI1_MISO   21    |o   o|   22    PC14
  SPI1_SCLK   23    |o   o|   24    SPI1_CS
       GND    25    |o   o|   26    PC8
                    +-----+
```

---

## ⚙️ Configuration Changes

### Key Differences in epdconfig.py

The Orange Pi version (`epdconfig_orangepi.py`) includes:

1. **OrangePiZero2W Class**: New hardware abstraction class
2. **OPi.GPIO Support**: Uses Orange Pi GPIO library
3. **python-periphery Fallback**: Alternative GPIO when OPi.GPIO unavailable
4. **SPI Bus 1**: Orange Pi Zero 2W uses `/dev/spidev1.0`
5. **Platform Detection**: Automatic detection via kernel version

### GPIO Library Priority

The system tries GPIO libraries in this order:
1. `OPi.GPIO` (preferred for Orange Pi)
2. `python-periphery` (universal fallback)
3. `gpiod` (Linux GPIO character device)

---

## 🧪 Testing

### Run Test Suite

```bash
cd /home/bjorn/Bjorn

# Install pytest
pip3 install pytest pytest-timeout --break-system-packages

# Run all tests
python3 -m pytest tests/test_orangepi_migration.py -v

# Run specific test class
python3 -m pytest tests/test_orangepi_migration.py::TestEPDConfig -v

# Run with hardware tests (only on actual Orange Pi)
python3 -m pytest tests/test_orangepi_migration.py -v --tb=short
```

### Manual Hardware Test

```bash
# Test SPI device
ls -la /dev/spidev*

# Test GPIO chip
ls -la /dev/gpiochip*

# Test I2C
sudo i2cdetect -y 0

# Test e-Paper (quick display test)
cd /home/bjorn/Bjorn
python3 -c "
from resources.waveshare_epd import epdconfig
print('Platform detection: OK')
print(f'Module: {type(epdconfig.implementation).__name__}')
"
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. SPI Device Not Found

```bash
# Check if SPI is enabled
ls /dev/spidev*

# If not found, verify device tree overlay
cat /boot/orangepiEnv.txt | grep overlays

# Add SPI overlay if missing
sudo sed -i 's/overlays=\(.*\)/overlays=\1 spi-spidev/' /boot/orangepiEnv.txt
sudo reboot
```

#### 2. GPIO Permission Denied

```bash
# Add user to gpio group
sudo usermod -a -G gpio bjorn

# Or run as root (service default)
sudo systemctl restart bjorn.service
```

#### 3. e-Paper Display Not Working

```bash
# Check wiring connections
# Verify correct e-Paper version in config

# Test with debug output
cd /home/bjorn/Bjorn
python3 -c "
import logging
logging.basicConfig(level=logging.DEBUG)
from resources.waveshare_epd.epdconfig_orangepi import *
print('Init result:', module_init())
"
```

#### 4. OPi.GPIO Import Error

```bash
# Install or reinstall OPi.GPIO
pip3 install --upgrade OPi.GPIO --break-system-packages

# If still failing, use periphery fallback
pip3 install python-periphery --break-system-packages
```

#### 5. Service Fails to Start

```bash
# Check service logs
sudo journalctl -u bjorn.service -n 50

# Run Bjorn manually for debugging
cd /home/bjorn/Bjorn
sudo python3 Bjorn.py
```

---

## 🚀 Performance Optimizations

### Recommended Settings for 4GB RAM

Edit `/home/bjorn/Bjorn/config/shared_config.json`:

```json
{
    "nmap_scan_aggressivity": "-T3",
    "scan_interval": 120,
    "scan_vuln_interval": 600,
    "comment_delaymin": 10,
    "comment_delaymax": 20,
    "failed_retry_delay": 300,
    "success_retry_delay": 600
}
```

### System Optimizations

```bash
# Reduce swap usage (4GB RAM is plenty)
echo "vm.swappiness = 5" | sudo tee -a /etc/sysctl.conf

# Increase network buffers
echo "net.core.rmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" | sudo tee -a /etc/sysctl.conf

sudo sysctl -p
```

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-12-30 | Initial Orange Pi Zero 2W migration |

---

## 🤝 Contributing

Found an issue with the Orange Pi migration? Please:

1. Check existing issues on GitHub
2. Create a detailed bug report with:
   - Orange Pi model and RAM
   - OS version (`cat /etc/os-release`)
   - Kernel version (`uname -a`)
   - Error logs (`journalctl -u bjorn.service`)

---

## 📜 License

2024 - Bjorn is distributed under the MIT License.

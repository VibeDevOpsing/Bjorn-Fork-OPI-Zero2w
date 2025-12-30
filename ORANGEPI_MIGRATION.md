# 🍊 Bjorn - Orange Pi Zero 2W Setup Guide

<p align="center">
  <img src="https://github.com/user-attachments/assets/c5eb4cc1-0c3d-497d-9422-1614651a84ab" alt="Bjorn Logo" width="150">
</p>

Complete setup guide for Bjorn on **Orange Pi Zero 2W**.

## 📋 Table of Contents

- [Overview](#-overview)
- [Hardware Setup](#-hardware-setup)
- [GPIO Pin Mapping](#-gpio-pin-mapping)
- [SPI Configuration](#-spi-configuration)
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

---

## 💻 Hardware Setup

### Required Components

| Component | Specification |
|-----------|--------------|
| Orange Pi Zero 2W | 1GB/1.5GB/2GB/4GB variant |
| e-Paper HAT | 2.13-inch (V2/V3/V4) or 2.7-inch |
| MicroSD Card | 16GB+ Class 10 |
| Power Supply | 5V/3A USB-C |

### Download OS Images

- **Official Debian**: [Orange Pi Downloads](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-Zero-2W.html)
- **Armbian** (recommended): [Armbian for Orange Pi Zero 2W](https://www.armbian.com/orange-pi-zero-2w/)

---

## 🔌 GPIO Pin Mapping

### e-Paper HAT Connection

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

### 26-Pin Header Diagram

```
                    +-----+
      3.3V     1    |o   o|    2    5V
   I2C0_SDA    3    |o   o|    4    5V
   I2C0_SCL    5    |o   o|    6    GND
      PC12     7    |o   o|    8    UART0_TX
       GND     9    |o   o|   10    UART0_RX
  RST  PC7    11    |o   o|   12    PC9      PWR
      PC10    13    |o   o|   14    GND
      PC11    15    |o   o|   16    PC15
      3.3V    17    |o   o|   18    PC6     BUSY
  MOSI SPI1   19    |o   o|   20    GND
  MISO SPI1   21    |o   o|   22    PC14     DC
  SCLK SPI1   23    |o   o|   24    SPI1_CS  CS
       GND    25    |o   o|   26    PC8
                    +-----+
```

---

## ⚙️ SPI Configuration

### Enable SPI via orangepi-config

```bash
sudo orangepi-config
# Navigate to: System > Hardware
# Enable: spi-spidev, i2c1
```

### Manual Configuration

Edit boot environment:
```bash
sudo nano /boot/orangepiEnv.txt
```

Add:
```
overlays=spi-spidev i2c1
param_spidev_spi_bus=1
```

Load modules on boot:
```bash
echo "spidev" | sudo tee -a /etc/modules
echo "i2c-dev" | sudo tee -a /etc/modules
```

### Verify SPI

```bash
ls -la /dev/spidev*
# Should show /dev/spidev1.0
```

---

## 🔧 Troubleshooting

### SPI Device Not Found

```bash
# Check if SPI is enabled
ls /dev/spidev*

# If not found, verify device tree overlay
cat /boot/orangepiEnv.txt | grep overlays

# Add SPI overlay if missing
sudo sed -i 's/overlays=\(.*\)/overlays=\1 spi-spidev/' /boot/orangepiEnv.txt
sudo reboot
```

### GPIO Permission Denied

```bash
# Add user to gpio group
sudo usermod -a -G gpio bjorn

# Or run as root
sudo systemctl restart bjorn.service
```

### e-Paper Display Not Working

```bash
# Check wiring connections
# Verify correct e-Paper version in config

# Test with debug output
cd /home/bjorn/Bjorn
python3 -c "
import logging
logging.basicConfig(level=logging.DEBUG)
from resources.waveshare_epd.epdconfig import *
print('Init result:', module_init())
"
```

### Service Fails to Start

```bash
# Check service logs
sudo journalctl -u bjorn.service -n 50

# Run manually for debugging
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

## 📜 License

2024 - Bjorn is distributed under the MIT License.

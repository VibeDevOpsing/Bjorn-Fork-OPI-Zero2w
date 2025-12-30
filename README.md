# <img src="https://github.com/user-attachments/assets/c5eb4cc1-0c3d-497d-9422-1614651a84ab" alt="thumbnail_IMG_0546" width="33"> Bjorn

![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=fff)
![Status](https://img.shields.io/badge/Status-Development-blue.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Orange Pi](https://img.shields.io/badge/Orange_Pi-Zero_2W-orange?logo=linux)
![Debian](https://img.shields.io/badge/Debian-12_Bookworm-red?logo=debian)

[![Reddit](https://img.shields.io/badge/Reddit-Bjorn__CyberViking-orange?style=for-the-badge&logo=reddit)](https://www.reddit.com/r/Bjorn_CyberViking)
[![Discord](https://img.shields.io/badge/Discord-Join%20Us-7289DA?style=for-the-badge&logo=discord)](https://discord.com/invite/B3ZH9taVfT)

<p align="center">
  <img src="https://github.com/user-attachments/assets/c5eb4cc1-0c3d-497d-9422-1614651a84ab" alt="thumbnail_IMG_0546" width="150">
  <img src="https://github.com/user-attachments/assets/1b490f07-f28e-4418-8d41-14f1492890c6" alt="bjorn_epd-removebg-preview" width="150">
</p>

Bjorn is a « Tamagotchi like » sophisticated, autonomous network scanning, vulnerability assessment, and offensive security tool designed to run on a **Orange Pi Zero 2W** (or Raspberry Pi) equipped with a 2.13-inch e-Paper HAT. This document provides a detailed explanation of the project.

## 🍊 Orange Pi Zero 2W Optimized

This branch is optimized for **Orange Pi Zero 2W** with the following specifications:
- **SoC**: Allwinner H618 Quad-core Cortex-A53
- **RAM**: 4GB DDR4 (also supports 1GB/1.5GB/2GB variants)
- **Architecture**: ARM64 (aarch64)
- **OS**: Debian GNU/Linux 12 (bookworm)
- **Kernel**: Linux 6.1.31-sun50iw9

### Performance Improvements over Raspberry Pi Zero W
| Feature | RPi Zero W | Orange Pi Zero 2W |
|---------|------------|-------------------|
| CPU | 1GHz single-core | 1.5GHz quad-core |
| RAM | 512MB | Up to 4GB |
| Architecture | 32-bit | 64-bit |
| Scanning Speed | Baseline | ~4x faster |

## 📚 Table of Contents

- [Introduction](#-introduction)
- [Features](#-features)
- [Getting Started](#-getting-started)
  - [Prerequisites](#-prerequisites)
  - [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage Example](#-usage-example)
- [GPIO Pin Mapping](#-gpio-pin-mapping)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

## 📄 Introduction

Bjorn is a powerful tool designed to perform comprehensive network scanning, vulnerability assessment, and data ex-filtration. Its modular design and extensive configuration options allow for flexible and targeted operations. By combining different actions and orchestrating them intelligently, Bjorn can provide valuable insights into network security and help identify and mitigate potential risks.

The e-Paper HAT display and web interface make it easy to monitor and interact with Bjorn, providing real-time updates and status information. With its extensible architecture and customizable actions, Bjorn can be adapted to suit a wide range of security testing and monitoring needs.

## 🌟 Features

- **Network Scanning**: Identifies live hosts and open ports on the network.
- **Vulnerability Assessment**: Performs vulnerability scans using Nmap and other tools.
- **System Attacks**: Conducts brute-force attacks on various services (FTP, SSH, SMB, RDP, Telnet, SQL).
- **File Stealing**: Extracts data from vulnerable services.
- **User Interface**: Real-time display on the e-Paper HAT and web interface for monitoring and interaction.

![Bjorn Display](https://github.com/infinition/Bjorn/assets/37984399/bcad830d-77d6-4f3e-833d-473eadd33921)

## 🚀 Getting Started

## 📌 Prerequisites

### 📋 Prerequisites for Orange Pi Zero 2W (64-bit) - **Recommended**

<p align="center">
  <img src="https://www.orangepi.org/img/zero2w.png" alt="Orange Pi Zero 2W" width="200">
</p>

- **Hardware**: Orange Pi Zero 2W (1GB/1.5GB/2GB/4GB RAM)
- **Operating System**: 
  - Debian GNU/Linux 12 (bookworm)
  - Armbian (recommended alternative)
- **Kernel**: Linux 6.1.31-sun50iw9 or compatible
- **Username and hostname**: Set to `bjorn` (recommended)
- **Display**: 2.13-inch e-Paper HAT connected to GPIO pins

**Why Orange Pi Zero 2W?**
- 🚀 4x faster CPU (Quad-core vs Single-core)
- 💾 Up to 8x more RAM (4GB vs 512MB)
- 🔧 Better multitasking for concurrent scans
- 💰 Similar price point

### 📋 Prerequisites for Raspberry Pi Zero W (32-bit) - Legacy Support

![image](https://github.com/user-attachments/assets/3980ec5f-a8fc-4848-ab25-4356e0529639)

- Raspberry Pi OS installed (32-bit Bookworm)
- Username and hostname set to `bjorn`
- 2.13-inch e-Paper HAT connected to GPIO pins
- **Note**: Use the `requirements_rpi_backup.txt` and `install_bjorn_rpi_backup.sh` for Raspberry Pi

### 📋 Prerequisites for Raspberry Pi Zero W2 (64-bit) - Legacy Support

![image](https://github.com/user-attachments/assets/e8d276be-4cb2-474d-a74d-b5b6704d22f5)

- Raspberry Pi OS installed (64-bit Bookworm)
- Username and hostname set to `bjorn`
- 2.13-inch e-Paper HAT connected to GPIO pins

**Supported e-Paper Displays:**
- 2.13-inch V1, V2, V3, V4
- 2.7-inch

### 🔨 Installation

The fastest way to install Bjorn on **Orange Pi Zero 2W**:

```bash
# Download and run the installer
wget https://raw.githubusercontent.com/infinition/Bjorn/refs/heads/main/install_bjorn.sh
sudo chmod +x install_bjorn.sh && sudo ./install_bjorn.sh

# Choose option 1 for automatic installation
# Select your e-Paper display version
# Reboot when prompted
```

For **Raspberry Pi** (legacy):
```bash
# Use the Raspberry Pi specific files
wget https://raw.githubusercontent.com/infinition/Bjorn/refs/heads/main/install_bjorn_rpi_backup.sh
sudo chmod +x install_bjorn_rpi_backup.sh && sudo ./install_bjorn_rpi_backup.sh
```

For **detailed information** about **installation** process go to:
- [Orange Pi Migration Guide](ORANGEPI_MIGRATION.md) - **Recommended**
- [Legacy Install Guide](INSTALL.md) - For Raspberry Pi

## 🔌 GPIO Pin Mapping (Orange Pi Zero 2W)

### e-Paper HAT Connection

| e-Paper Pin | Function | Physical Pin | Notes |
|-------------|----------|--------------|-------|
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

## ⚡ Quick Start

**Need help? Struggle to find Bjorn's IP after installation?**
Use the Bjorn Detector & SSH Launcher:

[https://github.com/infinition/bjorn-detector](https://github.com/infinition/bjorn-detector)

![ezgif-1-a310f5fe8f](https://github.com/user-attachments/assets/182f82f0-5c3a-48a9-a75e-37b9cfa2263a)

**Still need help?**
For **detailed information** about **troubleshooting** go to [Troubleshooting](TROUBLESHOOTING.md)

## 💡 Usage Example

Here's a demonstration of how Bjorn autonomously hunts through your network like a Viking raider (fake demo for illustration):

```bash
# Reconnaissance Phase
[NetworkScanner] Discovering alive hosts...
[+] Host found: 192.168.1.100
    ├── Ports: 22,80,445,3306
    └── MAC: 00:11:22:33:44:55

# Attack Sequence 
[NmapVulnScanner] Found vulnerabilities on 192.168.1.100
    ├── MySQL 5.5 < 5.7 - User Enumeration
    └── SMB - EternalBlue Candidate

[SSHBruteforce] Cracking credentials...
[+] Success! user:password123
[StealFilesSSH] Extracting sensitive data...

# Automated Data Exfiltration
[SQLBruteforce] Database accessed!
[StealDataSQL] Dumping tables...
[SMBBruteforce] Share accessible
[+] Found config files, credentials, backups...
```

This is just a demo output - actual results will vary based on your network and target configuration.

All discovered data is automatically organized in the data/output/ directory, viewable through both the e-Paper display (as indicators) and web interface.
Bjorn works tirelessly, expanding its network knowledge base and growing stronger with each discovery.

No constant monitoring needed - just deploy and let Bjorn do what it does best: hunt for vulnerabilities.

🔧 **Expand Bjorn's Arsenal!**
Bjorn is designed to be a community-driven weapon forge. Create and share your own attack modules!

⚠️ **For educational and authorized testing purposes only** ⚠️

## 🧪 Testing

Run the test suite to verify your installation:

```bash
cd /home/bjorn/Bjorn
python3 -m pytest tests/test_orangepi_migration.py -v
```

## 🤝 Contributing

The project welcomes contributions in:

- New attack modules.
- Bug fixes.
- Documentation.
- Feature improvements.
- **Hardware support for other SBCs (Orange Pi, Banana Pi, etc.)**

For **detailed information** about **contributing** process go to [Contributing Docs](CONTRIBUTING.md), [Code Of Conduct](CODE_OF_CONDUCT.md) and [Development Guide](DEVELOPMENT.md).

## 📫 Contact

- **Report Issues**: Via GitHub.
- **Guidelines**:
  - Follow ethical guidelines.
  - Document reproduction steps.
  - Provide logs and context.
  - Include hardware info (Orange Pi model, RAM, OS version)

- **Author**: __infinition__
- **GitHub**: [infinition/Bjorn](https://github.com/infinition/Bjorn)

## 🌠 Stargazers

[![Star History Chart](https://api.star-history.com/svg?repos=infinition/bjorn&type=Date)](https://star-history.com/#infinition/bjorn&Date)

---

## 📜 License

2024 - Bjorn is distributed under the MIT License. For more details, please refer to the [LICENSE](LICENSE) file included in this repository.

---

## 📁 File Structure

```
Bjorn/
├── install_bjorn.sh              # Main installer (Orange Pi Zero 2W)
├── install_bjorn_rpi_backup.sh   # Raspberry Pi installer (legacy)
├── requirements.txt              # Python dependencies (Orange Pi)
├── requirements_rpi_backup.txt   # Python dependencies (Raspberry Pi)
├── resources/
│   └── waveshare_epd/
│       ├── epdconfig.py          # e-Paper config (Orange Pi)
│       ├── epdconfig_rpi_backup.py  # e-Paper config (Raspberry Pi)
│       └── epd2in13_V*.py        # Display drivers
├── tests/
│   ├── test_orangepi_migration.py  # Migration tests
│   └── conftest.py               # Test fixtures
├── ORANGEPI_MIGRATION.md         # Detailed migration guide
├── INSTALL.md                    # Installation guide
└── README.md                     # This file
```

#!/bin/bash

# BJORN Installation Script for Orange Pi Zero 2W
# Hardware: Orange Pi Zero 2W 4GB RAM
# OS: Debian GNU/Linux 12 (bookworm)
# Kernel: Linux 6.1.31-sun50iw9 aarch64
#
# Author: Bjorn Migration
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging configuration
LOG_DIR="/var/log/bjorn_install"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/bjorn_orangepi_install_$(date +%Y%m%d_%H%M%S).log"
VERBOSE=false

# Global variables
BJORN_USER="bjorn"
BJORN_PATH="/home/${BJORN_USER}/Bjorn"
CURRENT_STEP=0
TOTAL_STEPS=10

# Orange Pi specific paths
ORANGEPI_ENV="/boot/orangepiEnv.txt"
ORANGEPI_CONFIG="/boot/armbianEnv.txt"  # Alternative for Armbian-based systems

if [[ "$1" == "--help" ]]; then
    echo "BJORN Installation Script for Orange Pi Zero 2W"
    echo ""
    echo "Usage: sudo ./install_bjorn_orangepi.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help        Show this help message"
    echo "  --verbose     Enable verbose output"
    echo "  --skip-tests  Skip post-installation tests"
    echo ""
    echo "Requirements:"
    echo "  - Orange Pi Zero 2W with 4GB RAM"
    echo "  - Debian GNU/Linux 12 (bookworm) or Armbian"
    echo "  - Root privileges (sudo)"
    echo ""
    exit 0
fi

# Parse arguments
SKIP_TESTS=false
for arg in "$@"; do
    case $arg in
        --verbose)
            VERBOSE=true
            ;;
        --skip-tests)
            SKIP_TESTS=true
            ;;
    esac
done

# Function to display progress
show_progress() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Step $CURRENT_STEP of $TOTAL_STEPS: $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Logging function
log() {
    local level=$1
    shift
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo -e "$message" >> "$LOG_FILE"
    if [ "$VERBOSE" = true ] || [ "$level" != "DEBUG" ]; then
        case $level in
            "ERROR") echo -e "${RED}$message${NC}" ;;
            "SUCCESS") echo -e "${GREEN}$message${NC}" ;;
            "WARNING") echo -e "${YELLOW}$message${NC}" ;;
            "INFO") echo -e "${BLUE}$message${NC}" ;;
            *) echo -e "$message" ;;
        esac
    fi
}

# Error handling function
handle_error() {
    local error_code=$?
    local error_message=$1
    log "ERROR" "An error occurred during: $error_message (Error code: $error_code)"
    log "ERROR" "Check the log file for details: $LOG_FILE"

    echo -e "\n${RED}Would you like to:"
    echo "1. Retry this step"
    echo "2. Skip this step (not recommended)"
    echo "3. Exit installation${NC}"
    read -r choice

    case $choice in
        1) return 1 ;; # Retry
        2) return 0 ;; # Skip
        3) clean_exit 1 ;; # Exit
        *) handle_error "$error_message" ;; # Invalid choice
    esac
}

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$1"
        return 0
    else
        handle_error "$1"
        return $?
    fi
}

# Check system compatibility for Orange Pi Zero 2W
check_system_compatibility() {
    log "INFO" "Checking Orange Pi Zero 2W system compatibility..."
    local should_ask_confirmation=false
    
    # Check architecture (must be aarch64)
    architecture=$(uname -m)
    if [ "$architecture" != "aarch64" ]; then
        log "ERROR" "Invalid architecture. Expected: aarch64, Found: ${architecture}"
        echo -e "${RED}This script is designed for ARM64 (aarch64) architecture only.${NC}"
        exit 1
    else
        log "SUCCESS" "Architecture check passed: ${architecture}"
    fi

    # Check for Orange Pi or Allwinner H618
    kernel=$(uname -r)
    if [[ "$kernel" == *"sun50iw9"* ]]; then
        log "SUCCESS" "Detected Allwinner H618 kernel (Orange Pi Zero 2W)"
    elif [ -f /proc/device-tree/model ]; then
        model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
        if [[ "$model" == *"Orange"* ]]; then
            log "SUCCESS" "Detected Orange Pi: $model"
        else
            log "WARNING" "Device model: $model (not explicitly Orange Pi)"
            should_ask_confirmation=true
        fi
    else
        log "WARNING" "Could not confirm Orange Pi hardware"
        should_ask_confirmation=true
    fi

    # Check RAM (Orange Pi Zero 2W has 1GB, 1.5GB, 2GB, or 4GB variants)
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 900 ]; then
        log "WARNING" "Low RAM detected: ${total_ram}MB. Recommended: 1GB+"
        should_ask_confirmation=true
    else
        log "SUCCESS" "RAM check passed: ${total_ram}MB available"
    fi

    # Check available disk space (need at least 2GB)
    available_space=$(df -m /home | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 2048 ]; then
        log "WARNING" "Low disk space: ${available_space}MB. Recommended: 2GB+"
        should_ask_confirmation=true
    else
        log "SUCCESS" "Disk space check passed: ${available_space}MB available"
    fi

    # Check OS version
    if [ -f "/etc/os-release" ]; then
        source /etc/os-release
        log "INFO" "Operating System: ${PRETTY_NAME}"
        
        # Check for Debian 12 (Bookworm) or Armbian
        if [[ "$ID" == "debian" ]] || [[ "$ID_LIKE" == *"debian"* ]]; then
            if [[ "$VERSION_ID" == "12" ]] || [[ "$VERSION_CODENAME" == "bookworm" ]]; then
                log "SUCCESS" "OS version check passed: Debian 12 (bookworm)"
            else
                log "WARNING" "Different Debian version: ${VERSION_ID:-unknown}"
                should_ask_confirmation=true
            fi
        else
            log "WARNING" "Non-Debian OS detected: ${ID}"
            should_ask_confirmation=true
        fi
    fi

    # Check for SPI device availability
    if [ -e /dev/spidev1.0 ] || [ -e /dev/spidev0.0 ]; then
        log "SUCCESS" "SPI device found"
    else
        log "WARNING" "SPI device not found. May need to enable in device tree."
        should_ask_confirmation=true
    fi

    # Check for I2C device availability
    if [ -e /dev/i2c-0 ] || [ -e /dev/i2c-1 ]; then
        log "SUCCESS" "I2C device found"
    else
        log "WARNING" "I2C device not found. May need to enable in device tree."
        should_ask_confirmation=true
    fi

    if [ "$should_ask_confirmation" = true ]; then
        echo -e "\n${YELLOW}Some system compatibility warnings were detected (see above).${NC}"
        echo -e "${YELLOW}The installation might require additional configuration.${NC}"
        echo -e "${YELLOW}Do you want to continue anyway? (y/n)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "INFO" "Installation aborted by user after compatibility warnings"
            clean_exit 1
        fi
    else
        log "SUCCESS" "All compatibility checks passed"
    fi

    log "INFO" "System compatibility check completed"
    return 0
}

# Configure SPI and I2C interfaces for Orange Pi
configure_interfaces() {
    log "INFO" "Configuring SPI and I2C interfaces for Orange Pi..."
    
    # Try orangepi-config if available
    if command -v orangepi-config &> /dev/null; then
        log "INFO" "Found orangepi-config, enabling SPI and I2C..."
        orangepi-config --enable spi-spidev 2>/dev/null || true
        orangepi-config --enable i2c1 2>/dev/null || true
    fi

    # Try armbian-config if available
    if command -v armbian-config &> /dev/null; then
        log "INFO" "Found armbian-config..."
    fi

    # Manual configuration via device tree overlays
    local config_file=""
    if [ -f "$ORANGEPI_ENV" ]; then
        config_file="$ORANGEPI_ENV"
    elif [ -f "$ORANGEPI_CONFIG" ]; then
        config_file="$ORANGEPI_CONFIG"
    elif [ -f "/boot/armbianEnv.txt" ]; then
        config_file="/boot/armbianEnv.txt"
    fi

    if [ -n "$config_file" ]; then
        log "INFO" "Configuring device tree overlays in: $config_file"
        
        # Backup existing config
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Add SPI overlay if not present
        if ! grep -q "spi-spidev" "$config_file"; then
            if grep -q "overlays=" "$config_file"; then
                sed -i 's/overlays=\(.*\)/overlays=\1 spi-spidev/' "$config_file"
            else
                echo "overlays=spi-spidev" >> "$config_file"
            fi
            log "INFO" "Added spi-spidev overlay"
        fi
        
        # Add I2C overlay if not present
        if ! grep -q "i2c" "$config_file"; then
            if grep -q "overlays=" "$config_file"; then
                sed -i 's/overlays=\(.*\)/overlays=\1 i2c1/' "$config_file"
            else
                echo "overlays=i2c1" >> "$config_file"
            fi
            log "INFO" "Added i2c1 overlay"
        fi
        
        # Configure SPI parameters
        if ! grep -q "param_spidev_spi_bus" "$config_file"; then
            echo "param_spidev_spi_bus=1" >> "$config_file"
            log "INFO" "Set SPI bus to 1"
        fi
    else
        log "WARNING" "Could not find boot configuration file. Manual SPI/I2C configuration may be required."
    fi

    # Load kernel modules
    modprobe spidev 2>/dev/null || true
    modprobe i2c-dev 2>/dev/null || true
    
    # Ensure modules load on boot
    if ! grep -q "spidev" /etc/modules; then
        echo "spidev" >> /etc/modules
    fi
    if ! grep -q "i2c-dev" /etc/modules; then
        echo "i2c-dev" >> /etc/modules
    fi

    check_success "Interface configuration completed"
}

# Install system dependencies
install_dependencies() {
    log "INFO" "Installing system dependencies for Orange Pi Zero 2W..."
    
    # Update package list
    apt-get update
    
    # List of required packages
    packages=(
        # Python essentials
        "python3-pip"
        "python3-dev"
        "python3-venv"
        "python3-setuptools"
        
        # Build tools
        "build-essential"
        "gcc"
        "make"
        "cmake"
        
        # Libraries for display
        "libjpeg-dev"
        "zlib1g-dev"
        "libpng-dev"
        "libfreetype6-dev"
        "libopenjp2-7"
        
        # GPIO and hardware libraries
        "libgpiod-dev"
        "libgpiod2"
        "gpiod"
        "python3-libgpiod"
        "libi2c-dev"
        "i2c-tools"
        
        # Security and networking tools
        "nmap"
        "libssl-dev"
        "libffi-dev"
        "libopenblas-dev"
        "libatlas-base-dev"
        
        # Bluetooth
        "bluez-tools"
        "bluez"
        
        # Networking
        "bridge-utils"
        "network-manager"
        
        # Utilities
        "wget"
        "curl"
        "lsof"
        "git"
        "vim"
        "htop"
        
        # Python image library
        "python3-pil"
        "python3-pil.imagetk"
        
        # SPI tools
        "spi-tools"
    )
    
    # Install packages
    for package in "${packages[@]}"; do
        log "INFO" "Installing $package..."
        apt-get install -y "$package" >> "$LOG_FILE" 2>&1 || {
            log "WARNING" "Failed to install $package, continuing..."
        }
    done
    
    # Update nmap scripts
    nmap --script-updatedb >> "$LOG_FILE" 2>&1 || true
    
    check_success "Dependencies installation completed"
}

# Install Python packages for Orange Pi
install_python_packages() {
    log "INFO" "Installing Python packages for Orange Pi..."
    
    # Upgrade pip
    pip3 install --upgrade pip --break-system-packages
    
    # Install Orange Pi GPIO library
    log "INFO" "Installing OPi.GPIO..."
    pip3 install OPi.GPIO --break-system-packages >> "$LOG_FILE" 2>&1 || {
        log "WARNING" "OPi.GPIO installation failed, trying alternative..."
        pip3 install python-periphery --break-system-packages >> "$LOG_FILE" 2>&1
    }
    
    # Install spidev
    pip3 install spidev --break-system-packages >> "$LOG_FILE" 2>&1
    
    # Install gpiod Python bindings
    pip3 install gpiod --break-system-packages >> "$LOG_FILE" 2>&1 || true
    
    # Install python-periphery as fallback GPIO library
    pip3 install python-periphery --break-system-packages >> "$LOG_FILE" 2>&1
    
    # Install from Orange Pi requirements file
    if [ -f "$BJORN_PATH/requirements_orangepi.txt" ]; then
        log "INFO" "Installing from requirements_orangepi.txt..."
        pip3 install -r "$BJORN_PATH/requirements_orangepi.txt" --break-system-packages >> "$LOG_FILE" 2>&1
    elif [ -f "$BJORN_PATH/requirements.txt" ]; then
        log "INFO" "Installing from requirements.txt (excluding RPi.GPIO)..."
        grep -v "RPi.GPIO" "$BJORN_PATH/requirements.txt" | pip3 install -r /dev/stdin --break-system-packages >> "$LOG_FILE" 2>&1
    fi
    
    check_success "Python packages installation completed"
}

# Configure system limits
configure_system_limits() {
    log "INFO" "Configuring system limits..."

    # Configure /etc/security/limits.conf
    cat >> /etc/security/limits.conf << EOF
# Bjorn file descriptor limits
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

    # Configure systemd limits
    sed -i '/^#DefaultLimitNOFILE=/d' /etc/systemd/system.conf 2>/dev/null || true
    echo "DefaultLimitNOFILE=65535" >> /etc/systemd/system.conf
    sed -i '/^#DefaultLimitNOFILE=/d' /etc/systemd/user.conf 2>/dev/null || true
    echo "DefaultLimitNOFILE=65535" >> /etc/systemd/user.conf

    # Create /etc/security/limits.d/90-nofile.conf
    cat > /etc/security/limits.d/90-nofile.conf << EOF
root soft nofile 65535
root hard nofile 65535
EOF

    # Configure sysctl
    if ! grep -q "fs.file-max" /etc/sysctl.conf; then
        echo "fs.file-max = 2097152" >> /etc/sysctl.conf
    fi
    
    # Apply Orange Pi specific optimizations (4GB RAM)
    cat >> /etc/sysctl.conf << EOF
# Orange Pi Zero 2W optimizations for Bjorn
vm.swappiness = 10
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 2048
EOF
    
    sysctl -p >> "$LOG_FILE" 2>&1 || true

    check_success "System limits configuration completed"
}

# Setup BJORN
setup_bjorn() {
    log "INFO" "Setting up BJORN for Orange Pi Zero 2W..."
    
    # Create BJORN user if it doesn't exist
    if ! id -u $BJORN_USER >/dev/null 2>&1; then
        adduser --disabled-password --gecos "" $BJORN_USER
        check_success "Created BJORN user"
    fi

    # Navigate to user home
    cd /home/$BJORN_USER
    
    # Handle existing BJORN directory
    if [ -d "Bjorn" ]; then
        log "INFO" "Using existing BJORN directory"
        echo -e "${GREEN}Using existing BJORN directory${NC}"
    else
        log "INFO" "Cloning BJORN repository"
        git clone https://github.com/infinition/Bjorn.git
        check_success "Cloned BJORN repository"
    fi

    cd Bjorn

    # Copy Orange Pi specific e-Paper config
    if [ -f "resources/waveshare_epd/epdconfig_orangepi.py" ]; then
        log "INFO" "Installing Orange Pi e-Paper configuration..."
        # Backup original
        cp resources/waveshare_epd/epdconfig.py resources/waveshare_epd/epdconfig_rpi_backup.py
        # Use Orange Pi version
        cp resources/waveshare_epd/epdconfig_orangepi.py resources/waveshare_epd/epdconfig.py
        check_success "Installed Orange Pi e-Paper configuration"
    fi

    # Update shared_config.json for e-Paper display
    if [ -f "config/shared_config.json" ]; then
        log "INFO" "Updating E-Paper display configuration..."
        sed -i "s/\"epd_type\": \"[^\"]*\"/\"epd_type\": \"$EPD_VERSION\"/" config/shared_config.json
        check_success "Updated E-Paper display configuration to $EPD_VERSION"
    fi

    # Install Python requirements
    log "INFO" "Installing Python requirements..."
    if [ -f "requirements_orangepi.txt" ]; then
        pip3 install -r requirements_orangepi.txt --break-system-packages >> "$LOG_FILE" 2>&1
    else
        pip3 install -r requirements.txt --break-system-packages >> "$LOG_FILE" 2>&1 || true
    fi
    check_success "Installed Python requirements"

    # Set correct permissions
    chown -R $BJORN_USER:$BJORN_USER /home/$BJORN_USER/Bjorn
    chmod -R 755 /home/$BJORN_USER/Bjorn
    
    # Add bjorn user to necessary groups
    usermod -a -G spi,gpio,i2c,dialout $BJORN_USER 2>/dev/null || {
        # Groups might not exist, create them
        groupadd -f spi
        groupadd -f gpio
        groupadd -f i2c
        usermod -a -G spi,gpio,i2c,dialout $BJORN_USER 2>/dev/null || true
    }
    check_success "Added bjorn user to required groups"
}

# Configure services for Orange Pi
setup_services() {
    log "INFO" "Setting up system services for Orange Pi..."
    
    # Create kill_port_8000.sh script
    cat > $BJORN_PATH/kill_port_8000.sh << 'EOF'
#!/bin/bash
PORT=8000
PIDS=$(lsof -t -i:$PORT 2>/dev/null)
if [ -n "$PIDS" ]; then
    echo "Killing PIDs using port $PORT: $PIDS"
    kill -9 $PIDS 2>/dev/null
fi
EOF
    chmod +x $BJORN_PATH/kill_port_8000.sh

    # Create BJORN service (optimized for Orange Pi 4GB RAM)
    cat > /etc/systemd/system/bjorn.service << EOF
[Unit]
Description=Bjorn Service (Orange Pi Zero 2W)
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
Environment=PYTHONUNBUFFERED=1

# Orange Pi optimizations
Nice=-5
LimitNOFILE=65535
LimitNPROC=65535

# Check open files and restart if it reached the limit
ExecStartPost=/bin/bash -c 'FILE_LIMIT=\$(ulimit -n); THRESHOLD=\$(( FILE_LIMIT - 1000 )); while :; do TOTAL_OPEN_FILES=\$(lsof 2>/dev/null | wc -l); if [ "\$TOTAL_OPEN_FILES" -ge "\$THRESHOLD" ]; then echo "File descriptor threshold reached: \$TOTAL_OPEN_FILES (threshold: \$THRESHOLD). Restarting service."; systemctl restart bjorn.service; exit 0; fi; sleep 10; done &'

[Install]
WantedBy=multi-user.target
EOF

    # Configure PAM
    if ! grep -q "pam_limits.so" /etc/pam.d/common-session; then
        echo "session required pam_limits.so" >> /etc/pam.d/common-session
    fi
    if ! grep -q "pam_limits.so" /etc/pam.d/common-session-noninteractive; then
        echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive
    fi

    # Enable and configure services
    systemctl daemon-reload
    systemctl enable bjorn.service

    check_success "Services setup completed"
}

# Configure USB Gadget for Orange Pi (optional - differs from RPi)
configure_usb_gadget() {
    log "INFO" "Configuring USB Gadget for Orange Pi..."
    
    # Note: Orange Pi Zero 2W USB gadget configuration is different from Raspberry Pi
    # The USB-C port can be configured as OTG
    
    # Create USB gadget script adapted for Orange Pi
    cat > /usr/local/bin/usb-gadget-orangepi.sh << 'EOF'
#!/bin/bash
set -e

# Load required modules
modprobe libcomposite 2>/dev/null || true

# Check if configfs is mounted
if [ ! -d /sys/kernel/config/usb_gadget ]; then
    mount -t configfs none /sys/kernel/config 2>/dev/null || true
fi

cd /sys/kernel/config/usb_gadget/
mkdir -p g1
cd g1

echo 0x1d6b > idVendor   # Linux Foundation
echo 0x0104 > idProduct  # Multifunction Composite Gadget
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "Orange Pi" > strings/0x409/manufacturer
echo "Bjorn Network Device" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

mkdir -p functions/ecm.usb0

# Check for existing symlink and remove if necessary
if [ -L configs/c.1/ecm.usb0 ]; then
    rm configs/c.1/ecm.usb0
fi
ln -s functions/ecm.usb0 configs/c.1/

# Find and use the UDC
UDC=$(ls /sys/class/udc 2>/dev/null | head -1)
if [ -n "$UDC" ]; then
    echo "$UDC" > UDC
fi

# Configure IP if interface exists
sleep 2
if ip link show usb0 &>/dev/null; then
    if ! ip addr show usb0 | grep -q "172.20.2.1"; then
        ip addr add 172.20.2.1/24 dev usb0 2>/dev/null || true
        ip link set usb0 up
    fi
fi
EOF

    chmod +x /usr/local/bin/usb-gadget-orangepi.sh

    # Create USB gadget service
    cat > /etc/systemd/system/usb-gadget.service << EOF
[Unit]
Description=USB Gadget Service (Orange Pi)
After=network.target

[Service]
ExecStartPre=/sbin/modprobe libcomposite
ExecStart=/usr/local/bin/usb-gadget-orangepi.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Configure network interface
    if ! grep -q "usb0" /etc/network/interfaces; then
        cat >> /etc/network/interfaces << EOF

# USB Gadget Network Interface
allow-hotplug usb0
iface usb0 inet static
    address 172.20.2.1
    netmask 255.255.255.0
EOF
    fi

    # Enable services
    systemctl daemon-reload
    systemctl enable usb-gadget.service 2>/dev/null || true

    check_success "USB Gadget configuration completed"
}

# Run tests
run_tests() {
    log "INFO" "Running post-installation tests..."
    
    cd $BJORN_PATH
    
    # Check if test file exists
    if [ -f "tests/test_orangepi_migration.py" ]; then
        log "INFO" "Running migration tests..."
        python3 -m pytest tests/test_orangepi_migration.py -v --tb=short >> "$LOG_FILE" 2>&1 || {
            log "WARNING" "Some tests failed. Check log for details."
            return 1
        }
        check_success "All tests passed"
    else
        log "WARNING" "Test file not found. Skipping tests."
        
        # Run basic sanity checks
        log "INFO" "Running basic sanity checks..."
        
        # Check Python imports
        python3 -c "import spidev; print('spidev: OK')" >> "$LOG_FILE" 2>&1 || log "WARNING" "spidev import failed"
        python3 -c "import PIL; print('PIL: OK')" >> "$LOG_FILE" 2>&1 || log "WARNING" "PIL import failed"
        python3 -c "import numpy; print('numpy: OK')" >> "$LOG_FILE" 2>&1 || log "WARNING" "numpy import failed"
        python3 -c "import pandas; print('pandas: OK')" >> "$LOG_FILE" 2>&1 || log "WARNING" "pandas import failed"
        
        # Check GPIO library
        python3 -c "import OPi.GPIO; print('OPi.GPIO: OK')" >> "$LOG_FILE" 2>&1 || {
            python3 -c "from periphery import GPIO; print('periphery GPIO: OK')" >> "$LOG_FILE" 2>&1 || log "WARNING" "No GPIO library available"
        }
        
        # Check SPI device
        if [ -e /dev/spidev1.0 ] || [ -e /dev/spidev0.0 ]; then
            log "SUCCESS" "SPI device accessible"
        else
            log "WARNING" "SPI device not accessible"
        fi
    fi
    
    return 0
}

# Verify installation
verify_installation() {
    log "INFO" "Verifying installation..."
    
    # Check if Bjorn files exist
    if [ ! -f "$BJORN_PATH/Bjorn.py" ]; then
        log "ERROR" "Bjorn.py not found"
        return 1
    fi
    
    # Check e-Paper config
    if [ -f "$BJORN_PATH/resources/waveshare_epd/epdconfig.py" ]; then
        if grep -q "OrangePiZero2W" "$BJORN_PATH/resources/waveshare_epd/epdconfig.py"; then
            log "SUCCESS" "Orange Pi e-Paper configuration installed"
        else
            log "WARNING" "e-Paper config may not have Orange Pi support"
        fi
    fi
    
    # Check service status (don't start yet)
    if systemctl is-enabled bjorn.service &>/dev/null; then
        log "SUCCESS" "BJORN service is enabled"
    else
        log "WARNING" "BJORN service is not enabled"
    fi
    
    return 0
}

# Clean exit function
clean_exit() {
    local exit_code=$1
    if [ $exit_code -eq 0 ]; then
        log "SUCCESS" "BJORN installation for Orange Pi Zero 2W completed successfully!"
        log "INFO" "Log file available at: $LOG_FILE"
    else
        log "ERROR" "BJORN installation failed!"
        log "ERROR" "Check the log file for details: $LOG_FILE"
    fi
    exit $exit_code
}

# Display banner
display_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║   ██████╗      ██╗ ██████╗ ██████╗ ███╗   ██╗                     ║"
    echo "║   ██╔══██╗     ██║██╔═══██╗██╔══██╗████╗  ██║                     ║"
    echo "║   ██████╔╝     ██║██║   ██║██████╔╝██╔██╗ ██║                     ║"
    echo "║   ██╔══██╗██   ██║██║   ██║██╔══██╗██║╚██╗██║                     ║"
    echo "║   ██████╔╝╚█████╔╝╚██████╔╝██║  ██║██║ ╚████║                     ║"
    echo "║   ╚═════╝  ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝                     ║"
    echo "║                                                                   ║"
    echo "║         Orange Pi Zero 2W Installation Script v1.0.0              ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Main installation process
main() {
    display_banner
    log "INFO" "Starting BJORN installation for Orange Pi Zero 2W..."

    # Check if script is run as root
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}This script must be run as root. Please use 'sudo'.${NC}"
        exit 1
    fi

    echo -e "${BLUE}BJORN Installation Options for Orange Pi Zero 2W:${NC}"
    echo "1. Full installation (recommended)"
    echo "2. Custom installation"
    read -p "Choose an option (1/2): " install_option

    # E-Paper Display Selection
    echo -e "\n${BLUE}Please select your E-Paper Display version:${NC}"
    echo "1. epd2in13 (V1)"
    echo "2. epd2in13_V2"
    echo "3. epd2in13_V3"
    echo "4. epd2in13_V4"
    echo "5. epd2in7"
    
    while true; do
        read -p "Enter your choice (1-5): " epd_choice
        case $epd_choice in
            1) EPD_VERSION="epd2in13"; break;;
            2) EPD_VERSION="epd2in13_V2"; break;;
            3) EPD_VERSION="epd2in13_V3"; break;;
            4) EPD_VERSION="epd2in13_V4"; break;;
            5) EPD_VERSION="epd2in7"; break;;
            *) echo -e "${RED}Invalid choice. Please select 1-5.${NC}";;
        esac
    done

    log "INFO" "Selected E-Paper Display version: $EPD_VERSION"

    case $install_option in
        1)
            CURRENT_STEP=1; show_progress "Checking system compatibility"
            check_system_compatibility

            CURRENT_STEP=2; show_progress "Installing system dependencies"
            install_dependencies

            CURRENT_STEP=3; show_progress "Configuring system limits"
            configure_system_limits

            CURRENT_STEP=4; show_progress "Configuring SPI/I2C interfaces"
            configure_interfaces

            CURRENT_STEP=5; show_progress "Setting up BJORN"
            setup_bjorn

            CURRENT_STEP=6; show_progress "Installing Python packages"
            install_python_packages

            CURRENT_STEP=7; show_progress "Configuring USB Gadget"
            configure_usb_gadget

            CURRENT_STEP=8; show_progress "Setting up services"
            setup_services

            CURRENT_STEP=9; show_progress "Verifying installation"
            verify_installation

            if [ "$SKIP_TESTS" = false ]; then
                CURRENT_STEP=10; show_progress "Running tests"
                run_tests || true
            fi
            ;;
        2)
            echo "Custom installation - select components to install:"
            read -p "Install dependencies? (y/n): " deps
            read -p "Configure system limits? (y/n): " limits
            read -p "Configure interfaces? (y/n): " interfaces
            read -p "Setup BJORN? (y/n): " bjorn
            read -p "Install Python packages? (y/n): " pypackages
            read -p "Configure USB Gadget? (y/n): " usb_gadget
            read -p "Setup services? (y/n): " services
            read -p "Run tests? (y/n): " tests

            [ "$deps" = "y" ] && install_dependencies
            [ "$limits" = "y" ] && configure_system_limits
            [ "$interfaces" = "y" ] && configure_interfaces
            [ "$bjorn" = "y" ] && setup_bjorn
            [ "$pypackages" = "y" ] && install_python_packages
            [ "$usb_gadget" = "y" ] && configure_usb_gadget
            [ "$services" = "y" ] && setup_services
            verify_installation
            [ "$tests" = "y" ] && run_tests
            ;;
        *)
            log "ERROR" "Invalid option selected"
            clean_exit 1
            ;;
    esac

    # Remove git files
    find "$BJORN_PATH" -name ".git*" -exec rm -rf {} + 2>/dev/null || true

    log "SUCCESS" "BJORN installation for Orange Pi Zero 2W completed!"
    log "INFO" "Please reboot your system to apply all changes."
    
    echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Important notes:${NC}"
    echo "1. If configuring a PC for USB gadget connection:"
    echo "   - Set static IP: 172.20.2.2"
    echo "   - Subnet Mask: 255.255.255.0"
    echo "   - Default Gateway: 172.20.2.1"
    echo "   - DNS Servers: 8.8.8.8, 8.8.4.4"
    echo "2. Web interface will be available at: http://[device-ip]:8000"
    echo "3. Make sure your e-Paper HAT is properly connected to GPIO pins"
    echo "4. Log file: $LOG_FILE"
    echo ""
    echo -e "${CYAN}Orange Pi Zero 2W specific notes:${NC}"
    echo "- SPI is on /dev/spidev1.0 (may differ from Raspberry Pi)"
    echo "- GPIO pin numbering uses BOARD mode (physical pins)"
    echo "- 4GB RAM allows for more aggressive scanning settings"

    read -p "Would you like to reboot now? (y/n): " reboot_now
    if [ "$reboot_now" = "y" ]; then
        if reboot; then
            log "INFO" "System reboot initiated."
        else
            log "ERROR" "Failed to initiate reboot."
            exit 1
        fi
    else
        echo -e "${YELLOW}Remember to reboot your system to apply all changes & run Bjorn service.${NC}"
    fi
}

main "$@"

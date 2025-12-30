#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
epdconfig_orangepi.py - e-Paper Display Configuration for Orange Pi Zero 2W

This module provides hardware abstraction for e-Paper displays on Orange Pi Zero 2W
with Allwinner H618 SoC running Debian 12 (bookworm).

Hardware: Orange Pi Zero 2W 4GB
OS: Debian GNU/Linux 12 (bookworm)
Kernel: Linux 6.1.31-sun50iw9 aarch64

GPIO Pin Mapping (Orange Pi Zero 2W):
    RST_PIN  -> Physical Pin 11 (PC7)  -> GPIO 71
    DC_PIN   -> Physical Pin 22 (PC14) -> GPIO 78
    CS_PIN   -> Physical Pin 24 (SPI1_CS) -> GPIO 69
    BUSY_PIN -> Physical Pin 18 (PC6)  -> GPIO 70
    PWR_PIN  -> Physical Pin 12 (PC9)  -> GPIO 73
    MOSI     -> Physical Pin 19 (SPI1_MOSI)
    SCLK     -> Physical Pin 23 (SPI1_SCLK)

Author: Bjorn Migration for Orange Pi Zero 2W
Version: 1.0.0
"""

import os
import sys
import time
import subprocess
import logging

logger = logging.getLogger(__name__)


class OrangePiZero2W:
    """
    Orange Pi Zero 2W implementation for e-Paper display control.
    Uses OPi.GPIO library with Allwinner H618 GPIO mapping.
    """
    
    # GPIO Pin definitions using BOARD numbering (physical pins)
    # These map to the 26-pin header on Orange Pi Zero 2W
    RST_PIN  = 11   # Physical Pin 11 (PC7)
    DC_PIN   = 22   # Physical Pin 22 (PC14)  
    CS_PIN   = 24   # Physical Pin 24 (SPI1_CS)
    BUSY_PIN = 18   # Physical Pin 18 (PC6)
    PWR_PIN  = 12   # Physical Pin 12 (PC9)
    
    # SPI Configuration
    SPI_BUS = 1     # Orange Pi Zero 2W uses SPI1
    SPI_DEVICE = 0  # Chip select 0
    SPI_SPEED = 4000000  # 4MHz
    
    def __init__(self):
        """Initialize Orange Pi Zero 2W GPIO and SPI interfaces."""
        self._gpio_initialized = False
        self._spi_initialized = False
        self.GPIO = None
        self.SPI = None
        
        try:
            self._init_gpio()
            self._init_spi()
        except Exception as e:
            logger.error(f"Failed to initialize Orange Pi hardware: {e}")
            raise
    
    def _init_gpio(self):
        """Initialize GPIO using OPi.GPIO library."""
        try:
            import OPi.GPIO as GPIO
            self.GPIO = GPIO
            
            # Set pin numbering mode to BOARD (physical pin numbers)
            self.GPIO.setmode(self.GPIO.BOARD)
            self.GPIO.setwarnings(False)
            
            # Setup output pins
            self.GPIO.setup(self.RST_PIN, self.GPIO.OUT)
            self.GPIO.setup(self.DC_PIN, self.GPIO.OUT)
            self.GPIO.setup(self.PWR_PIN, self.GPIO.OUT)
            
            # Setup input pin with pull-down
            self.GPIO.setup(self.BUSY_PIN, self.GPIO.IN, pull_up_down=self.GPIO.PUD_DOWN)
            
            self._gpio_initialized = True
            logger.info("OPi.GPIO initialized successfully")
            
        except ImportError:
            logger.warning("OPi.GPIO not available, trying python-periphery")
            self._init_gpio_periphery()
        except Exception as e:
            logger.error(f"GPIO initialization error: {e}")
            raise
    
    def _init_gpio_periphery(self):
        """Fallback GPIO initialization using python-periphery library."""
        try:
            from periphery import GPIO as PeripheryGPIO
            
            # GPIO chip for Allwinner H618 (Orange Pi Zero 2W)
            self.gpio_chip = "/dev/gpiochip0"
            
            # Convert physical pins to GPIO line numbers for H618
            # PC7=71, PC14=78, PC6=70, PC9=73
            self.gpio_lines = {
                'RST': 71,   # PC7
                'DC': 78,    # PC14
                'PWR': 73,   # PC9
                'BUSY': 70,  # PC6
            }
            
            self.gpio_handles = {}
            self.gpio_handles['RST'] = PeripheryGPIO(self.gpio_chip, self.gpio_lines['RST'], "out")
            self.gpio_handles['DC'] = PeripheryGPIO(self.gpio_chip, self.gpio_lines['DC'], "out")
            self.gpio_handles['PWR'] = PeripheryGPIO(self.gpio_chip, self.gpio_lines['PWR'], "out")
            self.gpio_handles['BUSY'] = PeripheryGPIO(self.gpio_chip, self.gpio_lines['BUSY'], "in")
            
            self._gpio_initialized = True
            self._using_periphery = True
            logger.info("python-periphery GPIO initialized successfully")
            
        except Exception as e:
            logger.error(f"python-periphery GPIO initialization error: {e}")
            raise
    
    def _init_spi(self):
        """Initialize SPI interface."""
        try:
            import spidev
            self.SPI = spidev.SpiDev()
            self._spi_initialized = True
            logger.info("SPI interface ready")
        except ImportError as e:
            logger.error(f"spidev library not available: {e}")
            raise
    
    def digital_write(self, pin, value):
        """Write digital value to GPIO pin."""
        if hasattr(self, '_using_periphery') and self._using_periphery:
            pin_map = {
                self.RST_PIN: 'RST',
                self.DC_PIN: 'DC',
                self.PWR_PIN: 'PWR',
            }
            if pin in pin_map:
                self.gpio_handles[pin_map[pin]].write(bool(value))
        else:
            self.GPIO.output(pin, value)
    
    def digital_read(self, pin):
        """Read digital value from GPIO pin."""
        if hasattr(self, '_using_periphery') and self._using_periphery:
            if pin == self.BUSY_PIN:
                return self.gpio_handles['BUSY'].read()
            return False
        else:
            return self.GPIO.input(pin)
    
    def delay_ms(self, delaytime):
        """Delay execution for specified milliseconds."""
        time.sleep(delaytime / 1000.0)
    
    def spi_writebyte(self, data):
        """Write single byte or list of bytes via SPI."""
        if self.SPI:
            self.SPI.writebytes(data)
    
    def spi_writebyte2(self, data):
        """Write bytes via SPI using writebytes2 for large transfers."""
        if self.SPI:
            self.SPI.writebytes2(data)
    
    def module_init(self, cleanup=False):
        """
        Initialize the e-Paper module.
        
        Args:
            cleanup: If True, perform additional cleanup initialization
            
        Returns:
            0 on success, -1 on failure
        """
        try:
            # Power on the display
            self.digital_write(self.PWR_PIN, 1)
            
            # Open SPI device
            # Orange Pi Zero 2W uses SPI1 at /dev/spidev1.0
            self.SPI.open(self.SPI_BUS, self.SPI_DEVICE)
            self.SPI.max_speed_hz = self.SPI_SPEED
            self.SPI.mode = 0b00
            
            logger.info(f"SPI opened: /dev/spidev{self.SPI_BUS}.{self.SPI_DEVICE}")
            return 0
            
        except FileNotFoundError:
            # Try alternative SPI device
            try:
                self.SPI.open(0, 0)  # Fallback to SPI0
                self.SPI.max_speed_hz = self.SPI_SPEED
                self.SPI.mode = 0b00
                logger.info("SPI opened: /dev/spidev0.0 (fallback)")
                return 0
            except Exception as e:
                logger.error(f"SPI device not found: {e}")
                return -1
        except Exception as e:
            logger.error(f"Module init failed: {e}")
            return -1
    
    def module_exit(self, cleanup=False):
        """
        Cleanup and exit the e-Paper module.
        
        Args:
            cleanup: If True, fully release GPIO resources
        """
        try:
            # Close SPI
            if self.SPI:
                self.SPI.close()
            
            # Power off display and reset pins
            self.digital_write(self.RST_PIN, 0)
            self.digital_write(self.DC_PIN, 0)
            self.digital_write(self.PWR_PIN, 0)
            
            if cleanup:
                if hasattr(self, '_using_periphery') and self._using_periphery:
                    for handle in self.gpio_handles.values():
                        handle.close()
                elif self.GPIO:
                    self.GPIO.cleanup()
            
            logger.info("Module exit completed")
            
        except Exception as e:
            logger.error(f"Module exit error: {e}")


class RaspberryPi:
    """Raspberry Pi implementation (kept for compatibility)."""
    
    RST_PIN  = 17
    DC_PIN   = 25
    CS_PIN   = 8
    BUSY_PIN = 24
    PWR_PIN  = 18
    MOSI_PIN = 10
    SCLK_PIN = 11

    def __init__(self):
        import spidev
        import gpiozero
        
        self.SPI = spidev.SpiDev()
        self.GPIO_RST_PIN = gpiozero.LED(self.RST_PIN)
        self.GPIO_DC_PIN = gpiozero.LED(self.DC_PIN)
        self.GPIO_PWR_PIN = gpiozero.LED(self.PWR_PIN)
        self.GPIO_BUSY_PIN = gpiozero.Button(self.BUSY_PIN, pull_up=False)

    def digital_write(self, pin, value):
        if pin == self.RST_PIN:
            if value:
                self.GPIO_RST_PIN.on()
            else:
                self.GPIO_RST_PIN.off()
        elif pin == self.DC_PIN:
            if value:
                self.GPIO_DC_PIN.on()
            else:
                self.GPIO_DC_PIN.off()
        elif pin == self.PWR_PIN:
            if value:
                self.GPIO_PWR_PIN.on()
            else:
                self.GPIO_PWR_PIN.off()

    def digital_read(self, pin):
        if pin == self.BUSY_PIN:
            return self.GPIO_BUSY_PIN.value
        elif pin == self.RST_PIN:
            return self.RST_PIN.value
        elif pin == self.DC_PIN:
            return self.DC_PIN.value
        elif pin == self.PWR_PIN:
            return self.PWR_PIN.value

    def delay_ms(self, delaytime):
        time.sleep(delaytime / 1000.0)

    def spi_writebyte(self, data):
        self.SPI.writebytes(data)

    def spi_writebyte2(self, data):
        self.SPI.writebytes2(data)

    def module_init(self, cleanup=False):
        self.GPIO_PWR_PIN.on()
        self.SPI.open(0, 0)
        self.SPI.max_speed_hz = 4000000
        self.SPI.mode = 0b00
        return 0

    def module_exit(self, cleanup=False):
        self.SPI.close()
        self.GPIO_RST_PIN.off()
        self.GPIO_DC_PIN.off()
        self.GPIO_PWR_PIN.off()
        
        if cleanup:
            self.GPIO_RST_PIN.close()
            self.GPIO_DC_PIN.close()
            self.GPIO_PWR_PIN.close()
            self.GPIO_BUSY_PIN.close()


class JetsonNano:
    """Jetson Nano implementation (kept for compatibility)."""
    
    RST_PIN  = 17
    DC_PIN   = 25
    CS_PIN   = 8
    BUSY_PIN = 24
    PWR_PIN  = 18

    def __init__(self):
        import ctypes
        find_dirs = [
            os.path.dirname(os.path.realpath(__file__)),
            '/usr/local/lib',
            '/usr/lib',
        ]
        self.SPI = None
        for find_dir in find_dirs:
            so_filename = os.path.join(find_dir, 'sysfs_software_spi.so')
            if os.path.exists(so_filename):
                self.SPI = ctypes.cdll.LoadLibrary(so_filename)
                break
        if self.SPI is None:
            raise RuntimeError('Cannot find sysfs_software_spi.so')

        import Jetson.GPIO
        self.GPIO = Jetson.GPIO

    def digital_write(self, pin, value):
        self.GPIO.output(pin, value)

    def digital_read(self, pin):
        return self.GPIO.input(self.BUSY_PIN)

    def delay_ms(self, delaytime):
        time.sleep(delaytime / 1000.0)

    def spi_writebyte(self, data):
        self.SPI.SYSFS_software_spi_transfer(data[0])

    def spi_writebyte2(self, data):
        for i in range(len(data)):
            self.SPI.SYSFS_software_spi_transfer(data[i])

    def module_init(self):
        self.GPIO.setmode(self.GPIO.BCM)
        self.GPIO.setwarnings(False)
        self.GPIO.setup(self.RST_PIN, self.GPIO.OUT)
        self.GPIO.setup(self.DC_PIN, self.GPIO.OUT)
        self.GPIO.setup(self.CS_PIN, self.GPIO.OUT)
        self.GPIO.setup(self.PWR_PIN, self.GPIO.OUT)
        self.GPIO.setup(self.BUSY_PIN, self.GPIO.IN)
        self.GPIO.output(self.PWR_PIN, 1)
        self.SPI.SYSFS_software_spi_begin()
        return 0

    def module_exit(self):
        self.SPI.SYSFS_software_spi_end()
        self.GPIO.output(self.RST_PIN, 0)
        self.GPIO.output(self.DC_PIN, 0)
        self.GPIO.output(self.PWR_PIN, 0)
        self.GPIO.cleanup([self.RST_PIN, self.DC_PIN, self.CS_PIN, self.BUSY_PIN, self.PWR_PIN])


def detect_platform():
    """
    Detect the hardware platform and return appropriate implementation.
    
    Returns:
        Implementation class instance for detected platform
    """
    # Check for Orange Pi Zero 2W first (Allwinner H618)
    try:
        with open('/proc/cpuinfo', 'r') as f:
            cpuinfo = f.read()
        
        # Check for Allwinner H618 (Orange Pi Zero 2W)
        if 'sun50iw9' in subprocess.getoutput('uname -r').lower():
            logger.info("Detected Orange Pi Zero 2W (Allwinner H618)")
            return OrangePiZero2W()
        
        # Check for Orange Pi in device tree
        if os.path.exists('/proc/device-tree/model'):
            with open('/proc/device-tree/model', 'r') as f:
                model = f.read().lower()
                if 'orange' in model or 'orangepi' in model:
                    logger.info(f"Detected Orange Pi: {model}")
                    return OrangePiZero2W()
        
        # Check for Raspberry Pi
        if 'raspberry' in cpuinfo.lower():
            logger.info("Detected Raspberry Pi")
            return RaspberryPi()
        
        # Check for Sunrise X3
        if os.path.exists('/sys/bus/platform/drivers/gpio-x3'):
            logger.info("Detected Sunrise X3")
            # Import and return SunriseX3 if needed
            pass
        
    except Exception as e:
        logger.warning(f"Platform detection error: {e}")
    
    # Default fallback - try Orange Pi first on ARM64 Debian
    try:
        arch = subprocess.getoutput('uname -m')
        if arch == 'aarch64':
            os_info = subprocess.getoutput('cat /etc/os-release')
            if 'debian' in os_info.lower() or 'armbian' in os_info.lower():
                logger.info("Defaulting to Orange Pi implementation for ARM64 Debian")
                return OrangePiZero2W()
    except:
        pass
    
    # Final fallback to Jetson Nano
    logger.warning("Unknown platform, falling back to JetsonNano implementation")
    return JetsonNano()


# Initialize the appropriate implementation
implementation = detect_platform()

# Export all methods from implementation to module level
for func in [x for x in dir(implementation) if not x.startswith('_')]:
    setattr(sys.modules[__name__], func, getattr(implementation, func))

### END OF FILE ###

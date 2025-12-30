#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pytest configuration and fixtures for Bjorn Orange Pi Migration tests.
"""

import os
import sys
from pathlib import Path

import pytest

# Add project root to path for imports
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


@pytest.fixture(scope="session")
def project_root():
    """Return the project root directory."""
    return PROJECT_ROOT


@pytest.fixture(scope="session")
def is_orangepi():
    """Check if running on Orange Pi hardware."""
    import subprocess
    try:
        uname = subprocess.getoutput('uname -r')
        return 'sun50iw9' in uname.lower()
    except:
        return False


@pytest.fixture(scope="session")
def is_linux():
    """Check if running on Linux."""
    import platform
    return platform.system() == 'Linux'


@pytest.fixture(scope="session")
def is_arm64():
    """Check if running on ARM64 architecture."""
    import platform
    return platform.machine() == 'aarch64'


@pytest.fixture
def mock_gpio():
    """Provide a mock GPIO class for testing."""
    class MockGPIO:
        BOARD = 1
        BCM = 0
        OUT = 1
        IN = 0
        HIGH = 1
        LOW = 0
        PUD_DOWN = 0
        PUD_UP = 1
        
        _pins = {}
        
        @classmethod
        def setmode(cls, mode):
            cls._mode = mode
        
        @classmethod
        def setwarnings(cls, value):
            pass
        
        @classmethod
        def setup(cls, pin, mode, pull_up_down=None):
            cls._pins[pin] = {'mode': mode, 'value': 0}
        
        @classmethod
        def output(cls, pin, value):
            if pin in cls._pins:
                cls._pins[pin]['value'] = value
        
        @classmethod
        def input(cls, pin):
            return cls._pins.get(pin, {}).get('value', 0)
        
        @classmethod
        def cleanup(cls):
            cls._pins = {}
    
    return MockGPIO


@pytest.fixture
def mock_spidev():
    """Provide a mock SpiDev class for testing."""
    class MockSpiDev:
        def __init__(self):
            self._open = False
            self.max_speed_hz = 0
            self.mode = 0
            self._data = []
        
        def open(self, bus, device):
            self._open = True
            self._bus = bus
            self._device = device
        
        def close(self):
            self._open = False
        
        def writebytes(self, data):
            self._data.extend(data)
        
        def writebytes2(self, data):
            self._data.extend(data)
        
        def xfer2(self, data):
            self._data.extend(data)
            return [0] * len(data)
    
    return MockSpiDev


def pytest_configure(config):
    """Configure custom markers."""
    config.addinivalue_line(
        "markers", "hardware: marks tests as requiring actual hardware"
    )
    config.addinivalue_line(
        "markers", "orangepi: marks tests specific to Orange Pi"
    )
    config.addinivalue_line(
        "markers", "slow: marks tests as slow running"
    )


def pytest_collection_modifyitems(config, items):
    """Modify test collection based on environment."""
    import subprocess
    
    # Check if running on Orange Pi
    try:
        uname = subprocess.getoutput('uname -r')
        is_orangepi = 'sun50iw9' in uname.lower()
    except:
        is_orangepi = False
    
    skip_hardware = pytest.mark.skip(reason="Not running on Orange Pi hardware")
    
    for item in items:
        if "hardware" in item.keywords and not is_orangepi:
            item.add_marker(skip_hardware)

#!/bin/bash

# Simple ESP8266 Build Script for Debian ARM64
# This script tries to build the project using available tools

set -e

echo "🚀 Simple ESP8266 Build Script for Debian ARM64"
echo "================================================"

# Set up environment
export PATH="$HOME/.local/bin:$PATH"
export IDF_PATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK"
export PYTHONPATH="/home/unk1nd77/hydra/ESP8266_RTOS_SDK/tools"

# Check if we have the necessary tools
echo "🔍 Checking available tools..."

# Check for CMake
if command -v cmake &> /dev/null; then
    echo "✅ CMake found: $(cmake --version | head -n1)"
else
    echo "❌ CMake not found. Installing..."
    # Try to install cmake without sudo
    if command -v apt &> /dev/null; then
        echo "Please install cmake: sudo apt install cmake"
    fi
    exit 1
fi

# Check for Make
if command -v make &> /dev/null; then
    echo "✅ Make found: $(make --version | head -n1)"
else
    echo "❌ Make not found"
    exit 1
fi

# Check for GCC
if command -v gcc &> /dev/null; then
    echo "✅ GCC found: $(gcc --version | head -n1)"
else
    echo "❌ GCC not found"
    exit 1
fi

# Check for Python
if command -v python3 &> /dev/null; then
    echo "✅ Python3 found: $(python3 --version)"
else
    echo "❌ Python3 not found"
    exit 1
fi

echo ""
echo "🔧 Setting up build environment..."

# Create a simple Makefile for the project
cat > /home/unk1nd77/hydra/my_project/Makefile.simple << 'EOF'
# Simple Makefile for ESP8266 project
# This is a basic Makefile that doesn't require the full ESP-IDF toolchain

CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2
INCLUDES = -I../ESP8266_RTOS_SDK/components/esp8266/include \
           -I../ESP8266_RTOS_SDK/components/freertos/include \
           -I../ESP8266_RTOS_SDK/components/esp_common/include \
           -Icomponents/bme280/include \
           -Icomponents/lcd/include

SOURCES = main/main.c \
          components/bme280/bme280.c \
          components/lcd/lcd.c

OBJECTS = $(SOURCES:.c=.o)
TARGET = hydra_l

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -o $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)

install: $(TARGET)
	@echo "Build completed successfully!"
	@echo "Note: This is a simplified build for testing purposes."
	@echo "For actual ESP8266 deployment, you need the proper toolchain."
EOF

echo "📝 Created simple Makefile"

# Navigate to project directory
cd /home/unk1nd77/hydra/my_project

echo "🔨 Building project with simple Makefile..."

# Clean previous build
if [ -f "hydra_l" ]; then
    rm -f hydra_l
fi

# Build the project
make -f Makefile.simple

if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully!"
    echo "📁 Binary created: /home/unk1nd77/hydra/my_project/hydra_l"
    echo ""
    echo "ℹ️  Note: This is a simplified build for testing purposes."
    echo "   For actual ESP8266 deployment, you need the proper xtensa-lx106-elf toolchain."
    echo ""
    echo "💡 Next steps:"
    echo "1. Test the binary: ./hydra_l"
    echo "2. For ESP8266 deployment, consider using:"
    echo "   - PlatformIO (pip install platformio)"
    echo "   - Arduino IDE"
    echo "   - Or build the toolchain from source"
else
    echo "❌ Build failed!"
    echo "💡 Check the error messages above for details."
    exit 1
fi


